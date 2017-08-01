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
	let userDefs = UserDefaults.standard
	var sshConnectionStatus: SshConnectionStatus = .Unknown {
		didSet {
			print("sshConnectionStatus: \(sshConnectionStatus)")
		}
	}
	
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
		super.viewDidLoad()
		
		// TODO: replace with settings obj, passed in during segue?
		
		ipTextField.text = self.settingsProxy.ipAddress
		userTextField.text = self.settingsProxy.userName
		passTextField.text = self.settingsProxy.password
		
//		ipTextField.text = userDefs.string(forKey: K.UserDef.IpAddress)
//		userTextField.text = userDefs.string(forKey: K.UserDef.UserName)
//		passTextField.text = userDefs.string(forKey: K.UserDef.Password)
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
	
	
//	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//		// called before we transition out of here (back to VolumeVuCon)
//		print("leaving settingsVuCon")
//		
//		print("self.settingsProxy: \(self.settingsProxy)")
//		
//		if let volVuCon = segue.destination as? VolumeViewController {
//			// put settings back?
//			// TODO: volVuCon.setttings =
//			print("volVuCon: \(volVuCon)")
//		}
//		
//		
//	}
	
	
	func performBackSegue() {
		// called when we transition back to VolumeViewCon
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
		
		switch textField.tag {
		case K.UIElementTag.IpAddress:
			settingsProxy.ipAddress = textField.text!
//			userDefs.set(textField.text, forKey: K.UserDef.IpAddress)
		case K.UIElementTag.UserName:
			settingsProxy.userName = textField.text!
//			userDefs.set(textField.text, forKey: K.UserDef.UserName)
		case K.UIElementTag.Password:
			settingsProxy.password = textField.text!
//			userDefs.set(textField.text, forKey: K.UserDef.Password)
		default:
			break
		}

		userDefs.synchronize()

		textField.resignFirstResponder()
		
		SSHManager.sharedInstance.getVolumeFromRemote() // force status update
		
		return true
	}
}

