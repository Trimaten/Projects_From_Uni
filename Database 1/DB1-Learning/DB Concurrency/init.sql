-- Create tables
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    balance DECIMAL(10, 2)
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    account_id INT REFERENCES accounts(id),
    amount DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
INSERT INTO accounts (name, balance) VALUES ('Me', 1000);
INSERT INTO accounts (name, balance) VALUES ('Myself', 2000);

-- Test 1: Concurrent transactions (Update balances)
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;

BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;

-- Test 2: SERIALIZABLE transaction
BEGIN;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;

-- Test 3: Deadlock simulation
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 2;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;
COMMIT;

-- Test 4: Rollback on failure (Duplicate account insertion)
BEGIN;
UPDATE accounts SET balance = balance + 100 WHERE id = 1;

-- Attempt to insert duplicate entry (error will occur)
INSERT INTO accounts (id, name, balance) VALUES (1, 'I', 100);
COMMIT;

-- Rollback if error occurs
ROLLBACK;

-- Query to verify final state
SELECT * FROM accounts;
SELECT * FROM transactions;
