#!/usr/bin/env bash
#
# Build slides (pptx), PDF, and video for all learn_uart_spi_i2c modules.
#
# Usage (from repo root or anywhere):
#   ./scripts/build_all_media.sh
#   ./scripts/build_all_media.sh --pptx-only
#   ./scripts/build_all_media.sh --module 3
#   ./scripts/build_all_media.sh --regenerate-outlines
#   ./scripts/build_all_media.sh --install-deps
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Skill may live under ~/.cursor/skills/ or ~/.cursor/skills/skills/ (symlink layout).
if [[ -z "${SKILL_ROOT:-}" ]]; then
  for candidate in \
    "$HOME/.cursor/skills/module-to-slides-video" \
    "$HOME/.cursor/skills/skills/module-to-slides-video" \
    "$HOME/proj/skills/.cursor/skills/module-to-slides-video"; do
    if [[ -d "$candidate/scripts" ]]; then
      SKILL_ROOT="$candidate"
      break
    fi
  done
  SKILL_ROOT="${SKILL_ROOT:-$HOME/.cursor/skills/module-to-slides-video}"
fi
SKILL_SCRIPTS="$SKILL_ROOT/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PPTX_ONLY=0
REGENERATE=0
INSTALL_DEPS=0
MODULES_FILTER=""
SECONDS_PER_SLIDE=8
RUN_DEMOS=1
NO_NARRATION=1
EXTRA_ARGS=()

usage() {
  sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
  echo ""
  echo "Options:"
  echo "  --pptx-only            Skip PDF and video"
  echo "  --module N             Only module N or list 1,2,3"
  echo "  --regenerate-outlines  Run generate_outline_from_module.py + patch_media_outlines.py"
  echo "  --install-deps         sudo apt install libreoffice ffmpeg poppler-utils"
  echo "  --seconds-per-slide N  Video timing (default: 8)"
  echo "  --no-run-demos         Skip re-running capture commands during verify"
  echo "  --with-narration       Enable TTS narration (default: silent video)"
  echo "  -h, --help             Show help"
}

log() { echo -e "${CYAN}==>${NC} $*"; }
ok() { echo -e "${GREEN}OK:${NC} $*"; }
warn() { echo -e "${YELLOW}WARN:${NC} $*" >&2; }
die() { echo -e "${RED}ERROR:${NC} $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pptx-only) PPTX_ONLY=1; shift ;;
    --regenerate-outlines) REGENERATE=1; shift ;;
    --install-deps) INSTALL_DEPS=1; shift ;;
    --module) MODULES_FILTER="$2"; shift 2 ;;
    --seconds-per-slide) SECONDS_PER_SLIDE="$2"; shift 2 ;;
    --no-run-demos) RUN_DEMOS=0; shift ;;
    --with-narration) NO_NARRATION=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) EXTRA_ARGS+=("$1"); shift ;;
  esac
done

[[ -d "$SKILL_SCRIPTS" ]] || die "Skill not found: $SKILL_SCRIPTS (expected module-to-slides-video skill)"

install_system_deps() {
  log "Installing system packages (sudo required)..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    libreoffice-impress libreoffice-core libreoffice-writer \
    default-jre-headless ffmpeg poppler-utils
  ok "System dependencies installed"
}

check_system_deps() {
  local missing=0
  if [[ $PPTX_ONLY -eq 0 ]]; then
    command -v soffice >/dev/null 2>&1 || command -v libreoffice >/dev/null 2>&1 || {
      warn "LibreOffice not found — PDF/video will be skipped (run with --install-deps)"
      missing=1
    }
    command -v ffmpeg >/dev/null 2>&1 || {
      warn "ffmpeg not found — video will be skipped (run with --install-deps)"
      missing=1
    }
    command -v pdftoppm >/dev/null 2>&1 || {
      warn "pdftoppm not found — video will be skipped (run with --install-deps)"
      missing=1
    }
  fi
  return $missing
}

log "Course: $COURSE_ROOT"
log "Skill:  $SKILL_ROOT"

if [[ $INSTALL_DEPS -eq 1 ]]; then
  install_system_deps
fi

log "Setting up Python skill venv..."
bash "$SKILL_SCRIPTS/setup.sh" | tail -3

if [[ $REGENERATE -eq 1 ]]; then
  log "Regenerating outline.yaml from docs/MODULE*.md and moduleN/EXAMPLES.md..."
  "$SKILL_SCRIPTS/run_python.sh" "$SKILL_SCRIPTS/generate_outline_from_module.py" "$COURSE_ROOT"
  log "Patching outlines (self-check expects, remove scaffold slides)..."
  "$SKILL_SCRIPTS/run_python.sh" "$COURSE_ROOT/scripts/patch_media_outlines.py"
fi

if ! command -v verilator >/dev/null 2>&1; then
  warn "Verilator not in PATH — using offline demo/README screenshots for missing PNGs"
  warn "Install verilator and re-run without --skip-capture for live simulation captures"
  "$SKILL_SCRIPTS/run_python.sh" "$COURSE_ROOT/scripts/render_screenshot_fallbacks.py"
  EXTRA_ARGS+=(--skip-capture)
  RUN_DEMOS=0
fi

if [[ ! -f "$COURSE_ROOT/media/module1/outline.yaml" ]]; then
  warn "No media outlines — run with --regenerate-outlines first"
  die "Missing $COURSE_ROOT/media/module1/outline.yaml"
fi

BUILD_ARGS=("$COURSE_ROOT")
[[ -n "$MODULES_FILTER" ]] && BUILD_ARGS+=(--module "$MODULES_FILTER")
[[ $PPTX_ONLY -eq 1 ]] && BUILD_ARGS+=(--pptx-only)
[[ $RUN_DEMOS -eq 1 ]] && BUILD_ARGS+=(--run-demos)
[[ $NO_NARRATION -eq 1 ]] && BUILD_ARGS+=(--no-narration)
BUILD_ARGS+=(--seconds-per-slide "$SECONDS_PER_SLIDE")
BUILD_ARGS+=("${EXTRA_ARGS[@]}")

check_system_deps || true

log "Building media for all modules..."
bash "$SKILL_SCRIPTS/build_course_media.sh" "${BUILD_ARGS[@]}"

echo ""
log "Outputs:"
for f in "$COURSE_ROOT"/media/module*/slides.pptx; do
  [[ -f "$f" ]] && echo "  pptx: $f"
done
if [[ $PPTX_ONLY -eq 0 ]]; then
  for f in "$COURSE_ROOT"/media/module*/slides.pdf; do
    [[ -f "$f" ]] && echo "  pdf:  $f"
  done
  for f in "$COURSE_ROOT"/media/module*/video.mp4; do
    [[ -f "$f" ]] && echo "  mp4:  $f"
  done
fi

ok "Done. Review under: $COURSE_ROOT/media/"
