

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
    
    @IBOutlet weak var gainLeftLabel: NSTextField!
    @IBOutlet weak var gainLeftSlider: BlackmagicSlider!
    @IBOutlet weak var gainRightLabel: NSTextField!
    @IBOutlet weak var gainRightSlider: BlackmagicSlider!
    
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
        
        // Set values on sliders.
        whiteBalanceSlider.minValue = Double(VideoConfig.kWhiteBalanceMin)
        whiteBalanceSlider.maxValue = Double(VideoConfig.kWhiteBalanceMax)
        tintSlider.minValue = Double(VideoConfig.kTintMin)
        tintSlider.maxValue = Double(VideoConfig.kTintMax)
        irisSlider.minValue = 0.0
        irisSlider.maxValue = Double(LensConfig.fStopValues.count - 1)
        shutterSlider.minValue = 5.0
        shutterSlider.maxValue = 360.0
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
        //here we need to send the value to the camera, it should be between max values
        m_outgoingCameraControlDelegate?.onFocusIncremented()
    }
    
    @IBAction func onPrevFocusButtonClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onFocusDecremented()
    }
    
    @IBAction func onResetGammaButtonClicked(_ sender: NSButton) {
        m_outgoingCameraControlDelegate?.onGammaChanged(0.0, 0.0, 0.0, 0.0)
        updateGammaWidget(0.0, 0.0, 0.0, 0.0)
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

