#include <ESP8266WiFi.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>
#include <cmath>



// WiFi

const char* ssid = "TP-Link_0C4C";
const char* password = "77476913";

// Google Cloud Function URL
const char* googleCloudFunctionURL = "http://europe-west2-heliosrise2.cloudfunctions.net/function-3";


Adafruit_MPU6050 mpu;


WiFiClient client;


float dataBuffer[180][6];
int dataCount = 0; 
int prediction=0;


void setup() {
  Serial.begin(115200);
  while (!Serial); 

  pinMode(3, OUTPUT); 
  

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("Connected to WiFi");

  if (!mpu.begin()) {
    Serial.println("Failed to find MPU6050 chip");
    while (1) {
      delay(10);
    }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
  Serial.println("MPU6050 initialized");

  updateFlagFromCloud();

  

  
}

void loop() {
  
  sensors_event_t a, g, temp;


  if (!isEmpty) {
    for (int i = 1; i < 180; i++) { 
      for (int j = 0; j < 6; j++) { 
        dataBuffer[i - 1][j] = dataBuffer[i][j];
      }
    }


    if (dataCount > 0) {
      dataCount--;
    }
  }


  for (int i = 0; i < 25; i++) {
    mpu.getEvent(&a, &g, &temp);
    
    int index;
    if (isEmpty) {

      index = dataCount;
    } else {

      index = 179; 
    }


    dataBuffer[index][0] = a.acceleration.x;
    dataBuffer[index][1] = a.acceleration.y;
    dataBuffer[index][2] = a.acceleration.z;
    dataBuffer[index][3] = g.gyro.x;
    dataBuffer[index][4] = g.gyro.y;
    dataBuffer[index][5] = g.gyro.z;

    dataCount++;
    if (dataCount >= 180) {
      isEmpty = false;
      dataCount = 180; 
    }

    //delay(5);
  }


  unsigned long currentTime = millis();
  if (!isEmpty && currentTime - lastSendTime >= interval) { 
    sendDataToGoogleCloudFunction();

    lastSendTime = currentTime; 
  }



}
  

void sendDataToGoogleCloudFunction() {

    String data = "{\"instances\":[["; 

    for (int i = 0; i < 180; i++) {
        if (i > 0) data += ","; 
        data += "[" + String(dataBuffer[i][0]) + "," + String(dataBuffer[i][1]) + "," +
                String(dataBuffer[i][2]) + "," + String(dataBuffer[i][3]) + "," +
                String(dataBuffer[i][4]) + "," + String(dataBuffer[i][5]) + "]";
    }

    data += "]]}";
    Serial.println(data);

    // 发送HTTP POST请求
    if (WiFi.status() == WL_CONNECTED) {
        HTTPClient http;
        http.begin(client, googleCloudFunctionURL);
        http.addHeader("Content-Type", "application/json");
        int httpResponseCode = http.POST(data);
        if (httpResponseCode > 0) {
            String response = http.getString();
            Serial.println("HTTP Response code: " + String(httpResponseCode));
            Serial.println("Response: " + response);


        } else {
            Serial.println("Error on sending POST: " + String(httpResponseCode));
        }
        http.end();
    } else {
        Serial.println("WiFi Disconnected");
    }
}