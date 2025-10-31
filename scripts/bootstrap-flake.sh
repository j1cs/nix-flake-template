#!/usr/bin/env bash
set -euo pipefail

# bootstrap-flake.sh
# Create a parameterized copy of this nix-darwin/home-manager flake
# with your own username, email, and configuration name.
#
# Usage:
#   scripts/bootstrap-flake.sh \
#     --dest ~/Projects/my-nix \
#     --source /path/to/this/repo \
#     --username alice \
#     --email alice@example.com \
#     --config alice-mbp \
#     --system __SYSTEM__ \
#     --hostname alice-mbp   \
#     --remote https://github.com/alice/nix-macos.git
#     [--prepare-homebrew]
#
# If any flag is missing, you'll be prompted.
# The script copies the current repo (excluding .git/.direnv/result*),
# performs safe text replacements, and optionally renames the host folder.

# Defaults detected from current tree
CURRENT_USER="__USERNAME__"
CURRENT_EMAIL="__USERNAME__@company.com"
CURRENT_SYSTEM="__SYSTEM__"
CURRENT_HOST_SUFFIX="__HOST_SUFFIX__"

# Derived defaults (compose from base pieces so scripts can reuse logic)
CURRENT_CONFIG="${CURRENT_USER}-${CURRENT_SYSTEM}"
CURRENT_HOSTNAME="${CURRENT_USER}-${CURRENT_HOST_SUFFIX}"

DEST=""
SRC=""
NEW_USER=""
NEW_EMAIL=""
NEW_CONFIG=""
NEW_SYSTEM=""
NEW_HOSTNAME=""
NEW_HOST_SUFFIX=""
REMOTE_URL=""
PREPARE_HOMEBREW="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) DEST="$2"; shift 2;;
    --source) SRC="$2"; shift 2;;
    --username) NEW_USER="$2"; shift 2;;
    --email) NEW_EMAIL="$2"; shift 2;;
    --config) NEW_CONFIG="$2"; shift 2;;
    --system) NEW_SYSTEM="$2"; shift 2;;
    --hostname) NEW_HOSTNAME="$2"; shift 2;;
  --host-suffix) NEW_HOST_SUFFIX="$2"; shift 2;;
    --remote) REMOTE_URL="$2"; shift 2;;
    --prepare-homebrew) PREPARE_HOMEBREW="true"; shift 1;;
    -h|--help)
      grep '^# ' "$0" | sed 's/^# //'
      exit 0;;
    *) echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

prompt_if_empty() {
  local var_name="$1" prompt_text="$2" default_val="$3"
  local cur_val
  cur_val="${!var_name:-}"
  if [[ -z "$cur_val" ]]; then
    read -r -p "$prompt_text [$default_val]: " cur_val
    cur_val=${cur_val:-$default_val}
    eval "$var_name=\"$cur_val\""
  fi
}

prompt_if_empty DEST "Destination directory" "$HOME/CascadeProjects/nix-template"

# Default source to the repository root relative to this script
if [[ -z "$SRC" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Validate source contains a flake
if [[ ! -f "$SRC/flake.nix" ]]; then
  echo "Source does not look like a flake repo (missing flake.nix): $SRC" >&2
  echo "Use --source /path/to/flake to override." >&2
  exit 3
fi
prompt_if_empty NEW_USER "Username (primary user)" "$CURRENT_USER"
prompt_if_empty NEW_EMAIL "Email" "$CURRENT_EMAIL"
prompt_if_empty NEW_CONFIG "Darwin configuration name" "$CURRENT_CONFIG"
prompt_if_empty NEW_SYSTEM "System (__SYSTEM__|aarch64-darwin)" "$CURRENT_SYSTEM"
prompt_if_empty NEW_HOSTNAME "Hostname (macOS networking.hostName)" "$CURRENT_HOSTNAME"
prompt_if_empty NEW_HOST_SUFFIX "Host suffix (hostSuffix)" "$CURRENT_HOST_SUFFIX"

if [[ -e "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  echo "Destination already exists and is not empty: $DEST" >&2
  exit 2
fi

mkdir -p "$DEST"

# rsync tree excluding repo-specific and build outputs
RSYNC_EXCLUDES=(
  --exclude .git
  --exclude .direnv
  --exclude 'result*'
  --exclude '.DS_Store'
)

if command -v rsync >/dev/null 2>&1; then
  rsync -a "${RSYNC_EXCLUDES[@]}" "$SRC/" "$DEST/"
else
  echo "rsync not found; falling back to tar copy" >&2
  (cd "$SRC" && tar -c --exclude .git --exclude .direnv --exclude 'result*' --exclude '.DS_Store' .) | (cd "$DEST" && tar -x)
fi

# In-place sed cross-platform helper (macOS/BSD vs GNU)
sedi() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    # BSD sed (macOS)
    local lastarg="${@: -1}"
    sed -i '' "${@:1:$(($#-1))}" "$lastarg"
  fi
}

# Perform textual replacements across tracked files
cd "$DEST"

# Replace username/email/config/system in common file types
MAP_FROM=(
  "$CURRENT_USER"
  "$CURRENT_EMAIL"
  "__USERNAME__@falabelal.cl"
  "__CONFIG_NAME__"
  "$CURRENT_CONFIG"
  "$CURRENT_SYSTEM"
  "$CURRENT_HOST_SUFFIX"
  "$CURRENT_HOSTNAME"
)
MAP_TO=(
  "$NEW_USER"
  "$NEW_EMAIL"
  "$NEW_EMAIL"
  "$NEW_CONFIG"
  "$NEW_CONFIG"
  "$NEW_SYSTEM"
  "$NEW_HOST_SUFFIX"
  "$NEW_HOSTNAME"
)

# Find candidate text files
readarray -t FILES < <(find . -type f \
  \( -name '*.nix' -o -name '*.md' -o -name '*.sh' -o -name 'flake.*' -o -name '.*rc' -o -name '.envrc' \) \
  ! -path '*/.git/*')

for f in "${FILES[@]}"; do
  for i in "${!MAP_FROM[@]}"; do
    from="${MAP_FROM[$i]}"; to="${MAP_TO[$i]}"
    [[ -n "$from" && -n "$to" ]] || continue
    # Skip if identical
    [[ "$from" == "$to" ]] && continue
    sedi "s|$from|$to|g" "$f"
  done
done

# Rename host folder if present
if [[ -d hosts/$CURRENT_CONFIG ]]; then
  if [[ "$CURRENT_CONFIG" != "$NEW_CONFIG" ]]; then
    git mv -k "hosts/$CURRENT_CONFIG" "hosts/$NEW_CONFIG" 2>/dev/null || mv "hosts/$CURRENT_CONFIG" "hosts/$NEW_CONFIG"
  fi
fi

# Also handle placeholder-named host folder
if [[ -d hosts/__CONFIG_NAME__ ]] && [[ "__CONFIG_NAME__" != "$NEW_CONFIG" ]]; then
  git mv -k "hosts/__CONFIG_NAME__" "hosts/$NEW_CONFIG" 2>/dev/null || mv "hosts/__CONFIG_NAME__" "hosts/$NEW_CONFIG"
fi

# Optionally prepare Homebrew prefixes (requires sudo)
if [[ "$PREPARE_HOMEBREW" == "true" ]]; then
  echo "> Preparing Homebrew prefixes for $NEW_SYSTEM (requires sudo)"
  if [[ "$NEW_SYSTEM" == "x86_64-darwin" ]]; then
    # Intel macOS uses /usr/local
    echo "- Ensuring minimal dirs and permissions under /usr/local"
    sudo mkdir -p /usr/local/{bin,etc,include,lib,opt,sbin,share,Cellar,Caskroom,Frameworks,Homebrew,var}
    sudo chmod ug+rwx /usr/local /usr/local/bin
    sudo mkdir -p \
      /usr/local/{bin,etc,share} \
      /usr/local/share/{man/man1,zsh/site-functions,fish/vendor_completions.d} \
      /usr/local/etc/bash_completion.d
    sudo chown -R "$USER":staff /usr/local/bin /usr/local/etc /usr/local/share
    sudo chmod u+rwx /usr/local/bin /usr/local/etc /usr/local/share
  else
    # Apple Silicon uses /opt/homebrew
    echo "- Ensuring minimal dirs under /opt/homebrew (will create if missing)"
    if [[ ! -d /opt/homebrew ]]; then
      sudo mkdir -p /opt/homebrew/{bin,etc,share}
      sudo chown -R "$USER":admin /opt/homebrew
      sudo chmod u+rwx /opt/homebrew /opt/homebrew/bin /opt/homebrew/etc /opt/homebrew/share
    else
      echo "/opt/homebrew already exists; skipping creation"
    fi
  fi
fi

# Initialize git if not already a repo
if [[ ! -d .git ]]; then
  git init -b main
  git add .
  git commit -m "chore: bootstrap from template for $NEW_USER <$NEW_EMAIL> ($NEW_CONFIG)"
  if [[ -n "$REMOTE_URL" ]]; then
    git remote add origin "$REMOTE_URL"
    echo "Set git remote to $REMOTE_URL"
  fi
  echo "Initialized git repository in $DEST"
else
  echo "Note: .git exists in $DEST; not re-initializing. Stage your changes manually."
fi

echo "\nBootstrap complete. Next steps:"
echo "  cd $DEST"
echo "  # review changes and push"
echo "  [[ -n '$REMOTE_URL' ]] || git remote add origin <your-repo-url>"
echo "  git push -u origin main"
