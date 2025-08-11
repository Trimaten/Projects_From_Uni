import pika
import json
import time
import random

def too_hot_coffee():
    """Simulates blowing on coffee if it's too hot."""
    random_number = random.randint(1, 10)
    if random_number == 1:  # 10% chance
        print("Coffee is too hot! Blowing on coffee", end="")
        for _ in range(random.randint(1, 3)):
            print(".", end="", flush=True)
            time.sleep(2)
        print(" Done blowing!")

def process_order(ch, method, properties, body):
    # Decode the order message
    order = json.loads(body)
    print(f"Received order: {order}")

    # Simulate preparing coffee
    duration = order["items"]
    while duration > 0:
        too_hot_coffee()
        time.sleep(1)
        print(f"Preparing coffee... {duration}s left", flush=True)
        duration -= 1

    print("Coffee prepared!")

    # Create Prepared Coffee Message
    prepared_message = json.dumps({
        "id": order["id"],
        "status": "prepared",
        "preparedAt": int(time.time())
    })

    # Publish the prepared message to the finished_coffee queue
    ch.basic_publish(exchange="", routing_key="finished_coffee", body=prepared_message)
    print(f"Sent to finished_coffee queue: {prepared_message}")

    # Acknowledge the original order
    ch.basic_ack(delivery_tag=method.delivery_tag)

    # Print queue lengths
    connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
    channel = connection.channel()
    coffee_orders_queue = channel.queue_declare(queue="coffee_orders", passive=True)
    finished_coffee_queue = channel.queue_declare(queue="finished_coffee", passive=True)
    #print(f"Coffee Orders Queue Length: {coffee_orders_queue.method.message_count}")
    print(f"Finished Coffee Queue Length: {finished_coffee_queue.method.message_count}")

def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
    channel = connection.channel()

    # Declare both queues
    channel.queue_declare(queue="coffee_orders")
    channel.queue_declare(queue="finished_coffee")

    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue="coffee_orders", on_message_callback=process_order)

    print("Waiting for coffee orders...")
    channel.start_consuming()

if __name__ == "__main__":
    main()
