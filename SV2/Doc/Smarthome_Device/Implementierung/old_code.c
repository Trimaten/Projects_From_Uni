#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "nvs_flash.h"
#include "mqtt_client.h"
#include "lwip/inet.h"
#include "driver/gpio.h"


// Wi-Fi credentials
#define WIFI_SSID "FRITZ!Box 7590 VA" // Replace with your SSID
#define WIFI_PASSWORD "95184539975970760809" // Replace with your password

// MQTT Broker settings
#define MQTT_BROKER_URI "mqtt://192.168.178.118:1883"
#define MQTT_USERNAME "koti"
#define MQTT_PASSWORD "kot"

#define RELAY_GPIO GPIO_NUM_2  // Use GPIO2, or replace with your desired GPIO pin


// Event group and event bits
static EventGroupHandle_t wifi_event_group;
#define WIFI_CONNECTED_BIT BIT0

static const char *TAG = "MQTT_APP";
static esp_mqtt_client_handle_t mqtt_client;

// Event handler for Wi-Fi events
static void wifi_event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
        ESP_LOGI(TAG, "Trying to connect to Wi-Fi...");
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        ESP_LOGW(TAG, "Wi-Fi disconnected. Reconnecting...");
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;
        char ip_str[IP4ADDR_STRLEN_MAX];
        esp_ip4addr_ntoa(&event->ip_info.ip, ip_str, IP4ADDR_STRLEN_MAX);
        ESP_LOGI(TAG, "Connected successfully. IP Address: %s", ip_str);
        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

// MQTT event handler
// MQTT event handler
static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data) {
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;
    ESP_LOGI(TAG, "Handling MQTT event...");

    switch (event_id) {
        case MQTT_EVENT_CONNECTED:
            ESP_LOGI(TAG, "Connected to MQTT broker");
            // Subscribe to the command topic
            esp_mqtt_client_subscribe(mqtt_client, "home/esp32/relay/set", 0);
            ESP_LOGI(TAG, "Subscribed to topic: home/esp32/relay/set");
            break;

        case MQTT_EVENT_DATA:
            ESP_LOGI(TAG, "Received message on topic: %.*s", event->topic_len, event->topic);
            ESP_LOGI(TAG, "Message content: %.*s", event->data_len, event->data);

            // Handle command topic
            if (strncmp(event->topic, "home/esp32/relay/set", event->topic_len) == 0) {
                if (strncmp(event->data, "ON", event->data_len) == 0) {
                    ESP_LOGI(TAG, "Turning relay ON");
                    gpio_set_level(RELAY_GPIO, 1);
                    // Publish the new state
                    esp_mqtt_client_publish(mqtt_client, "home/esp32/relay/state", "ON", 0, 1, 1);
                } else if (strncmp(event->data, "OFF", event->data_len) == 0) {
                    ESP_LOGI(TAG, "Turning relay OFF");
                    gpio_set_level(RELAY_GPIO, 0);
                    // Publish the new state
                    esp_mqtt_client_publish(mqtt_client, "home/esp32/relay/state", "OFF", 0, 1, 1);
                } else {
                    ESP_LOGW(TAG, "Unknown command: %.*s", event->data_len, event->data);
                }
            }
            break;

        case MQTT_EVENT_ERROR:
            ESP_LOGE(TAG, "MQTT_EVENT_ERROR");
            ESP_LOGE(TAG, "Reconnecting to MQTT broker...");
            esp_mqtt_client_reconnect(mqtt_client);
            break;

        default:
            ESP_LOGI(TAG, "Unhandled MQTT event: %" PRIi32, event_id);
            break;
    }
    ESP_LOGI(TAG, "Finished handling MQTT event.");
}

// MQTT client initialization and start
void mqtt_app_start(void) {
    ESP_LOGI(TAG, "Initializing MQTT...");
    esp_mqtt_client_config_t mqtt_cfg = {
        .broker.address.uri = MQTT_BROKER_URI,
        .credentials = {
            .username = MQTT_USERNAME,
            .authentication.password = MQTT_PASSWORD,
        },
    };
    ESP_LOGI(TAG, "MQTT configuration set.");

    mqtt_client = esp_mqtt_client_init(&mqtt_cfg);
    if (mqtt_client == NULL) {
        ESP_LOGE(TAG, "Failed to initialize MQTT client");
        return;
    }
    ESP_LOGI(TAG, "MQTT client initialized.");

    esp_mqtt_client_register_event(mqtt_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    ESP_LOGI(TAG, "MQTT event handler registered.");

    esp_mqtt_client_start(mqtt_client);
    ESP_LOGI(TAG, "MQTT client started.");
}

// Wi-Fi initialization and connection
void init_wifi(void) {
    esp_netif_init();
    esp_event_loop_create_default();
    esp_netif_create_default_wifi_sta();

    wifi_event_group = xEventGroupCreate();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_wifi_init(&cfg);

    esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, NULL);
    esp_event_handler_instance_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, NULL);

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = WIFI_SSID,
            .password = WIFI_PASSWORD,
        },
    };
    esp_wifi_set_mode(WIFI_MODE_STA);
    esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_config);
    esp_wifi_start();

    ESP_LOGI(TAG, "Waiting for connection...");
    xEventGroupWaitBits(wifi_event_group, WIFI_CONNECTED_BIT, pdFALSE, pdTRUE, portMAX_DELAY);
}

// Main application entry point
void app_main(void) {
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    
    gpio_reset_pin(RELAY_GPIO);
    gpio_set_direction(RELAY_GPIO, GPIO_MODE_OUTPUT);
    gpio_set_level(RELAY_GPIO, 0);  // Set the initial state to OFF

    init_wifi();
    mqtt_app_start();

    while (1) {
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}
