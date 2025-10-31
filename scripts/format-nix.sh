#!/usr/bin/env bash
set -euo pipefail

# Format all .nix files in the repository using nixfmt or nixpkgs-fmt.
# Usage: ./scripts/format-nix.sh [--check] [--src <path>] or ./scripts/format-nix.sh [<path>] [--check]
# --check: don't write changes, just report which files would change (if supported by formatter)
# --src <path> or first positional path: repository root or directory to search for .nix files

# Parse args
CHECK_MODE=0
SRC=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK_MODE=1; shift ;;
    --src) SRC="$2"; shift 2 ;;
    -h|--help) cat <<'EOF'
Usage: format-nix.sh [--check] [--src <path>] or format-nix.sh [<path>] [--check]
  --check    : run formatter in check mode (if supported)
  --src PATH : directory to search for .nix files (defaults to repo root)
  -h, --help : show this help
EOF
      exit 0 ;;
    *)
      # If a positional argument is provided, treat it as SRC
      if [ -z "$SRC" ]; then
        SRC="$1"
      else
        echo "Unknown arg: $1" >&2; exit 2
      fi
      shift ;;
  esac
done

# Find repo root (fall back to cwd if not in git)
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
if [ -n "$SRC" ]; then
  # If SRC is absolute, use it; if relative, join to REPO_ROOT
  if [ "${SRC:0:1}" = "/" ]; then
    TARGET="$SRC"
  else
    TARGET="$REPO_ROOT/$SRC"
  fi
else
  TARGET="$REPO_ROOT"
fi
cd "$TARGET"

# Choose formatter
if command -v nixfmt >/dev/null 2>&1; then
  FMT_CMD=nixfmt
  # nixfmt: -w is NOT 'write' (it's width). By default nixfmt writes in-place when
  # given filenames. Use -c/--check for check mode.
  FMT_WRITE_ARGS=( )
  FMT_CHECK_ARGS=( -c )
elif command -v nixpkgs-fmt >/dev/null 2>&1; then
  FMT_CMD=nixpkgs-fmt
  # nixpkgs-fmt writes in place and doesn't support --check historically
  FMT_WRITE_ARGS=( )
  FMT_CHECK_ARGS=( )
else
  cat <<EOF
No nix formatter found (nixfmt or nixpkgs-fmt).
Install one with one of the following commands and re-run this script:

  # Install nixfmt (recommended)
  nix profile install nixpkgs#nixfmt

  # Or install nixpkgs-fmt
  nix profile install nixpkgs#nixpkgs-fmt

EOF
  exit 1
fi

# Collect .nix files (ignore .git and nix-store directories)
mapfile -d '' FILES < <(find . -type f -name '*.nix' -not -path './.git/*' -print0)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No .nix files found in $TARGET"
  exit 0
fi

echo "Found ${#FILES[@]} .nix files. Using formatter: $FMT_CMD"

# Run formatter per-file to avoid issues with passing a large/concatenated file list
rc=0
for f in "${FILES[@]}"; do
  if [ ! -r "$f" ]; then
    echo "Skipping unreadable file: $f"
    continue
  fi

  if [ "$CHECK_MODE" -eq 1 ]; then
    if [ ${#FMT_CHECK_ARGS[@]} -eq 0 ]; then
      echo "--check is not supported by $FMT_CMD; run without --check to format in-place."
      exit 2
    fi
    echo "Checking $f"
    if ! "$FMT_CMD" "${FMT_CHECK_ARGS[@]}" "$f" 2>&1; then
      echo "Formatter (check) failed on $f"
      rc=1
    fi
  else
    echo "Formatting $f"
    if ! "$FMT_CMD" "${FMT_WRITE_ARGS[@]}" "$f" 2>&1; then
      echo "Formatter failed on $f"
      rc=1
    fi
  fi
done

if [ $rc -eq 0 ]; then
  echo "Formatting complete."
else
  echo "Formatting finished with errors (see above)."
fi

exit $rc
