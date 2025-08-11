import requests

# HTTP Bridge endpoint
url = "http://localhost:8081/mqtt"

# Payload
payload = {
    "topic": "actuators/actuatorrr",
    "message": {
        "from": "hub",
        "action": "turn_on"
    }
}

# Send HTTP POST request
response = requests.post(url, json=payload)
print(f"Status Code: {response.status_code}")
print(f"Response: {response.text}")
