import processing.serial.*;
import cc.arduino.*;

Arduino arduino;

int ledPin = 13;
int lightSensorPin = 0;
int temperatuerSensorPin = 1;
int time;
int startup;
boolean isOn = false;

float temperature = 0;
float light = 0;
boolean drawWarning = false;
boolean beSilent = false;
boolean clicked = false;

enum State {
  STARTUP,
  IDLE,
  WARNING,
  WARNING_SILENT,
  CALLING,
}


State state = State.STARTUP;

void setup() {
  size(800, 480);
  background(245);
  
  arduino = new Arduino(this, "COM5", 57600);
  
  time = millis();
  
  arduino.pinMode(6, Arduino.SERVO);
  
  arduino.servoWrite(6, (i % 2 == 0) ? 5 : 30);
  
  startup = millis() + 2000;
}

void draw() {
  background(245);
  
  processArduino();
  
  switch (state) {
    case STARTUP:
    if (millis() >= startup)
      state = State.IDLE;
    break;
    
    case IDLE:
    if (drawWarning) {
      enableAlarm();
      
      state = State.WARNING;
    }
    
    textAlign(LEFT);
    
    // Draw temperature
    fill(0);
    textSize(40);
    text("Temperatur: " + Float.toString(temperature).substring(0, 4) + "°C", 20, 60);    
    
    // Draw Light intensity
    fill(0);
    textSize(40);
    text("Licht Intensiteat: " + Float.toString(light * 10).substring(0, 4) + "%", 20, 120);    
    break;
    
    case WARNING:
    if (!drawWarning) {
      beSilent = false;
  
      disableAlarm();
      
      state = State.IDLE;
      
    } else if (clicked && mouseX >= 300 && mouseX <= 500 && mouseY >= 345 && mouseY <= 425) {
      disableAlarm();
      
      state = State.WARNING_SILENT;
    }
    
    // Draw red modal
    fill(255, 0, 0);
    rect(50, 30, 700, 420, 10, 10, 10, 10);
    
    // Draw silent button
    stroke(255);
    strokeWeight(4);
    rect(100, 345, 600, 80, 10, 10, 10, 10);
    
    // Draw text in silent button
    fill(255);
    textSize(40);
    textAlign(CENTER);
    text("Alarm ausschalten", 400, 400);
    
    text("Defekt!", 400, 100);
    
    textSize(30);
    text("Ihre Steuerung muss von einem", 400, 180);
    text("Techniker repariert werden!", 400, 230);
    break;
    
    case WARNING_SILENT:
    if (!drawWarning) {
      beSilent = false;
  
      disableAlarm();
      
      state = State.IDLE;
    } else if (clicked && mouseX >= 300 && mouseX <= 500 && mouseY >= 345 && mouseY <= 425)
      state = State.CALLING;
    
    // Draw red modal
    fill(255, 0, 0);
    rect(50, 30, 700, 420, 10, 10, 10, 10);
    
    // Draw silent button
    stroke(255);
    strokeWeight(4);
    rect(100, 345, 600, 80, 10, 10, 10, 10);
    
    // Draw text in silent button
    fill(255);
    textSize(40);
    textAlign(CENTER);
    text("Techniker rufen", 400, 400);
    
    text("Defekt!", 400, 100);
    
    textSize(30);
    text("Reperatur Nr.:", 400, 180);
    text("1589 2561 1548", 400, 230);
    break;
    
    case CALLING:
    if (!drawWarning) {
      beSilent = false;
      
      state = State.IDLE;
    }
    
    // Draw red modal
    fill(255, 0, 0);
    rect(50, 30, 700, 420, 10, 10, 10, 10);
    
    // Draw text in silent button
    fill(255);
    textSize(40);
    textAlign(CENTER);
    text("Rufaufbau...", 400, 400);
    
    text("Defekt!", 400, 100);
    
    textSize(30);
    text("Reperatur Nr.:", 400, 180);
    text("1589 2561 1548", 400, 230);
    break;
  }
  
  clicked = false;
}

void mouseClicked() {
  clicked = true;
  
  draw();
}

void processArduino() {
  process();
  checkHardware();
}

void checkHardware() {
  float light = measureLightIntensity();
  
  if (light >= 4.9 || light <= 0.1) {
    drawWarning = true;
  } else {
    drawWarning = false;
  }
}

void process() {
  if (millis() >= time) {
    if (isOn) {
      arduino.digitalWrite(ledPin, Arduino.LOW);
      
      time = millis() + 950;
    } else {
      arduino.digitalWrite(ledPin, Arduino.HIGH);
     
      time = millis() + 50;
      
      temperature = measureTemperature();
      light = measureLightIntensity();
    }
    
    isOn = !isOn;
  }
}

void enableAlarm() {
  arduino.analogWrite(10, 150);
}

void disableAlarm() {
  arduino.analogWrite(10, 0);
}

float measureLightIntensity() {
  return measureVoltage(lightSensorPin);
}

float measureTemperature() {
  return (measureVoltage(temperatuerSensorPin) - 0.5) * 100.0;
}

//Function to read and return
float measureVoltage(int pin) {
  return arduino.analogRead(pin) * 0.004882814; 
}