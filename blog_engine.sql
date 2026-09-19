CREATE TABLE posts (
    id BIGINT GENERATED ALWAYS AS IDENTITY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    search_vec TSVECTOR,
    published_at TIMESTAMPTZ NOT NULL
) PARTITION BY RANGE (published_at);

CREATE TABLE posts_2025 PARTITION OF posts
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE FUNCTION posts_search_update() RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vec := to_tsvector(
        'english',
        coalesce(NEW.title, '') || ' ' || coalesce(NEW.body, '')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_search
BEFORE INSERT OR UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION posts_search_update();

CREATE INDEX idx_posts_search
ON posts USING GIN (search_vec);

INSERT INTO posts (title, body, metadata, published_at) VALUES
    ('PostgreSQL Indexing', 'A guide to B-tree and GIN indexes.',
     '{"tags":["postgres","performance"]}', '2025-03-01'),
    ('Intro to JSONB', 'Storing flexible data in Postgres.',
     '{"tags":["postgres","jsonb"]}', '2025-04-10');

CREATE INDEX idx_posts_meta
ON posts USING GIN (metadata);

SELECT title
FROM posts
WHERE metadata @> '{"tags":["performance"]}';

SELECT title, ts_rank(search_vec, q) AS rank
FROM posts, to_tsquery('english','postgresql & index') q
WHERE search_vec @@ q
ORDER BY rank DESC;

EXPLAIN ANALYZE
SELECT title
FROM posts
WHERE published_at >= '2025-01-01'
  AND search_vec @@ to_tsquery('english','postgres');

SELECT id, title, metadata, search_vec, published_at
FROM posts;