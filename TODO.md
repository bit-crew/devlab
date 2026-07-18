# dev-setup — TODO

## Debug TUI (experiencia similar a VSCode debugger)

Pendiente de implementar. Opciones evaluadas:

| Herramienta | Proposito | Notas |
|---|---|---|
| nvim-dap | DAP en Neovim (breakpoints, stepping, variables) | Plugin para LazyVim |
| nvim-dap-ui | UI visual con panels (variables, stack, repl) | Se siente como VSCode debugger |
| nvim-dap-python | Config lista para Python (usa debugpy) | Necesita debugpy instalado |
| Helix DAP nativo | Debug integrado en Helix sin plugins | Solo necesita los adapters |
| debugpy | Debug adapter para Python | Instalar en server.nix |
| codelldb | Debug adapter para Rust/C/C++ | Instalar en server.nix |

### Implementacion

1. Instalar adapters en server.nix: `debugpy`, `codelldb`
2. Configurar nvim-dap en LazyVim (dotfiles/nvim/)
3. Helix: solo necesita los adapters en PATH, DAP ya viene integrado

## Enganche con kestrel

Cuando kestrel tenga CLI, dev-setup sera invocable con:
```
kestrel setup --perfil tech
```
Que internamente clona dev-setup y ejecuta `home-manager switch --flake .#server`.
Por ahora no se implementa, solo se documenta.
