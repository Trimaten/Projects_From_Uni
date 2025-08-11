import psycopg2
import threading

# Connect to the database
conn = psycopg2.connect(
    dbname="Kotbank", user="Kot", password="kot", host="localhost", port="5432"
)
cur = conn.cursor()


def print_db_state(test_name):
    print(f"\nDatabase state before {test_name}:")
    cur.execute("SELECT * FROM accounts;")
    rows = cur.fetchall()
    for row in rows:
        print(row)


# Setup method: Clears existing data and seeds the database with test data.
def setup():
    print("Setting up test environment...")
    # Rollback any ongoing transactions to ensure a clean state
    cur.execute("ROLLBACK;")
    # Clear the tables to ensure no data persists between tests
    cur.execute("TRUNCATE TABLE transactions, accounts RESTART IDENTITY CASCADE;")
    # Seed the database with initial accounts for testing
    cur.execute("INSERT INTO accounts (id, name, balance) VALUES (1, 'Me', 1000);")
    cur.execute("INSERT INTO accounts (id, name, balance) VALUES (2, 'Myself', 2000);")
    conn.commit()
    print("Test environment setup completed.")


# Transaction 1: Simulates a basic transaction where the balance of account 1 is updated.
def transaction1():
    print("Starting transaction1...")
    cur.execute("BEGIN; UPDATE accounts SET balance = balance + 100 WHERE id = 1; COMMIT;")
    print("Transaction1 completed!")

# Transaction 2: Another transaction updating account 1's balance, potentially conflicting with Transaction 1.
def transaction2():
    print("Starting transaction2...")
    cur.execute("BEGIN; UPDATE accounts SET balance = balance + 100 WHERE id = 1; COMMIT;")
    print("Transaction2 completed!")

# Transaction with SERIALIZABLE isolation level: Ensures strict serializability for concurrent updates.
def transaction_serializable():
    print("Starting SERIALIZABLE transaction...")
    # Rollback any ongoing transactions first
    cur.execute("ROLLBACK;")
    # Set isolation level before starting any transaction
    cur.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;")
    cur.execute("BEGIN;")
    cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 1;")
    cur.execute("COMMIT;")
    print("SERIALIZABLE transaction completed!")


# Deadlock simulation transaction 1: Updates account 1 and account 2, creating a potential deadlock.
def transaction_deadlock1():
    print("Starting transaction_deadlock1...")
    cur.execute("BEGIN; UPDATE accounts SET balance = balance + 100 WHERE id = 1;")
    cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 2;")
    cur.execute("COMMIT;")
    print("transaction_deadlock1 completed!")

# Deadlock simulation transaction 2: Simulates a deadlock by updating account 2 before account 1.
def transaction_deadlock2():
    print("Starting transaction_deadlock2...")
    cur.execute("BEGIN; UPDATE accounts SET balance = balance + 100 WHERE id = 2;")
    cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 1;")
    cur.execute("COMMIT;")
    print("transaction_deadlock2 completed!")

# Rollback transaction: Tries an update and then inserts a duplicate, rolling back on failure.
def transaction_rollback():
    print("Starting rollback transaction...")
    try:
        cur.execute("BEGIN;")
        cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 1;")
        # Generate a new unique ID to avoid conflicts with existing data
        cur.execute("SELECT MAX(id) FROM accounts;")
        max_id = cur.fetchone()[0]
        new_id = max_id + 1
        cur.execute(f"INSERT INTO accounts (id, name, balance) VALUES ({new_id}, 'I', 100);")
        cur.execute("COMMIT;")  # Commit should only happen if no exception occurs
    except Exception as e:
        print(f"Error occurred: {e}")
        cur.execute("ROLLBACK;")  # Rollback if there was an error
    print("Rollback transaction completed!")

def transaction_bad_case_rollback():
    print("Starting bad case rollback transaction...")
    try:
        cur.execute("BEGIN;")
        cur.execute("UPDATE accounts SET balance = balance + 100 WHERE id = 1;")
        # Attempting to insert a record with a duplicate ID (which will violate the primary key constraint)
        cur.execute("INSERT INTO accounts (id, name, balance) VALUES (1, 'Duplicate', 100);")
        cur.execute("COMMIT;")
    except Exception as e:
        print(f"Error occurred: {e}")
        cur.execute("ROLLBACK;")
    print("Bad case rollback transaction completed!")

# Call setup before each test to ensure a clean database state
setup()

# Test 1: Run both transactions concurrently to test concurrency
print("Test 1: Running transactions concurrently")
setup()
print_db_state("Test 1")
thread1 = threading.Thread(target=transaction1)
thread2 = threading.Thread(target=transaction2)
thread1.start()
thread2.start()
thread1.join()
thread2.join()
print_db_state("Test 1 (after)")

# Test 2: Test SERIALIZABLE isolation level with strict transaction control
print("Test 2: Running SERIALIZABLE isolation transaction")
setup()
print_db_state("Test 2")
transaction_serializable()
print_db_state("Test 2 (after)")

# Test 3: Simulate a deadlock scenario by running conflicting transactions
print("Test 3: Running deadlock simulation")
setup()
print_db_state("Test 3")
thread1 = threading.Thread(target=transaction_deadlock1)
thread2 = threading.Thread(target=transaction_deadlock2)
thread1.start()
thread2.start()
thread1.join()
thread2.join()
print_db_state("Test 3 (after)")

# Test 4: Test rollback behavior when an error occurs
print("Test 4: Running rollback on failure")
setup()
print_db_state("Test 4")
transaction_rollback()
print_db_state("Test 4 (after)")

# Test 5: Test rollback behavior in a bad case scenario
print("Test 5: Running rollback on duplicate key violation")
setup()
print_db_state("Test 5")
transaction_bad_case_rollback()
print_db_state("Test 5 (after)")

# Close connection after tests
cur.close()
conn.close()