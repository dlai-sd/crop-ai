"""Prediction adapter and small CLI for the crop-ai demo.

This module provides a framework-agnostic `ModelAdapter` stub that agents
can extend to integrate PyTorch, TensorFlow, or a remote model server.

Keep this file small and testable; real model-loading logic belongs behind
an adapter class that isolates the dependency (torch/tf) from the rest of
the codebase.
"""
from __future__ import annotations

from typing import Any, Iterable, List, Optional


class ModelAdapter:
    """Thin, framework-agnostic model adapter stub.

    Usage examples:
    - `ModelAdapter(framework='torch', model_path='path/to.pt')`
    - `ModelAdapter()` and then subclass to implement `load()`/`predict()`
    """

    def __init__(self, framework: Optional[str] = None, model_path: Optional[str] = None) -> None:
        self.framework = framework
        self.model_path = model_path
        self.model: Optional[Any] = None

    def load(self) -> None:
        """Load model into memory.

        This stub sets a lightweight marker dict. Replace with real
        loading logic (torch.load, tf.saved_model.load, or remote call).
        """
        self.model = {"loaded": True, "framework": self.framework, "path": self.model_path}

    def predict(self, inputs: Iterable[Any]) -> List[Any]:
        """Run inference on inputs.

        The stub returns a deterministic, simple transformation so tests
        can validate behavior without heavy ML dependencies.
        """
        if self.model is None:
            raise RuntimeError("Model not loaded. Call load() before predict().")
        results: List[Any] = []
        for x in inputs:
            try:
                results.append(len(x))
            except Exception:
                results.append(1)
        return results


def cli_main() -> None:
    import argparse
    import json

    parser = argparse.ArgumentParser(description="Run a simple prediction using ModelAdapter stub")
    parser.add_argument("--model-path", help="optional model path", default=None)
    parser.add_argument("--framework", help="optional framework name", default=None)
    parser.add_argument("--inputs", help="JSON list of inputs", default="[]")
    args = parser.parse_args()

    adapter = ModelAdapter(framework=args.framework, model_path=args.model_path)
    adapter.load()
    inputs = json.loads(args.inputs)
    outputs = adapter.predict(inputs)
    print(json.dumps({"outputs": outputs}))


if __name__ == "__main__":
    cli_main()
