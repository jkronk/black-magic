import Foundation
import AppKit

import CoreBluetooth

class BaseViewController: NSViewController, ConnectionStatusToUIDelegate, IncomingSlateToUIDelegate, IncomingRecordControlToUIDelegate {

    // Member variables
    var m_selectController: SelectViewController?
    var m_contentController: NSViewController?
    var m_mainController: MainViewController?

    //==================================================
    //    UIViewController methods
    //==================================================
    override func viewDidLoad() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let cameraControlInterface: CameraControlInterface = appDelegate.cameraControlInterface
        cameraControlInterface.m_connectionStatusDelegate = self

        let mainStoryboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        m_selectController = mainStoryboard.instantiateController(withIdentifier: "selectController") as? SelectViewController
        m_contentController = mainStoryboard.instantiateController(withIdentifier: "contentController") as? ContentViewController
        m_mainController = mainStoryboard.instantiateController(withIdentifier: "mainController") as? MainViewController

        showSelectView()
        //showContentView()
        super.viewDidLoad()
    }

    //==================================================
    //    ConnectionStatusToUIDelegate methods
    //==================================================
    func onConnectionLost() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if appDelegate.cameraControlInterface.m_isSimulatorMode { return }
        switchToSelectView()
    }

    func onDisconnection() {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        if appDelegate.cameraControlInterface.m_isSimulatorMode { return }
        switchToSelectView()
    }

    func onReconnection() {}
    func onCameraPoweredOff() {}
    func onCameraPoweredOn() {}
    func onCameraReady() {}
    
    //==================================================
    //    UI control
    //==================================================
    func showSelectView() {
        if let selectController = m_selectController {
            addChild(selectController)
            view.addSubview(selectController.view)
            view.frame = selectController.view.frame
        }
    }
    
    func removeSelectView() {
        if let selectController = m_selectController {
            removeChild(at: 0)
            selectController.view.removeFromSuperview()
        }
    }
    
    func showContentView() {
        if let contentController = m_contentController {
            addChild(contentController)
            view.addSubview(contentController.view)
            view.frame = contentController.view.frame
        }
    }
    
    func removeContentView() {
        if let contentController = m_contentController {
            removeChild(at: 0)
            contentController.view.removeFromSuperview()
        }
    }
    
    func switchToSelectView() {
        removeContentView()
        showSelectView()
    }
    
    func switchToContentView() {
        removeSelectView()
        showContentView()
    }
}
