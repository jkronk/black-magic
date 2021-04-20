import Foundation
import CoreBluetooth

public class CameraControlInterface:
    ConnectionManagerDelegate,
    InitialConnectionFromUIDelegate,
    PacketReceivedDelegate,
    PacketDecodedDelegate,
    PacketEncodedDelegate,
    OutgoingSlateFromUIDelegate,
    OutgoingCameraControlFromUIDelegate,
    OutgoingRecordControlFromUIDelegate,
    OutgoingPowerFromUIDelegate,
    LocationServicesDelegate {
    
    
    let m_connectionManager: ConnectionManager
    var m_peripheralInterface: PeripheralInterface?
    let m_packetReader: PacketReader
    let m_packetWriter: PacketWriter
    var m_cameraState: CameraState
    
    #if os(iOS)
        let m_locationServices: LocationServices
    #endif

    var m_diskTimer: Timer?
    private var m_isSuspended: Bool = false
    let kDiskInfoDelay: Double = 0.2
	
	var m_shutterValueIsAngle: Bool = true
	var m_sensorGainIsISO: Bool = true

    struct ConnectionStatusFlags {
        static let kNone: UInt8 = 0x00
        static let kPower: UInt8 = 0x01
        static let kConnected: UInt8 = 0x02
        static let kPaired: UInt8 = 0x04
        static let kVersionsVerified: UInt8 = 0x08
        static let kInitialPayloadReceived: UInt8 = 0x10
        static let kCameraReady: UInt8 = 0x20
    }

    var m_connectionStatus: UInt8 = 0

    public weak var m_initialConnectionToUIDelegate: InitialConnectionToUIDelegate?
    public weak var m_cameraControlToUIDelegate: IncomingCameraControlToUIDelegate?
    public weak var m_slateToUIDelegate: IncomingSlateToUIDelegate?
    public weak var m_recordControlToUIDelegate: IncomingRecordControlToUIDelegate?
    public weak var m_connectionStatusDelegate: ConnectionStatusToUIDelegate?
    public weak var m_cameraNameDelegate: CameraNameDelegate?

    public init() {
        m_connectionManager = ConnectionManager()
        m_packetReader = PacketReader()
        m_packetWriter = PacketWriter()
        m_cameraState = CameraState()
		
		// Remove macro to enable location services on MacOS
		#if os(iOS)
			m_locationServices = LocationServices()
			m_locationServices.m_delegate = self
			m_locationServices.updateLocation()
		#endif

        m_connectionManager.m_connectionManagerDelegate = self
        m_packetReader.m_packetDecodedDelegate = self
        m_packetWriter.m_packetEncodedDelegate = self
	
        m_cameraState.expectedFStopIndex.m_expectedValueNotReceivedCallback = {
            [weak self]() -> Void in
            if let cameraControl = self {
                let fStopIndex: Int = cameraControl.m_cameraState.fStopIndex
                cameraControl.m_cameraControlToUIDelegate?.onIrisReceived(fStopIndex)
            }
        }

        m_cameraState.expectedOffSpeedFrameRate.m_expectedValueNotReceivedCallback = {
            [weak self]() -> Void in
            if let cameraControl = self {
                let offSpeedEnabled: Bool = cameraControl.m_cameraState.recordingFormatData.offSpeedEnabled
                let offSpeedFrameRate: Int16 = cameraControl.m_cameraState.recordingFormatData.offSpeedFrameRate
                cameraControl.m_cameraControlToUIDelegate?.onOffSpeedFrameRateReceived(offSpeedEnabled, offSpeedFrameRate)
            }
        }
    }
    
    public func setSuspended(_ suspended: Bool) {
        m_isSuspended = suspended
    }
    
    public func updateAllUI() {
        onControlViewLoaded()
        onSlateViewLoaded()
        onTransportViewLoaded()
    }

    public func onControlViewLoaded() {
        m_cameraControlToUIDelegate?.onTransportModeReceived(m_cameraState.transportInfo.transportMode)
        let whiteBalancePresetIndex = VideoConfig.GetWhiteBalancePresetFromValues(m_cameraState.whiteBalance, m_cameraState.tint)
        m_cameraControlToUIDelegate?.onWhiteBalanceReceived(m_cameraState.whiteBalance, m_cameraState.tint, whiteBalancePresetIndex)
		if (m_shutterValueIsAngle) {
			m_cameraControlToUIDelegate?.onShutterAngleReceived(m_cameraState.shutterAngle)
		} else {
			m_cameraControlToUIDelegate?.onShutterSpeedReceived(m_cameraState.shutterSpeed)
		}
        m_cameraControlToUIDelegate?.onOffSpeedFrameRateReceived(m_cameraState.recordingFormatData.offSpeedEnabled, m_cameraState.recordingFormatData.offSpeedFrameRate)
        m_cameraControlToUIDelegate?.onIrisReceived(m_cameraState.fStopIndex)
		updateIrisAndShutterControl()
		
		if (m_sensorGainIsISO) {
			if let isoIndex: Int = VideoConfig.kISOValues.index(of: m_cameraState.ISO) {
				m_cameraControlToUIDelegate?.onISOReceived(isoIndex)
			}
		} else {
			if let gainIndex: Int = VideoConfig.kGainValues.index(of: m_cameraState.gain) {
				m_cameraControlToUIDelegate?.onGainReceived(gainIndex)
			}
		}
    }

    public func onSlateViewLoaded() {
        m_slateToUIDelegate?.onReelReceived(Int16(m_cameraState.reel))
        m_slateToUIDelegate?.onSceneTagsReceived(Int(m_cameraState.sceneTag.rawValue), Int(m_cameraState.locationTag.rawValue), Int(m_cameraState.timeTag.rawValue))
        m_slateToUIDelegate?.onSceneReceived(m_cameraState.scene)
        m_slateToUIDelegate?.onTakeReceived(Int8(m_cameraState.takeNumber), Int(m_cameraState.takeTag.rawValue))
        m_slateToUIDelegate?.onSlateForNameReceived(m_cameraState.slateName)
        m_slateToUIDelegate?.onGoodTakeReceived(m_cameraState.goodTake)
        m_slateToUIDelegate?.setSlateForNextClip(m_cameraState.slateType == CCUPacketTypes.MetadataSlateForType.NextClip)
    }

    public func onTransportViewLoaded() {
        m_recordControlToUIDelegate?.onRecordTimeRemainingReceived(m_cameraState.remainingTimeStrings)
        m_recordControlToUIDelegate?.setRecordingError(m_cameraState.hasRecordingError)
        m_recordControlToUIDelegate?.onActiveDisksReceived(m_cameraState.transportInfo.disk1Active, m_cameraState.transportInfo.disk2Active)
        m_recordControlToUIDelegate?.onTimelapseReceived(m_cameraState.transportInfo.timelapseRecording)
        m_recordControlToUIDelegate?.onTimecodeReceived(m_cameraState.timecode)
        let transportMode = m_cameraState.transportInfo.transportMode
        let playbackSpeed = m_cameraState.transportInfo.speed
        m_recordControlToUIDelegate?.setRecording(transportMode == CCUPacketTypes.MediaTransportMode.Record)
        
        if transportMode == CCUPacketTypes.MediaTransportMode.Play {
            m_recordControlToUIDelegate?.showPlaybackView(for: m_cameraState.slateName, at: Int(playbackSpeed))
        } else {
            m_recordControlToUIDelegate?.hidePlaybackView()
        }
    }

    public func getCameraName() -> String {
        return m_peripheralInterface?.getPeripheral()?.name ?? "Blackmagic Design Camera"
    }

    // InitialConnectionFromUIDelegate methods
    public func attemptConnection(to identifier: UUID) {
        m_connectionManager.attemptConnection(to: identifier)
    }

    public func disconnect() {
        let peripheral: CBPeripheral? = m_peripheralInterface?.getPeripheral()
        if peripheral != nil {
            m_connectionManager.disconnect(from: peripheral!)
            m_peripheralInterface = nil
            m_cameraState.hasRecordingError = false
            m_connectionStatus = ConnectionStatusFlags.kNone
        }
    }

    public func refreshScan() {
        m_connectionManager.refreshScan()
    }

    // ConnectionManagerDelegate methods
    public func updateDiscoveredPeripheralList(_ peripheralList: [DiscoveredPeripheral]) {
        m_initialConnectionToUIDelegate?.updateDiscoveredPeripheralList(peripheralList)
    }

    public func connectedToPeripheral(_ peripheral: CBPeripheral) {
        m_peripheralInterface = PeripheralInterface(peripheral: peripheral)
        m_peripheralInterface?.m_packetReceivedDelegate = self
        m_connectionStatus |= ConnectionStatusFlags.kConnected

        if let peripheralName = peripheral.name {
            Logger.Log("Connected to \(String(describing: peripheralName))")
        }
    }
    
    public func isConnected() -> Bool {
        return m_connectionStatus & ConnectionStatusFlags.kConnected != 0
    }

    public func onConnectionLost() {
        m_connectionStatusDelegate?.onConnectionLost()
        m_connectionStatus = ConnectionStatusFlags.kNone
    }

    public func onDisconnected(with error: Error?) {
        if let peripheralInterface = m_peripheralInterface, let error = error {
            let isPaired = peripheralInterface.isPaired()
            if !isPaired {
                let nsError = error as NSError
                let errorType: ConnectionManager.ErrorType = (domain: nsError.domain, code: nsError.code)
                let clearDeviceError = ConnectionManager.kPairingFailClearDeviceErrors.contains { $0 == errorType }
                let tryAgainError = ConnectionManager.kPairingFailTryAgainErrors.contains { $0 == errorType }
				let name = peripheralInterface.getPeripheral()?.name ?? "this camera"
				
				#if os(iOS)
					if clearDeviceError {
						m_initialConnectionToUIDelegate?.onPairingFailed(name, resolution: PairingFailureType.ClearDevice)
					} else if tryAgainError {
						m_initialConnectionToUIDelegate?.onPairingFailed(name, resolution: PairingFailureType.TryAgain)
					}
				#else
					m_initialConnectionToUIDelegate?.onPairingFailed(name, resolution: PairingFailureType.Unspecified)
				#endif
            }
        }

        m_peripheralInterface = nil
        m_connectionStatus = ConnectionStatusFlags.kNone
        m_connectionStatusDelegate?.onDisconnection()
    }

    public func onReconnection() {
        m_connectionStatus |= ConnectionStatusFlags.kConnected
    }

    // LocationServicesDelegate methods
    func onLocationReceived(_ latitide: UInt64, _ longitude: UInt64) {
        m_packetWriter.writeLocation(latitide, longitude)
    }

    func onLocationFailed(_ error: Error) {
        // On macOS, a wi-fi connection needs to be active, or location discovery will fail.
        Logger.LogError(error.localizedDescription)
    }

    // PacketReceivedDelegate methods
	public func onSuccessfulPairing(_ cameraName: String) {
        m_connectionStatus |= ConnectionStatusFlags.kPaired
        m_initialConnectionToUIDelegate?.onSuccessfulPairing(cameraName)
    }

    public func onTimecodePacketReceived(_ data: Data?) {
        m_packetReader.readTimecodePacket(data)
    }

    public func onCameraStatusPacketReceived(_ data: Data?) {
        let cameraStatus: UInt8 = m_packetReader.readCameraStatus(data)
        Logger.Log("Camera Status: \(cameraStatus)") 
        let cameraIsOn = cameraStatus & CameraStatus.Flags.CameraPowerFlag != 0
        let cameraIsReady = cameraStatus & CameraStatus.Flags.CameraReadyFlag != 0
        let cameraWasReady = m_connectionStatus & ConnectionStatusFlags.kCameraReady != 0
        let alreadyReceivedInitalPayload = m_connectionStatus & ConnectionStatusFlags.kInitialPayloadReceived != 0
        
        if cameraIsReady {
            if !alreadyReceivedInitalPayload {
                onInitialPayloadReceived()
            }
            if !cameraWasReady {
                m_connectionStatusDelegate?.onCameraReady()
            }
            m_connectionStatus |= ConnectionStatusFlags.kInitialPayloadReceived
            m_connectionStatus |= ConnectionStatusFlags.kCameraReady
            m_connectionStatus |= ConnectionStatusFlags.kPower
        } else if cameraIsOn {
            m_connectionStatus |= ConnectionStatusFlags.kPower
            m_connectionStatusDelegate?.onCameraPoweredOn()
        } else {
            m_connectionStatus &= ~ConnectionStatusFlags.kCameraReady
            m_connectionStatus &= ~ConnectionStatusFlags.kPower
            m_connectionStatusDelegate?.onCameraPoweredOff()
        }
    }

    public func onCCUPacketReceived(_ data: Data?) {
        m_packetReader.readCCUPacket(data)
    }

    public func onCameraModelPacketReceived(_ data: Data?) {
        m_packetReader.readCameraModelPacket(data)
    }

    public func onReadValueErrorReported(_ error: Error) {
        if let peripheral = m_peripheralInterface?.getPeripheral() {
            m_connectionManager.disconnect(from: peripheral, with: error)
        }
    }

    public func onWriteValueErrorReported(_ error: Error) {
        if let peripheral = m_peripheralInterface?.getPeripheral() {
            m_connectionManager.disconnect(from: peripheral, with: error)
        }
    }

    public func onCameraNameChanged(_ cameraName: String) {
        m_cameraNameDelegate?.onCameraNameChanged(cameraName)
    }

    func onInitialPayloadReceived() {
        m_initialConnectionToUIDelegate?.transitionToCameraControl()
    }

    public func onProtocolVersionReceived(_ peripheral: CBPeripheral, _ data: Data?) {
        var cameraVersionNumbers: [String] = []
        if let data: Data = data {
            let optionalProtocolVersion = String(data: data, encoding: .utf8)
            if let protocolVersion: String = optionalProtocolVersion {
                cameraVersionNumbers = protocolVersion.components(separatedBy: ".")
            }
        }

        verifyVersionNumbersAreCompatible(peripheral, cameraVersionNumbers)
    }

    func verifyVersionNumbersAreCompatible(_ peripheral: CBPeripheral, _ versionNumbers: [String]) {
        let appMajorVersion = ProtocolVersionNumber.kMajor
        let cameraMajorVersion = versionNumbers.count > 0 ? (versionNumbers[0].toInt() ?? -1) : -1
        let compatibilityVerified = cameraMajorVersion == appMajorVersion

        if compatibilityVerified {
            m_connectionStatus |= ConnectionStatusFlags.kVersionsVerified
        } else {
            disconnect()
            refreshScan()
            let cameraName = peripheral.name ?? "Blackmagic Design Camera"
            m_initialConnectionToUIDelegate?.onIncompatibleProtocolVersion(cameraName, cameraVersion: cameraMajorVersion, appVersion: appMajorVersion)
        }
    }

    // PacketEncodedDelegate methods
    func onCCUPacketEncoded(_ data: Data) {
        m_peripheralInterface?.sendPacket(data, BMDCameraServices.kMainService, BMDCameraCharacteristics.kOutgoingCCU)
    }

    func onPowerPacketEncoded(_ data: Data) {
        m_peripheralInterface?.sendPacket(data, BMDCameraServices.kMainService, BMDCameraCharacteristics.kCameraStatus)
    }

    // PacketDecodedDelegate methods
    public func onWhiteBalanceReceived(_ whiteBalance: Int16, _ tint: Int16) {
        m_cameraState.whiteBalance = whiteBalance
        m_cameraState.tint = tint

        if m_isSuspended { return }
        
        let wasWhiteBalanceExpected = m_cameraState.expectedWhiteBalance.removeUpToExpectedValue(whiteBalance)
        let wasTintExpected = m_cameraState.expectedTint.removeUpToExpectedValue(tint)
        if !wasWhiteBalanceExpected || !wasTintExpected {
            let presetIndex = VideoConfig.GetWhiteBalancePresetFromValues(whiteBalance, tint)
            m_cameraControlToUIDelegate?.onWhiteBalanceReceived(whiteBalance, tint, presetIndex)
        }
    }

    public func onRecordingFormatReceived(_ recordingFormatData: CCUPacketTypes.RecordingFormatData) {
        let lastOffSpeedFrameRate = m_cameraState.recordingFormatData.offSpeedFrameRate
        let newOffSpeedFrameRate = recordingFormatData.offSpeedFrameRate
        let offSpeedEnabled = recordingFormatData.offSpeedEnabled
        m_cameraState.recordingFormatData = recordingFormatData
        m_cameraState.frameRateForShutterCalculations = recordingFormatData.offSpeedFrameRate

        if !offSpeedEnabled && lastOffSpeedFrameRate != 0 && lastOffSpeedFrameRate != newOffSpeedFrameRate {
            m_cameraState.recordingFormatData.offSpeedFrameRate = lastOffSpeedFrameRate
        }

        if m_isSuspended { return }
        
        let wasExpected = m_cameraState.expectedOffSpeedFrameRate.removeUpToExpectedValue(newOffSpeedFrameRate)
        if !wasExpected {
            m_cameraControlToUIDelegate?.onOffSpeedFrameRateReceived(offSpeedEnabled, newOffSpeedFrameRate)
        }
    }
	
	public func onAutoExposureModeReceived(_ autoExposureMode: CCUPacketTypes.AutoExposureMode) {
		m_cameraState.autoExposureMode = autoExposureMode
		updateIrisAndShutterControl()
	}
	
	func updateIrisAndShutterControl() {
		let autoExposureMode = m_cameraState.autoExposureMode
		let manualIris = (autoExposureMode == CCUPacketTypes.AutoExposureMode.Manual) || (autoExposureMode == CCUPacketTypes.AutoExposureMode.Shutter)
		let manualShutter = (autoExposureMode == CCUPacketTypes.AutoExposureMode.Manual) || (autoExposureMode == CCUPacketTypes.AutoExposureMode.Iris)
		let lensAttached = m_cameraState.fStopIndex >= 0
		
		m_cameraControlToUIDelegate?.setIrisControlEnabled(manualIris && lensAttached)
		m_cameraControlToUIDelegate?.setShutterControlEnabled(manualShutter)
	}

    public func onIrisReceived(_ fStopIndex: Int) {
        m_cameraState.fStopIndex = fStopIndex

        if m_isSuspended { return }
        
        let wasExpected = m_cameraState.expectedFStopIndex.removeUpToExpectedValue(fStopIndex)
        if !wasExpected {
            m_cameraControlToUIDelegate?.onIrisReceived(fStopIndex)
			updateIrisAndShutterControl()
        }
    }

    public func onExposureReceived(_ exposure: Int32) {
    }
	
	public func onShutterSpeedReceived(_ shutterSpeed: Int32) {
		m_shutterValueIsAngle = false
		let wasExpected = m_cameraState.expectedShutterSpeed.removeUpToExpectedValue(shutterSpeed)
		m_cameraState.shutterSpeed = shutterSpeed
		
		if m_isSuspended { return }
		
		if !wasExpected {
			m_cameraControlToUIDelegate?.onShutterSpeedReceived(m_cameraState.shutterSpeed)
		}
	}
	
	public func onShutterAngleReceived(_ shutterAngleX100: Int32) {
		m_shutterValueIsAngle = true
		let wasExpected = m_cameraState.expectedShutterAngle.removeUpToExpectedValue(shutterAngleX100)
		m_cameraState.shutterAngle = Double(shutterAngleX100) / 100.0
		
		if m_isSuspended { return }
		
		if !wasExpected {
			m_cameraControlToUIDelegate?.onShutterAngleReceived(m_cameraState.shutterAngle)
		}
	}

    public func onISOReceived(_ iso: Int) {
		m_sensorGainIsISO = true
		m_cameraState.ISO = iso
        
        if m_isSuspended { return }
		
        if let isoIndex: Int = VideoConfig.kISOValues.firstIndex(of: iso) {
            m_cameraControlToUIDelegate?.onISOReceived(isoIndex)
        }
    }
	
	public func onGainReceived(_ gain: Int) {
		m_sensorGainIsISO = false
		m_cameraState.gain = gain
		
		if m_isSuspended { return }
		
		if let gainIndex: Int = VideoConfig.kGainValues.firstIndex(of: gain) {
			m_cameraControlToUIDelegate?.onGainReceived(gainIndex)
		}
	}

    public func onReelReceived(_ reelNumber: Int16) {
        m_cameraState.reel = Int(reelNumber)
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onReelReceived(reelNumber)
    }

    public func onSceneTagsReceived(_ sceneTag: CCUPacketTypes.MetadataSceneTag, _ locationTag: CCUPacketTypes.MetadataLocationTypeTag, _ timeTag: CCUPacketTypes.MetadataDayNightTag) {
        m_cameraState.sceneTag = sceneTag
        m_cameraState.locationTag = locationTag
        m_cameraState.timeTag = timeTag
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onSceneTagsReceived(Int(sceneTag.rawValue), Int(locationTag.rawValue), Int(timeTag.rawValue))
    }

    public func onSceneReceived(_ scene: String) {
        m_cameraState.scene = scene
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onSceneReceived(scene)
    }

    public func onTakeReceived(_ takeNumber: Int8, _ takeTag: CCUPacketTypes.MetadataTakeTag) {
        m_cameraState.takeNumber = Int(takeNumber)
        m_cameraState.takeTag = takeTag
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onTakeReceived(takeNumber, Int(takeTag.rawValue))
    }

    public func onGoodTakeReceived(_ goodTake: Bool) {
        m_cameraState.goodTake = goodTake
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onGoodTakeReceived(goodTake)
    }

	public func onSlateForNameReceived(_ slateForName: String) {
        m_cameraState.slateName = slateForName
        
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.onSlateForNameReceived(slateForName)
        m_recordControlToUIDelegate?.updateClipName(slateForName)
    }

    public func onSlateForTypeReceived(_ slateForType: CCUPacketTypes.MetadataSlateForType) {
        m_cameraState.slateType = slateForType
        if m_isSuspended { return }
        
        m_slateToUIDelegate?.setSlateForNextClip(slateForType == CCUPacketTypes.MetadataSlateForType.NextClip)
    }

    // OutgoingCameraControlFromUIDelegate methods

    // White Balance
    public func onWhiteBalanceIncremented() -> (whiteBalance: Int16, presetIndex: Int) {
        var newWhiteBalance: Int16 = m_cameraState.whiteBalance + VideoConfig.kWhiteBalanceStep
        if newWhiteBalance > VideoConfig.kWhiteBalanceMax {
            newWhiteBalance = VideoConfig.kWhiteBalanceMin
        }

        let presetIndex: Int = onWhiteBalanceChanged(newWhiteBalance)
        return (newWhiteBalance, presetIndex)
    }

    public func onWhiteBalanceDecremented() -> (whiteBalance: Int16, presetIndex: Int) {
        var newWhiteBalance: Int16 = m_cameraState.whiteBalance - VideoConfig.kWhiteBalanceStep
        if newWhiteBalance < VideoConfig.kWhiteBalanceMin {
            newWhiteBalance = VideoConfig.kWhiteBalanceMax
        }

        let presetIndex: Int = onWhiteBalanceChanged(newWhiteBalance)
        return (newWhiteBalance, presetIndex)
    }

    public func onWhiteBalanceChanged(_ whiteBalance: Int16) -> Int {
        m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(whiteBalance)
        m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(m_cameraState.tint)
        m_packetWriter.writeWhiteBalance(whiteBalance, m_cameraState.tint)

        return VideoConfig.GetWhiteBalancePresetFromValues(whiteBalance, m_cameraState.tint)
    }

    // Tint
    public func onTintIncremented() -> (tint: Int16, presetIndex: Int) {
        var newTint = m_cameraState.tint + 1
        if newTint > VideoConfig.kTintMax {
            newTint = VideoConfig.kTintMin
        }

        let presetIndex: Int = onTintChanged(newTint)
        return (newTint, presetIndex)
    }

    public func onTintDecremented() -> (tint: Int16, presetIndex: Int) {
        var newTint = m_cameraState.tint - 1
        if newTint < VideoConfig.kTintMin {
            newTint = VideoConfig.kTintMax
        }

        let presetIndex: Int = onTintChanged(newTint)
        return (newTint, presetIndex)
    }

    public func onTintChanged(_ tint: Int16) -> Int {
        m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(m_cameraState.whiteBalance)
        m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(tint)
        m_packetWriter.writeWhiteBalance(m_cameraState.whiteBalance, tint)

        return VideoConfig.GetWhiteBalancePresetFromValues(m_cameraState.whiteBalance, tint)
    }

    // White Balance Presets
    public func onWhiteBalancePresetPressed(_ presetIndex: Int, _ currentlySelected: Bool, _ saveCustomValues: Bool) -> (whiteBalance: Int16, tint: Int16)? {
        if saveCustomValues {
            m_cameraState.customWhiteBalance = m_cameraState.whiteBalance
            m_cameraState.customTint = m_cameraState.tint
        }

        if !currentlySelected {
            if presetIndex < VideoConfig.kWhiteBalancePresets.count {
                let whiteBalancePreset: VideoConfig.WhiteBalancePreset = VideoConfig.kWhiteBalancePresets[presetIndex]

                m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(m_cameraState.whiteBalance)
                m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(whiteBalancePreset.whiteBalance)
                m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(m_cameraState.tint)
                m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(whiteBalancePreset.tint)

                m_packetWriter.writeWhiteBalance(whiteBalancePreset.whiteBalance, whiteBalancePreset.tint)
                return (whiteBalancePreset.whiteBalance, whiteBalancePreset.tint)
            } else {
                onAutoWhiteBalancePressed()
            }
        } else {
            m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(m_cameraState.whiteBalance)
            m_cameraState.expectedWhiteBalance.addExpectedValueAllowingDuplicates(m_cameraState.customWhiteBalance)
            m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(m_cameraState.tint)
            m_cameraState.expectedTint.addExpectedValueAllowingDuplicates(m_cameraState.customTint)

            m_packetWriter.writeWhiteBalance(m_cameraState.customWhiteBalance, m_cameraState.customTint)
            return (m_cameraState.customWhiteBalance, m_cameraState.customTint)
        }

        return nil
    }

    // Off-Speed Frame Rate
    public func onOffSpeedFrameRateToggled(_ offSpeedEnabled: Bool) {
        m_cameraState.recordingFormatData.offSpeedEnabled = offSpeedEnabled
        m_packetWriter.writeRecordingFormat(m_cameraState.recordingFormatData)
    }

    public func onOffSpeedFrameRateIncremented() -> Int16 {
        var newOffSpeedFrameRate = m_cameraState.recordingFormatData.offSpeedFrameRate + 1
        if newOffSpeedFrameRate > VideoConfig.kOffSpeedFrameRateMax {
            newOffSpeedFrameRate = VideoConfig.kOffSpeedFrameRateMin
        }

        onOffSpeedFrameRateChanged(newOffSpeedFrameRate)
        return newOffSpeedFrameRate
    }

    public func onOffSpeedFrameRateDecremented() -> Int16 {
        var newOffSpeedFrameRate = m_cameraState.recordingFormatData.offSpeedFrameRate - 1
        if newOffSpeedFrameRate < VideoConfig.kOffSpeedFrameRateMin {
            newOffSpeedFrameRate = VideoConfig.kOffSpeedFrameRateMax
        }

        onOffSpeedFrameRateChanged(newOffSpeedFrameRate)
        return newOffSpeedFrameRate
    }

    public func onOffSpeedFrameRateChanged(_ frameRate: Int16) {
        var recordingFormatData = m_cameraState.recordingFormatData
        recordingFormatData.offSpeedFrameRate = frameRate
        let addedExpectedValue = m_cameraState.expectedOffSpeedFrameRate.addExpectedValue(frameRate)
        if addedExpectedValue {
            m_packetWriter.writeRecordingFormat(recordingFormatData)
        }
    }
    
    // Iris
    public func onIrisIncremented() -> Int {
        let newIndex = m_cameraState.fStopIndex + 1
        if newIndex >= LensConfig.fStopValues.count {
            return m_cameraState.fStopIndex
        }

        onIrisChanged(newIndex)
        return newIndex
    }

    public func onIrisDecremented() -> Int {
        let newIndex = m_cameraState.fStopIndex - 1
        if newIndex < 0 {
            return m_cameraState.fStopIndex
        }

        onIrisChanged(newIndex)
        return newIndex
    }

    public func onIrisChanged(_ fStopIndex: Int) {
        if fStopIndex >= 0 && fStopIndex < LensConfig.apertureNumbers.count {
            let addedExpectedValue = m_cameraState.expectedFStopIndex.addExpectedValue(fStopIndex)
            if addedExpectedValue {
                let apertureValue = LensConfig.apertureNumbers[fStopIndex]
                m_packetWriter.writeIris(apertureValue)
            }
        }
    }
    
    //Void command
    public func onAutoWhiteBalancePressed() {
        m_packetWriter.writeAutoWhiteBalance()
    }
    
    public func onAudioGainChanged(_ gainL: Double,_ gainR: Double) ->  (Int32, Int32)? {
        let leftValue = CCUPacketTypes.CCUFixedFromFloat(gainL)
        let rightValue = CCUPacketTypes.CCUFixedFromFloat(gainR)
        
        m_packetWriter.writeAudioGain(leftValue, rightValue)
        
        return (left: CCUPacketTypes.CCUPercentFromFixed(leftValue), right: CCUPacketTypes.CCUPercentFromFixed(rightValue))
    }
    
    public func onGammaChanged(_ red: Double, _ green: Double, _ blue: Double, _ luma: Double) {
        let redValue = CCUPacketTypes.CCUFixedFromFloat(red)
        let greenValue = CCUPacketTypes.CCUFixedFromFloat(green)
        let blueValue = CCUPacketTypes.CCUFixedFromFloat(blue)
        let lumaValue = CCUPacketTypes.CCUFixedFromFloat(luma)
        m_packetWriter.writeGamma(redValue, greenValue, blueValue, lumaValue)
    }
    
    public func onGammaReceived(_ red: Int16, _ green: Int16, _ blue: Int16, _ luma: Int16) {
        m_cameraControlToUIDelegate?.onGammaReceived(red, green, blue, luma)
    }
    
    public func onAudioGainReceived(_ gainL: Int16, _ gainR: Int16) {
        m_cameraControlToUIDelegate?.onAudioGainReceived(gainL, gainR)
    }
    
    public func onFocusPeakReceived(_ peak: Int16) {
        m_cameraControlToUIDelegate?.onFocusPeakReceived(peak)
    }
    
    // Shutter
    public func onShutterIncremented() -> Double {
        let nextShutterValue = getNextPresetShutterValue()
        onShutterChanged(nextShutterValue)

        return nextShutterValue
    }
    
    public func onScreenDisplayChanged(_ displayVisisble: Int) {
        m_packetWriter.writeOnScreenDisplayValue(displayVisisble)
    }
    
    public func onCodecChanged(_ codec: Int, _ codecVariant: Int) {
        m_packetWriter.writeCodec(codec, codecVariant)
    }
    
    public func OnAutoFocusPressed() {
        m_packetWriter.writeAutoFocusPressed()
    }
    
    public func onFocusPeakPressed() {
        m_packetWriter.writeFocusPeakPressed()
    }

    public func onFocusAssistColorPressed(_ color: Int32) {
        m_packetWriter.writeFocusAssistColorPressed(color)
    }
    
    public func onFocusIncremented() -> Double {
        var newFocus = m_cameraState.focus + 0.1
        if newFocus > LensConfig.kMaxFocus {
            newFocus = LensConfig.kMaxFocus
        }
        
        onFocusChanged(newFocus)
        
        return newFocus
    }
    
    public func onFocusDecremented() -> Double {
        var newFocus = m_cameraState.focus - 0.1
        if newFocus < LensConfig.kMinFocus {
            newFocus = LensConfig.kMinFocus
        }
        
        onFocusChanged(newFocus)
        
        return newFocus
    }
    
    public func onFocusChanged(_ newFocus: Double) {
        let focusValue = CCUPacketTypes.CCUFixedFromFloat(newFocus)
        let addedExpectedValue = m_cameraState.expectedFocus.addExpectedValue(focusValue)
        if addedExpectedValue {
            m_packetWriter.writeFocus(focusValue)
        }
    }
    
    public func onFocusReceived(_ focus:Int16) {
        let wasFocusExpected = m_cameraState.expectedFocus.removeUpToExpectedValue(focus)
        if !wasFocusExpected {
            m_cameraControlToUIDelegate?.onFocusReceived(focus)
        }
    }
    
    public func onShutterDecremented() -> Double {
        let prevShutterValue = getPrevPresetShutterValue()
        onShutterChanged(prevShutterValue)

        return prevShutterValue
    }

    func getNextPresetShutterValue() -> Double {
		if (m_shutterValueIsAngle)	{
			for value in VideoConfig.kShutterAngles {
				if value > m_cameraState.shutterAngle {
					return value
				}
			}
			
			return VideoConfig.kShutterAngles[0]
		} else {
			for value in VideoConfig.kShutterSpeeds {
				if value > m_cameraState.shutterSpeed {
					return Double(value)
				}
			}
			return Double(VideoConfig.kShutterSpeeds[0])
		}
    }

    func getPrevPresetShutterValue() -> Double {
		if (m_shutterValueIsAngle)	{
			for index in stride(from: VideoConfig.kShutterAngles.count - 1, to: 0, by: -1) {
				let value = VideoConfig.kShutterAngles[index]
				if value < m_cameraState.shutterAngle {
					return value
				}
			}
			return VideoConfig.kShutterAngles.last!
		} else {
			for index in stride(from: VideoConfig.kShutterSpeeds.count - 1, to: 0, by: -1) {
				let value = VideoConfig.kShutterSpeeds[index]
				if value < m_cameraState.shutterSpeed {
					return Double(value)
				}
			}
			return Double(VideoConfig.kShutterSpeeds.last!)
		}
    }

    public func onShutterChanged(_ shutterValue: Double) {
		if (m_shutterValueIsAngle)	{
			let shutterAngleX100 = Int32(shutterValue * 100.0)
			let addedExpectedValue = m_cameraState.expectedShutterAngle.addExpectedValue(shutterAngleX100)
			if addedExpectedValue {
				m_packetWriter.writeShutterAngle(shutterAngleX100)
			}
		} else {
			let shutterSpeed = Int32(shutterValue)
			let addedExpectedValue = m_cameraState.expectedShutterSpeed.addExpectedValue(shutterSpeed)
			if addedExpectedValue {
				m_packetWriter.writeShutterSpeed(shutterSpeed)
			}
		}
    }

    // ISO
    public func onISOChanged(_ isoIndex: Int) {
        let iso = VideoConfig.kISOValues[isoIndex]
        m_packetWriter.writeISO(iso)
    }
    
    public func onFocusPeakChanged(_ peak: Double) {
        let peakValue = CCUPacketTypes.CCUFixedFromFloat(peak)
        m_packetWriter.writeFocusPeak(peakValue)
    }

    // OutgoingSlateToCameraDelegate methods
    public func onReelIncremented() {
        let reel = m_cameraState.reel + 1
        if reel <= 999 {
            m_packetWriter.writeReel(Int16(reel))
        }
    }

    public func onReelDecremented() {
        let reel = m_cameraState.reel - 1
        if reel > 0 {
            m_packetWriter.writeReel(Int16(reel))
        }
    }

    public func onSceneTagSelected(sceneTagIndex: Int) {
        if let sceneTag = CCUPacketTypes.MetadataSceneTag(rawValue: Int8(sceneTagIndex)) {
            m_packetWriter.writeSceneTags(sceneTag, m_cameraState.locationTag, m_cameraState.timeTag)
        }
    }

    public func onLocationTagSelected(locationTagIndex: Int) {
        if let locationTag = CCUPacketTypes.MetadataLocationTypeTag(rawValue: UInt8(locationTagIndex)) {
            m_packetWriter.writeSceneTags(m_cameraState.sceneTag, locationTag, m_cameraState.timeTag)
        }
    }

    public func onTimeTagSelected(timeTagIndex: Int) {
        if let timeTag = CCUPacketTypes.MetadataDayNightTag(rawValue: UInt8(timeTagIndex)) {
            m_packetWriter.writeSceneTags(m_cameraState.sceneTag, m_cameraState.locationTag, timeTag)
        }
    }

    public func onSceneIncremented() {
        let newString = StringFunctions.IncrementSceneString(m_cameraState.scene)
        m_packetWriter.writeScene(newString)
    }

    public func onSceneDecremented() {
        let newString = StringFunctions.DecrementSceneString(m_cameraState.scene)
        m_packetWriter.writeScene(newString)
    }

    public func onTakeIncremented() {
        let take = m_cameraState.takeNumber + 1
        if take <= 99 {
            m_packetWriter.writeTake(take, m_cameraState.takeTag)
        }
    }

    public func onTakeDecremented() {
        let take = m_cameraState.takeNumber - 1
        if take > 0 {
            m_packetWriter.writeTake(take, m_cameraState.takeTag)
        }
    }

    public func onTakeTagSelected(takeTagIndex: Int) {
        if let takeTag = CCUPacketTypes.MetadataTakeTag(rawValue: Int8(takeTagIndex)) {
            m_packetWriter.writeTake(m_cameraState.takeNumber, takeTag)
        }
    }

    public func onGoodTakeToggled(_ goodTake: Bool) {
        m_packetWriter.writeGoodTake(goodTake)
    }

    // OutgoingPowerFromUIDelegate methods
    public func onPowerOff() {
        let turnPowerOn = false
        m_packetWriter.writePower(turnPowerOn)
    }

    // IncomingRecordingControlFromCameraDelegate methods
    func scheduleDiskInfoUpdate() {
        if m_isSuspended { return }
        
        m_diskTimer?.invalidate()
        m_diskTimer = Timer.scheduledTimer(timeInterval: kDiskInfoDelay, target: self, selector: #selector(updateDiskInfo), userInfo: nil, repeats: false)
    }

    @objc func updateDiskInfo() {
        let isRecording = m_cameraState.transportInfo.transportMode == CCUPacketTypes.MediaTransportMode.Record
        m_recordControlToUIDelegate?.setRecording(isRecording)
        m_recordControlToUIDelegate?.onRecordTimeRemainingReceived(m_cameraState.remainingTimeStrings)
        m_recordControlToUIDelegate?.setRecordingError(m_cameraState.hasRecordingError)
        m_recordControlToUIDelegate?.onTimelapseReceived(m_cameraState.transportInfo.timelapseRecording)
        
        let cardStatuses: [CardStatus] = m_cameraState.cardStatuses
        for slotIndex in 0 ..< cardStatuses.count {
            let recordTimeWarning: RecordTimeWarning = isRecording ? cardStatuses[slotIndex].recordTimeWarning : RecordTimeWarning.NoWarning
            m_recordControlToUIDelegate?.setRecordTimeWarning(recordTimeWarning, slotIndex)
        }
    }

    public func onTransportInfoReceived(_ transportInfo: TransportInfo) {
        let oldTransportMode = m_cameraState.transportInfo.transportMode
        let newTransportMode = transportInfo.transportMode
        let playbackSpeed = transportInfo.speed
        let anyDiskActive = transportInfo.disk1Active || transportInfo.disk2Active
        let isMovingFromPreview = (oldTransportMode == CCUPacketTypes.MediaTransportMode.Preview) && (newTransportMode != CCUPacketTypes.MediaTransportMode.Preview)
        m_cameraState.hasRecordingError = m_cameraState.hasRecordingError && anyDiskActive && !isMovingFromPreview
        m_cameraState.transportInfo = transportInfo
        
        if m_isSuspended { return }
        
        scheduleDiskInfoUpdate()

        m_recordControlToUIDelegate?.onActiveDisksReceived(transportInfo.disk1Active, transportInfo.disk2Active)
        m_cameraControlToUIDelegate?.onTransportModeReceived(newTransportMode)
        m_cameraControlToUIDelegate?.onOffSpeedFrameRateReceived(m_cameraState.recordingFormatData.offSpeedEnabled, m_cameraState.recordingFormatData.offSpeedFrameRate)
        
        if newTransportMode == CCUPacketTypes.MediaTransportMode.Play {
            m_recordControlToUIDelegate?.showPlaybackView(for: m_cameraState.slateName, at: Int(playbackSpeed))
        } else {
            m_recordControlToUIDelegate?.hidePlaybackView()
        }
        
        if newTransportMode == CCUPacketTypes.MediaTransportMode.Record {
            for slotIndex in 0 ..< m_cameraState.cardStatuses.count {
                m_cameraState.cardStatuses[slotIndex].recordTimeWarning = RecordTimeWarning.NoWarning
            }
        }
    }

    public func onTimecodeReceived(_ timecode: String) {
        m_cameraState.timecode = timecode
        
        if m_isSuspended { return }
        
        m_recordControlToUIDelegate?.onTimecodeReceived(timecode)
    }

    public func onMediaStatusReceived(_ mediaStatuses: [CCUPacketTypes.MediaStatus]) {
        m_cameraState.mediaStatuses = mediaStatuses

        var hasRecordingError = m_cameraState.hasRecordingError
        for cardIndex in 0 ..< 2 {
            let mediaStatus: CCUPacketTypes.MediaStatus = mediaStatuses[cardIndex]
            m_cameraState.cardStatuses[cardIndex].cardStatus = mediaStatus
            hasRecordingError = hasRecordingError || (mediaStatus == CCUPacketTypes.MediaStatus.RecordError)
        }

        m_cameraState.hasRecordingError = hasRecordingError
        
        updateRecordTimeRemainingStrings()
        scheduleDiskInfoUpdate()
    }

    public func onRecordTimeRemainingReceived(_ remainingRecordTimes: [String], _ remainingTimesInMinutes: [Int16]) {
        
        for slotIndex in 0 ..< 2 {
            m_cameraState.cardStatuses[slotIndex].remainingRecordTime = remainingRecordTimes[slotIndex]
        }
        
        var recordTimeWarnings: [RecordTimeWarning] = [RecordTimeWarning.NoWarning, RecordTimeWarning.NoWarning]
        for slotIndex in 0 ..< 2 {
            var minutesRemaining = remainingTimesInMinutes[slotIndex]
            let cardStatus = m_cameraState.cardStatuses[slotIndex]
            if cardStatus.cardStatus == CCUPacketTypes.MediaStatus.None || cardStatus.cardStatus == CCUPacketTypes.MediaStatus.MountError {
                minutesRemaining = 0
            }
            
            if minutesRemaining <= 2 {
                recordTimeWarnings[slotIndex] = RecordTimeWarning.TwoMinutesLeft
            } else if minutesRemaining <= 5 {
                recordTimeWarnings[slotIndex] = RecordTimeWarning.FiveMinutesLeft
            }
        }
        
        let disk1Active: Bool = m_cameraState.transportInfo.disk1Active
        let disk2Active: Bool = m_cameraState.transportInfo.disk2Active
        let isDualRecordMode: Bool = disk1Active && disk2Active
        
        if !isDualRecordMode {
            let lowestSeverityTimeWarning = recordTimeWarnings[0].rawValue < recordTimeWarnings[1].rawValue ? recordTimeWarnings[0] : recordTimeWarnings[1]
            recordTimeWarnings[0] = disk1Active ? lowestSeverityTimeWarning : RecordTimeWarning.NoWarning
            recordTimeWarnings[1] = disk2Active ? lowestSeverityTimeWarning : RecordTimeWarning.NoWarning
        }
        
        for slotIndex in 0 ..< recordTimeWarnings.count {
            m_cameraState.cardStatuses[slotIndex].recordTimeWarning = recordTimeWarnings[slotIndex]
        }
        
        updateRecordTimeRemainingStrings()
        scheduleDiskInfoUpdate()
    }

    func updateRecordTimeRemainingStrings() {
        for cardIndex in 0 ..< 2 {
            let noCardInSlot: Bool = m_cameraState.mediaStatuses[cardIndex] == CCUPacketTypes.MediaStatus.None
            let remainingRecordTimeString: String = m_cameraState.cardStatuses[cardIndex].remainingRecordTime
            m_cameraState.remainingTimeStrings[cardIndex] = noCardInSlot ? String.Localized("Transport.NoCard") : remainingRecordTimeString
        }
    }

    // OutgoingRecordingControlFromUIDelegate methods
    public func onRecordPressed() {
        var transportInfo = m_cameraState.transportInfo
        let isCurrentlyInPreview = transportInfo.transportMode == CCUPacketTypes.MediaTransportMode.Preview
        transportInfo.transportMode = isCurrentlyInPreview ? CCUPacketTypes.MediaTransportMode.Record : CCUPacketTypes.MediaTransportMode.Preview
        m_packetWriter.writeTransportPacket(transportInfo)
    }
    
    public func onPlayPressed() {
        var transportInfo = m_cameraState.transportInfo
        let isCurrentlyInPreview = transportInfo.transportMode == CCUPacketTypes.MediaTransportMode.Preview
        transportInfo.transportMode = isCurrentlyInPreview ? CCUPacketTypes.MediaTransportMode.Play : CCUPacketTypes.MediaTransportMode.Preview
        m_packetWriter.writeTransportPacket(transportInfo)
    }
    
    public func onNextClipPressed() {
        var transportInfo = m_cameraState.transportInfo
        transportInfo.speed = 1
        m_packetWriter.writeTransportPacket(transportInfo)
    }
    
    public func onPrevClipPressed() {
        var transportInfo = m_cameraState.transportInfo
        transportInfo.speed = -1
        m_packetWriter.writeTransportPacket(transportInfo)
    }
    
    public func returnToPreviewMode() {
        var transportInfo = m_cameraState.transportInfo
        transportInfo.transportMode = CCUPacketTypes.MediaTransportMode.Preview
        m_packetWriter.writeTransportPacket(transportInfo)
    }
    
    public func onDisk1Pressed() {
        let disk1Status: CCUPacketTypes.MediaStatus = m_cameraState.mediaStatuses[0]
        var transportInfo = m_cameraState.transportInfo

        if transportInfo.disk2Active && (disk1Status == CCUPacketTypes.MediaStatus.Ready || disk1Status == CCUPacketTypes.MediaStatus.RecordError) {
            transportInfo.disk1Active = true
            transportInfo.disk2Active = false
            m_packetWriter.writeTransportPacket(transportInfo)
        }
    }

    public func onDisk2Pressed() {
        let disk2Status: CCUPacketTypes.MediaStatus = m_cameraState.mediaStatuses[1]
        var transportInfo = m_cameraState.transportInfo

        if transportInfo.disk1Active && (disk2Status == CCUPacketTypes.MediaStatus.Ready || disk2Status == CCUPacketTypes.MediaStatus.RecordError) {
            transportInfo.disk1Active = false
            transportInfo.disk2Active = true
            m_packetWriter.writeTransportPacket(transportInfo)
        }
    }
}
