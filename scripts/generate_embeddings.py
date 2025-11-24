#!/usr/bin/env python3
"""
Generate embeddings for all manual sections using DistilUSE.

This script:
1. Loads the sentence-transformers model
2. Reads all sections from the SQLite database
3. Generates embeddings for each section
4. Stores embeddings back in the database

Requirements:
    pip install sentence-transformers sqlite3

Usage:
    python scripts/generate_embeddings.py
"""

import sqlite3
import struct
import os
import numpy as np

# Try to import sentence_transformers, provide helpful error if not installed
try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("Error: sentence-transformers not installed.")
    print("Install with: pip install sentence-transformers")
    exit(1)

# Configuration
DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'database', 'cacao_manual.db')
MODEL_NAME = 'sentence-transformers/distiluse-base-multilingual-cased-v2'
EMBEDDING_DIM = 512


def add_embedding_columns(conn):
    """Add embedding columns if they don't exist."""
    cursor = conn.cursor()

    # Check existing columns
    cursor.execute("PRAGMA table_info(manual_sections)")
    columns = {row[1] for row in cursor.fetchall()}

    if 'embedding' not in columns:
        cursor.execute('ALTER TABLE manual_sections ADD COLUMN embedding BLOB')
        print("Added 'embedding' column")

    if 'embedding_norm' not in columns:
        cursor.execute('ALTER TABLE manual_sections ADD COLUMN embedding_norm REAL')
        print("Added 'embedding_norm' column")

    conn.commit()


def generate_section_text(section):
    """Concatenate relevant fields for embedding generation."""
    parts = [
        section[1] or '',  # chapter
        section[2] or '',  # section_title
        section[3] or '',  # content
        section[4] or '',  # symptoms
        section[5] or '',  # treatment
        section[6] or '',  # prevention
    ]

    full_text = ' '.join(filter(None, parts))

    # Truncate to ~400 words for optimal embedding quality
    words = full_text.split()
    if len(words) > 400:
        full_text = ' '.join(words[:400])

    return full_text


def embedding_to_bytes(embedding):
    """Convert numpy array to bytes (float32)."""
    return struct.pack(f'{len(embedding)}f', *embedding.tolist())


def main():
    # Check if database exists
    if not os.path.exists(DB_PATH):
        print(f"Error: Database not found at {DB_PATH}")
        print("Run create_cacao_db.py first to create the database.")
        exit(1)

    print(f"Loading model: {MODEL_NAME}")
    print("This may take a moment on first run...")
    model = SentenceTransformer(MODEL_NAME)
    print(f"Model loaded. Embedding dimension: {model.get_sentence_embedding_dimension()}")

    # Connect to database
    conn = sqlite3.connect(DB_PATH)

    # Ensure embedding columns exist
    add_embedding_columns(conn)

    cursor = conn.cursor()

    # Get all sections
    cursor.execute('''
        SELECT id, chapter, section_title, content, symptoms, treatment, prevention
        FROM manual_sections
    ''')
    sections = cursor.fetchall()

    print(f"\nGenerating embeddings for {len(sections)} sections...")

    for i, section in enumerate(sections):
        section_id = section[0]
        section_title = section[2][:50] if section[2] else 'Unknown'

        # Generate text for embedding
        text = generate_section_text(section)

        if not text.strip():
            print(f"  ⚠ Section {section_id}: Empty text, skipping")
            continue

        # Generate embedding (normalized)
        embedding = model.encode(text, normalize_embeddings=True)

        # Convert to bytes
        embedding_bytes = embedding_to_bytes(embedding)

        # Calculate L2 norm (should be 1.0 since we normalized)
        embedding_norm = float(np.linalg.norm(embedding))

        # Update database
        cursor.execute('''
            UPDATE manual_sections
            SET embedding = ?, embedding_norm = ?
            WHERE id = ?
        ''', (embedding_bytes, embedding_norm, section_id))

        print(f"  ✓ [{i+1}/{len(sections)}] Section {section_id}: {section_title}...")

    conn.commit()
    conn.close()

    print(f"\n{'='*50}")
    print(f"✅ Embeddings generated successfully!")
    print(f"   Sections processed: {len(sections)}")
    print(f"   Embedding dimension: {EMBEDDING_DIM}")
    print(f"   Bytes per embedding: {EMBEDDING_DIM * 4}")
    print(f"   Database: {DB_PATH}")
    print(f"{'='*50}")


if __name__ == '__main__':
    main()
