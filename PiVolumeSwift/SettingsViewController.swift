//
//  SecondViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate
{
	let userDefs = UserDefaults.standard // OBSOLETE??
	var sshConnectionStatus: SshConnectionStatus = .Unknown {
		didSet {
			print("sshConnectionStatus: \(sshConnectionStatus)")
		}
	}
	
	@IBOutlet weak var deviceNameTextField: UITextField!
	@IBOutlet weak var ipTextField: UITextField!
	@IBOutlet weak var userTextField: UITextField!
	@IBOutlet weak var passTextField: UITextField!
	
	@IBOutlet weak var statusLabel: UILabel!
	
	var settingsProxy = SettingsProxy()
	
	// MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
		navigationItem.title = "Connection"
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(performBackSegue))
		
	}
	
	override func viewDidLoad() {
		// called each time we appear - even if we've been on sreen before
		// settingsProxy already set in segue
		super.viewDidLoad()
		
		deviceNameTextField.text = self.settingsProxy.deviceName
		ipTextField.text = self.settingsProxy.ipAddress
		userTextField.text = self.settingsProxy.userName
		passTextField.text = self.settingsProxy.password
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateStatusLabel(status: SSHManager.sharedInstance.connectionStatus)
		
		NotificationCenter.default.addObserver(forName: NSNotification.Name("\(K.Notif.SshConnectionStatusChanged)"),
		                                       object: nil,
		                                       queue: OperationQueue.main,
		                                       using: { [weak self] (notif) in
												guard let state = notif.userInfo?[K.Key.ConnectionStatus] as? SshConnectionStatus else { return }
												self?.updateStatusLabel(status: state)
		})
		
		SSHManager.sharedInstance.getVolumeFromRemote() // force status update
	}
	
	
	override func viewWillDisappear(_ animated: Bool) {
		view.endEditing(true) // retracts keyboard on any textField
		NotificationCenter.default.removeObserver(self)
		super.viewWillDisappear(animated)
	}
	
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called before we transition out of here (back to VolumeVuCon)
		if let volVuCon = segue.destination as? VolumeViewController {
			print("volVuCon: \(volVuCon)") // OBSOLETE, whole method
		}
	}
	
	
	@objc func performBackSegue() {
		// called from back btn when we transition back to VolumeViewCon
		performSegue(withIdentifier: "FromSettingsSegue", sender: self)
	}
	
	func updateStatusLabel(status: SshConnectionStatus) {
		switch status {
		case .Succeded:
			self.statusLabel.text = "ok"
		case .Failed:
			self.statusLabel.text = "failed"
		case .InProgress:
			self.statusLabel.text = "…"
		case .Unknown:
			self.statusLabel.text = "??"
		}
		
		// TODO: make enum?
	}
	

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		
		
		// TODO: implement settings obj
		// (could replace this mechanism with an IBAction - not much better & might fire upon each letter entered...)
		// ??? TODO: ask SM Geeks how to 'bind' text value to settings obj
		
		switch textField {
		case deviceNameTextField:
			settingsProxy.deviceName = textField.text!
		case ipTextField:
			settingsProxy.ipAddress = textField.text!
		case userTextField:
			settingsProxy.userName = textField.text!
		case passTextField:
			settingsProxy.password = textField.text!
		default:
			_ = 42
		}
		
		
		
//		switch textField.tag {
//		case K.UIElementTag.IpAddress:
////			settingsProxy.ipAddress = textField.text!
////			userDefs.set(textField.text, forKey: K.UserDef.IpAddress)
//			_ = 42
//		case K.UIElementTag.UserName:
//			settingsProxy.userName = textField.text!
////			userDefs.set(textField.text, forKey: K.UserDef.UserName)
//		case K.UIElementTag.Password:
//			settingsProxy.password = textField.text!
////			userDefs.set(textField.text, forKey: K.UserDef.Password)
//		default:
//			break
//		}
//
//		userDefs.synchronize()

		textField.resignFirstResponder()
		
		SSHManager.sharedInstance.getVolumeFromRemote() // force status update
		
		return true
	}
}

