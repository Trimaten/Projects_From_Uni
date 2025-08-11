#include <WiFi.h>
#include <PubSubClient.h>
#include <Arduino.h>
#include <iostream>

// Wi-Fi credentials
#define WIFI_SSID "Kotspot" // Replace with your SSID
#define WIFI_PASSWORD "kotfressemagkot" // Replace with your password

// MQTT Broker settings
#define MQTT_BROKER "192.168.187.225"
#define MQTT_PORT 1883
#define MQTT_USER "koti"
#define MQTT_PASSWORD "kot"

#define LIGHTS 0

WiFiClient espClient;
PubSubClient mqttClient(espClient);

void setup_wifi() {
    delay(10);
    Serial.println();
    Serial.print("Connecting to ");
    Serial.println(WIFI_SSID);

    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }

    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
}

void mqtt_callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Message arrived [");
    Serial.print(topic);
    Serial.print("] ");
    for (int i = 0; i < length; i++) {
        Serial.print((char)payload[i]);
    }
    Serial.println();

    // Handle command topic
    if (strcmp(topic, "home/esp32/relay/set2") == 0) {
        if (strncmp((char*)payload, "LON", length) == 0) {
            Serial.println("Turning Lights on");
            digitalWrite(LIGHTS, true);
            digitalWrite(LED_BUILTIN, true);
            //mqttClient.publish("home/esp32/relay/state", "ON");
        } else if (strncmp((char*)payload, "LOFF", length) == 0) {
          Serial.println("Turning lights off");
            digitalWrite(LIGHTS, false);
            digitalWrite(LED_BUILTIN, false);
          //mqttClient.publish("home/esp32/relay/state", "OFF");
        } else {
            Serial.print("Unknown command: ");
            Serial.println((char*)payload);
        }
    }
}

void reconnect() {
    // Loop until we're reconnected
    while (!mqttClient.connected()) {
        Serial.print("Attempting MQTT connection...");
        // Attempt to connect
        if (mqttClient.connect("ESP32Lightslave", MQTT_USER, MQTT_PASSWORD)) {
            Serial.println("connected");
            // Subscribe
            mqttClient.subscribe("home/esp32/relay/set2");
        } else {
            Serial.print("failed, rc=");
            Serial.print(mqttClient.state());
            Serial.println(" try again in 5 seconds");
            // Wait 5 seconds before retrying
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    pinMode(LIGHTS, OUTPUT);
    digitalWrite(LIGHTS, LOW);  // Set the initial state to OFF
    setup_wifi();
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setCallback(mqtt_callback);
}

void loop() {

  if (!mqttClient.connected()) {
      reconnect();
  }
  mqttClient.loop();

  // Your other loop code here
}