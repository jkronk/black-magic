# BlackmagicControl

A macOS application for remotely controlling Blackmagic Design cameras over Bluetooth Low Energy (BLE). Built with Swift and AppKit, the app communicates using Blackmagic's Camera Control Unit (CCU) binary protocol over GATT characteristics — no external SDK framework required.

## Features

- **BLE Discovery & Pairing** — Scan for nearby Blackmagic cameras, connect, and pair via CoreBluetooth
- **White Balance & Tint** — Adjust color temperature (2500–10000K) and tint with presets, sliders, or steppers
- **Iris / Aperture** — Control lens aperture (requires electronically controllable lens)
- **Shutter** — Adjust shutter angle or shutter speed depending on camera mode
- **ISO / Gain** — Step through ISO or sensor gain values
- **Focus** — Nudge focus offset, trigger auto-focus, and control focus peaking (level + color)
- **Gamma Correction** — Per-channel (R/G/B) and luma gamma adjustment
- **Audio Gain** — Left and right channel input gain
- **Codec Selection** — Switch between BRAW (Q0/Q1/Q3/Q5, 3:1–12:1) and ProRes (HQ/422/LT/Proxy)
- **Recording & Transport** — Start/stop recording, play/pause, next/previous clip, timecode display
- **Slate Metadata** — Reel, scene, take, tags (scene type, location, day/night), good-take marker
- **OSD Toggle** — Show/hide on-screen display on the camera
- **Power Off** — Remotely power down the camera
- **Auto-Reconnection** — Automatically attempts to reconnect on unexpected disconnection

## Requirements

- macOS 11.1+
- Xcode 12+ (Swift 5)
- A Blackmagic Design camera with Bluetooth camera control (e.g., Pocket Cinema Camera 4K/6K)
- Bluetooth must be enabled on the Mac

The app is sandboxed and requests the `com.apple.security.device.bluetooth` entitlement.

## Project Structure

```
BlackmagicControl/
├── AppDelegate.swift                 # App entry point; owns the shared CameraControlInterface
├── API/
│   ├── CameraControlInterface.swift  # Central facade wiring BLE, CCU, and UI delegates
│   ├── CameraState.swift             # In-memory model of all camera parameters
│   ├── DelegateDefinitions.swift     # All delegate protocols (UI ↔ camera layer)
│   ├── ExpectedValues.swift          # Echo-suppression queue for in-flight commands
│   └── Versions.swift                # BLE protocol version compatibility check
├── Bluetooth/
│   ├── BMDCameraCharacteristics.swift  # GATT characteristic UUIDs
│   ├── BMDCameraServices.swift         # BLE service UUIDs
│   ├── ConnectionManager.swift         # CBCentralManager: scan, connect, reconnect
│   ├── DiscoveredPeripheral.swift      # Wrapper for CBPeripheral + display name
│   └── PairingFailureType.swift        # Pairing error classification
├── Camera/
│   ├── PacketReader.swift            # Routes incoming BLE bytes to CCU decoder
│   ├── PacketWriter.swift            # Builds CCU commands, validates, and sends
│   ├── PeripheralInterface.swift     # CBPeripheralDelegate: GATT discovery, bonding, I/O
│   ├── PowerControl.swift            # Camera power status flags and on/off payloads
│   ├── Timecode.swift                # Timecode holder
│   ├── TransportInfo.swift           # Transport mode, speed, active disks, flags
│   └── RecordTimeWarning.swift       # Low record-time warning levels
├── CCU/
│   ├── CCUPacketTypes.swift          # Protocol layout: categories, parameters, enums, Command struct
│   ├── CCUEncodingFunctions.swift    # Factory methods for outgoing CCU commands
│   ├── CCUDecodingFunctions.swift    # Parser for incoming CCU packets
│   ├── CCUValidationFunctions.swift  # Packet validation (size, category, parameter)
│   └── CCUExtensions.swift           # Debug logging and data-type helpers
├── Config/
│   ├── VideoConfig.swift             # WB presets, ISO table, shutter angles/speeds
│   ├── LensConfig.swift              # F-stop table, aperture numbers, focus offsets
│   └── ColorCorrectionConfig.swift   # Gamma slider bounds
├── Location/
│   └── LocationServices.swift        # CLLocationManager (iOS only, unused on macOS)
├── UI/
│   ├── BlackmagicSlider.swift        # Custom NSSlider with tentative/committed callbacks
│   ├── BlackmagicSliderCell.swift    # Custom NSSliderCell for drag tracking
│   └── Localizable.strings           # UI string resources
├── ViewControllers/
│   ├── BaseViewController.swift      # Root controller; swaps between Select and Content views
│   ├── SelectViewController.swift    # Camera discovery list; initiates connection
│   ├── ContentViewController.swift   # Wrapper with back-to-select navigation
│   └── MainViewController.swift      # Primary control surface (all sliders, buttons, labels)
└── Base.lproj/
    └── Main.storyboard               # Interface Builder layout
```

## Architecture

The app follows a **delegate-driven** architecture with a single central facade:

```
┌─────────────────────────────────────────────────────────┐
│                      AppDelegate                        │
│              owns CameraControlInterface                │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
  ┌───────────────┐        ┌────────────────┐
  │ View          │        │ CameraControl  │
  │ Controllers   │◄──────►│ Interface      │
  │               │delegate│ (facade)       │
  └───────────────┘ pairs  └──┬──────┬──────┘
                              │      │
                   ┌──────────┘      └──────────┐
                   ▼                             ▼
          ┌────────────────┐           ┌─────────────────┐
          │ PacketWriter   │           │ PacketReader     │
          │ (encode + send)│           │ (receive + decode│
          └───────┬────────┘           └────────┬────────┘
                  │                             │
                  │    ┌─────────────────┐      │
                  └───►│ Peripheral      │◄─────┘
                       │ Interface       │
                       │ (GATT I/O)      │
                       └───────┬─────────┘
                               │ BLE
                       ┌───────┴─────────┐
                       │ Connection      │
                       │ Manager         │
                       │ (CBCentralMgr)  │
                       └───────┬─────────┘
                               │
                        ┌──────┴──────┐
                        │  Blackmagic │
                        │   Camera    │
                        └─────────────┘
```

**`CameraControlInterface`** is the heart of the app. It implements nearly every delegate protocol, acting as the single point of coordination between the UI layer and the Bluetooth/CCU transport layer. It also maintains `CameraState`, which holds the authoritative copy of every camera parameter.

## Data Flow

### Outgoing: UI Control → Camera

When the user manipulates a control (e.g., drags the white balance slider), the command travels through five layers before reaching the camera:

```
 ┌─────────────────────────────────────────────────────────────┐
 │  1. MainViewController                                      │
 │     User drags WB slider → onWhiteBalanceSliderSet() fires  │
 │     Calls delegate: onWhiteBalanceChanged(newValue)         │
 └──────────────────────────┬──────────────────────────────────┘
                            │  OutgoingCameraControlFromUIDelegate
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  2. CameraControlInterface                                  │
 │     a. Registers expected values (echo suppression)         │
 │     b. Calls PacketWriter.writeWhiteBalance(wb, tint)       │
 └──────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  3. PacketWriter                                            │
 │     a. CCUEncodingFunctions builds a CCU Command struct     │
 │     b. CCUValidationFunctions validates the packet          │
 │     c. Serializes to Data, fires onCCUPacketEncoded(data)   │
 └──────────────────────────┬──────────────────────────────────┘
                            │  PacketEncodedDelegate
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  4. CameraControlInterface (as PacketEncodedDelegate)       │
 │     Routes to PeripheralInterface.sendPacket(data,          │
 │       service: kMainService, char: kOutgoingCCU)            │
 └──────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  5. PeripheralInterface                                     │
 │     CBPeripheral.writeValue(data, for: characteristic,      │
 │       type: .withResponse)                                  │
 │     → Bytes sent over BLE GATT to the camera                │
 └─────────────────────────────────────────────────────────────┘
```

**Concrete example — changing white balance to 5600K:**

1. **MainViewController** slider callback fires with value `5600`
2. **CameraControlInterface.onWhiteBalanceChanged(5600)** queues `5600` in `expectedWhiteBalance` and the current tint in `expectedTint`, then calls `PacketWriter.writeWhiteBalance(5600, currentTint)`
3. **PacketWriter** calls `CCUEncodingFunctions.CreateVideoWhiteBalanceCommand(5600, tint)` which builds a `CCUPacketTypes.Command` with category `Video`, parameter `WhiteBalance`, and the values serialized as fixed-point integers. The packet is validated by `CCUValidationFunctions` and serialized to `Data`.
4. **CameraControlInterface.onCCUPacketEncoded(data)** passes the bytes to `PeripheralInterface.sendPacket()` targeting the outgoing CCU characteristic
5. **PeripheralInterface** writes the bytes to the BLE GATT characteristic with `CBCharacteristicWriteType.withResponse`

### Incoming: Camera → UI

When the camera's state changes (either from our command or from on-body controls), it notifies us via BLE characteristic updates:

```
 ┌─────────────────────────────────────────────────────────────┐
 │  1. PeripheralInterface (CBPeripheralDelegate)              │
 │     didUpdateValueFor characteristic fires                  │
 │     Routes by UUID → onCCUPacketReceived(data)              │
 └──────────────────────────┬──────────────────────────────────┘
                            │  PacketReceivedDelegate
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  2. CameraControlInterface (as PacketReceivedDelegate)      │
 │     Passes raw data to PacketReader.readCCUPacket(data)     │
 └──────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  3. PacketReader                                            │
 │     a. CCUValidationFunctions validates the packet          │
 │     b. CCUDecodingFunctions parses category + parameter     │
 │     c. Fires typed callback, e.g. onWhiteBalanceReceived()  │
 └──────────────────────────┬──────────────────────────────────┘
                            │  PacketDecodedDelegate
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  4. CameraControlInterface (as PacketDecodedDelegate)       │
 │     a. Updates CameraState with new value                   │
 │     b. Checks ExpectedValues — was this our own echo?       │
 │        • If YES (expected): suppresses UI update            │
 │        • If NO (external change): forwards to UI delegate   │
 └──────────────────────────┬──────────────────────────────────┘
                            │  IncomingCameraControlToUIDelegate
                            ▼
 ┌─────────────────────────────────────────────────────────────┐
 │  5. MainViewController                                      │
 │     Updates slider position, label text, preset highlights  │
 └─────────────────────────────────────────────────────────────┘
```

### Echo Suppression (ExpectedValues)

A critical subtlety: when you send a command, the camera echoes the new value back. Without mitigation, this echo would fight the UI — the slider would jitter between the user's intent and stale values arriving out of order.

`ExpectedValues<T>` solves this:

1. **On send**: the outgoing value is pushed onto a FIFO queue (`addExpectedValue`)
2. **On receive**: `removeUpToExpectedValue` checks if the incoming value matches any queued expected value (within an error tolerance). If it matches, the queue drains up to that point and the UI update is **suppressed** (it's just our own echo).
3. **Timeout**: if the expected value isn't received within 500ms, the queue is cleared and the callback restores the UI to the camera's authoritative state.

This ensures smooth slider behavior while still allowing external changes (e.g., someone adjusting the camera body) to update the UI.

## BLE Protocol Details

The app communicates over two BLE services:

| Service | Purpose |
|---------|---------|
| Main Service (`291D567A-...`) | Camera control: CCU in/out, timecode, camera status, device name, protocol version |
| Camera Information Service | Camera model string |

Key GATT characteristics:

| Characteristic | Direction | Content |
|----------------|-----------|---------|
| Outgoing CCU | App → Camera | Serialized CCU commands |
| Incoming CCU | Camera → App | Camera state updates (CCU packets) |
| Camera Status | Bidirectional | Power state flags; also used to initiate bonding |
| Timecode | Camera → App | Running timecode |
| Protocol Version | Camera → App | Version string for compatibility check |
| Device Name | App → Camera | Controller's name sent during bonding |
| Camera Model | Camera → App | Camera model string |

All CCU packets follow the Blackmagic CCU binary format, organized by **category** (Lens, Video, Audio, Output, Display, Tally, Reference, Configuration, Metadata) and **parameter** within each category.
