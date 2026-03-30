import os
import logging
from typing import List

from src.services.qdrant_client_service import get_qdrant_client, ensure_collection, QDRANT_COLLECTION

logger = logging.getLogger(__name__)


def _get_embeddings(texts: List[str]) -> List[List[float]]:
    """Return placeholder vectors for the given texts.

    This service intentionally does not perform any embedding/model
    inference. Instead it produces fixed-size zero vectors which are
    stored in Qdrant alongside the chunk payloads. Set
    `QDRANT_VECTOR_SIZE` to control the vector dimension (defaults to 1).
    """
    if not texts:
        return []

    vec_size = int(os.getenv("QDRANT_VECTOR_SIZE", "1"))
    return [[0.0] * vec_size for _ in texts]


def delete_document_chunks(document_id: str) -> None:
    """Delete all Qdrant points associated with a specific document_id."""
    if not document_id:
        return

    client = get_qdrant_client()
    # Use scroll to find matching point ids by payload
    try:
        from qdrant_client.models import Filter, FieldCondition, MatchValue

        flt = Filter(must=[FieldCondition(key="document_id", match=MatchValue(value=document_id))])
        # scroll returns items with 'id' attribute
        items = client.scroll(collection_name=QDRANT_COLLECTION, filter=flt, limit=1000)
        ids = [it.id for it in items]
        if ids:
            client.delete(collection_name=QDRANT_COLLECTION, points=ids)
            logger.info("Deleted %d existing chunks for document_id=%s", len(ids), document_id)
    except Exception:
        logger.exception("Failed to delete existing document chunks for %s", document_id)


def upsert_document_chunks(*, patient_id: str, document_id: str, document_type: str, test_name: str | None, source_file_url: str | None, uploaded_at: str | None, chunks: List[str]) -> int:
    """Generate embeddings for chunks and upsert them into Qdrant.

    Returns the number of chunks inserted.
    """
    if not chunks:
        return 0

    # Generate placeholder vectors (no model inference performed)
    embeddings = _get_embeddings(chunks)
    if not embeddings or len(embeddings) != len(chunks):
        raise ValueError("Failed to produce chunk vectors")

    vector_size = len(embeddings[0])
    ensure_collection(vector_size)
    client = get_qdrant_client()

    points = []
    for idx, (chunk, emb) in enumerate(zip(chunks, embeddings)):
        pid = f"{document_id}_{idx}"
        payload = {
            "patient_id": patient_id,
            "document_id": document_id,
            "document_type": document_type,
            "test_name": test_name or "",
            "chunk_index": idx,
            "text": chunk,
            "source_file_url": source_file_url or "",
            "uploaded_at": uploaded_at or "",
        }
        points.append({"id": pid, "vector": emb, "payload": payload})

    try:
        client.upsert(collection_name=QDRANT_COLLECTION, points=points)
        logger.info("Upserted %d chunks for document_id=%s", len(points), document_id)
        return len(points)
    except Exception:
        logger.exception("Failed to upsert document chunks for %s", document_id)
        raise
