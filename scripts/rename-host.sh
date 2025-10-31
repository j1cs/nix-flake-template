#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Rename configured macOS hostname in your nix-darwin setup.

Usage:
  rename-host.sh <new-hostname> [--rename-dir]

Notes:
  - Updates networking.hostName in the host module configuration.
  - Optionally renames the hosts/<dir> and updates flake import when --rename-dir is provided.
  - Does NOT change the flake output name (#__USERNAME__-__SYSTEM__).

After running:
  nix build nix-darwin#darwin-rebuild
  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__
  exec zsh -l
USAGE
}

if [[ ${1-} == "-h" || ${1-} == "--help" || $# -lt 1 ]]; then
  usage
  exit 0
fi

NEW_HOST=$1; shift || true
RENAME_DIR=false
if [[ ${1-} == "--rename-dir" ]]; then
  RENAME_DIR=true
fi

# Basic validation: no underscores; only letters, digits, hyphens and dots.
if [[ "$NEW_HOST" =~ _ ]]; then
  echo "Error: hostname must not contain underscores (_). Use hyphens (-) instead." >&2
  exit 1
fi
if ! [[ "$NEW_HOST" =~ ^[A-Za-z0-9.-]+$ ]]; then
  echo "Error: invalid hostname. Allowed characters: letters, digits, hyphen (-), dot (.)." >&2
  exit 1
fi

CFG_DIR="$HOME/.config/nix"
FLAKE_FILE="$CFG_DIR/flake.nix"
[[ -f "$FLAKE_FILE" ]] || { echo "Flake not found: $FLAKE_FILE" >&2; exit 1; }

# Find the imported host configuration path like ./hosts/<name>/configuration.nix
HOST_REL=$(grep -oE '\./hosts/[^"[:space:]]+/configuration\.nix' "$FLAKE_FILE" | head -n1 || true)
if [[ -z "$HOST_REL" ]]; then
  echo "Could not locate host import in flake.nix (./hosts/<name>/configuration.nix)." >&2
  exit 1
fi

HOST_DIR_REL=$(dirname "$HOST_REL")    # ./hosts/<name>
HOST_DIR_ABS="$CFG_DIR/${HOST_DIR_REL#./}"  # ~/.config/nix/hosts/<name>
HOST_CFG_ABS="$CFG_DIR/${HOST_REL#./}"      # ~/.config/nix/hosts/<name>/configuration.nix

[[ -f "$HOST_CFG_ABS" ]] || { echo "Host config not found: $HOST_CFG_ABS" >&2; exit 1; }

echo "> Updating networking.hostName in: $HOST_CFG_ABS"
# Replace existing assignment (macOS sed needs empty backup suffix)
sed -i '' -E "s#(networking\.hostName\s*=\s*)\"[^\"]*\";#\1\"$NEW_HOST\";#" "$HOST_CFG_ABS"

if $RENAME_DIR; then
  NEW_DIR_REL="./hosts/$NEW_HOST"
  NEW_DIR_ABS="$CFG_DIR/hosts/$NEW_HOST"
  if [[ -e "$NEW_DIR_ABS" ]]; then
    echo "Error: target directory already exists: $NEW_DIR_ABS" >&2
    exit 1
  fi
  echo "> Renaming $HOST_DIR_ABS -> $NEW_DIR_ABS"
  mv "$HOST_DIR_ABS" "$NEW_DIR_ABS"
  NEW_HOST_REL="$NEW_DIR_REL/configuration.nix"
  echo "> Updating import path in flake.nix"
  sed -i '' -E "s#${HOST_REL//\/#}#${NEW_HOST_REL//\/#}#" "$FLAKE_FILE"
fi

echo "> Done. Next steps:"
echo "  nix build nix-darwin#darwin-rebuild"
echo "  sudo darwin-rebuild switch --flake ~/.config/nix#__USERNAME__-__SYSTEM__"
echo "  exec zsh -l"

