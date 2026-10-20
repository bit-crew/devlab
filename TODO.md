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

## Fase Android (cliente dc1 en tablet/Termux)

Objetivo: que el cliente dc1 corra en una tablet Android via Termux
(arquitectura aarch64/ARM64). Se valido todo lo posible sin hardware; falta la
prueba en tablet real.

### Hecho (sin hardware)

- **CI compila aarch64**: `build-installer.yml` produce
  `devlab-install-aarch64-linux` con target `aarch64-unknown-linux-musl`
  (estatico) en un runner ARM nativo, con smoke test (`verify` desde dir
  vacio) que confirma que el binario arranca en ARM. musl estatico corre en
  Linux ARM y en Termux (bionic libc); un binario glibc ARM NO correria en
  Termux.
- **install.sh soporta aarch64**: `asset_suffix()` mapea `aarch64`/`arm64` ->
  `aarch64-linux`, asi que `curl install.sh | sh` baja el binario correcto en
  ARM. Termux reporta `uname -s = Linux`, asi que la deteccion de SO funciona.
- **Fix IPv4** en descargas (binario y install.sh): evita cuelgues en hosts con
  IPv6 roto (se dio en el VPS con dl.google.com).

### Pendiente (requiere tablet con Termux)

1. Instalar Termux desde **F-Droid** (la de Play Store esta desactualizada) y
   probar `curl -fsSL https://raw.githubusercontent.com/bit-crew/devlab/main/install.sh | sh`.
   Esperado: el binario arranca; probablemente falle al instalar herramientas.
2. **Herramientas glibc no corren en Termux (bionic).** node/go/helix y demas se
   instalan hoy como tarballs glibc; en Termux hay que instalarlas via `pkg`
   (el gestor de Termux) en vez de los tarballs. `packages/system.txt` ya tiene
   columna `pkg`, pero los binarios descargados (install_node, install_go,
   install_helix, etc.) necesitan una ruta alternativa para el perfil Termux.
   Hay que probar con la tablet que provee `pkg` y que no.
3. Confirmar que chezmoi, zsh, Pi/gentle-ai y engram funcionan en Termux (o
   decidir que subset del entorno aplica al cliente movil).
4. Revisar `chsh` a zsh en Termux (el mecanismo de login shell difiere).

### Nota de diseño

Decidir que subset del entorno tiene sentido en un cliente movil: quizas el
cliente dc1-tablet solo necesite editor + multiplexer + cliente SSH para
conectarse al VPS, no todo el stack de Data Engineering.
