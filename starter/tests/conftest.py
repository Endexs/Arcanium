"""
pytest fixtures shared across the test suite.

Add per-project fixtures here (database paths, dummy API keys, sample data).
Keep this file small; complex fixtures belong in tests/fixtures/.
"""
from __future__ import annotations

import os
import pytest


@pytest.fixture
def dummy_api_key(monkeypatch):
    """Set a placeholder API key so code-under-test passes its env check
    without hitting a real provider. Tests should mock the HTTP layer
    (e.g., respx) rather than relying on this key."""
    monkeypatch.setenv("OPENAI_API_KEY", "sk-test-dummy")
    return "sk-test-dummy"
