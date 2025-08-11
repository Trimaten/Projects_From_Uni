# Inhaltsverzeichnis
- [Inhaltsverzeichnis](#inhaltsverzeichnis)
  - [Voraussetzungen](#voraussetzungen)
  - [Ordnerstruktur im Verzeichnis erstellen](#ordnerstruktur-im-verzeichnis-erstellen)
  - [Docker-Compose Datei erstellen](#docker-compose-datei-erstellen)
  - [Terminal öffnen und Docker starten](#terminal-öffnen-und-docker-starten)
  - [Konfigurationsdateien ersetzen](#konfigurationsdateien-ersetzen)
  - [Visual Studio Code öffnen](#visual-studio-code-öffnen)
  - [PlatformIO installieren](#platformio-installieren)
  - [Neues Projekt starten](#neues-projekt-starten)
  - [Board auswählen](#board-auswählen)
  - [INI-Datei bearbeiten](#ini-datei-bearbeiten)
  - [Code einfügen / bearbeiten](#code-einfügen--bearbeiten)
  - [(optional) Bibliotheken installieren](#optional-bibliotheken-installieren)
  - [PlatformIO Terminal starten](#platformio-terminal-starten)
  - [Code auf den ESP32 laden](#code-auf-den-esp32-laden)
  - [(optional) Seriellen Monitor starten](#optional-seriellen-monitor-starten)
  - [Fertig](#fertig)

---

## Voraussetzungen
- Docker Kenntnisse
## Ordnerstruktur im Verzeichnis erstellen
Erstelle eine Ordnerstruktur für das Projekt. Dies hilft, die Dateien organisiert zu halten.

```
HHN-SV2/
├── docker-compose.yml
├── home_assistant/
│ └── config/
└── mosquitto/
  └── config/
```
home_assistant:

![Making home_assistant](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/home%20assistance%20folder.gif)
![Making home_assistant](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/home%20assistance%20config.gif)

---

Mosquitto:

![Making mosquitto](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/mosquito%20folder.gif)
![Making mosquitto](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/mosquito%20config.gif)

## Docker-Compose Datei erstellen

Erstelle eine `docker-compose.yml`-Datei im Stammverzeichnis, um Home Assistant und den MQTT-Broker zu starten.

```
  home_assistant:
    image: lscr.io/linuxserver/homeassistant:latest
    container_name: home_assistant
    restart: unless-stopped
    ports:
      - "8124:8123"
    volumes:
      - ./home_assistant/config:/config
    environment:
      - TZ=Europe/Berlin
      - MQTT_HOST=localhost
      - MQTT_PORT=1883
      - MQTT_USERNAME=koti
      - MQTT_PASSWORD=kot

  mosquitto:
    image: eclipse-mosquitto:latest
    container_name: mosquitto
    restart: always
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto/config:/mosquitto/config
    environment:
      - TZ=Europe/Berlin
```

![Creating docker Image](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/docker-compose%20creation.gif)


## Terminal öffnen und Docker starten
1. Öffne ein Terminal im Stammverzeichnis (wo die docker-compose.yml-Datei liegt).
2. Starte die Docker-Container mit dem folgenden Befehl:
   ```
   docker-compose up -d
   ```
   
![Creating docker Image](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/docker%20compose%20up%20and%20localhost.gif)

3. Sobald alles heruntergeladen ist sollten mehr Datein in den Ordner sein.
## Konfigurationsdateien ersetzen
Ersetze die Konfigurationsdateien in den Ordnern home_assistant/config/ und mosquitto/config/ mit den gewünschten Einstellungen. Dies kann z. B. die Konfiguration von Home Assistant oder die MQTT-Benutzerauthentifizierung umfassen.
In home_assistant/config/`configuration.yaml` haben wir:

```yaml
# Loads default set of integrations. Do not remove.
default_config:

# Load frontend themes from the themes folder
frontend:
  themes: !include_dir_merge_named themes

# Include automations, scripts, and scenes
automation: !include automations.yaml
script: !include scripts.yaml
scene: !include scenes.yaml

# HTTP Configuration for reverse proxy or Cloudflare
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 127.0.0.1
    - 192.168.178.79 //Hier die IP von dem Gerät welches die Instanz hosted
    - ::1


# MQTT Configuration
mqtt:
  switch:
    - name: "My Led Strip"
      state_topic: "home/esp32/relay/state"
      command_topic: "home/esp32/relay/set"
      payload_on: "ON"
      payload_off: "OFF"
      state_on: "ON"
      state_off: "OFF"
      qos: 1
      retain: true

    - name: "LOFF/LON Switch"
      state_topic: "home/esp32/relay/state"  # Topic to receive the state (LOFF or LON)
      command_topic: "home/esp32/relay/set2"  # Topic to send commands (LOFF or LON)
      payload_on: "LON"  # Payload to send when turning on
      payload_off: "LOFF"  # Payload to send when turning off
      state_on: "LON"  # State value that represents "on"
      state_off: "LOFF"  # State value that represents "off"
      qos: 1
      retain: true

# Input Text for Color Picker
input_text:
  color_picker:
    name: Color Picker
    initial: "FFFFFF"  # Default value, ensures the field is never empty
    min: 6             # Minimum length of 6 characters
    max: 6             # Maximum length of 6 characters
    pattern: "^[0-9A-F]{6}$"  # Only allows 6 characters of 0-9 and A-F (uppercase only)

# Input Number for Slider and Number of Turns
input_number:
  number_field:
    name: Number of Turns
    initial: 0       # Start at 0
    min: -12         # Minimum value
    max: 12          # Maximum value
    step: 1          # Step size (whole numbers only)
    mode: slider     # Display as a slider in the UI

  slider_value:
    name: Motor Speed
    initial: 5       # Default value (midpoint of 1-10)
    min: 1           # Minimum value
    max: 10          # Maximum value
    step: 1          # Step size (whole numbers only)
    mode: slider     # Display as a slider in the UI

# Input Buttons
input_button:
  send_mon_button:
    name: Send mON

  send_sbn_button:  # Corrected slug
    name: Send sON

# Automations
automation:
  - alias: Send Color or Slider via MQTT
    trigger:
      - platform: state
        entity_id: input_text.color_picker
      - platform: state
        entity_id: input_number.slider_value
    action:
      - choose:
          - conditions: "{{ trigger.entity_id == 'input_text.color_picker' }}"
            sequence:
              - service: mqtt.publish
                data:
                  topic: "home/esp32/relay/set"
                  payload: "#{{ states('input_text.color_picker') }}"  # Add the hashtag for color
                  qos: 1
                  retain: true
          - conditions: "{{ trigger.entity_id == 'input_number.slider_value' }}"
            sequence:
              - service: mqtt.publish
                data:
                  topic: "home/esp32/relay/set"
                  payload: "s{{ states('input_number.slider_value') | int }}"  # Add 's' for slider
                  qos: 1
                  retain: true
  - alias: "Send LON or LOFF based on switch state"
    trigger:
      - platform: state
        entity_id: switch.loff_lon_switch  # Replace with the actual entity ID of your switch
    action:
      - choose:
          - conditions: "{{ trigger.to_state.state == 'on' }}"
            sequence:
              - service: mqtt.publish
                data:
                  topic: "home/esp32/relay/set2"
                  payload: "LON"  # Send LON when the switch is turned on
                  qos: 1
                  retain: true
          - conditions: "{{ trigger.to_state.state == 'off' }}"
            sequence:
              - service: mqtt.publish
                data:
                  topic: "home/esp32/relay/set2"
                  payload: "LOFF"  # Send LOFF when the switch is turned off
                  qos: 1
                  retain: true
  - alias: Send mON and Number of Turns on Button Press
    trigger:
      - platform: event
        event_type: call_service
        event_data:
          domain: input_button
          service: press
          service_data:
            entity_id: input_button.send_mon_button
    action:
      - service: mqtt.publish
        data:
          topic: "home/esp32/relay/set"
          payload: "MON{{ states('input_number.number_field') | int }}"  # Send 'MON' and the number of turns
          qos: 1
          retain: true

  - alias: Send sON on Button Press
    trigger:
      - platform: event
        event_type: call_service
        event_data:
          domain: input_button
          service: press
          service_data:
            entity_id: input_button.send_sbn_button
    action:
      - service: mqtt.publish
        data:
          topic: "home/esp32/relay/set"
          payload: "AON"  # Send 'sON'
          qos: 1
          retain: true

```

![find config](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/find%20configuration%20file.gif)


und in mosquitto/config/`mosquitto.conf` :

```conf
# General settings
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

# Default listener for MQTT
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwords.txt

# WebSocket listener (optional)
listener 9001
protocol websockets

log_dest stderr
```

![create mosquitto config](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/mosquito%20conf%20creation.gif)


## Visual Studio Code öffnen 
Öffne Visual Studio Code um mit der Entwicklung des ESP32-Codes zu beginnen.
## PlatformIO installieren
1. Öffne die Extensions-Ansicht in Vs Code.
2. Suche nach `PlatformIO` IDE und installiere es.

  ![Install PIO](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/install%20PIO.gif)

3. (Optional) Visual Studio Code nach der Installation neustarten.
## Neues Projekt starten
1. Klicke in Vs Code auf das PlatformIO-Symbol in der Sidebar.
2. Wähle `New Project`

  ![PIO Project](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/Create%20PIO%20project.gif)

3. Gib dem Projekt einen Namen, z.B.     ESP32_SmartHome.
4. Wähle des Board und das Framework aus.
## Board auswählen
1. Falls Marc dir die Hardware gegeben hat ist es wahrscheinlich ein ESP32 Dev Module.
2. Wähle als Framework Arduino.
## INI-Datei bearbeiten
Location:

 ![Find Project](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/PIO%20project%20location.gif)

Öffne die `platformio.ini`-Datei und passe sie an:

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
upload_speed = 115200
monitor_speed = 115200
```

 ![Change Ini](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/PIO%20ini%20config.gif)
## Code einfügen / bearbeiten
Füge den Code in die src/`main.cpp` (oder `main.c` für Espressif).
z.B:
```cpp
#include <Arduino.h> //Libraries

void setup() { //Was ausgeführt wird beim Programm start
//stuff
}

void loop() { //Wird regelmäßig wiederholt ausgeführt
//other stuff
}
```
![find main.cpp](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/find%20main%20cpp.gif)

 ![getting the right constants](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/config%20with%20your%20adress.gif)
## (optional) Bibliotheken installieren
1. Öffne das PlatformIO-Symbol und klicke auf Libraries.
2. Suche nach deiner Libary und füge sie zu deinem Projekt hinzu.
   ![getting libs](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/add%20PIO%20stuff%20to%20library.gif)
3. Deine Ini file wird automatisch verändert.
## PlatformIO Terminal starten
1. Öffne das PlatformIO-Symbol und klicke auf `New Terminal`.
2. Stelle sicher, dass der ESP32 mit dem Computer verbunden ist.
   Du kannst es prüfen, indem du den `Geräte-Manager` öffnest und nach `Ports` schaust.
   Falls es nicht erkannt wird kannst du hier die Treiber [hier](https://www.silabs.com/developer-tools/usb-to-uart-bridge-vcp-drivers) installieren.
    ![Treiber](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/first%20time%20ESP32%20driver.gif)
## Code auf den ESP32 laden
1. Führe den folgenden Befehl im PlatformIO-Terminal aus, um den Code auf den ESP32 zu laden:
   ```
   pio run --target upload
   ```

  ![start upload](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/connect%20and%20upload%20code%20to%20ESP32.gif)
  
2. Es kann sein, dass der ESP32 nicht in dem richtigen Zustand ist, weshalb man während des Upload den `Boot`-Knopf, der sich auf dem Brett befindet, drücken muss.
   
  ![what if](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/upload%20error%20message.gif)

## (optional) Seriellen Monitor starten
1. Starte den seriellen Monitor, um die Ausgaben des ESP32 zu sehen:
   ```
   pio device monitor
   ```
  
  ![what if](https://github.com/Kotfresse/HHN-SV2-Doc/raw/main/quickstart%20gifs/pressing%20stuff%20and%20seeing%20what%20changes%20in%20console.gif)
     
2. Der Code läuft auch ohne diesen Schritt.
## Fertig
Der ESP32 führt nun den Code aus und in unserem Fall hat er sich mit dem Wlan und MQTT Broker verbunden und hat auf Nachrichten reagiert.

<video controls width="100%">
  <source src="https://github.com/Kotfresse/HHN-SV2-Doc/raw/refs/heads/main/Semcon.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>