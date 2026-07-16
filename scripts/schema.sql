-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create bookmark table
CREATE TABLE IF NOT EXISTS bookmark (
    id BIGINT PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE,
    last_processed_at TIMESTAMP WITH TIME ZONE,
    title TEXT,
    url TEXT,
    summary TEXT,
    category TEXT,
    type TEXT,
    tags TEXT[],
    summary_embedding vector(768)
);
