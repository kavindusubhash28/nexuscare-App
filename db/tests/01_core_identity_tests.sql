-- =========================================
-- TEST SCRIPT FOR users TABLE
-- =========================================

-- 1️⃣ Check if users table exists
SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'users'
) AS users_table_exists;


-- 2️⃣ Check total number of users (should be at least 5 from seed)
SELECT COUNT(*) AS total_users
FROM users;


-- 3️⃣ Verify System Admin exists
SELECT *
FROM users
WHERE user_id = 'U001';


-- 4️⃣ Check NOT NULL constraints are respected
SELECT *
FROM users
WHERE name IS NULL
   OR contact_no1 IS NULL
   OR address IS NULL
   OR created_at IS NULL;


-- 5️⃣ Check Primary Key uniqueness
SELECT user_id, COUNT(*)
FROM users
GROUP BY user_id
HAVING COUNT(*) > 1;


-- 6️⃣ Check created_at default working
SELECT user_id, created_at
FROM users
ORDER BY created_at DESC;
