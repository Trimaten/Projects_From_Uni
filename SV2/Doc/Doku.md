# Inhaltsverzeichnis
- [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Einführung](#einführung)
  - [IDE-Auswahl und Hardware-Aufteilung](#ide-auswahl-und-hardware-aufteilung)
  - [Home Assistant und MQTT-Integration](#home-assistant-und-mqtt-integration)
  - [Erste Tests und Probleme](#erste-tests-und-probleme)
  - [LED-Streifen und Motorsteuerung](#led-streifen-und-motorsteuerung)
  - [Lautsprecher und Tonerzeugung](#lautsprecher-und-tonerzeugung)
  - [Fotoresistor und Lichtsteuerung](#fotoresistor-und-lichtsteuerung)
  - [Zusammenfassung](#zusammenfassung)

---

## Einführung
Um mit dem Projekt anzufangen, mussten wir zuerst eine IDE auswählen und haben uns für PlatformIO entschieden, um mit dem ESP32 zu coden. Wir haben die Hardware aufgeteilt, damit wir in den Ferien selbst forschen und probieren konnten.

---

## IDE-Auswahl und Hardware-Aufteilung
Tri hat nach einem Weg gesucht, um den ESP32 für eine Smarthome-Integration zu verwenden, und hat zunächst Google Home angeschaut. Ihm wurde schnell klar, dass es sehr kompliziert und vor allem gerade schwierig ist, weil Google ihre Tools migriert. AWS war auch eine Option, aber nur als Trial (Testzeit). Das Gleiche gilt für IFTTT, und Tri wollte eher etwas, das unabhängig von irgendwelchen Abonnements ist. Deshalb kam Home Assistant als Selfhosting-Instanz in Frage, bei der man über eine MQTT-Integration den ESP32 mit Home Assistant verbinden kann.

---

## Home Assistant und MQTT-Integration
Tri hat also einen Docker-Container mit Home Assistant und einem MQTT-Broker eingerichtet. Das Erste, was Tri testen wollte, war, ob der ESP32 sich überhaupt mit meinem Heimnetzwerk verbinden konnte. Als es Zeit war, den Code auszuprobieren, gab es das Problem, dass der ESP32 nicht erkannt wurde. Es war nur ein Treiberproblem, und nach vielen chinesischen Treibern wurde er irgendwann erkannt. Nach einigen Code-Problemen, weil alles in C geschrieben ist, lief er schließlich und konnte mir seine IP-Adresse liefern. Erfolg! Er hat sich verbunden, und ich konnte ihn pingen.

=== Code of ESP32 Network Connection here ===

-> **Video of Log? here**: Show the ESP32 connecting to the network and sending its IP address to the serial monitor.

Als Nächstes wollte ich testen, ob man einem MQTT-Topic subscriben und etwas publishen kann. Das ging relativ leicht und funktionierte direkt in Testterminals. Auch als ich es im Home Assistant GUI geschickt habe, kam es an. Somit konnte ich Nachrichten an den ESP32 senden, und der ESP32 konnte darauf antworten und Aufgaben ausführen, wie zum Beispiel einen Pin auf High stellen. Genau das habe ich auch gecodet. Das Testen war schwierig, weil ich kein Multimeter hatte, also musste ich am nächsten Morgen eins von meinem Onkel ausleihen. Es stellte sich heraus, dass es funktioniert.

=== Code of MQTT Subscribe/Publish here ===

-> **Video of MQTT and Homeassistant here**: Demonstrate sending an MQTT command from Home Assistant and the ESP32 responding (e.g., turning on an LED or sending a message back).

---

## Erste Tests und Probleme
Da Home Assistant und der ESP32 Nachrichten austauschen können, kann der ESP32 zum Beispiel einen Motor steuern, der eine Tür schließt, oder als Sensor verwendet werden, wenn die richtige Hardware angeschlossen ist, und ein Signal an Home Assistant senden, woraufhin das Licht anging.

Während des Tests kam ich mit den Pins in Kontakt und habe es kurzgeschlossen, was den ESP32 zum Crashen brachte und dieser neustartete. Jetzt konnte ich nichts mehr machen, da ich bisher nur meine privaten Teile verwendet hatte und die anderen Hardwarekomponenten bei den anderen lagen.

---

## LED-Streifen und Motorsteuerung
Es stellte sich heraus, dass es den anderen beiden nicht möglich war, etwas über die Ferien zu machen, außerdem musste einer von uns sich noch um Prüfungen kümmern. Es gab auch Probleme bei einem der Beiden, das dazu führte, dass sein ESP32 keine Daten empfangen konnte.

Trotzdem haben wir uns drangemacht und mit mehr Hardware angefangen, diese mit den ESP32 anzusprechen. Wir haben den Code, den ich in C geschrieben habe, von der Platform Espressif auf Arduino C++ umgestellt, weil das leichter zu coden ist. Jetzt mit mehr Hardware konnten wir endlich testen, ob der ESP32 die Hardwareteile ansprechen kann.

=== Code of Arduino C++ Conversion here ===
```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <Arduino.h>

// Wi-Fi credentials
#define WIFI_SSID "Kotspot" // Replace with SSID
#define WIFI_PASSWORD "kotfressemagkot" // Replace with password

// MQTT Broker settings
#define MQTT_BROKER "192.168.167.225"
#define MQTT_PORT 1883
#define MQTT_USER "koti"
#define MQTT_PASSWORD "kot"

#define RELAY_GPIO 2

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
    if (strcmp(topic, "home/esp32/relay/set") == 0) {
        if (strncmp((char*)payload, "ON", length) == 0) {
            Serial.println("Turning relay ON");
            digitalWrite(RELAY_GPIO, HIGH);
            mqttClient.publish("home/esp32/relay/state", "ON");
        } else if (strncmp((char*)payload, "OFF", length) == 0) {
            Serial.println("Turning relay OFF");
            digitalWrite(RELAY_GPIO, LOW);
            mqttClient.publish("home/esp32/relay/state", "OFF");
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
        if (mqttClient.connect("ESP32Client", MQTT_USER, MQTT_PASSWORD)) {
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

    setup_wifi();
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setCallback(mqtt_callback);
}

void loop() {
    if (!mqttClient.connected()) {
        reconnect();
    }
    mqttClient.loop();
}
```

Dieser Code gleicht dem alten C Code von der Funktionsweise, verwendet aber das Arduino Framework. Zuerst verbindet sich der ESP32 mit dem WLAN-Netzwerk, in dem sich auch der Home Assistant und MQTT-Broker befinden; hierfür wurde ein Hotspot verwendet. Als nächstes verbindet er sich mit dem Broker, und Abonniert das Thema "home/esp32/relay/set". Wenn eine Nachricht mit diesem Thema empfangen wird, wird die Methode `mqtt_callback` aufgerufen. Diese untersucht den Inhalt der Nachricht handelt entsprechend; hierüber bauen wir alle neuen Funktionen ein.

Nach Implimentierung eines LED-Streifens und eines Motors sieht der Code dieser Methode wie folgt aus:

```cpp
[neue Variablen]
CRGB ledcolor = CRGB::Gray; //Farbe des LED-Streifens
bool lightson = false; //Leuchtet der Streifen?
int motordelay = 1; //Konfigurierte Drehgeschwindikeit des Motors
bool turning = false; //Dreht sich der Motor?
[...]
```

```cpp
[Ausschnitt aus mqtt_callback]
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
        }
[weiterer Code]
```
Dieser Code nimmt fünf verschiede Befehle an: `ON` und `OFF` steuert die Lichterkette, ein Hexcode, eingeleitet mit `#`, ändert die Farbe des Lichts, `s1`-`s10` konfigurieren die Geschwindigkeit des Motors, und `MON-12` bis `MON12` lassen den Motor sich drehen, wobei eine Zahl einer Vierteldrehung entspricht. Die Lichter und der Motor werden von seperaten Threads gesteuert, damit der ESP32 während dieser Zeit weiterhin Befehle annehmen kann. Um diese Threads zu handhaben, werden die globalen booleans `lightson` und `turning` verwendet. Hier sind die methoden, die auf den Threads ausgeführt werden.
```cpp
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
```
Diese Methoden steuern die Peripheriegeräte durch Ansprechen der GPIO-Pins des ESP32, an die die Geräte angeschlossen sind.
```cpp
#define NUM_LEDS 13 // Wie lang ist die Lichterkette?
#define DATA_PIN 2 //Dieser Pin steuert die LEDs
#define CLOCK_PIN 4 //Dieser Pin ist für manche LED-Ketten erforderlich

#define MOTOR_PIN_1 26 //Diese vier Pins steuern den Motor
#define MOTOR_PIN_2 25
#define MOTOR_PIN_3 33
#define MOTOR_PIN_4 32
```
Falls die LEDs während einer Motorbewegung nicht aktiv sind, fungieren sie als Fortschrittsleiste.

-> **Video of MY EYES THEY ARE BURNING here**: Show the LED strip changing colors or the motor turning in response to MQTT commands.

---

## Lautsprecher und Tonerzeugung
Am Abend haben wir noch Lautsprecher ausprobiert, um zu sehen, ob wir Musik spielen können. Wir haben im Internet eine Notentabelle mit Frequenzen gefunden und die Melodie gecodet und abgespielt. Eigentlich gibt es in Arduino eine Tone-Funktion, die wir verwenden wollten, aber in PlatformIO war sie nicht dabei, also haben wir unsere eigene codet, die aber nicht perfekt war.

=== Code of Tone Function Implementation here ===

-> **Video of BEEP BOOP here**: Demonstrate the ESP32 playing a melody through the connected speakers.

---

## Fotoresistor und Lichtsteuerung
Unser nächster Versuch ist mit einem Fotoresistor, den wir mit unserem Gerät anschließen. Diesen wollen wir unter bestimmten Bedingungen dazu bringen, Daten zu einem zweiten ESP32 senden zu können. Zuerst haben wir den Pin auf 34 gesetzt und den Code geschrieben. Jetzt, je nachdem ob das Licht aus oder an ist, kriegen wir unterschiedliche Stromwerte, mehr Strom kommt durch, wenn Licht da ist und kaum bis gar kein Strom, wenn das Licht aus ist.

=== Code of Photoresistor Integration here ===

-> **Video of Photores here**: Show the photoresistor detecting light changes and triggering actions (e.g., turning on an LED or sending a signal to Home Assistant).

---

## Zusammenfassung
Insgesamt haben wir viele Fortschritte gemacht, aber es gab auch einige Herausforderungen. Wir haben gelernt, wie man den ESP32 mit Home Assistant und MQTT integriert, LED-Streifen und Motoren steuert, sowie Tonerzeugung und Lichtsteuerung mit einem Fotoresistor umsetzt. Aus dem Projekt haben wir gelernt dass man es endlos erweitern könnte und verschiedene Smart-Home Geräte miteinander sprechen lassen kann.

---
Doku.md
15 KB