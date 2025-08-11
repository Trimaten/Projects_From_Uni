import pika
import json
import random
import time
import os

def generate_unique_id(barista_id):
    """Generates a unique order ID using timestamp and barista ID."""
    timestamp = int(time.time() * 1000)  # Current time in milliseconds
    random_part = random.randint(1000, 9999)  # Random number for uniqueness
    return f"{barista_id}-{timestamp}-{random_part}"

def main():
    barista_id = os.getenv("BARISTA_ID", "barista_1")  # Use environment variable for Barista ID
    connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
    channel = connection.channel()
    
    # Declare the coffee_orders queue
    channel.queue_declare(queue="coffee_orders")

    while True:
        # Generate a unique order ID
        order_id = generate_unique_id(barista_id)

        # Generate a random number of items (1-3)
        items = random.randint(1, 3)

        # Create the order message
        message = json.dumps({
            "id": order_id,
            "items": items,
            "createdAt": int(time.time())
        })

        # Publish the message to the coffee_orders queue
        channel.basic_publish(exchange="", routing_key="coffee_orders", body=message)

        # Get the queue length
        queue_state = channel.queue_declare(queue="coffee_orders", passive=True)
        queue_length = queue_state.method.message_count

        # Print details
        print(f"New order: {message}")
        print(f"Queue length: {queue_length}")

        time.sleep(random.randint(1, 3))  # Simulate time between orders

if __name__ == "__main__":
    main()
