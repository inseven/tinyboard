// Copyright (c) 2022-2023 Jason Morley
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <bluefruit.h>
#include <TinyUSB_Mouse_and_Keyboard.h>

BLEDfu bledfu;
BLEUart bleuart;

#define MESSAGE_TYPE_PRESS 1
#define MESSAGE_TYPE_RELEASE 2
#define MESSAGE_TYPE_DISABLE 3
#define MESSAGE_TYPE_ENABLE 4
#define MESSAGE_TYPE_MOUSE_MOVE 5
#define MESSAGE_TYPE_MOUSE_PRESS 6
#define MESSAGE_TYPE_MOUSE_RELEASE 7
#define MESSAGE_TYPE_MOUSE_SCROLL 8

int messageLength(uint8_t messageType) {

  switch (messageType) {
  case MESSAGE_TYPE_PRESS:
    return 1;
  case MESSAGE_TYPE_RELEASE:
    return 1;
  case MESSAGE_TYPE_DISABLE:
    return 0;
  case MESSAGE_TYPE_ENABLE:
    return 0;
  case MESSAGE_TYPE_MOUSE_MOVE:
    return 2;
  case MESSAGE_TYPE_MOUSE_PRESS:
    return 1;
  case MESSAGE_TYPE_MOUSE_RELEASE:
    return 1;
  case MESSAGE_TYPE_MOUSE_SCROLL:
    return 1;
  }
  return 0;
}

void setup() {

  pinMode(PIN_BUTTON1, INPUT_PULLUP);
  Keyboard.begin();
  Mouse.begin();
  
  Bluefruit.begin();
  Bluefruit.setTxPower(4);    // Check bluefruit.h for supported values
  bledfu.begin();  // To be consistent OTA DFU should be added first if it exists
  bleuart.begin();  // Configure and start the BLE Uart service
  startAdv();  // Set up and start advertising
};

void startAdv(void) {

  // Advertising packet
  Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.addTxPower();
  
  // Include the BLE UART (AKA 'NUS') 128-bit UUID
  Bluefruit.Advertising.addService(bleuart);

  // Secondary Scan Response packet (optional)
  // Since there is no room for 'Name' in Advertising packet
  Bluefruit.ScanResponse.addName();

  /* Start Advertising
   * - Enable auto advertising if disconnected
   * - Interval:  fast mode = 20 ms, slow mode = 152.5 ms
   * - Timeout for fast mode is 30 seconds
   * - Start(timeout) with timeout = 0 will advertise forever (until connected)
   * 
   * For recommended advertising interval
   * https://developer.apple.com/library/content/qa/qa1931/_index.html   
   */
  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 244);    // in unit of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  Bluefruit.Advertising.start(0);                // 0 = Don't stop advertising after n seconds  
}

bool lastButtonState = HIGH;

bool keyboardInputActive = true;

void enableKeyboardInput() {
  write(&bleuart, "enable input");
  keyboardInputActive = true;
  ledOn(PIN_LED1);
  ledOn(PIN_LED2);
}

void disableKeyboardInput() {
  write(&bleuart, "disable input");
  keyboardInputActive = false;
  ledOff(PIN_LED1);
  ledOff(PIN_LED2);
}

char writeBuffer[255] = { 0 };

void write(BLEUart *bleUart, const char *string, ...) {
  va_list args;
  memset(writeBuffer, 0, 255);
  va_start(args, string);
  vsprintf(writeBuffer, string, args);
  va_end(args);
  bleUart->write(writeBuffer, strlen(writeBuffer));
}

// Buffer for reading control characters.
// Currently no messages are longer than 3 bytes.
uint8_t packetBuffer[3];

void loop () {

  // Read the button and only act on button release transitions (LOW -> HIGH).
  // TODO: Consider debouncing the button (see https://www.arduino.cc/en/Tutorial/BuiltInExamples/Debounce).
  int buttonState = digitalRead(PIN_BUTTON1);
  if (lastButtonState != buttonState) {
    lastButtonState = buttonState;
    if (buttonState == HIGH) {  // Key release.
      keyboardInputActive = !keyboardInputActive;
      if (keyboardInputActive) {
        enableKeyboardInput();
      } else {
        disableKeyboardInput();
      }
    }
  }

  while (bleuart.available()) {

    // Read the message type.
    packetBuffer[0] = bleuart.read();

    // Read the remainder of the message.
    int length = messageLength(packetBuffer[0]);
    for (int i = 1; i <= length; i++) {
      packetBuffer[i] = bleuart.read();      
    }

    int deltaX;
    int deltaY;

    switch (packetBuffer[0]) {
      case MESSAGE_TYPE_PRESS:
        if (keyboardInputActive) {        
          Keyboard.press(packetBuffer[1]);
        } else {
          write(&bleuart, "press '%c'", packetBuffer[1]);
        }
        break;
      case MESSAGE_TYPE_RELEASE:
        if (keyboardInputActive) {
          Keyboard.release(packetBuffer[1]);
        } else {
          write(&bleuart, "press '%c'", packetBuffer[1]);
        }
        break;
      case MESSAGE_TYPE_DISABLE:
        write(&bleuart, "Disable input");
        disableKeyboardInput();
        break;
      case MESSAGE_TYPE_ENABLE:
        write(&bleuart, "Enable input");
        enableKeyboardInput();
        break;
      case MESSAGE_TYPE_MOUSE_MOVE:
        deltaX = packetBuffer[1];
        deltaY = packetBuffer[2];
        if (keyboardInputActive) {
          Mouse.move(deltaX, deltaY);
        } else {
          write(&bleuart, "mouse move (%d, %d)", deltaX, deltaY);
        }
        break;
      case MESSAGE_TYPE_MOUSE_PRESS:
        if (keyboardInputActive) {
          Mouse.press(packetBuffer[1]);
        } else {
          write(&bleuart, "mouse press");
        }
        break;
      case MESSAGE_TYPE_MOUSE_RELEASE:
        if (keyboardInputActive) {
          Mouse.release(packetBuffer[1]);
        } else {
          write(&bleuart, "mouse release");
        }
        break;
      case MESSAGE_TYPE_MOUSE_SCROLL:
        deltaY = packetBuffer[1];
        if (keyboardInputActive) {
          Mouse.move(0, 0, deltaY);
        } else {
          write(&bleuart, "mouse scroll (%d)", deltaY);
        }
    }
    
  }
  
}
