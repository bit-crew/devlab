CONFIG_DIR = $(HOME)/.config
STOW_DIR = $(CURDIR)
BIN_DIR = $(HOME)/.local/bin

PACKAGES_CONFIG = ghostty helix zellij lazygit atuin

OS := $(shell uname -s | tr A-Z a-z)
ARCH := $(shell uname -m)

# Normalización de arquitecturas para descargas
ifeq ($(ARCH),x86_64)
	ARCH = x86_64
else ifeq ($(ARCH),arm64)
	ARCH = aarch64
else ifeq ($(ARCH),aarch64)
	ARCH = aarch64
endif

.PHONY: all setup_dirs deploy uninstall install-tools install

all: deploy

setup_dirs:
	mkdir -p $(CONFIG_DIR)/ghostty
	mkdir -p $(CONFIG_DIR)/helix
	mkdir -p $(CONFIG_DIR)/zellij
	mkdir -p $(CONFIG_DIR)/lazygit
	mkdir -p $(CONFIG_DIR)/atuin
	mkdir -p $(BIN_DIR)

install-tools: setup_dirs
	@echo "Instalando herramientas usando binarios estáticos (agnóstico al SO)..."
	
	@echo "Instalando Helix..."
	@curl -fsSL "https://github.com/helix-editor/helix/releases/download/23.10/helix-23.10-$(ARCH)-$(OS).tar.xz" -o /tmp/helix.tar.xz
	@tar -xf /tmp/helix.tar.xz -C /tmp
	@mv /tmp/helix-*/hx $(BIN_DIR)/hx
	@rm -rf /tmp/helix*

	@echo "Instalando Zellij..."
	@curl -fsSL "https://github.com/zellij-org/zellij/releases/download/v0.38.2/zellij-$(ARCH)-unknown-$(OS)-musl.tar.gz" -o /tmp/zellij.tar.gz
	@tar -xzf /tmp/zellij.tar.gz -C $(BIN_DIR)
	@chmod +x $(BIN_DIR)/zellij
	@rm /tmp/zellij.tar.gz

	@echo "Instalando Lazygit..."
	@curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v0.40.2/lazygit_0.40.2_$(OS)_$(ARCH).tar.gz" -o /tmp/lazygit.tar.gz
	@tar -xzf /tmp/lazygit.tar.gz lazygit -C $(BIN_DIR)
	@chmod +x $(BIN_DIR)/lazygit
	@rm /tmp/lazygit.tar.gz

	@echo "Instalando Atuin..."
	@curl -fsSL https://setup.atuin.sh | sh

	@echo "Instalando Zoxide..."
	@curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

	@echo "Instalando Antigravity CLI (agy)..."
	@curl -fsSL https://antigravity.google/cli/install.sh | bash

install: install-tools deploy
	@echo "Instalación completada. Asegúrate de añadir $(BIN_DIR) a tu PATH."

deploy: setup_dirs
	@echo "Deploying dotfiles using stow..."
	@for pkg in $(PACKAGES_CONFIG); do \
		echo "Stowing $$pkg to $(CONFIG_DIR)/$$pkg..."; \
		stow -t $(CONFIG_DIR)/$$pkg -d $(STOW_DIR) $$pkg; \
	done
	@echo "Deployment complete."

uninstall:
	@echo "Uninstalling dotfiles..."
	@for pkg in $(PACKAGES_CONFIG); do \
		echo "Removing $$pkg..."; \
		stow -D -t $(CONFIG_DIR)/$$pkg -d $(STOW_DIR) $$pkg; \
	done
	@echo "Uninstallation complete."
