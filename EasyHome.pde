import processing.serial.*;
import cc.arduino.*;
import interfascia.*;

GUIController c, w;
IFButton b1, b2;
IFLabel l;

Arduino arduino;

int ledPin = 13;
int lightSensorPin = 0;
int temperatuerSensorPin = 1;
int time;
boolean isOn = false;

float temperature = Float.NaN;
boolean drawWarning = false;
boolean beSilent = false;

enum State {
  IDLE,
  WARNING,
  WARNING_SILENT,
}

State state = State.IDLE;

void setup() {
  arduino = new Arduino(this, "COM5", 57600);
  
  time = millis();
  
  size(800, 480);
  
  c = new GUIController(this);
  w = new GUIController(this);
  
  b1 = new IFButton("Leise", 280, 380, 160, 50);
  b2 = new IFButton("Blue", 120, 40, 40, 17);

  b1.addActionListener(this);
  b2.addActionListener(this);

  w.add(b1);
  c.add(b2);
}

void draw() {
  processArduino();
  
  switch (state) {
    case IDLE:
    if (drawWarning) {
      c.setVisible(false);
      
      background(155);
      
      fill(255, 0, 0);
      rect(50, 30, 700, 420);
      
      enableAlarm();
      
      state = State.WARNING;
    }
    break;
    case WARNING:
    if (!drawWarning) {
      c.setVisible(true);
      
      beSilent = false;
      disableAlarm();
      
      state = State.IDLE;
      
    } else if (beSilent) {
      disableAlarm();
      
      state = State.WARNING_SILENT;
    }
    break;
    case WARNING_SILENT:
    if (!drawWarning) {
      c.setVisible(true);
      
      beSilent = false;
      
      state = State.IDLE;
    }
    break;
  }
}

void processArduino() {
  processStatusLed();
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

void processStatusLed() {
  if (millis() >= time) {
    if (isOn) {
      arduino.digitalWrite(ledPin, Arduino.LOW);
      
      time = millis() + 950;
    } else {
      arduino.digitalWrite(ledPin, Arduino.HIGH);
     
      time = millis() + 50;
    }
    
    isOn = !isOn;
  }
}

void actionPerformed(GUIEvent e) {
  if (e.getSource() == b1) {
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