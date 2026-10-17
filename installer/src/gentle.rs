//! Phase 2c: curate gentle/Pi after installing it (Option A — by files).
//!
//! The content (skills + instructions + manifest) is NOT vendored here: it
//! lives in the standalone `bit-crew/prim-skills` repo so any agent can reuse
//! it. This module clones that repo to a temp dir, curates it into the Pi /
//! gentle-ai install, then removes the clone so no content lingers on the VPS.
//!
//! Curation on top of what gentle-ai already provisions:
//!   - install OUR skills into Pi's user skills dir (~/.pi/agent/skills),
//!   - concatenate OUR instructions into Pi's AGENTS.md,
//!   - remove only hermes-ephemeral-delegation (not our agent),
//!   - keep Engram LOCAL only (no Engram Cloud),
//!   - refresh the skill registry so Pi sees the curated set.
//!
//! Pi's user skill scan roots are defined by gentle-pi's skill-registry; the
//! canonical one for Pi is ~/.pi/agent/skills (verified against gentle-pi).
//!
//! Non-fatal: logs and continues, so a partial install does not abort.

use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

const BLUE: &str = "\x1b[1;34m";
const RESET: &str = "\x1b[0m";

fn note(msg: &str) {
    println!("{BLUE}[gentle]{RESET} {msg}");
}

/// Content repo cloned at install time (content only, agent-agnostic).
const SKILLS_REPO: &str = "https://github.com/bit-crew/prim-skills.git";

/// Skills removed after gentle installs (only ones that don't apply to us).
const SKILLS_TO_REMOVE: &[&str] = &["hermes-ephemeral-delegation"];

/// Pi's user skills directory (the canonical scan root for the Pi agent).
fn pi_skills_dir(home: &Path) -> PathBuf {
    home.join(".pi").join("agent").join("skills")
}

/// Pi's agent config dir, where AGENTS.md lives.
fn pi_agent_dir(home: &Path) -> PathBuf {
    home.join(".pi").join("agent")
}

/// Run the full curation. Called after gentle-ai is installed (VPS profile).
pub fn curate() {
    let Some(home) = dirs::home_dir() else {
        note("sin HOME; se omite la curaduria.");
        return;
    };

    // Clone the content repo to a temp dir; remove it at the end.
    let Some(content) = clone_content() else {
        note("no se pudo clonar prim-skills; se omite la curaduria.");
        return;
    };

    install_our_skills(&content, &pi_skills_dir(&home));
    append_our_instructions(&content, &pi_agent_dir(&home));
    remove_unwanted_skills(&pi_skills_dir(&home));
    ensure_engram_local();
    refresh_index();

    let _ = std::fs::remove_dir_all(&content);
    note("Curaduria de Pi/gentle completa (clon de prim-skills eliminado).");
}

/// Clone prim-skills into a fresh temp dir. Returns the clone path on success.
fn clone_content() -> Option<PathBuf> {
    let base = std::env::temp_dir().join(format!("prim-skills-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&base);
    note("Clonando prim-skills (contenido agnostico)...");
    let ok = Command::new("git")
        .args(["clone", "--depth", "1", SKILLS_REPO])
        .arg(&base)
        .status()
        .map(|s| s.success())
        .unwrap_or(false);
    if ok {
        Some(base)
    } else {
        None
    }
}

/// Copy content/skills/* into Pi's user skills dir.
fn install_our_skills(content: &Path, dst_root: &Path) {
    let from_root = content.join("skills");
    let Ok(entries) = std::fs::read_dir(&from_root) else {
        note(&format!(
            "no se pudieron leer skills en {}",
            from_root.display()
        ));
        return;
    };
    let _ = std::fs::create_dir_all(dst_root);
    let mut n = 0;
    for entry in entries.filter_map(|e| e.ok()) {
        let p = entry.path();
        if p.is_dir() {
            let dst = dst_root.join(entry.file_name());
            if copy_dir(&p, &dst).is_ok() {
                n += 1;
            }
        }
    }
    note(&format!(
        "{n} skills propias instaladas en {}",
        dst_root.display()
    ));
}

/// Append our always-on instructions to Pi's AGENTS.md. Strips the YAML
/// frontmatter of each file and resolves the ODD memory marker (Engram is on).
fn append_our_instructions(content: &Path, agent_dir: &Path) {
    // Order matters; mirror manifest.toml always-on instructions.
    let files = ["tech.md", "code-conventions.md", "odd.md"];
    let mut body = String::from("\n<!-- Managed by devlab-install. Source: prim-skills -->\n\n");
    for f in files {
        match std::fs::read_to_string(content.join("instructions").join(f)) {
            Ok(raw) => {
                let text = strip_frontmatter(&raw);
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

    let path = agent_dir.join("AGENTS.md");
    let _ = std::fs::create_dir_all(agent_dir);
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
fn remove_unwanted_skills(skills_dir: &Path) {
    for name in SKILLS_TO_REMOVE {
        let dir = skills_dir.join(name);
        if dir.exists() && std::fs::remove_dir_all(&dir).is_ok() {
            note(&format!("skill '{name}' eliminada."));
        }
    }
}

/// Keep Engram LOCAL only. We deliberately do NOT set ENGRAM_CLOUD_* or enable
/// autosync; local is Engram's default. This is an intent assertion.
fn ensure_engram_local() {
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
