import json
import time
import datetime
import paho.mqtt.client as mqtt
import sys

# Toggle debug mode
DEBUG = False
SenOrAct = True
Hub = False

def debug_print(message):
    if DEBUG:
        print(message)

# Check for username as argument
try:
    username = sys.argv[1]
    mode = int(sys.argv[2])
    if mode == 1:
        SenOrAct = True  # Sensor mode
    elif mode == 2:
        SenOrAct = False  # Actuator mode
    elif mode == 3:
        Hub = True  # Hub mode
    else:
        raise ValueError("Invalid mode. Use 1 for Sensor, 2 for Actuator, 3 for Hub.")
    debug_print(f"[DEBUG] Username: {username}, Mode: {mode}")
except (IndexError, ValueError) as e:
    print(f"[ERROR] {e}")
    sys.exit(1)

# Callback when connected to broker
def on_connect(client, userdata, flags, rc, properties=None):
    debug_print(f"[DEBUG] Connected to broker with result code: {rc}")
    debug_print(f"[DEBUG] Notifying others that {username} is online...")
    client.publish("commands/user_online", json.dumps({"from": username}))
    debug_print(f"[DEBUG] Subscribing to 'channels/general' and 'private/{username}/+' topics...")
    if Hub:
        debug_print("[DEBUG] Subscribing to all actuator messages as a Hub...")
        client.subscribe("commands/actuator_message")
        client.subscribe("channels/general")
        client.subscribe(f"private/{username}/+")
    elif(SenOrAct):
        client.subscribe(f"sensors/{username}/+")
        client.subscribe("channels/general")
        client.subscribe(f"private/{username}/+")
    else:
        client.subscribe(f"actuators/{username}/+")
        client.subscribe("channels/general")
        client.subscribe(f"private/{username}/+")
    print(f"Connected as {username}")

# Callback when a message is received
def on_message(client, userdata, msg):
    debug_print(f"[DEBUG] Message received on topic: {msg.topic}")
    debug_print(f"[DEBUG] Raw payload: {msg.payload}")
    topic_parts = msg.topic.split("/")  # Split the topic into components
    data = json.loads(msg.payload)
    timestamp = datetime.datetime.fromtimestamp(data["time"]).strftime("%H:%M:%S")

    
    if topic_parts[0] == "channels" and topic_parts[1] == "general":
        if data["from"] == "server" and "is online" in data["text"]:
            # Format the user online message
            print(f"{timestamp} <#general> {data['text']}")
        else:
            print(f"{timestamp} <{data['from']}#{topic_parts[1]}> {data['text']}")
    elif topic_parts[0] == "private" and topic_parts[1] == username:
        print(f"{timestamp} <{topic_parts[1]}/{topic_parts[2]}> {data['text']}")
    elif topic_parts[0] == "sensors" and topic_parts[1] == username:
        print(f"{timestamp} <Sensor/{topic_parts[2]}> {data['value']}")
    elif topic_parts[0] == "actuators" and topic_parts[1] == username:
        print(f"{timestamp} <Actuator/{topic_parts[2]}> {data['action']}")
    elif Hub and topic_parts[0] == "commands" and topic_parts[1] == "actuator_message":
        debug_print(f"[DEBUG] Hub received actuator command: {data}")
        recipient = data.get("to")
        if recipient:
            # Forward message to the specific actuator topic
            client.publish(f"actuators/{recipient}/{username}", json.dumps(data))
            print(f"{timestamp} <Hub> Forwarded actuator command to {recipient}")
        else:
            print("[ERROR] No recipient specified in actuator_message.")

    print_prompt()


def publish_command(command, data):
    data["time"] = int(time.time())
    client.publish(f"commands/{command}", json.dumps(data))

# Setup MQTT client
debug_print("[DEBUG] Setting up MQTT client...")
client = mqtt.Client(protocol=mqtt.MQTTv5)
client.on_connect = on_connect
client.on_message = on_message

# Connect to broker
debug_print("[DEBUG] Connecting to broker at localhost:1883...")
client.connect("localhost", 1883, 60)

# Start loop
debug_print("[DEBUG] Starting MQTT client loop...")
client.loop_start()

# Print prompt
def print_prompt():
    print("> ", end="", flush=True)

# Main input loop
print_prompt()
while True:
    try:
        user_input = input().strip()
        if user_input.startswith("@"):  # Check for private message syntax
            recipient, *message = user_input[1:].split(" ", 1)
            if message:
                publish_command("private_message", {"from": username, "to": recipient, "text": message[0]})
            else:
                print("[ERROR] Private message requires a recipient and a message")
        elif user_input.startswith("-ac"):
            if Hub:
                try:
                    recipient, *message = user_input[4:].strip().split(" ", 1)
                    if not message:
                        raise ValueError("Actuator message requires a recipient and a message.")
                    publish_command("actuator_message", {"from": username, "to": recipient, "action": message[0]})
                except ValueError as e:
                    print(f"[ERROR] {e}")
            else:
                print("[ERROR] Only Hub devices can send actuator messages.")

        else:  # Handle general messages
            publish_command("general_message", {"from": username, "text": user_input})
    except KeyboardInterrupt:
        print("\n[INFO] Exiting...")
        break
