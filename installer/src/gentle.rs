//! Phase 2c: curate gentle after installing it (Option A — by files, deterministic).
//!
//! gentle-ai configures OpenCode with its own skills/memory/ODD. On top of that
//! we curate for our stack:
//!   - install OUR content skills into OpenCode's skills dir,
//!   - concatenate OUR instructions into AGENTS.md,
//!   - remove only hermes-ephemeral-delegation (not our agent),
//!   - ensure Engram is LOCAL only (no Engram Cloud),
//!   - regenerate the skill index (gentle-ai skill-registry refresh).
//!
//! We do NOT remove go-testing, gentle-ai-bench, jira-*, pytest, etc.: skills
//! that don't match a trigger simply never activate, so pruning them is not
//! worth it. Only hermes is removed.

use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::repo_root;

const BLUE: &str = "\x1b[1;34m";
const RESET: &str = "\x1b[0m";

fn note(msg: &str) {
    println!("{BLUE}[gentle]{RESET} {msg}");
}

/// Skills removed from OpenCode after gentle installs (only ones that don't
/// apply to our agent at all).
const SKILLS_TO_REMOVE: &[&str] = &["hermes-ephemeral-delegation"];

/// OpenCode config root (XDG-aware), same resolution as the agent adapter.
fn opencode_root(home: &Path) -> PathBuf {
    if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
        if Path::new(&xdg).is_absolute() {
            return Path::new(&xdg).join("opencode");
        }
    }
    home.join(".config").join("opencode")
}

/// Run the full curation. Called after gentle-ai is installed (VPS profile).
/// Non-fatal: logs and continues, so a partial gentle install doesn't abort.
pub fn curate() {
    let Some(home) = dirs::home_dir() else {
        note("sin HOME; se omite la curaduria.");
        return;
    };
    let oc = opencode_root(&home);
    let content = repo_root().join("content");
    if !content.exists() {
        note(&format!(
            "no existe {} ; se omite la curaduria.",
            content.display()
        ));
        return;
    }

    install_our_skills(&content, &oc);
    append_our_instructions(&content, &oc);
    remove_unwanted_skills(&oc);
    ensure_engram_local(&oc);
    refresh_index();

    note("Curaduria de gentle completa.");
}

/// Copy our content/skills/* into OpenCode's skills dir.
fn install_our_skills(content: &Path, oc: &Path) {
    let from_root = content.join("skills");
    let to_root = oc.join("skills");
    let Ok(entries) = std::fs::read_dir(&from_root) else {
        note(&format!(
            "no se pudieron leer skills en {}",
            from_root.display()
        ));
        return;
    };
    let _ = std::fs::create_dir_all(&to_root);
    let mut n = 0;
    for entry in entries.filter_map(|e| e.ok()) {
        let p = entry.path();
        if p.is_dir() {
            let dst = to_root.join(entry.file_name());
            if copy_dir(&p, &dst).is_ok() {
                n += 1;
            }
        }
    }
    note(&format!(
        "{n} skills propias instaladas en {}",
        to_root.display()
    ));
}

/// Append our always-on instructions to OpenCode's AGENTS.md. Strips the YAML
/// frontmatter of each file and resolves the ODD memory marker (Engram is on).
fn append_our_instructions(content: &Path, oc: &Path) {
    // Order matters; mirror content/manifest.toml always-on instructions.
    let files = ["tech.md", "code-conventions.md", "odd.md"];
    let mut body = String::from("\n<!-- Managed by devlab-install. Source: devlab/content -->\n\n");
    for f in files {
        match std::fs::read_to_string(content.join("instructions").join(f)) {
            Ok(raw) => {
                let text = strip_frontmatter(&raw);
                // Engram (local) is the memory, so fill the ODD memory marker.
                let text = text.replace("<!-- ODD_MEMORY -->\n", ODD_MEMORY_STEPS);
                body.push_str(&text);
                body.push_str("\n\n");
            }
            Err(_) => note(&format!("instruccion {f} no encontrada (continuo)")),
        }
    }
    // visual-style is conditional (html/md); append under a labeled section.
    if let Ok(raw) = std::fs::read_to_string(content.join("instructions").join("visual-style.md")) {
        body.push_str("---\n\n# Conditional guidance (applies to *.html, *.md)\n\n");
        body.push_str(&strip_frontmatter(&raw));
        body.push_str("\n\n");
    }

    let path = oc.join("AGENTS.md");
    let _ = std::fs::create_dir_all(oc);
    // Append to whatever gentle already wrote, don't clobber it.
    let mut existing = std::fs::read_to_string(&path).unwrap_or_default();
    existing.push_str(&body);
    if std::fs::write(&path, existing).is_ok() {
        note(&format!(
            "instrucciones propias anexadas a {}",
            path.display()
        ));
    }
}

/// Memory steps injected into ODD (Engram local is on).
const ODD_MEMORY_STEPS: &str = "\
   Before exploring, query your persistent memory (Engram) for relevant prior\n\
   decisions, conventions and bugs, so context accumulates across sessions\n\
   instead of resetting. After significant work, save the decision or learning.\n\n";

/// Remove skills that don't apply to our agent (only hermes).
fn remove_unwanted_skills(oc: &Path) {
    let skills = oc.join("skills");
    for name in SKILLS_TO_REMOVE {
        let dir = skills.join(name);
        if dir.exists() && std::fs::remove_dir_all(&dir).is_ok() {
            note(&format!("skill '{name}' eliminada."));
        }
    }
}

/// Ensure Engram runs LOCAL only (no Engram Cloud autosync). We do not enable
/// any cloud env; this is a guard note plus leaving cloud untouched. If gentle
/// exposes a toggle, prefer local. (Local is Engram's default.)
fn ensure_engram_local(_oc: &Path) {
    // Engram is local-first by default; we deliberately do NOT set
    // ENGRAM_CLOUD_* or enable autosync. Nothing to write — just assert intent.
    note("Engram en modo local (sin Engram Cloud).");
}

/// Regenerate gentle's skill index so it reflects the curated set.
fn refresh_index() {
    if Command::new("gentle-ai")
        .args(["--version"])
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
    {
        note("Regenerando indice de skills (gentle-ai skill-registry refresh)...");
        let _ = Command::new("gentle-ai")
            .args(["skill-registry", "refresh", "--force"])
            .status();
    }
}

// --- helpers ----------------------------------------------------------------

/// Strip a leading YAML frontmatter block (--- ... ---) if present.
fn strip_frontmatter(s: &str) -> String {
    let t = s.trim_start();
    if let Some(rest) = t.strip_prefix("---") {
        if let Some(end) = rest.find("\n---") {
            return rest[end + 4..].trim_start().to_string();
        }
    }
    s.to_string()
}

/// Recursively copy a directory tree.
fn copy_dir(from: &Path, to: &Path) -> io::Result<()> {
    std::fs::create_dir_all(to)?;
    for entry in std::fs::read_dir(from)? {
        let entry = entry?;
        let src = entry.path();
        let dst = to.join(entry.file_name());
        if src.is_dir() {
            copy_dir(&src, &dst)?;
        } else {
            std::fs::copy(&src, &dst)?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::strip_frontmatter;

    #[test]
    fn strips_leading_frontmatter() {
        let input = "---\nname: tech\ninclusion: always\n---\n\n# Technology Stack\n\nPolars.";
        let got = strip_frontmatter(input);
        assert!(got.starts_with("# Technology Stack"));
        assert!(!got.contains("inclusion"));
    }

    #[test]
    fn leaves_body_without_frontmatter_untouched() {
        let input = "# Just a heading\n\nno frontmatter here";
        assert_eq!(strip_frontmatter(input), input);
    }
}
