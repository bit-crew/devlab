# devlab — TODO

## Debug TUI (experiencia similar a VSCode debugger)

Pendiente de implementar. Opciones evaluadas:

| Herramienta | Proposito | Notas |
|---|---|---|
| Helix DAP nativo | Debug integrado en Helix sin plugins | Solo necesita los adapters en PATH |
| debugpy | Debug adapter para Python | Instalar en el proyecto via uv |
| codelldb | Debug adapter para Rust/C/C++ | Instalar via apt o cargo |

### Implementacion

1. Añadir adapters al perfil correspondiente: `debugpy` (uv, por proyecto),
   `codelldb` (apt o `cargo install`).
2. Helix ya trae DAP integrado: basta con tener los adapters en PATH.

## Enganche con prim

Cuando prim tenga CLI, devlab sera invocable con:
```
prim setup --perfil tech
```
Que internamente clona devlab y ejecuta el binario `devlab-install` con perfil
`vps` (o `dc1`).
Por ahora no se implementa, solo se documenta.
