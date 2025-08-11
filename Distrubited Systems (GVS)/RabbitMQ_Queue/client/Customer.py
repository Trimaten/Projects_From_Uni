import pika
import json
import time

def serve_coffee(ch, method, properties, body):
    # Decode the prepared coffee message
    prepared_coffee = json.loads(body)
    print(f"Received prepared coffee: {prepared_coffee}")

    # Simulate serving coffee
    time.sleep(2)
    print(f"Coffee ID {prepared_coffee['id']} has been served. Status: {prepared_coffee['status']}")

    # Acknowledge the message
    ch.basic_ack(delivery_tag=method.delivery_tag)

def main():
    connection = pika.BlockingConnection(pika.ConnectionParameters(host="rabbitmq"))
    channel = connection.channel()

    # Declare the finished_coffee queue
    channel.queue_declare(queue="finished_coffee")

    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue="finished_coffee", on_message_callback=serve_coffee)

    print("Waiting for finished coffee...")
    channel.start_consuming()

if __name__ == "__main__":
    main()
