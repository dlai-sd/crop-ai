"""Convert `DLAI Prompt.docx` into a simple `docs/context.md` markdown file.

This script uses `python-docx` to extract paragraph text. It preserves
blank lines between paragraphs and writes a simple header for provenance.

Usage: `python scripts/convert_docx.py`
"""
from __future__ import annotations

from pathlib import Path

from docx import Document


def convert(docx_path: Path, out_md: Path) -> None:
    doc = Document(docx_path)
    lines: list[str] = []
    lines.append("# DLAI Prompt — Extracted Context")
    lines.append("")
    for para in doc.paragraphs:
        text = para.text.strip()
        if not text:
            lines.append("")
            continue
        lines.append(text)
        lines.append("")

    out_md.parent.mkdir(parents=True, exist_ok=True)
    out_md.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    docx_path = root / "DLAI Prompt.docx"
    out_md = root / "docs" / "context.md"
    if not docx_path.exists():
        raise SystemExit(f"Input file not found: {docx_path}")
    convert(docx_path, out_md)
    print(f"Wrote {out_md}")
