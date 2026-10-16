



---
name: setup
description: Initialize new Python projects with complete tooling. Use when starting a new project or setting up environment from scratch.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Setup Skill

Complete project initialization workflow for Python 3.12+ projects.

## Workflow Sequence

Execute steps in order:

### 1. Initialize Git
```bash
git init
git add .
git commit -m "Initial commit"
```

### 2. Create .gitignore
Copy from `skills/devops/assets/.gitignore` or create minimal:
```
__pycache__/
*.py[cod]
.env
.venv/
*.egg-info/
dist/
build/
.pytest_cache/
.ruff_cache/
.secrets.baseline
```

### 3. Copy Configuration Files
From `skills/devops/assets/`:
- `pyproject.toml` - project metadata + tool configs
- `.pre-commit-config.yaml` - pre-commit hooks

### 4. Install Dependencies
```bash
python -m pip install -e ".[dev]"
pre-commit install
pre-commit install --hook-type commit-msg --hook-type pre-push
```

### 5. Validate Setup
```bash
makevalidate  # or ruff check && ruff format --check && bandit -c pyproject.toml -r skills/
```

## Configuration Templates Location

```
skills/devops/assets/
├── pyproject.toml          # Ruff, codespell, pytest config
├── .pre-commit-config.yaml # All hooks (security, lint, format)
├── .gitignore             # Python project ignores
└── Makefile               # Common targets (optional)
```

## Makefile Target Template

```makefile
.PHONY: install test lint format validate clean

install:
    python -m pip install -e ".[dev]"
    pre-commit install

test:
    pytest

lint:
    ruff check .

format:
    ruff format .

validate:
    ruff check . && ruff format --check . && bandit -c pyproject.toml -r skills/

clean:
    rm -rf __pycache__/ .pytest_cache/ .ruff_cache/ *.egg-info/
```

## Tool Version Checks

Ensure installed versions match config:
- Python >= 3.12
- ruff >= 0.9.4
- bandit >= 1.8.2
- semgrep >= 1.97.0
- safety >= 3.3.0

## Post-Setup Validation

After initial setup, verify:
1. `ruff check .` passes
2. `ruff format --check .` passes
3. `bandit -r skills/` passes
4. `pre-commit run --all-files` passes

## Asset Copy Commands

```bash
cp skills/devops/assets/pyproject.toml .
cp skills/devops/assets/.pre-commit-config.yaml .
cp skills/devops/assets/.gitignore .
```
