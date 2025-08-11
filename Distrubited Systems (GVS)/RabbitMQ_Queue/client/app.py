import pika
import time

# Function to establish a connection to RabbitMQ
def connect_to_rabbitmq():
    for i in range(10):  # Retry logic
        try:
            connection = pika.BlockingConnection(
                pika.ConnectionParameters(host="rabbitmq")  # Connect to RabbitMQ container
            )
            return connection
        except Exception as e:
            print(f"Connection failed ({i+1}/10): {e}")
            time.sleep(5)  # Wait before retrying
    raise Exception("Could not connect to RabbitMQ after 10 attempts")

def main():
    connection = connect_to_rabbitmq()
    channel = connection.channel()  # Open a channel

    # Declare a queue (creates it if it doesn't exist)
    channel.queue_declare(queue="coffee_orders")

    # Publish a message to the queue
    channel.basic_publish(exchange="", routing_key="coffee_orders", body="Test Order")
    print("Message sent to RabbitMQ queue!")

    connection.close()  # Close the connection

if __name__ == "__main__":
    main()