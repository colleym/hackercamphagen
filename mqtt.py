import random
import time

from paho.mqtt import client as mqtt_client

####################################################
MAC_ADDRESS="94:B9:7E:E9:12:08" # repace with your co2ampel Wifi MAC-Address

MQTT_BROKER="mqtt.eclipseprojects.io"
MQTT_PORT=1883
MQTT_CLIENTID="co2ampel-py-" + str(random.randint(100,200))

MQTT_PUB_TEMP="esp32/ccs811/temp/" 
MQTT_PUB_CO="esp32/ccs811/co2/"
MQTT_PUB_TVOC="esp32/ccs811/tvoc/"
MQTT_PUB_LED="esp32/ccs811/led/"
#####################################################

broker = MQTT_BROKER
port = MQTT_PORT
topic = MQTT_PUB_TEMP + MAC_ADDRESS
# generate client ID with pub prefix randomly
client_id = MQTT_CLIENTID
# username = 'emqx'
# password = 'public'

def connect_mqtt():
    print ("Connecton as client: " + client_id)
    print ("Subcribe to topic: " + topic)
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("Connected to MQTT Broker!")
        else:
            print("Failed to connect, return code %d\n", rc)

    client = mqtt_client.Client(client_id)
    #client.username_pw_set(username, password)
    client.on_connect = on_connect
    client.connect(broker, port)
    return client


def subscribe(client: mqtt_client):
    def on_message(client, userdata, msg):
        print(f"Received `{msg.payload.decode()}` from `{msg.topic}` topic")

    client.subscribe(topic)
    client.on_message = on_message


def run():
    client = connect_mqtt()
    subscribe(client)
    client.loop_forever()


if __name__ == '__main__':
    run()