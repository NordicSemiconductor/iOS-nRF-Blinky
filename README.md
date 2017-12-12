# nRF BLINKY

nRF Blinky is an example app targeted towards newcomer BLE developers.
This application will demonstrate how to control a LED on an nRF development kit and receive notifications when the button on the kit is pressed and released.

## Nordic LED and Button Service
###### Service UUID: `00001523-1212-EFDE-1523-785FEABCD123`
A simplified proprietary service by Nordic Semiconductor, containing two characteristics one to control LED3 and Button1:
- First characteristic controls the LED state (On/Off).
  - UUID: **`00001525-1212-EFDE-1523-785FEABCD123`**
  - Value: **`1`** => LED On
  - Value: **`0`** => LED Off
- Second characteristic notifies central of the button state on change (Pressed/Released).
  - UUID: **`00001524-1212-EFDE-1523-785FEABCD123`**
  - Value: **`1`** => Button Pressed
  - Value: **`0`** => Button Released

### Requirements:
- An iOS device with BLE capabilities
- A [nRF52](https://www.nordicsemi.com/eng/Products/Bluetooth-low-energy/nRF52-DK) or [nRF51](https://www.nordicsemi.com/eng/Products/nRF51-DK) Dev Kit
- The Blinky example firmware to flash on the Development Kit, there are a few places to acquire that:
- For your conveninence, we have bundled two firmwares in this project under the Firmwares directory.
- To get the latest firmwares and check the source code, you may go directly to our [Developers website](http://developer.nordicsemi.com/nRF5_SDK/) and download the SDK version you need, then you can find the source code and hex files to the blinky demo in the directory `/examples/ble_peripheral/ble_app_blinky/`

### Installation and usage:
- Prepare your Development kit.
  - Plug in the Development Kit to your computer via USB.
  - Power On the Development Kit.
  - The Development Kit will now appear as a Mass storage device.
  - Drag (or copy/paste) the appropriate HEX file onto that new device.
  - The Development Kit lEDS will flash and it will disconnect and reconnect.
  - The Development Kit is now ready and flashed with the nRFBlinky example firmware.

- Start Xcode and run build the project against your target iOS Device (**Note:** BLE is not available in the iOS simulator, so the iOS device is a requirement to test the application).
  - Launch the nRFBlinky app on your iOS device.
  - The app will start scanning for nearby peripherals.
  - Select the nRF_Blinky peripheral that appears on screen (**Note:** if the peripheral does not show up, ensure that it's powered on and functional).
  - Your iOS device will now connect to the peripheral and state is displayed on the screen.
  - Changing the value of the Toggle switch will turn LED 3 on or off.
  - Pressing Button 1 on the Development Kit will show the button state as Pressed on the app.
  - Releasing Button 1 will show the state as Released on the App.
