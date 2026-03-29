import os
import requests

EMBEDDING_SERVICE_URL = os.getenv(
    "EMBEDDING_SERVICE_URL",
    "http://127.0.0.1:8001/embed"
)


def embed_text(text: str) -> list[float]:
    try:
        response = requests.post(
            EMBEDDING_SERVICE_URL,
            json={"text": text},
            timeout=60,
        )
        response.raise_for_status()
        return response.json()["embedding"]
    except requests.RequestException as e:
        raise RuntimeError(f"Embedding service unavailable: {e}") from e


def get_embedding_dimension() -> int:
    sample = embed_text("test")
    return len(sample)
