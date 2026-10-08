-- V4__category_tree.sql
-- Recursive CTE for traversing the category hierarchy

WITH RECURSIVE category_tree AS (
    SELECT
        id,
        name,
        parent_id,
        0 AS level,
        name::text AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    SELECT
        c.id,
        c.name,
        c.parent_id,
        ct.level + 1,
        ct.path || ' > ' || c.name
    FROM categories c
    JOIN category_tree ct
        ON c.parent_id = ct.id
)
SELECT
    id,
    name,
    parent_id,
    level,
    path
FROM category_tree
ORDER BY path;
