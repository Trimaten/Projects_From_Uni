import json
import time
import paho.mqtt.client as mqtt

# Toggle debug mode
DEBUG = True

def debug_print(message):
    if DEBUG:
        print(message)

# Log messages to a file
LOG_FILE = "chat_server.log"

def log_event(message):
    with open(LOG_FILE, "a") as log_file:
        log_file.write(f"{message}\n")

# Callback when the server connects to the broker
def on_connect(client, userdata, flags, rc, properties=None):
    debug_print(f"[DEBUG] Server connected with result code {rc}")
    # Subscribe to all topics
    client.subscribe("commands/#")
    debug_print("[DEBUG] Subscribed to all topics")

# Callback when a message is received
def on_message(client, userdata, msg):
    debug_print(f"[DEBUG] Received message on topic {msg.topic}")
    debug_print(f"[DEBUG] Raw payload: {msg.payload}")
    topic = msg.topic.split("/")
    data = json.loads(msg.payload)
    
    if topic[0] == "commands":
        match topic[1]:
            case "user_online":
                debug_print(f"[DEBUG] User {data['from']} is online")
                log_event(f"[INFO] {data['from']} came online")
                publish_message("channels/general", {"from": "server", "text": f"{data['from']} is online"})
            case "general_message":
                debug_print(f"[DEBUG] Received general message from {data['from']}")
                publish_message("channels/general", data)
            case "actuator_message":
                debug_print(f"[DEBUG] Data is {data}")
                # Publish to the topic following the structure private/{recipient}/{sender}
                publish_message(f"actuators/{data['to']}/{data['from']}", data)
            case "sensor_message":
                debug_print(f"[DEBUG] Received sensor message: {data}")
                publish_message(f"sensors/{data['to']}/{data['from']}", data)
            case "private_message":
                debug_print(f"[DEBUG] Received private message: {data}")
                publish_message(f"private/{data['to']}/{data['from']}", data)
            case _:
                debug_print(f"[DEBUG] Unknown command: {topic[1]}")


def publish_message(topic, data):
    data["time"] = int(time.time())
    client.publish(topic, payload=json.dumps(data))
    debug_print(f"[DEBUG] Published message to {topic}")

# Setup the MQTT client
debug_print("[DEBUG] Connecting to broker...")
client = mqtt.Client(protocol=mqtt.MQTTv5)
client.on_connect = on_connect
client.on_message = on_message

# Connect to the broker
client.connect("localhost", 1883, 60)

# Start the loop to listen for messages
debug_print("[DEBUG] Starting server loop...")
client.loop_forever()
