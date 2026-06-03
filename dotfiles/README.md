# Dev Setup Dotfiles

Este repositorio contiene la configuración del entorno de desarrollo para Data Engineering (PySpark, AWS) optimizado para sistemas Unix (Linux/Mac/WSL), utilizando un stack de terminal ultrarrápido y manejado mediante GNU Stow.

## Instalación Rápida (Recomendado)

Todo el proceso (instalación de herramientas vía Homebrew y el enlace de configuraciones vía GNU Stow) está automatizado en el `Makefile`. Con este único comando descargas el proyecto, instalas los programas y aplicas la configuración:

```bash
git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles && cd ~/dotfiles && make install
```
*(Recuerda reemplazar `TU_USUARIO` por tu usuario de GitHub).*

## Estructura del Repositorio

La estructura está aplanada para facilitar la navegación, delegando la creación de rutas correctas (`~/.config/`) al `Makefile`.

```text
dotfiles/
├── ghostty/           # Emulador de terminal GPU-accelerated
├── helix/             # Editor de texto modal
├── zellij/            # Multiplexor de terminal
├── lazygit/           # Interfaz TUI para Git
├── atuin/             # Historial de comandos sincronizado y vitaminado
├── Makefile           # Automatización de Instalación y Despliegue
└── README.md          # Esta guía
```

*Nota: **Zoxide** (el navegador de directorios inteligente) también se instala, pero no requiere carpeta de dotfiles aquí, ya que se autoconfigura añadiendo `eval "$(zoxide init bash/zsh)"` a tu archivo de shell preferido.*

## Comandos del Makefile

Si en el futuro requieres administrar las configuraciones manualmente, el `Makefile` expone varios targets útiles:

- `make install-tools`: Descarga e instala los programas binarios requeridos (Homebrew, Helix, Zellij, Lazygit, Ghostty, Zoxide, Atuin, agy).
- `make deploy`: Simplemente crea los enlaces de GNU Stow (útil tras agregar configuraciones nuevas o actualizar repositorios).
- `make uninstall`: Elimina los enlaces de configuración (`stow -D`) revirtiendo tu sistema.

## Gestión de Reglas IA con Antigravity CLI (agy)

El entorno está preparado para integrarse con **Antigravity CLI (agy)**. Las reglas de Data Engineering están modularizadas en el proyecto `agent/` como skills (`architect`, `developer`, `migration`). Estas skills se cargan y vinculan automáticamente en el entorno del agente para guiar su comportamiento de manera autónoma en tareas de PySpark, AWS, calidad de código y diseño.
