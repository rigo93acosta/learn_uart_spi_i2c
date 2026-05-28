# Scripts

Scripts for running module checks, demos, and **slides/PDF/video** generation.

## Media scripts

| Script | Purpose |
|--------|---------|
| `build_all_media.sh` | Build **all** modules: pptx → pdf → video |
| `verify_all_media.sh` | Verify outlines, assets, and deliverables |
| `patch_media_outlines.py` | Post-process generated `outline.yaml` (self-check expects, manifest sync) |
| `render_screenshot_fallbacks.py` | Offline terminal PNGs when Verilator is unavailable |

```bash
./scripts/build_all_media.sh --regenerate-outlines   # first time: generate outlines from docs/
./scripts/build_all_media.sh                         # full build
./scripts/build_all_media.sh --module 3              # one module
./scripts/verify_all_media.sh                        # quick check
```

Outputs: `media/moduleN/slides.pptx`, `slides.pdf`, `video.mp4`. After each build, the skill prints a **slide summary** table (`print_slide_summary.py`: slide count from `outline.yaml`, plus pptx/pdf/mp4 status). Same table after `regenerate_media_outlines.sh` and `verify_all_media.sh`. See [media/README.md](../media/README.md) and [media/INDEX.md](../media/INDEX.md).

**Live simulation screenshots** require Verilator in PATH. Without it, the build uses `--demo` / README excerpts (see `render_screenshot_fallbacks.py`).

## Module scripts

Run from the **repository root**:

| Script | Purpose | Options |
|--------|---------|---------|
| `module1.sh` | Spec → RTL methodology | `--check`, `--demo`, `--run`, `--trace` |
| `module2.sh` | UVM smoke test | `--check`, `--demo`, `--run` |
| `module3.sh` | UART baseline RTL + TB | `--check`, `--demo`, `--run` |
| `module4.sh` | UART UVM verification | `--check`, `--demo`, `--run` |
| `module5.sh` | SPI baseline RTL + TB | `--check`, `--demo`, `--run` |
| `module6.sh` | SPI UVM verification | `--check`, `--demo`, `--run` |
| `module7.sh` | I²C baseline RTL + TB | `--check`, `--demo`, `--run` |
| `module8.sh` | I²C UVM verification | `--check`, `--demo`, `--run` |

Example:

```bash
./scripts/module1.sh --check
./scripts/module4.sh --run
```

## Making scripts executable

From the repo root:

```bash
chmod +x scripts/*.sh
```
