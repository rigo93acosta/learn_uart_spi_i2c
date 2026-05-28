#!/usr/bin/env python3
"""Render terminal PNGs from manifest when live capture is unavailable.

Uses existing .log files under assets/screenshots/ when present; otherwise
runs lightweight read-only commands (e.g. --demo, README excerpts) that do not
require Verilator.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any

import yaml

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    Image = None  # type: ignore[misc, assignment]

COURSE = Path(__file__).resolve().parent.parent

# Offline-friendly capture when Verilator/simulation is unavailable.
OFFLINE_CAPTURE: dict[int, dict[str, tuple[str, str]]] = {
    1: {
        "module1_check": (
            "./scripts/module1.sh --demo",
            "make run",
        ),
        "ex01_spec_to_rtl": (
            "sed -n '30,36p' module1/examples/spec_to_rtl/README.md",
            "[PASS] spec_to_rtl",
        ),
    },
    2: {
        "module2_check": ("./scripts/module2.sh --demo", "uvm_smoke"),
        "ex01_uvm_smoke": (
            "sed -n '24,28p' module2/examples/uvm_smoke/README.md",
            "SCOREBOARD",
        ),
    },
    3: {
        "module3_check": ("./scripts/module3.sh --demo", "uart_baseline"),
        "ex01_uart_baseline": (
            "sed -n '20,24p' module3/examples/uart_baseline/README.md",
            "UART baseline test PASS",
        ),
    },
    4: {
        "module4_check": ("./scripts/module4.sh --demo", "uart_uvm"),
        "ex01_uart_uvm": (
            "sed -n '33,36p' module4/examples/uart_uvm/README.md",
            "SCOREBOARD",
        ),
    },
    5: {
        "module5_check": ("./scripts/module5.sh --demo", "spi_baseline"),
        "ex01_spi_baseline": (
            "sed -n '20,23p' module5/examples/spi_baseline/README.md",
            "SPI baseline test PASS",
        ),
    },
    6: {
        "module6_check": ("./scripts/module6.sh --demo", "spi_uvm"),
        "ex01_spi_uvm": (
            "sed -n '33,36p' module6/examples/spi_uvm/README.md",
            "SCOREBOARD",
        ),
    },
    7: {
        "module7_check": ("./scripts/module7.sh --demo", "i2c_baseline"),
        "ex01_i2c_baseline": (
            "sed -n '40,44p' module7/examples/i2c_baseline/README.md",
            "I2C baseline test PASS",
        ),
    },
    8: {
        "module8_check": ("./scripts/module8.sh --demo", "i2c_uvm"),
        "ex01_i2c_uvm": (
            "sed -n '33,36p' module8/examples/i2c_uvm/README.md",
            "SCOREBOARD",
        ),
    },
}


def render_terminal_png(out: Path, log: str, title: str) -> None:
    """Draw a terminal-style PNG from log text."""
    if Image is None:
        raise RuntimeError("Pillow required")
    img = Image.new("RGB", (1920, 1080), color=(30, 30, 46))
    draw = ImageDraw.Draw(img)
    try:
        mono = ImageFont.truetype("DejaVuSansMono.ttf", 18)
        header = ImageFont.truetype("DejaVuSans.ttf", 24)
    except OSError:
        mono = header = ImageFont.load_default()
    draw.text((40, 30), f"Terminal: {title}", fill=(255, 255, 255), font=header)
    y = 80
    for line in log.splitlines()[:40]:
        draw.text((40, y), line[:100], fill=(200, 220, 200), font=mono)
        y += 22
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)


def run_command(course_root: Path, cmd: str) -> str:
    """Run a shell command and return combined stdout/stderr."""
    result = subprocess.run(
        cmd,
        shell=True,
        cwd=str(course_root),
        capture_output=True,
        text=True,
        timeout=60,
        check=False,
    )
    return result.stdout + result.stderr


def resolve_asset_id(asset: dict[str, Any]) -> str:
    """Return manifest asset id or derive from file stem."""
    aid = str(asset.get("id", ""))
    if aid:
        return aid
    file_rel = str(asset.get("file", ""))
    return Path(file_rel).stem


def render_module(module: int, force: bool) -> int:
    """Create missing screenshot PNGs for one module."""
    media = COURSE / "media" / f"module{module}"
    manifest_path = media / "assets" / "manifest.yaml"
    if not manifest_path.is_file():
        print(f"SKIP module {module}: no manifest")
        return 0

    manifest = yaml.safe_load(manifest_path.read_text(encoding="utf-8")) or {}
    offline = OFFLINE_CAPTURE.get(module, {})
    created = 0

    for asset in manifest.get("assets") or []:
        if asset.get("type") == "diagram":
            continue
        file_rel = str(asset.get("file", ""))
        if not file_rel.endswith(".png"):
            continue
        out = media / file_rel
        if out.is_file() and not force:
            continue

        aid = resolve_asset_id(asset)
        log_path = media / "assets" / "screenshots" / f"{aid}.log"
        log_text = ""
        if log_path.is_file() and not force:
            log_text = log_path.read_text(encoding="utf-8")

        if not log_text.strip():
            if aid in offline:
                cmd, _expect = offline[aid]
                log_text = run_command(COURSE, cmd)
                log_path.write_text(log_text, encoding="utf-8")
            elif asset.get("capture_command"):
                log_text = run_command(COURSE, str(asset["capture_command"]))
                log_path.write_text(log_text, encoding="utf-8")

        if not log_text.strip():
            log_text = f"# Placeholder for {aid}\n# Install Verilator and re-run build_all_media.sh\n"
        render_terminal_png(out, log_text, aid)
        print(f"rendered: {out}")
        created += 1

    return created


def main() -> int:
    parser = argparse.ArgumentParser(description="Render offline screenshot fallbacks")
    parser.add_argument("--module", type=int, default=0, help="Single module (0 = all)")
    parser.add_argument("--force", action="store_true", help="Overwrite existing PNGs")
    args = parser.parse_args()

    if Image is None:
        print("ERROR: Pillow not available", file=sys.stderr)
        return 1

    modules = [args.module] if args.module else list(range(1, 9))
    total = 0
    for mod in modules:
        total += render_module(mod, args.force)
    print(f"Created/updated {total} screenshot(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
