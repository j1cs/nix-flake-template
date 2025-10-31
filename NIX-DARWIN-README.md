# nix-darwin (macOS) — Install and Maintenance Guide

This guide explains why it didn’t work “out of the box”, what happened, and the recommended procedure to install and maintain nix-darwin on your Mac.

## Install

- Install Nix (Determinate Systems .pkg is fine).
- Ensure your flake is at `~/.config/nix/flake.nix` and the output name is `__USERNAME__-__SYSTEM__`.

## Usage (start here)

Important: activation must run as root. Build as your user; use sudo only for the switch.

```
# 1) Build as your user
nix build --extra-experimental-features 'nix-command flakes' nix-darwin#darwin-rebuild

# 2) First activation: use the build result (requires sudo)
sudo ./result/bin/darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__

# 3) Refresh your login shell so PATH and aliases update
exec zsh -l

# 4) Subsequent activations (PATH now has darwin-rebuild)
sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
```

Tip: you have an alias `nix-switch` that runs the sudo command for you.

## Cheat Sheet

- **Build & Switch (system)**
  ```
  nix build nix-darwin#darwin-rebuild
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  exec zsh -l
  ```

- **Home Manager (user)**
  ```
  home-manager switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  home-manager generations
  home-manager expire-generations "14d"
  ```

- **Inspect flake inputs**
  ```
  nix flake show ~/.config/nix
  nix flake show https://flakehub.com/f/NixOS/nixpkgs/0
  nix flake show github:nix-community/home-manager/release-25.05
  ```

- **Search packages in your pinned nixpkgs**
  ```
  nix search "flake:https://flakehub.com/f/NixOS/nixpkgs/0" ripgrep
  nix build "flake:https://flakehub.com/f/NixOS/nixpkgs/0#hello" --dry-run
  ```

- **System options and verification**
  ```
  darwin-option networking.hostName
  which darwin-rebuild
  echo $PATH | tr ':' '\n' | grep /run/current-system/sw/bin
  ```

- **GC and cleanup**
  ```
  darwin-rebuild --list-generations
  sudo nix-env -p /nix/var/nix/profiles/system --delete-generations 14d
  nix-collect-garbage -d
  sudo nix-collect-garbage -d
  ```

- **Homebrew**
  ```
  brew list
  brew list --cask
  brew cleanup --prune=all -s
  ```

- **Containers (Colima + Docker)**
  ```
  colima start --launchd
  docker context use colima
  docker ps
  ```

- **Hostname helper**
  ```
  chmod +x ~/.config/nix/scripts/rename-host.sh
  ~/.config/nix/scripts/rename-host.sh <new-hostname> [--rename-dir]
  ```

- **Rust overlay example**
  ```
  nix flake show github:oxalica/rust-overlay
  nix build github:oxalica/rust-overlay#rust-bin.stable.latest.default --dry-run
  ```

- **Common problems (shortcuts)**
  ```
  # Unexpected files in /etc (fix and retry)
  sudo sh -c 'ts=$(date +%Y%m%d-%H%M%S); for f in /etc/nix/nix.custom.conf /etc/zshrc /etc/zprofile; do if [ -e "$f" ]; then cp -a "$f" "$f.backup.$ts"; mv "$f" "$f.before-nix-darwin"; fi; done'
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  exec zsh -l
  ```

- VS Code Copilot (unfree + login redirect):

  - Si el inicio de sesión de GitHub para Copilot redirige a `vscode.dev` y falla, fuerza el servidor local en tu Home Manager `home/vscode.nix`:

    ```nix
    programs.vscode = {
      enable = true;
      # ...
      profiles.default.userSettings = {
        "github.authentication.useLocalServer" = true;
      };
    };
    ```

  - Como Copilot/Copilot Chat son unfree, permite solo esas extensiones con un predicado restringido (en `home/vscode.nix`):

    ```nix
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
    ];
    ```

  - Declara las extensiones si usas `mutableExtensionsDir = false;`:

    ```nix
    programs.vscode.profiles.default.extensions = with inputs.nix-vscode-extensions.extensions.${pkgs.system}.vscode-marketplace; [
      github.copilot
      github.copilot-chat
    ];
    ```

  - Aplica cambios y reinicia VS Code:

    ```
    home-manager switch --flake ~/.config/nix#jcuzmar-x86_64-darwin
    # o, si lo llevas vía nix-darwin:
    sudo darwin-rebuild switch --flake ~/.config/nix#jcuzmar-x86_64-darwin
    ```

## Home Manager vs nix-darwin (when to use which?)

- **Use Home Manager only (fast, no sudo)** for user-level changes:
  - Zsh/Prezto/Starship, Git, Neovim, VS Code (settings/extensions), Ghostty, `home.packages`.
  - Files under `~/.config/nix/home/…`
  - Command:
    ```
    home-manager switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
    exec zsh -l
    ```

- **Use nix-darwin (sudo)** for system-level changes:
  - macOS system settings, `launchd` services, Nix daemon, Homebrew (casks/brews), users/groups.
  - Files under `~/.config/nix/darwin/…` and `~/.config/nix/hosts/…`
  - Command:
    ```
    nix build nix-darwin#darwin-rebuild
    sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
    exec zsh -l
    ```

- **Rule of thumb**: if the change is in `home/`, use Home Manager; if it’s in `darwin/` or `hosts/`, use nix-darwin.

## Flake Registry (avoid GitHub 429)

To avoid GitHub rate limits when resolving flake URLs, keep a local copy of the upstream registry. The flake is already configured to use `/etc/nix/flake-registry.json`.

```
curl -fsSL https://raw.githubusercontent.com/NixOS/flake-registry/master/flake-registry.json -o /tmp/flake-registry.json
sudo install -m 0644 /tmp/flake-registry.json /etc/nix/flake-registry.json
```

## Verification

```
darwin-option networking.hostName   # should show __USERNAME__-x86-64-darwin
which darwin-rebuild                # /run/current-system/sw/bin/darwin-rebuild
echo $PATH | tr ':' '\n' | grep /run/current-system/sw/bin
git config --global --get user.name   # __USERNAME__
git config --global --get user.email  # __USERNAME__@company.com
```

## Verify Microsoft Edge

Use these checks to confirm Edge is installed and set correctly:

```
# Cask installed
brew list --cask | grep microsoft-edge

# App bundle present
ls -d /Applications/Microsoft\ Edge.app

# Bundle ID (should print com.microsoft.edgemac)
mdls -name kMDItemCFBundleIdentifier -r "/Applications/Microsoft Edge.app"

# Default browser (should print com.microsoft.edgemac)
defaultbrowser
```

## Troubleshooting

- System activation must run as root:

  ```
  # If you just built this generation:
  sudo ./result/bin/darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__

  # After you've reloaded your shell once (exec zsh -l):
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  ```

- Unexpected files in /etc (abort):

  If activation aborts with files like `/etc/zshrc`, `/etc/zprofile`, or `/etc/nix/nix.custom.conf`, rename them (a dated backup is created) and retry.

  ```
  sudo sh -c 'ts=$(date +%Y%m%d-%H%M%S); for f in /etc/nix/nix.custom.conf /etc/zshrc /etc/zprofile; do if [ -e "$f" ]; then cp -a "$f" "$f.backup.$ts"; mv "$f" "$f.before-nix-darwin"; fi; done'
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  exec zsh -l
  ```

## Common Gotchas & Tips

- Homebrew on Intel (`/usr/local` permissions):
  - Create minimal dirs and set ownership (avoid chmod on top-level `/usr/local`):
  ```
  sudo mkdir -p /usr/local/{bin,etc,share} \
               /usr/local/share/{man/man1,zsh/site-functions,fish/vendor_completions.d} \
               /usr/local/etc/bash_completion.d
  sudo chown -R $USER:staff /usr/local/bin /usr/local/etc /usr/local/share
  sudo chmod u+rwx /usr/local/bin /usr/local/etc /usr/local/share
  ```

- Home Manager backups for existing dotfiles:
  - We enable `home-manager.backupFileExtension = "backup";` so `~/.zshrc` → `~/.zshrc.backup` on first activation.

- Keep Home Manager pinned to your nixpkgs release:
  - Current pin: `home-manager/release-25.05` to match nixpkgs 25.05.

- Hostname rules:
  - macOS hostnames cannot include underscores. We use `__USERNAME__-x86-64-darwin` (hyphens) in `hosts/__USERNAME__-__SYSTEM__/configuration.nix`.
  - Flake output remains `__USERNAME__-__SYSTEM__` (that’s fine and intentional).

- Mise notes:
  - Auto-install is disabled during activation to avoid network calls. Install tools manually after login:
  ```
  mise set MISE_NODE_COREPACK=true
  mise settings add idiomatic_version_file_enable_tools "[]"
  mise use --global node@lts bun@latest deno@latest uv@latest go@stable
  ```

- LazyVim lockfile (lazy-lock.json) permission denied:
  - We copy the LazyVim starter into `~/.config/nvim` at activation (instead of symlinking) so lazy.nvim can write `lazy-lock.json`.
  - We avoid read-only perms from the Nix store and remove any existing `lazy-lock.json` so LazyVim can recreate it.
  - If you ever manually remove `~/.config/nvim`, the next switch recreates it from the pinned starter.
  - Ensure `git` is installed (`which git`) so lazy.nvim can bootstrap plugins on first run.

## Spotlight Indexing (Home Manager Apps)

- Problem
  - Home Manager symlinks GUI apps to `~/Applications/Home Manager Apps/`. Spotlight/Alfred often ignore those symlinked bundles (e.g., Meld, Flameshot don’t show).

- Solution used (hybrid copy)
  - Copy only `Info.plist` and the primary icon into `~/Applications/<App>.app` and symlink the rest of the bundle from the Nix store.
  - Implemented via a Home Manager activation step in `home/default.nix:112` that runs after `linkGeneration` and triggers `mdimport` to reindex `~/Applications`.
  - File reference: `home/default.nix:1` defines the `hm-apps-spotlight-sync` script used by the activation.

- Alternatives
  - nix-darwin’s new “copying” strategy applies to apps installed by nix-darwin (e.g., items in `environment.systemPackages`), placing bundles under `/Applications/Nix Apps` in a Spotlight-friendly way.
  - mac-app-util (hraban/mac-app-util): creates Spotlight-visible trampolines for HM apps. Lower maintenance but introduces wrapper apps. We avoid trampolines here by design.

- When to use which
  - Few HM GUI apps and no trampolines desired → keep the hybrid approach already in place.
  - Many HM GUI apps or you prefer an external maintained tool → consider mac-app-util.
  - If you move GUI apps to Homebrew or nix-darwin, this section is not needed for those apps.

- Enable/disable (toggle)
  - In `home/default.nix:90`, set `hmSpotlightIndexEnable = false;` to disable the hybrid indexer without removing code.
  - When enabled (`true`), it runs after `linkGeneration` and reindexes `~/Applications`.

- Example: Windsurf
  - Moved from Home Manager to nix-darwin: `darwin/default.nix:40` adds `environment.systemPackages = [ windsurf ];` so `Windsurf.app` lives under `/Applications/Nix Apps` and is indexed without extra steps.

## Neovim config (personal repo)

Your Neovim configuration is managed from your Git repository and lives at `~/.config/nvim`.

- Repo: `https://github.com/j1cs/nvim`
- On activation (Home Manager or nix-darwin):
  - If `~/.config/nvim` does not exist, it is cloned from the repo.
  - If it is a Git repo with `origin` equal to your repo and the working tree is clean, it updates with `git pull --ff-only`.
  - If there are local changes or a different origin, it is left untouched.
- You can freely edit files locally and commit/push to keep them synced:
  ```
  cd ~/.config/nvim
  git status
  git add -A
  git commit -m "feat: update my nvim config"
  git push
  ```
- To apply updates from the repo (when your local tree is clean):
  ```
  home-manager switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  # or
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  ```
- If `~/.config/nvim` exists but is not a Git repo and you want to adopt your repo:
  ```
  rm -rf ~/.config/nvim
  git clone https://github.com/j1cs/nvim.git ~/.config/nvim
  ```
- If the repo exists but points elsewhere, change the remote:
  ```
  git -C ~/.config/nvim remote set-url origin https://github.com/j1cs/nvim.git
  ```

## Remove Old Stuff & Cleanup

- Remove declaratively
  - Nix user packages: edit `~/.config/nix/home/packages.nix` and remove items under `home.packages = [ ... ];`
  - Homebrew apps: edit `~/.config/nix/darwin/homebrew.nix` and remove items under `casks = [ ... ];` and `brews = [ ... ];`
  - Optional modules:
    - Disable Starship: `~/.config/nix/home/shell.nix` → `programs.starship.enable = false;`
    - Disable Mise: `~/.config/nix/home/mise.nix` → `programs.mise.enable = false;`
    - Stop vendoring LazyVim: remove `./neovim.nix` from `~/.config/nix/home/default.nix` and delete that file

- Apply changes
  ```
  nix build nix-darwin#darwin-rebuild
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  exec zsh -l
  ```

- Garbage collect old generations and store paths
  - System (nix-darwin):
    ```
    darwin-rebuild --list-generations
    sudo nix-env -p /nix/var/nix/profiles/system --delete-generations 14d
    ```
  - Home Manager (user):
    ```
    home-manager generations
    home-manager expire-generations "14d"
    ```
  - Nix store GC:
    ```
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
    ```

- Homebrew cleanup
  ```
  brew cleanup --prune=all -s
  brew list
  brew list --cask
  ```

- Dotfiles backups created by Home Manager
  ```
  ls -la ~ | grep \.backup$
  rm -f ~/.zshrc.backup ~/.zprofile.backup  # if no longer needed
  ```

- Neovim/LazyVim reset (optional)
  ```
  rm -rf ~/.local/share/nvim ~/.cache/nvim
  # Next switch re-copies the pinned starter into ~/.config/nvim
  ```

- Misc
  ```
  # Fix root-owned flake.lock from early sudo runs (if any)
  sudo chown $USER:staff ~/.config/nix/flake.lock
  ```

- Rollback a generation if needed:
  ```
  sudo darwin-rebuild rollback
  ```

## Containers (Colima)

This setup includes the Docker CLI and Colima via Homebrew. Use Colima to provide the Docker daemon on macOS without Docker Desktop.

```
# Start Colima and initialize a default VM
colima start

# Ensure Docker uses Colima (often automatic)
docker context use colima

# Verify
docker ps
docker run hello-world

# Auto-start on login (launchd)
colima start --launchd

# Adjust resources
colima stop
colima start --cpu 4 --memory 8
```

Alternative: Docker Desktop (GUI)

```
brew install --cask docker
open -a Docker
docker ps
```

## Hostname Migration

Changing your macOS hostname does not require changing the flake output; keep using `~/.config/nix#__USERNAME__-__SYSTEM__`. If you want to update the declarative hostname and (optionally) rename the host module folder, use the helper script:

```
# Make it executable (once)
chmod +x ~/.config/nix/scripts/rename-host.sh

# Update networking.hostName inside the host module
~/.config/nix/scripts/rename-host.sh <new-hostname>

# Also rename hosts/<dir> and fix flake import
~/.config/nix/scripts/rename-host.sh <new-hostname> --rename-dir

# Apply changes
nix build nix-darwin#darwin-rebuild
sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
exec zsh -l
```

Notes:
- macOS hostnames cannot contain underscores; use hyphens. Current configured hostname is `__USERNAME__-x86-64-darwin`.
- The flake output name intentionally remains `__USERNAME__-__SYSTEM__`.

## Why It’s Not “Out of the Box”

- The Nix installer sets up Nix (daemon, store, etc.), but nix-darwin is an additional layer you must apply via `darwin-rebuild switch`.
- The path `/run/current-system/sw/bin` is created and managed by nix-darwin during activation; before that, it doesn’t exist nor is it in `PATH`.
- If there are unmanaged files in `/etc` (like `/etc/zshrc`, `/etc/zprofile`, `/etc/nix/nix.custom.conf`), nix-darwin stops to avoid overwriting your changes.
- Avoid running everything with `sudo nix run …`; build as your user, then use `sudo` only for activation to avoid HOME/permission confusion.

## Flake Preparation

- Flake path: `~/.config/nix/flake.nix`.
- Architecture:
  - Intel: `system = "__SYSTEM__"`
  - Apple Silicon: `system = "aarch64-darwin"`
- Configuration name (`darwinConfigurations."…"`): use your `LocalHostName` or a simple name (e.g., `mbp-__USERNAME__`) so you don’t need the `#…` suffix each time.
- If you use Determinate Nix, keep `nix.enable = false;` and centralize settings in `determinate-nix.customSettings` (e.g., `flake-registry`, `eval-cores`, `extra-experimental-features`).

Example to enable zsh management by nix-darwin:

```
programs.zsh.enable = true;
```

## Install Checklist (Intel and Apple Silicon)

1) Check your architecture:

```
uname -m  # x86_64 (Intel) or arm64 (Apple Silicon)
```

2) Set `system` in the flake accordingly.

3) Build `darwin-rebuild` (as your user):

```
nix build --extra-experimental-features 'nix-command flakes' nix-darwin#darwin-rebuild
```

4) First run only — if you see “Unexpected files in /etc, aborting activation”, inspect and rename the conflicting files:

```
sudo sh -c 'for f in /etc/nix/nix.custom.conf /etc/zshrc /etc/zprofile; do [ -e "$f" ] && echo "--- $f ---" && sed -n "1,120p" "$f"; done'
sudo sh -c 'ts=$(date +%Y%m%d-%H%M%S); for f in /etc/nix/nix.custom.conf /etc/zshrc /etc/zprofile; do if [ -e "$f" ]; then cp -a "$f" "$f.backup.$ts"; mv "$f" "$f.before-nix-darwin"; fi; done'
```

5) Activate the configuration (only this step with sudo):

```
sudo ./result/bin/darwin-rebuild switch --flake ~/.config/nix#<config-name>
```

6) Verify and refresh PATH:

```
ls -l /run/current-system/sw/bin
exec zsh -l
echo $PATH | tr ':' '\n' | grep '/run/current-system/sw/bin'
```

## Optional: Simplify the Command

Use your `LocalHostName` as the configuration name to avoid the `#…` suffix:

```
scutil --get LocalHostName
```

In the flake, define:

```
darwinConfigurations."<LocalHostName>" = inputs.nix-darwin.lib.darwinSystem { ... };
```

Then you can activate with:

```
sudo ./result/bin/darwin-rebuild switch --flake ~/.config/nix
```

## Maintenance

- Re-apply flake changes:

```
nix build nix-darwin#darwin-rebuild
sudo ./result/bin/darwin-rebuild switch --flake ~/.config/nix#<config-name>
```

- Discover options/modules:

```
darwin-option search <keyword>
darwin-help
```

- Keep the flake lock owned by your user:

```
nix flake lock ~/.config/nix
# If flake.lock ended up owned by root:
sudo chown $USER:staff ~/.config/nix/flake.lock
```

## Migrate previous zsh customizations

If you had content in `/etc/zshrc` or `/etc/zprofile`, move it into the flake instead:

```
programs.zsh.interactiveShellInit = ''
  # aliases, prompt, etc.
'';

environment.loginShellInit = ''
  # login-shell config
'';

environment.variables.MY_VAR = "value";
```

For Nix, any configuration from `/etc/nix/nix.custom.conf` should be expressed in `determinate-nix.customSettings`.

## Troubleshooting

- “system activation must now be run as root”
  - Build as your user and run only activation with `sudo`.

- “Unexpected files in /etc, aborting activation”
  - Inspect and rename to `.before-nix-darwin` (see checklist).

- Warning `$HOME not owned by you` when using `sudo nix run …`
  - Avoid it by building as your user and using `sudo` only for `darwin-rebuild switch`.

- PATH not updated after switch
  - Start a login shell: `exec zsh -l` or open a new session.

## Quick Verification

```
which darwin-rebuild
darwin-rebuild --version
ls -l /run/current-system/sw/bin
echo $PATH | tr ':' '\n' | grep '/run/current-system/sw/bin'
```

---

Current system notes:

- Config in use: `~/.config/nix#__USERNAME__-__SYSTEM__` (Intel). If you move to Apple Silicon, change to `aarch64-darwin`.
- `programs.zsh.enable = true;` and `nix.enable = false;` with Determinate settings unified under `determinate-nix.customSettings`.

## yabai — Scripting Addition (SA) y pasos mínimos para SIP (guía rápida)

Si usas `yabai` y quieres probar su "scripting-addition" (SA) para controlar Spaces, esta sección te deja una guía clara en español para hacerlo con la mínima relajación de System Integrity Protection (SIP). Sigue las advertencias y pasos exactamente.

Advertencia: relajar SIP reduce protecciones del sistema. Haz backup (Time Machine) antes de proceder y aplica sólo las excepciones necesarias. En versiones preview de macOS (Tahoe/Sequoia) la SA puede requerir offsets/parches nuevos que aún no están soportados por upstream; si la SA falla, mantén el uso del tiling sin la SA y reintenta más tarde.

A) Preparación (desde tu sesión normal)

1. Verifica el binario y la versión:

```bash
which yabai
yabai --version
```

2. Guarda logs y estado previo (opcional):

```bash
ls -la /Library/ScriptingAdditions/yabai.osax 2>/dev/null || true
sudo log show --style syslog --last 10m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' > /tmp/yabai-dock-pre.log 2>/dev/null || true
```

3. (Opcional) Prepara un script para ejecutar al volver de Recovery:

```bash
cat > /tmp/yabai_install_sa.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/yabai_install_sa.log
echo "=== running yabai SA install: $(date) ===" > $LOG
YABAI_BIN=/etc/profiles/per-user/jcuzmar/bin/yabai
sudo ${YABAI_BIN} --unload-sa || true
sudo ${YABAI_BIN} --load-sa || true
sudo codesign --force --sign - /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
sleep 2
yabai -m space --focus 2 >> $LOG 2>&1 || true
sudo strings /Library/ScriptingAdditions/yabai.osax/Contents/Resources/payload.bundle/Contents/MacOS/payload | sed -n '1,200p' >> $LOG 2>&1 || true
sudo log show --style syslog --last 2m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' >> $LOG 2>&1 || true
echo "=== done ===" >> $LOG
echo "Wrote $LOG"
EOF
chmod +x /tmp/yabai_install_sa.sh
```

B) Entrar a Recuperación y aplicar relajación mínima de SIP

1. Reinicia en Recuperación (Intel: reinicia y mantén ⌘R).
2. En Recovery → Utilities → Terminal, ejecuta:

```bash
csrutil enable --without fs --without debug
reboot
```

Explicación: `--without fs` y `--without debug` son excepciones frecuentemente usadas para permitir la instalación de la SA sin deshabilitar SIP por completo.

C) Pasos después del reinicio (instalar SA y verificar)

Ejecuta el script preparado o haz los pasos manualmente:

```bash
# Ejecutar el script preparado (opcional)
sudo /tmp/yabai_install_sa.sh

# O pasos manuales:
YABAI_BIN=/etc/profiles/per-user/jcuzmar/bin/yabai
sudo $YABAI_BIN --unload-sa || true
sudo $YABAI_BIN --load-sa || true
sudo codesign --force --sign - /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
sleep 2
yabai -m space --focus 2 || true
# Si falla, recoge logs:
sudo log show --style syslog --last 5m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' > /tmp/yabai-dock-post.log 2>/dev/null || true
sudo strings /Library/ScriptingAdditions/yabai.osax/Contents/Resources/payload.bundle/Contents/MacOS/payload | sed -n '1,200p' > /tmp/yabai-payload-strings.log || true
yabai -m query --spaces > /tmp/yabai-spaces.log 2>&1 || true
```

Interpretación rápida:
- Si `yabai -m space --focus 2` funciona → SA operativa.
- Si aparece "cannot focus space due to an error with the scripting-addition." o en `yabai-payload-strings.log` aparecen mensajes como "could not locate pointer to dock.spaces" o "animation_time_addr vm_protect failed", la SA no puede parchear Dock (probable incompatibilidad con macOS preview). Mantén tiling-only por ahora.

D) Revertir y buenas prácticas

1. Si deseas remover la SA después de las pruebas:

```bash
sudo /etc/profiles/per-user/jcuzmar/bin/yabai --unload-sa || true
sudo rm -rf /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
```

2. Volver a activar SIP completo (Recovery → Terminal):

```bash
csrutil enable
reboot
```

E) Mantener tiling-only (inmediato y seguro)

Si decides no tocar SIP, usa solo el tiling; para ello asegúrate de que yabai tenga permiso de Accessibility y elimina/evita instalar la SA:

```bash
# comprobar permisos y binario
which yabai; yabai --version
# eliminar SA si existe
sudo rm -rf /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
# reiniciar el agente de usuario si usas LaunchAgent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.koekeishiya.yabai.plist 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.koekeishiya.yabai.plist || true
```

Si quieres que añada la advertencia y estos pasos de forma declarativa en `INSTALL_YABAI_SA_MINIMAL.md` o que haga un pequeño cambio en `darwin/yabai.nix` para mantener tiling-only declarativamente, dímelo y lo hago.

## yabai — Scripting Addition (SA) and minimal SIP steps (quick guide)

If you use `yabai` and want to try the scripting-addition (SA) to control Spaces, this section provides a clear English guide to do it with minimal System Integrity Protection (SIP) relaxation. Follow the warnings and steps exactly.

Warning: relaxing SIP reduces system protections. Make a backup (Time Machine) before proceeding and apply only the exceptions required. On macOS preview releases (Tahoe/Sequoia) the SA may require new offsets/patches not yet supported upstream; if the SA fails, keep using tiling-only and try again later.

A) Preparation (from your normal session)

1. Verify the yabai binary and version:

```bash
which yabai
yabai --version
```

2. Save logs and current state (optional):

```bash
ls -la /Library/ScriptingAdditions/yabai.osax 2>/dev/null || true
sudo log show --style syslog --last 10m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' > /tmp/yabai-dock-pre.log 2>/dev/null || true
```

3. (Optional) Prepare a script to run after returning from Recovery:

```bash
cat > /tmp/yabai_install_sa.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
LOG=/tmp/yabai_install_sa.log
echo "=== running yabai SA install: $(date) ===" > $LOG
YABAI_BIN=/etc/profiles/per-user/jcuzmar/bin/yabai
sudo ${YABAI_BIN} --unload-sa || true
sudo ${YABAI_BIN} --load-sa || true
sudo codesign --force --sign - /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
sleep 2
yabai -m space --focus 2 >> $LOG 2>&1 || true
sudo strings /Library/ScriptingAdditions/yabai.osax/Contents/Resources/payload.bundle/Contents/MacOS/payload | sed -n '1,200p' >> $LOG 2>&1 || true
sudo log show --style syslog --last 2m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' >> $LOG 2>&1 || true
echo "=== done ===" >> $LOG
echo "Wrote $LOG"
EOF
chmod +x /tmp/yabai_install_sa.sh
```

B) Enter Recovery and apply minimal SIP relaxation

1. Reboot into Recovery (Intel: reboot and hold ⌘R).
2. In Recovery → Utilities → Terminal, run:

```bash
csrutil enable --without fs --without debug
reboot
```

Explanation: `--without fs` and `--without debug` are commonly used exceptions to allow installing the SA without disabling SIP completely.

C) Post‑reboot steps (install SA and verify)

Run the prepared script or perform the steps manually:

```bash
# Run the prepared script (optional)
sudo /tmp/yabai_install_sa.sh

# Or manual steps:
YABAI_BIN=/etc/profiles/per-user/jcuzmar/bin/yabai
sudo $YABAI_BIN --unload-sa || true
sudo $YABAI_BIN --load-sa || true
sudo codesign --force --sign - /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
sleep 2
yabai -m space --focus 2 || true
# If it fails, collect logs:
sudo log show --style syslog --last 5m --predicate 'process == "Dock" and (eventMessage CONTAINS "yabai" OR eventMessage CONTAINS "ScriptingAdditions")' > /tmp/yabai-dock-post.log 2>/dev/null || true
sudo strings /Library/ScriptingAdditions/yabai.osax/Contents/Resources/payload.bundle/Contents/MacOS/payload | sed -n '1,200p' > /tmp/yabai-payload-strings.log || true
yabai -m query --spaces > /tmp/yabai-spaces.log 2>&1 || true
```

Quick interpretation:
- If `yabai -m space --focus 2` works → SA is operational.
- If you see "cannot focus space due to an error with the scripting-addition." or `yabai-payload-strings.log` contains lines like "could not locate pointer to dock.spaces" or "animation_time_addr vm_protect failed", the SA cannot patch Dock (likely incompatible with macOS preview). Keep tiling-only for now.

D) Revert and best practices

1. If you want to remove the SA after testing:

```bash
sudo /etc/profiles/per-user/jcuzmar/bin/yabai --unload-sa || true
sudo rm -rf /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
```

2. Re-enable SIP fully (Recovery → Terminal):

```bash
csrutil enable
reboot
```

E) Keep tiling-only (safe immediate option)

If you choose not to touch SIP, use only yabai's tiling features. Ensure yabai has Accessibility permission and avoid installing the SA:

```bash
# check binary and permissions
which yabai; yabai --version
# remove SA if present
sudo rm -rf /Library/ScriptingAdditions/yabai.osax || true
sudo killall Dock || true
# restart user launch agent if using LaunchAgent
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.koekeishiya.yabai.plist 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.koekeishiya.yabai.plist || true
```

If you want me to add the warning and these steps to `INSTALL_YABAI_SA_MINIMAL.md` as well, or to make a small change in `darwin/yabai.nix` to keep tiling-only declaratively, tell me and I'll do it.
