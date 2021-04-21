

import Foundation
import AppKit

class MainViewController: NSViewController, IncomingCameraControlToUIDelegate, IncomingSlateToUIDelegate, IncomingRecordControlToUIDelegate {
    
    @IBOutlet weak var whiteBalanceLabel: NSTextField!
    @IBOutlet weak var whiteBalanceSlider: BlackmagicSlider!
    
    @IBOutlet weak var tintLabel: NSTextField!
    @IBOutlet weak var tintSlider: BlackmagicSlider!
    
    @IBOutlet weak var irisLabel: NSTextField!
    @IBOutlet weak var irisSlider: BlackmagicSlider!
    
    @IBOutlet weak var shutterLabel: NSTextField!
    @IBOutlet weak var shutterSlider: BlackmagicSlider!
    
    @IBOutlet weak var isoLabel: NSTextField!
    @IBOutlet weak var isoSlider: BlackmagicSlider!
    
    @IBOutlet weak var wbPreset1Button: NSButton!
    @IBOutlet weak var wbPreset2Button: NSButton!
    @IBOutlet weak var wbPreset3Button: NSButton!
    @IBOutlet weak var wbPreset4Button: NSButton!
    @IBOutlet weak var wbPreset5Button: NSButton!
    
    @IBOutlet weak var shutterPreset1Button: NSButton!
    @IBOutlet weak var shutterPreset2Button: NSButton!
    @IBOutlet weak var shutterPreset3Button: NSButton!
    @IBOutlet weak var shutterPreset4Button: NSButton!
    @IBOutlet weak var shutterPreset5Button: NSButton!
    @IBOutlet weak var shutterPreset6Button: NSButton!
    
    @IBOutlet weak var focusLabel: NSTextField!
    
    @IBOutlet weak var focusPeakLabel: NSTextField!
    @IBOutlet weak var focusPeakSlider: BlackmagicSlider!
    
    @IBOutlet weak var gainLeftLabel: NSTextField!
    @IBOutlet weak var gainLeftSlider: BlackmagicSlider!
    @IBOutlet weak var gainRightLabel: NSTextField!
    @IBOutlet weak var gainRightSlider: BlackmagicSlider!
    
    @IBOutlet weak var timeCodeLabel: NSTextField!
    
    @IBOutlet weak var gammaLabelRed: NSTextField!
    @IBOutlet weak var gammaLabelGreen: NSTextField!
    @IBOutlet weak var gammaLabelBlue: NSTextField!
    @IBOutlet weak var gammaLabelLuma: NSTextField!
    
    @IBOutlet weak var gammaSliderRed: BlackmagicSlider!
    @IBOutlet weak var gammaSliderGreen: BlackmagicSlider!
    @IBOutlet weak var gammaSliderBlue: BlackmagicSlider!
    @IBOutlet weak var gammaSliderLuma: BlackmagicSlider!
    
    var wbPresetButtons = [NSButton]()
    var shutterPresetButtons = [NSButton]()
    
    var m_shutterValueIsAngle: Bool = true
    weak var m_outgoingCameraControlDelegate: OutgoingCameraControlFromUIDelegate?
    weak var m_outgoingRecordControlDelegate: OutgoingRecordControlFromUIDelegate?
    weak var m_outgoingSlateControlDelegate: OutgoingSlateFromUIDelegate?
    
    //==================================================
    //    UIViewController methods
    //==================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wbPresetButtons.append(wbPreset1Button)
        wbPresetButtons.append(wbPreset2Button)
        wbPresetButtons.append(wbPreset3Button)
        wbPresetButtons.append(wbPreset4Button)
        wbPresetButtons.append(wbPreset5Button)
        
        shutterPresetButtons.append(shutterPreset1Button)
        shutterPresetButtons.append(shutterPreset2Button)
        shutterPresetButtons.append(shutterPreset3Button)
        shutterPresetButtons.append(shutterPreset4Button)
        shutterPresetButtons.append(shutterPreset5Button)
        shutterPresetButtons.append(shutterPreset6Button)
        
        // Set values on sliders.
        whiteBalanceSlider.minValue = Double(VideoConfig.kWhiteBalanceMin)
        whiteBalanceSlider.maxValue = Double(VideoConfig.kWhiteBalanceMax)
        tintSlider.minValue = Double(VideoConfig.kTintMin)
        tintSlider.maxValue = Double(VideoConfig.kTintMax)
        irisSlider.minValue = 0.0
        irisSlider.maxValue = Double(LensConfig.fStopValues.count - 1)
        shutterSlider.minValue = 5.0
        shutterSlider.maxValue = 360.0
        isoSlider.minValue = 0.0
        isoSlider.maxValue = Double(VideoConfig.kISOValues.count - 1)
        focusPeakSlider.minValue = 0.0
        focusPeakSlider.maxValue = 1.0
        focusPeakSlider.floatValue = 0.5
        gainLeftSlider.minValue = 0.0
        gainLeftSlider.maxValue = 1.0
        gainLeftSlider.floatValue = 1.0
        gainRightSlider.minValue = 0.0
        gainRightSlider.maxValue = 1.0
        gainRightSlider.floatValue = 1.0
        gammaSliderRed.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderRed.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderRed.floatValue = 0.0
        gammaSliderGreen.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderGreen.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderGreen.floatValue = 0.0
        gammaSliderBlue.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderBlue.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderBlue.floatValue = 0.0
        gammaSliderLuma.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderLuma.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderLuma.floatValue = 0.0
        
        // Assign callbacks to our sliders
        whiteBalanceSlider.setCallbacks(onTentativeValueChanged: onWhiteBalanceSliderChanged, onValueChanged: onWhiteBalanceSliderSet)
        tintSlider.setCallbacks(onTentativeValueChanged: onTintSliderChanged, onValueChanged: onTintSliderSet)
        irisSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onIrisSliderSet)
        shutterSlider.setCallbacks(onTentativeValueChanged: onShutterSliderChanged, onValueChanged: onShutterSliderSet)
        isoSlider.setCallbacks(onValueChanged: onIsoSliderSet)
        focusPeakSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onFocusPeakSliderSet)
        gainLeftSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGainSliderSet)
        gainRightSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGainSliderSet)
        gammaSliderRed.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderGreen.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderBlue.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderLuma.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let cameraControlInterface: CameraControlInterface = appDelegate.cameraControlInterface
        m_outgoingCameraControlDelegate = cameraControlInterface
        m_outgoingRecordControlDelegate = cameraControlInterface
        m_outgoingSlateControlDelegate = cameraControlInterface
        cameraControlInterface.m_cameraControlToUIDelegate = self
        cameraControlInterface.m_slateToUIDelegate = self
        cameraControlInterface.m_recordControlToUIDelegate = self
        cameraControlInterface.onControlViewLoaded()
        cameraControlInterface.onSlateViewLoaded()
        cameraControlInterface.onTransportViewLoaded()
    }
    
    //==================================================
    //    IncomingCameraControlToUIDelegate methods
    //==================================================
    func onWhiteBalanceReceived(_ whiteBalance: Int16, _ tint: Int16, _ presetIndex: Int) {
        updateWhiteBalanceWidgets(whiteBalance)
        updateTintWidgets(tint)
        wbPresetButtons.forEach { $0.isSelected = $0.tag == presetIndex }
    }
    
    func onIrisReceived(_ fStopIndex: Int) {
        updateIrisWidgets(fStopIndex)
    }
    
    func onISOReceived(_ isoIndex: Int) {
        updateIsoWidgets(isoIndex)
    }
        
    func onShutterAngleReceived(_ shutterAngle: Double) {
        m_shutterValueIsAngle = true
        shutterSlider.minValue = VideoConfig.kShutterAngleMin
        shutterSlider.maxValue = VideoConfig.kShutterAngleMax
        updateShutterWidgets(Float(shutterAngle))
    }
    
    func onShutterSpeedReceived(_ shutterSpeed: Int32) {
        m_shutterValueIsAngle = false
        shutterSlider.minValue = Double(VideoConfig.kShutterSpeedMin)
        shutterSlider.maxValue = Double(VideoConfig.kShutterSpeedMax)
        updateShutterWidgets(Float(shutterSpeed))
    }
    
    func onGammaReceived(_ red: Int16, _ green: Int16, _ blue: Int16, _ luma: Int16) {
        updateGammaWidget(Float(red), Float(green), Float(blue), Float(luma))
    }
    
    func onFocusReceived(_ focus: Int16) {
        updateFocusText(Float(focus))
    }
    
    func onAudioGainReceived(_ gainL: Int16, _ gainR: Int16) {
        //updateGainWidget(Float(gainL), Float(gainR))
    }
    
    func onFocusPeakReceived(_ peak: Int16) {
        updateFocusPeakWidgets(Float(peak))
    }
    
    func onTimecodeReceived(_ timecode: String) {
        timeCodeLabel.stringValue = timecode
    }
    
    //==================================================
    //    BlackmagicSlider callbacks
    //==================================================
    func onWhiteBalanceSliderChanged(_: BlackmagicSlider) {
        let newWhiteBalance = (Int16(whiteBalanceSlider.floatValue) / VideoConfig.kWhiteBalanceStep) * VideoConfig.kWhiteBalanceStep
        updateWhiteBalanceWidgets(newWhiteBalance)
    }

    func onWhiteBalanceSliderSet(_: BlackmagicSlider) {
        let newWhiteBalance = (Int16(whiteBalanceSlider.floatValue) / VideoConfig.kWhiteBalanceStep) * VideoConfig.kWhiteBalanceStep
        let presetIndex: Int? = m_outgoingCameraControlDelegate?.onWhiteBalanceChanged(newWhiteBalance)
        wbPresetButtons.forEach { $0.isSelected = $0.tag == presetIndex }
    }
    
    func onTintSliderChanged(_: BlackmagicSlider) {
        let newTint = Int16(tintSlider.floatValue)
        updateTintWidgets(newTint)
    }

    func onTintSliderSet(_: BlackmagicSlider) {
        let newTint = Int16(tintSlider.floatValue)
        let presetIndex: Int? = m_outgoingCameraControlDelegate?.onTintChanged(newTint)
        wbPresetButtons.forEach { $0.isSelected = $0.tag == presetIndex }
    }
    
    func onIrisSliderSet(_: BlackmagicSlider) {
        let newIndex = Int(irisSlider.floatValue)
        m_outgoingCameraControlDelegate?.onIrisChanged(newIndex)
        updateIrisWidgets(newIndex)
    }
    
    func onShutterSliderChanged(_: BlackmagicSlider) {
        let newShutterValue = shutterSlider.floatValue.rounded()
        updateShutterWidgets(newShutterValue)
    }

    func onShutterSliderSet(_: BlackmagicSlider) {
        let newShutterValue = shutterSlider.floatValue.rounded()
        updateShutterWidgets(newShutterValue)
        m_outgoingCameraControlDelegate?.onShutterChanged(Double(newShutterValue))
        shutterPresetButtons.forEach { $0.isSelected = false }
    }
    
    func onIsoSliderSet(_: BlackmagicSlider) {
        let newIsoIndex = Int(isoSlider.floatValue)
        m_outgoingCameraControlDelegate?.onISOChanged(newIsoIndex)
        updateIsoWidgets(newIsoIndex)
    }
    
    func onFocusPeakSliderSet(_: BlackmagicSlider) {
        let newFocusPeakValue = focusPeakSlider.floatValue
        updateFocusPeakWidgets(newFocusPeakValue)
        m_outgoingCameraControlDelegate?.onFocusPeakChanged(Double(newFocusPeakValue))
    }
    
    //this is the preferred way when working with multi value commands
    func onGainSliderSet(_: BlackmagicSlider) {
        if let gainValues : (gainL: Int32, gainR: Int32) = m_outgoingCameraControlDelegate?.onAudioGainChanged(Double(gainLeftSlider.floatValue), Double(gainRightSlider.floatValue)) {
                updateGainWidget(gainValues.gainL, gainValues.gainR)
        }
    }
    
    func onGammaSliderSet(_: BlackmagicSlider) {
        let redValue = gammaSliderRed.floatValue
        let greenValue = gammaSliderGreen.floatValue
        let blueValue = gammaSliderBlue.floatValue
        let lumaValue = gammaSliderLuma.floatValue
        
        m_outgoingCameraControlDelegate?.onGammaChanged(Double(redValue), Double(greenValue), Double(blueValue), Double(lumaValue))
        updateGammaWidget(redValue, greenValue, blueValue, lumaValue)
    }
    
    //==================================================
    //    IBActions
    //==================================================
    @IBAction func onNextWhiteBalanceClicked(_ sender: NSButton) {
        if let newValues: (whiteBalance: Int16, presetIndex: Int) = m_outgoingCameraControlDelegate?.onWhiteBalanceIncremented() {
            updateWhiteBalanceWidgets(newValues.whiteBalance)
            wbPresetButtons.forEach { $0.isSelected = $0.tag == newValues.presetIndex }
        }
    }
    
    @IBAction func onPrevWhiteBalanceClicked(_ sender: NSButton) {
        if let newValues: (whiteBalance: Int16, presetIndex: Int) = m_outgoingCameraControlDelegate?.onWhiteBalanceDecremented() {
            updateWhiteBalanceWidgets(newValues.whiteBalance)
            wbPresetButtons.forEach { $0.isSelected = $0.tag == newValues.presetIndex }
        }
    }
    
    @IBAction func onPrevTintButtonClicked(_: NSButton) {
        if let newValues: (tint: Int16, presetIndex: Int) = m_outgoingCameraControlDelegate?.onTintDecremented() {
            updateTintWidgets(newValues.tint)
            wbPresetButtons.forEach { $0.isSelected = $0.tag == newValues.presetIndex }
        }
    }

    @IBAction func onNextTintButtonClicked(_: NSButton) {
        if let newValues: (tint: Int16, presetIndex: Int) = m_outgoingCameraControlDelegate?.onTintIncremented() {
            updateTintWidgets(newValues.tint)
            wbPresetButtons.forEach { $0.isSelected = $0.tag == newValues.presetIndex }
        }
    }
    
    @IBAction func onPrevIrisButtonClicked(_: NSButton) {
        let newIrisIndex = m_outgoingCameraControlDelegate?.onIrisDecremented()
        if newIrisIndex != nil {
            updateIrisWidgets(newIrisIndex!)
        }
    }

    @IBAction func onNextIrisButtonClicked(_: NSButton) {
        let newIrisIndex = m_outgoingCameraControlDelegate?.onIrisIncremented()
        if newIrisIndex != nil {
            updateIrisWidgets(newIrisIndex!)
        }
    }

    @IBAction func onPrevShutterButtonClicked(_: NSButton) {
        let newShutterValue = m_outgoingCameraControlDelegate?.onShutterDecremented()
        if newShutterValue != nil {
            updateShutterWidgets(Float(newShutterValue!))
            shutterPresetButtons.forEach { $0.isSelected = false }
        }
    }

    @IBAction func onNextShutterButtonClicked(_: NSButton) {
        let newShutterValue = m_outgoingCameraControlDelegate?.onShutterIncremented()
        if newShutterValue != nil {
            updateShutterWidgets(Float(newShutterValue!))
            shutterPresetButtons.forEach { $0.isSelected = false }
        }
    }
    
    @IBAction func onNextIsoButtonClicked(_: NSButton) {
        let newIsoValue = Int(isoSlider.floatValue) + 1
        if newIsoValue < VideoConfig.kISOValues.count {
            m_outgoingCameraControlDelegate?.onISOChanged(newIsoValue)
            updateIsoWidgets(newIsoValue)
        }
    }
    
    @IBAction func onPrevIsoButtonClicked(_: NSButton) {
        let newIsoValue = Int(isoSlider.floatValue) - 1
        if newIsoValue >= 0 {
            m_outgoingCameraControlDelegate?.onISOChanged(newIsoValue)
            updateIsoWidgets(newIsoValue)
        }
    }
    
    @IBAction func onAutoFocusButtonClicked(_ sender: NSButton){
        m_outgoingCameraControlDelegate?.OnAutoFocusPressed()
    }
    
    @IBAction func onNextFocusButtonClicked(_ sender: NSButton) {
        if let newFocus = m_outgoingCameraControlDelegate?.onFocusIncremented() {
            updateFocusText(Float(newFocus))
        }
    }
    
    @IBAction func onPrevFocusButtonClicked(_ sender: NSButton) {
        if let newFocus = m_outgoingCameraControlDelegate?.onFocusDecremented() {
            updateFocusText(Float(newFocus))
        }
    }
    
    @IBAction func onFocusPeakClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onFocusPeakPressed()
    }
    
    @IBAction func onFocusRedClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onFocusAssistColorPressed(CCUPacketTypes.DisplayFocusAssistColour.Red.rawValue)
    }
    
    @IBAction func onFocusGreenClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onFocusAssistColorPressed(CCUPacketTypes.DisplayFocusAssistColour.Green.rawValue)
    }
    
    @IBAction func onFocusWhiteClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onFocusAssistColorPressed(CCUPacketTypes.DisplayFocusAssistColour.White.rawValue)
    }
    
    @IBAction func onResetGammaButtonClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onGammaChanged(0.0, 0.0, 0.0, 0.0)
        updateGammaWidget(0.0, 0.0, 0.0, 0.0)
    }
    
    @IBAction func onWhiteBalancePresetButtonClicked(_ sender: NSButton) {
        let currentlySelected = !sender.isSelected
        let selectedButtons = wbPresetButtons.filter { return $0.isSelected }
        let saveCustomValues = selectedButtons.count != 0
        wbPresetButtons.forEach { $0.isSelected = false }

        let presetIndex = sender.tag
        let newValues: (whiteBalance: Int16, tint: Int16)? = m_outgoingCameraControlDelegate?.onWhiteBalancePresetPressed(presetIndex, currentlySelected, saveCustomValues)
        if newValues != nil {
            updateWhiteBalanceWidgets(newValues!.whiteBalance)
            updateTintWidgets(newValues!.tint)
        }

        sender.isSelected = !currentlySelected
        wbPresetButtons.last!.isSelected = false
    }
    
    @IBAction func onShutterPresetButtonClicked(_ sender: NSButton) {
        let currentlySelected = !sender.isSelected
        shutterPresetButtons.forEach { $0.isSelected = false }
        
        let shutterValue = Float(sender.tag)
        m_outgoingCameraControlDelegate?.onShutterChanged(Double(shutterValue))
        updateShutterWidgets(shutterValue)
        
        sender.isSelected = !currentlySelected
        shutterPresetButtons.last!.isSelected = false
    }
    
    @IBAction func onScreenDisplayToggle(_ sender: NSSwitch){
        let displayVisible = sender.state.rawValue
        
        m_outgoingCameraControlDelegate?.onScreenDisplayChanged(displayVisible)
    }
        
    @IBAction func onQZeroClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBrawQ0)
    }
    
    @IBAction func onQFiveClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBrawQ5)
    }
    
    @IBAction func onBrawThreeOneClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBraw3_1)
    }
    
    @IBAction func onBrawFiveOneClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBraw5_1)
    }
    
    @IBAction func onBrawEightOneClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBraw8_1)
    }
    
    @IBAction func onBrawTwelveOneClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.BRAW.rawValue, CCUPacketTypes.CodecVariants.kBraw12_1)
    }
    
    @IBAction func onProResHQClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.ProRes.rawValue, CCUPacketTypes.CodecVariants.kProResHQ)
    }
    
    @IBAction func onProRes422Clicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.ProRes.rawValue, CCUPacketTypes.CodecVariants.kProRes422)
    }
    
    @IBAction func onProResLTClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.ProRes.rawValue, CCUPacketTypes.CodecVariants.kProResLT)
    }
    
    @IBAction func onProResPXYClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onCodecChanged(CCUPacketTypes.BasicCodec.ProRes.rawValue, CCUPacketTypes.CodecVariants.kProResProxy)
    }

    @IBAction func returnToPreviewPressed(_ sender: NSButton) {
        m_outgoingRecordControlDelegate?.returnToPreviewMode()
    }
    
    @IBAction func btnRecordPressed(_ sender: NSButton) {
        m_outgoingRecordControlDelegate?.onRecordPressed()
    }
    
    @IBAction func btnPlayPressed(_ sender: NSButton) {
        m_outgoingRecordControlDelegate?.onPlayPressed()
    }
    
    @IBAction func onNextPressed(_ sender: NSButton) {
        m_outgoingRecordControlDelegate?.onPlaybackChanged(CCUPacketTypes.PlaybackControl.Next.rawValue)
    }
    
    @IBAction func onPrevPressed(_ sender: NSButton) {
        m_outgoingRecordControlDelegate?.onPlaybackChanged(CCUPacketTypes.PlaybackControl.Previous.rawValue)
    }
    
    //==================================================
    //    UI control
    //==================================================
    func updateWhiteBalanceWidgets(_ whiteBalance: Int16) {
        whiteBalanceLabel.stringValue = "\(whiteBalance)K"
        whiteBalanceSlider.floatValue = Float(whiteBalance)
    }
    
    func updateTintWidgets(_ tint: Int16) {
        tintLabel.stringValue = "\(tint)"
        tintSlider.floatValue = Float(tint)
    }
    
    func updateIrisWidgets(_ newIrisIndex: Int) {
        if newIrisIndex >= 0 && newIrisIndex < LensConfig.fStopValues.count {
            let fStop = LensConfig.fStopValues[newIrisIndex]
            irisLabel.stringValue = LensConfig.GetFStopString(fStop)
            irisSlider.floatValue = Float(newIrisIndex)
        }
    }
    
    func updateShutterWidgets(_ newShutterValue: Float) {
        shutterSlider.floatValue = newShutterValue
        
        if (m_shutterValueIsAngle) {
            shutterLabel.stringValue = "\(newShutterValue.getStringValue())°"
        }
        else {
            shutterLabel.stringValue = "1/\(Int(newShutterValue))"
        }
    }
    
    func updateFocusPeakWidgets(_ newFocusPeakValue: Float) {
        focusPeakSlider.floatValue = newFocusPeakValue
        focusPeakLabel.stringValue = "\(Int(floor(newFocusPeakValue * 100)))%"
    }
    
    func updateIsoWidgets(_ index: Int) {
        if index >= 0 && index < VideoConfig.kISOValues.count {
            let iso = VideoConfig.kISOValues[index]
            isoLabel.stringValue = String(iso)
            isoSlider.floatValue = Float(index)
        }
    }
    
    func updateGainWidget(_ leftValue: Int32, _ rightValue: Int32) {
        gainLeftLabel.stringValue = "\(leftValue)%"
        gainRightLabel.stringValue = "\(rightValue)%"
    }
    
    func updateGammaWidget(_ redValue: Float, _ greenValue: Float,_ blueValue: Float,_ lumaValue: Float) {
        gammaSliderRed.floatValue = redValue
        gammaLabelRed.stringValue = "\(roundGamma(redValue))"
        gammaSliderGreen.floatValue = greenValue
        gammaLabelGreen.stringValue = "\(roundGamma(greenValue))"
        gammaSliderBlue.floatValue = blueValue
        gammaLabelBlue.stringValue = "\(roundGamma(blueValue))"
        gammaSliderLuma.floatValue = lumaValue
        gammaLabelLuma.stringValue = "\(roundGamma(lumaValue))"
    }
    
    func updateFocusText(_ focus: Float) {
        focusLabel.stringValue = "\(focus)"
    }
    
    func roundGamma(_ gamma: Float) -> Float {
        return floor(gamma * 10) / 10.0
    }
}

