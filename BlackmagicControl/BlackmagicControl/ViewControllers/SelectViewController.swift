import Foundation
import AppKit

class SelectViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, InitialConnectionToUIDelegate {
    
    //IBOutlets
    @IBOutlet weak var cameraTableView: NSTableView!
    @IBOutlet weak var messageLabel: NSTextField!
    
    //member variables
    weak var m_initialConnectionInterfaceDelegate: InitialConnectionFromUIDelegate?
    var m_displayedCameras = [DiscoveredPeripheral]()
    var m_selectedCameraIdentifer: UUID?
    var m_simulateButton: NSButton?
    
    //UIViewController methods
    override func viewDidLoad() {
        cameraTableView.delegate = self
        cameraTableView.dataSource = self
        
        let simulateButton = NSButton(title: "Simulate Camera", target: self, action: #selector(onSimulateButtonClicked(_:)))
        simulateButton.bezelStyle = .rounded
        simulateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(simulateButton)
        
        NSLayoutConstraint.activate([
            simulateButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -5),
            simulateButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])
        
        m_simulateButton = simulateButton
    }
    
    override func viewWillAppear() {
        //register initialconnection to UI delegate with the CCI
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        let cameraControlInterface: CameraControlInterface = appDelegate.cameraControlInterface
        cameraControlInterface.m_initialConnectionToUIDelegate = self
        m_initialConnectionInterfaceDelegate = cameraControlInterface
        
        m_initialConnectionInterfaceDelegate?.disconnect()
        m_initialConnectionInterfaceDelegate?.refreshScan()
        
        m_displayedCameras.removeAll()
        messageLabel.stringValue = String.Localized("Information.Searching")
        
        super.viewWillAppear()
    }
    
    //IBActions
    @IBAction func onConnectButtonClicked(_:Any){
        let selectedIndex = cameraTableView.selectedRow
        if selectedIndex >= 0 {
            let uuid: UUID = m_displayedCameras[selectedIndex].peripheral.getPeripheralIdentifier()
            m_initialConnectionInterfaceDelegate?.attemptConnection(to: uuid)
            messageLabel.stringValue = String.Localized("Information.Connecting")
        }
    }
    
    @objc func onSimulateButtonClicked(_: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.cameraControlInterface.enterSimulatorMode()
    }
    
    //nstableviewdelegate methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        return m_displayedCameras.count
    }
    
    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        return m_displayedCameras[row].name
    }
 
    //initial connection to ui delegate methods
    func updateDiscoveredPeripheralList(_ discoveredPeripheralList: [DiscoveredPeripheral]) {
        //remoe all cached cameras
        m_displayedCameras.removeAll()
        
        //add all cameras from the peripheral displayed list
        for peripheral in discoveredPeripheralList{
            m_displayedCameras.append(peripheral)
        }
        
        //update the ui to display the discovered camers
        cameraTableView.reloadData()
    }
    
    func transitionToCameraControl() {
        if let baseViewController = self.parent as? BaseViewController {
            baseViewController.switchToContentView()
        }
    }
}
