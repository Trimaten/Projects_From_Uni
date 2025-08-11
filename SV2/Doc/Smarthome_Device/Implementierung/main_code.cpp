#include <WiFi.h>
#include <PubSubClient.h>
#include <Arduino.h>
#include <FastLED.h>
#include <thread>
#include <iostream>

// Wi-Fi credentials
#define WIFI_SSID "Internet Name" // Replace with your SSID
#define WIFI_PASSWORD "Internet Passwort" // Replace with your password

// MQTT Broker settings
#define MQTT_BROKER "192.168.187.225"
#define MQTT_PORT 1883
#define MQTT_USER "koti"
#define MQTT_PASSWORD "kot"

#define RELAY_GPIO 2  // Use GPIO2, or replace with your desired GPIO pin

#define NUM_LEDS 13 // or 77
#define DATA_PIN 2
#define CLOCK_PIN 4

#define MOTOR_PIN_1 26
#define MOTOR_PIN_2 25
#define MOTOR_PIN_3 33
#define MOTOR_PIN_4 32

#define SPEAKER_1_PIN 16
#define SPEAKER_2_PIN 17

#define PHOTORES 34

int seq[8][4] = {
        {1, 0, 0, 0},
        {1, 1, 0, 0},
        {0, 1, 0, 0},
        {0, 1, 1, 0},
        {0, 0, 1, 0},
        {0, 0, 1, 1},
        {0, 0, 0, 1},
        {1, 0, 0, 1} };

int melody[] = {
  294, 294, 587, 440, 415, 392, 349, 294, 349, 392,
  262, 262, 587, 440, 415, 392, 349, 294, 349, 392,
  247, 247, 587, 440, 415, 392, 349, 294, 349, 392,
  233, 233, 587, 440, 415, 392, 349, 294, 349, 392,
  
};

// Define the duration of each note (in milliseconds)
int noteDurations[] = {
  50, 50, 200, 400, 200, 200, 200, 25, 25, 25,
  50, 50, 200, 400, 200, 200, 200, 25, 25, 25,
  50, 50, 200, 400, 200, 200, 200, 25, 25, 25,
  50, 50, 200, 400, 200, 200, 200, 25, 25, 25,
};

WiFiClient espClient;
PubSubClient mqttClient(espClient);
CRGB leds[NUM_LEDS];
CRGB ledcolor = CRGB::Gray;
bool lightson = false;
int motordelay = 1;
bool turning = false;
bool musicplaying = false;
bool lightpresent;
void lightloop();
void turnmotor(int quarterturns);
void speakerv1();
void speakerv2();

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

void GPTone(int pin, int frequency, int duration) {
  int period = 1000000L / frequency; // Calculate the period in microseconds
  int pulseWidth = period / 2;       // Square wave: half the period high, half low

  for (long i = 0; i < duration * 1000L; i += period) {
    digitalWrite(pin, true);
    delayMicroseconds(pulseWidth);
    digitalWrite(pin, false);
    delayMicroseconds(pulseWidth);
  }
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
    if (strcmp(topic, "home/esp32/relay/set") == 0) {
        if (strncmp((char*)payload, "ON", length) == 0) {
            Serial.println("Turning relay ON");
            if (!turning) {
              lightson = true;
              std::thread(lightloop).detach();
            }
            mqttClient.publish("home/esp32/relay/state", "ON");
        } else if (strncmp((char*)payload, "OFF", length) == 0) {
            Serial.println("Turning relay OFF");
            lightson = false;
            mqttClient.publish("home/esp32/relay/state", "OFF");
        } else if (*payload == '#' && length == 7) {
            Serial.println("Special color command received.");
            std::string s((char*)payload);
            s = s.substr(1, 6);
            Serial.print("Setting color to ");
            std::cout << s << std::endl;
            ledcolor = std::stoul(s, nullptr, 16);
        } else if (*payload == 's') { 
          //handle speed change
          std::string s((char*)payload, 1, length-1);
          motordelay = 11 - std::stoi(s);
          Serial.println(motordelay);
        } else if (strncmp((char*)payload, "MON", 3) == 0) { 
          //start motor with specified turns
          std::string s((char*)payload, 3, length-3);
          if (!turning) {
            std::thread(turnmotor, std::stoi(s)).detach();
          }
        } else if (strncmp((char*)payload, "AON", length) == 0 && !musicplaying) {
          //sands undertale
          Serial.println("Commencing bad time...");
          musicplaying = true;
          std::thread(speakerv1).detach();
          std::thread(speakerv2).detach();
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
        if (mqttClient.connect("ESP32Main", MQTT_USER, MQTT_PASSWORD)) {
            Serial.println("connected");
            // Subscribe
            mqttClient.subscribe("home/esp32/relay/set");
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
    pinMode(RELAY_GPIO, OUTPUT);
    digitalWrite(RELAY_GPIO, LOW);  // Set the initial state to OFF
    pinMode(MOTOR_PIN_1, OUTPUT);
    pinMode(MOTOR_PIN_2, OUTPUT);
    pinMode(MOTOR_PIN_3, OUTPUT);    
    pinMode(MOTOR_PIN_4, OUTPUT); 
    pinMode(SPEAKER_1_PIN, OUTPUT);
    pinMode(SPEAKER_2_PIN, OUTPUT); //setup pins
    pinMode(PHOTORES, INPUT);
    Serial.print("Reading resistor voltage-value: ");
    Serial.print(analogRead(PHOTORES));
    Serial.println();
    setup_wifi();
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setCallback(mqtt_callback);
    FastLED.addLeds<WS2811, DATA_PIN, GRB>(leds, NUM_LEDS); // -- short LED strip, takes GRB for some reason
    //FastLED.addLeds<APA102, DATA_PIN, CLOCK_PIN, RGB>(leds, NUM_LEDS);  // BGR ordering is typical -- LOOOONG LED

}

void loop() {

  if (!mqttClient.connected()) {
      reconnect();
  }
  mqttClient.loop();

  // Your other loop code here
  if (analogRead(PHOTORES) >= 2000 && !lightpresent) {
    //mqttClient.publish("home/esp32/relay/set2", "LOFF");
    mqttClient.publish("home/esp32/relay/state", "LOFF");
    Serial.println("Room lit up, turning off lights");
    lightpresent = true;
  } else if (analogRead(PHOTORES) < 2000 && lightpresent) {
    //mqttClient.publish("home/esp32/relay/set2", "LON");
    mqttClient.publish("home/esp32/relay/state", "LON");
    Serial.println("Room got dark, turning on lights");
    lightpresent = false;
  }
}

void lightloop() {
  
  while (lightson) {
  for(int whiteLed = 0; whiteLed < NUM_LEDS; whiteLed = whiteLed + 1) {
    if(!lightson) {
      break;
    }
    leds[whiteLed] = /*0xFFFFFF - */ledcolor; //color is inverted for some reason
    FastLED.show();
    delay(100);
    leds[whiteLed] = CRGB::Black;
    }
  for(int whiteLed = NUM_LEDS-2; whiteLed > 0; whiteLed = whiteLed - 1) {
    if(!lightson) {
      break;
    }
    leds[whiteLed] = /*0xFFFFFF - */ledcolor; //color is inverted for some reason
    FastLED.show();
    delay(100);
    leds[whiteLed] = CRGB::Black;
    }
  }
  FastLED.show();
}

void turnmotor(int quarterturns) {
  turning = true;
  int c = 0;
  if (quarterturns < 0) {
  for(int i = 0; i < -128*quarterturns; i++) {
    for (int j = 7; j >= 0; j--) {
      digitalWrite(26, seq[j][0]);
      digitalWrite(25, seq[j][1]);
      digitalWrite(33, seq[j][2]);
      digitalWrite(32, seq[j][3]);
      delay(motordelay);
    }
    if(!lightson) {
      if (i % (-128*quarterturns / 13) == 0) {
        leds[c++] = 0x002000;
        FastLED.show();
      }
    }
  }
  } else {
    for(int i = 0; i < 128*quarterturns; i++) {
    for (int j = 0; j < 8; j++) {
      digitalWrite(MOTOR_PIN_1, seq[j][0]);
      digitalWrite(MOTOR_PIN_2, seq[j][1]);
      digitalWrite(MOTOR_PIN_3, seq[j][2]);
      digitalWrite(MOTOR_PIN_4, seq[j][3]);
      delay(motordelay);
    }
    if(!lightson) {
      if (i % (128*quarterturns / NUM_LEDS) == 0) {
        leds[c++] = 0x002000;
        FastLED.show();
      }
    }
  }
  }
  for(int i = 0; i < NUM_LEDS; i++) {
    leds[i] = CRGB::Black;
  }
  FastLED.show();
  turning = false;
}

void speakerv1() {
  Serial.println("v1 thread");
  for (int i = 0; i < 40; i++) {
    tone(SPEAKER_1_PIN, melody[i], 200);
    delay(noteDurations[i]+200);
  }
}

void speakerv2() {
  Serial.println("v2 thread");
  GPTone(SPEAKER_2_PIN, 294, 3375);
  GPTone(SPEAKER_2_PIN, 262, 3375);
  GPTone(SPEAKER_2_PIN, 247, 3375);
  GPTone(SPEAKER_2_PIN, 233, 1687);
  GPTone(SPEAKER_2_PIN, 262, 1687);
  musicplaying = false;
}