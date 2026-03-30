"""Small CLI to verify chunk writes to Qdrant.

Usage:
  Set `QDRANT_URL`, `QDRANT_API_KEY`, and optionally `QDRANT_COLLECTION` and
  `QDRANT_VECTOR_SIZE` in your environment, then run:

    python backend/scripts/verify_qdrant_write.py

This script will upsert two test chunks for a temporary `document_id`, then
query Qdrant to confirm the points were stored and print the payloads.
"""
import os
from dotenv import load_dotenv

# Load environment variables from backend/.env (if present) so
# QDRANT_URL and QDRANT_API_KEY are available before importing
# services that read them at import time.
load_dotenv()

import uuid
import pprint
from src.services.qdrant_client_service import get_qdrant_client, ensure_collection, QDRANT_COLLECTION


def main():
    vector_size = int(os.getenv("QDRANT_VECTOR_SIZE", "1"))
    client = get_qdrant_client()

    # Ensure collection exists with expected vector size
    ensure_collection(vector_size)

    document_id = f"verify-{uuid.uuid4().hex[:8]}"
    patient_id = f"PAT-{uuid.uuid4().hex[:6]}"
    chunks = [
        "This is a test chunk for verification.",
        "Second test chunk to verify upsert and retrieval.",
    ]

    # Create placeholder vectors (zeros)
    vectors = [[0.0] * vector_size for _ in chunks]

    points = []
    for i, (chunk, vec) in enumerate(zip(chunks, vectors)):
        # Qdrant requires point IDs to be either unsigned integers or UUIDs.
        # Use a UUID here to avoid format errors from custom string IDs.
        pid = str(uuid.uuid4())
        payload = {
            "patient_id": patient_id,
            "document_id": document_id,
            "document_type": "lab_report",
            "test_name": "verify",
            "chunk_index": i,
            "text": chunk,
        }
        points.append({"id": pid, "vector": vec, "payload": payload})

    print("Upserting points to Qdrant collection:", QDRANT_COLLECTION)
    try:
        upsert_res = client.upsert(collection_name=QDRANT_COLLECTION, points=points)
        print("Upsert response:", upsert_res)
    except Exception as e:
        print("Upsert failed:", e)
        return

    # Query back by payload filter
    try:
        from qdrant_client.models import Filter, FieldCondition, MatchValue

        flt = Filter(must=[FieldCondition(key="document_id", match=MatchValue(value=document_id))])

        # Different qdrant-client versions accept either `filter` or `query_filter`.
        # Try `filter=` first, and if the client rejects that argument (some
        # versions raise a runtime error), fall back to `query_filter=`.
        # Note: client.scroll() returns (points, next_page_offset), not just points.
        items = None
        try:
            result = client.scroll(collection_name=QDRANT_COLLECTION, filter=flt, limit=100)
            # Unpack the tuple if it's (points, offset)
            items = result[0] if isinstance(result, tuple) else result
        except Exception as e_filter:
            msg = str(e_filter).lower()
            if "unknown arguments" in msg or "filter" in msg:
                try:
                    result = client.scroll(collection_name=QDRANT_COLLECTION, query_filter=flt, limit=100)
                    items = result[0] if isinstance(result, tuple) else result
                except Exception as e_qf:
                    # Last-resort fallback: retrieve without server-side filter and filter locally.
                    result = client.scroll(collection_name=QDRANT_COLLECTION, limit=100)
                    items = result[0] if isinstance(result, tuple) else result
            else:
                raise

        # Print collection count for debugging
        try:
            cnt = client.count(collection_name=QDRANT_COLLECTION)
            print("Collection count:", getattr(cnt, 'count', cnt))
        except Exception:
            pass

        # If the returned items are raw point objects, ensure we have an iterable
        # and filter locally by payload/document_id if needed.
        try:
            filtered = [it for it in items if getattr(it, 'payload', {}).get('document_id') == document_id]
        except Exception:
            # If items is a mapping or different structure, attempt to normalize
            filtered = []
            for it in items:
                payload = None
                try:
                    payload = it.payload
                except Exception:
                    try:
                        payload = it.get('payload')
                    except Exception:
                        payload = None
                if payload and payload.get('document_id') == document_id:
                    filtered.append(it)

        items = filtered

        # For extra visibility, print the raw items we scanned (max 10)
        try:
            print("Sample scanned items (up to 10):")
            for it in list(items)[:10]:
                try:
                    print({"id": getattr(it, 'id', None), "payload": getattr(it, 'payload', None)})
                except Exception:
                    print(it)
        except Exception:
            pass

        print(f"Found {len(items)} points for document_id={document_id}")
        for it in items:
            print("---")
            pprint.pprint({"id": it.id, "payload": it.payload})
    except Exception as e:
        print("Failed to query Qdrant:", e)


if __name__ == "__main__":
    main()
