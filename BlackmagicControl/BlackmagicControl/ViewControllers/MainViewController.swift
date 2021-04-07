

import Foundation
import AppKit

class MainViewController: NSViewController, IncomingCameraControlToUIDelegate {
    
    @IBOutlet weak var whiteBalanceLabel: NSTextField!
    @IBOutlet weak var whiteBalanceSlider: BlackmagicSlider!
    
    @IBOutlet weak var tintLabel: NSTextField!
    @IBOutlet weak var tintSlider: BlackmagicSlider!
    
    @IBOutlet weak var irisLabel: NSTextField!
    @IBOutlet weak var irisSlider: BlackmagicSlider!
    
    @IBOutlet weak var shutterLabel: NSTextField!
    @IBOutlet weak var shutterSlider: BlackmagicSlider!
    
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
    
    @IBOutlet weak var iso100RadioButton: NSButton!
    @IBOutlet weak var iso200RadioButton: NSButton!
    @IBOutlet weak var iso400RadioButton: NSButton!
    @IBOutlet weak var iso800RadioButton: NSButton!
    @IBOutlet weak var iso1600RadioButton: NSButton!
    
    @IBOutlet weak var focusLabel: NSTextField!
    
    @IBOutlet weak var focusPeakLabel: NSTextField!
    @IBOutlet weak var focusPeakSlider: BlackmagicSlider!
    
    @IBOutlet weak var gainLeftLabel: NSTextField!
    @IBOutlet weak var gainLeftSlider: BlackmagicSlider!
    @IBOutlet weak var gainRightLabel: NSTextField!
    @IBOutlet weak var gainRightSlider: BlackmagicSlider!
    
    @IBOutlet weak var cmbCodec: NSComboBox!
    @IBOutlet weak var cmbCodecVariant: NSComboBox!
    
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
    var isoRadioButtons = [NSButton]()
    
    var m_shutterValueIsAngle: Bool = true
    weak var m_outgoingCameraControlDelegate: OutgoingCameraControlFromUIDelegate?
    
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
        
        isoRadioButtons.append(iso100RadioButton)
        isoRadioButtons.append(iso200RadioButton)
        isoRadioButtons.append(iso400RadioButton)
        isoRadioButtons.append(iso800RadioButton)
        isoRadioButtons.append(iso1600RadioButton)
        
        cmbCodec.addItems(withObjectValues: ["RAW", "DNxHD", "ProRes", "BRAW"])
        
        // Set values on sliders.
        whiteBalanceSlider.minValue = Double(VideoConfig.kWhiteBalanceMin)
        whiteBalanceSlider.maxValue = Double(VideoConfig.kWhiteBalanceMax)
        tintSlider.minValue = Double(VideoConfig.kTintMin)
        tintSlider.maxValue = Double(VideoConfig.kTintMax)
        irisSlider.minValue = 0.0
        irisSlider.maxValue = Double(LensConfig.fStopValues.count - 1)
        shutterSlider.minValue = 5.0
        shutterSlider.maxValue = 360.0
        focusPeakSlider.minValue = 0.0
        focusPeakSlider.maxValue = 1.0
        gainLeftSlider.minValue = 0.0
        gainLeftSlider.maxValue = 1.0
        gainRightSlider.minValue = 0.0
        gainRightSlider.maxValue = 1.0
        gammaSliderRed.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderRed.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderGreen.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderGreen.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderBlue.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderBlue.maxValue = ColorCorrectionConfig.kMaxGamma
        gammaSliderLuma.minValue = ColorCorrectionConfig.kMinGamma
        gammaSliderLuma.maxValue = ColorCorrectionConfig.kMaxGamma
        
        // Assign callbacks to our sliders
        whiteBalanceSlider.setCallbacks(onTentativeValueChanged: onWhiteBalanceSliderChanged, onValueChanged: onWhiteBalanceSliderSet)
        tintSlider.setCallbacks(onTentativeValueChanged: onTintSliderChanged, onValueChanged: onTintSliderSet)
        irisSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onIrisSliderSet)
        shutterSlider.setCallbacks(onTentativeValueChanged: onShutterSliderChanged, onValueChanged: onShutterSliderSet)
        focusPeakSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onFocusPeakSliderSet)
        gainLeftSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGainSliderSet)
        gainRightSlider.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGainSliderSet)
        gammaSliderRed.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderGreen.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderBlue.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
        gammaSliderLuma.setCallbacks(onTentativeValueChanged: nil, onValueChanged: onGammaSliderSet)
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
        updateISOWidgets(isoIndex)
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
        updateGainWidget(Float(gainL), Float(gainR))
    }
    
    func onFocusPeakReceived(_ peak: Int16) {
        updateFocusPeakWidgets(Float(peak))
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
    
    func onFocusPeakSliderSet(_: BlackmagicSlider) {
        let newFocusPeakValue = focusPeakSlider.floatValue.rounded()
        updateFocusPeakWidgets(newFocusPeakValue)
        m_outgoingCameraControlDelegate?.onFocusPeakChanged(Double(newFocusPeakValue))
    }
    
    //this is the preferred way when working with multi value commands
    func onGainSliderSet(_: BlackmagicSlider) {
        let leftValue = gainLeftSlider.floatValue
        let rightValue = gainRightSlider.floatValue
        m_outgoingCameraControlDelegate?.onAudioGainChanged(Double(leftValue), Double(rightValue))
        updateGainWidget(leftValue, rightValue)
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
    @IBAction func onISORadioButtonClicked(_ sender: NSButton) {
        let isoIndex: Int = sender.tag
        m_outgoingCameraControlDelegate?.onISOChanged(isoIndex)
        updateISOWidgets(isoIndex)
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
    
    @IBAction func comboCodecSelectionChanged(_ sender: NSComboBox) {
        if cmbCodec.numberOfItems < 1 || cmbCodecVariant.numberOfItems < 1 { return
        }
        cmbCodecVariant.removeAllItems()
        if sender.indexOfSelectedItem == 0 {
            cmbCodecVariant.addItems(withObjectValues: ["Uncompressed", "3:1", "4:1"])
        }
        else if sender.indexOfSelectedItem == 2 {
            cmbCodecVariant.addItems(withObjectValues: ["HQ", "422", "LT", "Proxy", "444", "444XQ"])
        }
        else if sender.indexOfSelectedItem == 3 {
            cmbCodecVariant.addItems(withObjectValues: ["Q0", "Q1", "3:1", "5:1", "8:1", "12:1"])
        }
        
        m_outgoingCameraControlDelegate?.onCodecChanged(cmbCodec.indexOfSelectedItem, cmbCodecVariant.indexOfSelectedItem)
    }
    
    @IBAction func cmbCodecVariantSelectionChanged(_ sender: NSComboBox) {
        
        if cmbCodec.numberOfItems < 1 || cmbCodecVariant.numberOfItems < 1 { return
        }
        
        m_outgoingCameraControlDelegate?.onCodecChanged(cmbCodec.indexOfSelectedItem, cmbCodecVariant.indexOfSelectedItem)
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
        focusPeakLabel.stringValue = "\(newFocusPeakValue)"
    }
    
    func updateISOWidgets(_ index: Int) {
        isoRadioButtons.forEach { $0.isSelected = false }
        isoRadioButtons[index].isSelected = true
    }
    
    func updateGainWidget(_ leftValue: Float, _ rightValue: Float) {
        gainLeftLabel.stringValue = "\(leftValue)"
        gainLeftSlider.floatValue = leftValue
        gainRightLabel.stringValue = "\(rightValue)"
        gainRightSlider.floatValue = rightValue
    }
    
    func updateGammaWidget(_ redValue: Float, _ greenValue: Float,_ blueValue: Float,_ lumaValue: Float) {
        gammaSliderRed.floatValue = redValue
        gammaLabelRed.stringValue = "\(redValue)"
        gammaSliderGreen.floatValue = greenValue
        gammaLabelGreen.stringValue = "\(greenValue)"
        gammaSliderBlue.floatValue = blueValue
        gammaLabelBlue.stringValue = "\(blueValue)"
        gammaSliderLuma.floatValue = lumaValue
        gammaLabelLuma.stringValue = "\(lumaValue)"
    }
    
    func updateFocusText(_ focus: Float) {
        focusLabel.stringValue = "\(focus)"
    }
}

