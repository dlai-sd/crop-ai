<!-- GitHub Copilot / AI agent instructions for the crop-ai repository -->
# Repo intent (short)
This repository is a small prototype/demo: "Crop Identification demo — Modular AI system for crop identification using satellite imagery". The codebase is minimal; most domain/context lives in `DLAI Prompt.docx` and `README.md`.

# Big picture (what an agent needs to know)
- **Goal:** produce modular, testable components that ingest satellite imagery, run model inference, and expose dataset/transform utilities.
- **Where to look first:** `README.md` (project description) and `DLAI Prompt.docx` (project prompt/background). There are currently no Python packages or source folders tracked — expect new modules under a top-level `src/` or `crop_ai/` package.

# Project structure & conventions
- This repo currently contains only top-level metadata: `README.md`, `LICENSE`, `.gitignore`, and `DLAI Prompt.docx`.
- Preferred Python layout: create a package directory (`src/` or `crop_ai/`) and a `tests/` folder. Use a virtual environment (`.venv`) and list deps in `requirements.txt` or `pyproject.toml`.
- Ignore secrets and environments: `.env`, `.venv`, and other entries are in `.gitignore`.

# Developer workflows (explicit)
- Local environment setup (assume Python 3.10+):
  - Create venv: `python -m venv .venv` and activate `source .venv/bin/activate`.
  - Install runtime/dev deps: create `requirements.txt` or `pyproject.toml`; otherwise install ad-hoc with `pip install -U pip` and packages.
- Tests: there are no tests yet. Prefer `pytest` with `tests/` directory. Run tests with `pytest`.
- Linting/formatting: add `ruff`/`black` if desired. Use `.gitignore` entries already present for `ruff` cache.

# Patterns & examples the agent should follow
- Small, focused modules: each component should expose a clear public API and include a lightweight README or docstring.
- Data transforms: implement deterministic transforms for reproducibility. Persist dataset/transform versions with explicit file names (e.g., `data/transforms/v1.json`).
- Model interface: create a thin adapter class (e.g., `ModelAdapter`) that isolates ML framework choice and prediction I/O.

# Integration points and external deps
- No external services are currently configured. If adding external integrations (S3, GCS, model serving), add configuration via environment variables and document keys in `README.md`.

# Helpful, specific tasks an AI agent can do now
- Scaffold package: add `src/crop_ai/__init__.py`, a `predict.py` with a `ModelAdapter` stub, and `tests/test_predict.py` with a simple unit test.
- Add `requirements.txt` and CI workflow (GitHub Actions) that runs `pytest` and basic linting.
- Extract essential prompt/context: convert `DLAI Prompt.docx` contents into `docs/context.md` to make the high-level objective easily accessible to contributors and agents.

# Commit / PR guidance for agents
- Keep changes small and focused (one logical change per branch/PR).
- Use clear commit messages: `feat: add model adapter stub` or `chore: add CI workflow`.

# When you can't find information
- If a specific architecture decision isn't present in the repo (e.g., model framework, storage backend), create a short design note under `docs/decision-<topic>.md` and pick sensible defaults (pure-Python stubs, config via env vars).

# Where to ask for clarification
- Ask the repo owner about preferred package layout (`src/` vs top-level package), model framework (PyTorch/TF), and whether the binary `DLAI Prompt.docx` should be converted to markdown.

---
If you'd like, I can now scaffold the recommended layout (`src/`, `tests/`), add a `requirements.txt`, and convert `DLAI Prompt.docx` into `docs/context.md` (requires you to provide the text or allow me to extract it). Feedback or specific preferences? 
