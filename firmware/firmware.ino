#include <bluefruit.h>
#include <TinyUSB_Mouse_and_Keyboard.h>

BLEDfu bledfu;
BLEUart bleuart;

void setup() {

  pinMode(PIN_BUTTON1, INPUT_PULLUP);
  Keyboard.begin();
  
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

bool lastButtonState = false;
bool keyboardInputActive = true;

// Buffer for reading control characters.
// We expect packets to be three bytes long, with the third byte being a null terminator.
uint8_t packetBuffer[2];
uint16_t readIndex = 0;
// memset(packetBuffer, 0, 2);

void loop() {

  // Read the button and only act on button release transitions (LOW -> HIGH).
  // TODO: Consider debouncing the button (see https://www.arduino.cc/en/Tutorial/BuiltInExamples/Debounce).
  int buttonState = digitalRead(PIN_BUTTON1);
  if (lastButtonState != buttonState) {
    lastButtonState = buttonState;
    if (buttonState == HIGH) {  // Key release.
      keyboardInputActive = !keyboardInputActive;
      if (keyboardInputActive) {
        ledOn(PIN_LED1);
        ledOn(PIN_LED2);
      } else {
        ledOff(PIN_LED1);
        ledOff(PIN_LED2);
      }
    }
  }

  if (bleuart.available()) {

    // Read a character and echo it.
    char c =  bleuart.read();

    if (c == 0) {  // Reset the index if the packet is a null terminator and process the previous packet.
      
      // Inject the key if enabled.
      if (keyboardInputActive) {
        if (packetBuffer[0] == 1) {
          Keyboard.press(packetBuffer[1]);
        } else if (packetBuffer[0] == 2) {
          Keyboard.release(packetBuffer[1]);
        }
      }

      // Reset the index and clear the buffer for the next read.
      readIndex = 0;
      memset(packetBuffer, 0, 2);

    } else {  // Store the character and increment the index, wrapping if necessary.
      packetBuffer[readIndex] = c;
      readIndex = readIndex + 1;
      if (readIndex > 1) {
        readIndex = 0;
      }
    }

  }

  // TODO: Is this really necessary?
  // delay(10);
}
