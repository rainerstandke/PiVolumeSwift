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
	@IBOutlet weak var deviceNameTextField: UITextField!
	@IBOutlet weak var ipTextField: UITextField!
	@IBOutlet weak var userNameTextField: UITextField!
	
	@IBOutlet weak var statusLabel: UILabel!
	
	// set by VolVuCon during segue
	var sshMan: SSHManager?
	
	var connectStatusObservation: NSKeyValueObservation?
	
	// MARK: -
	
	override func awakeFromNib() {
		super.awakeFromNib()
		navigationItem.title = "Connection"
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(performBackSegue))
	}
	
	override func viewDidLoad() {
		// called each time we appear - even if we've been on screen before
		// settingsProxy already set in segue
		super.viewDidLoad()
		
		if let settingsPr = sshMan?.settingsPr {
			deviceNameTextField.text = settingsPr.deviceName
			ipTextField.text = settingsPr.ipAddress
			userNameTextField.text = settingsPr.userName
		}
		
		// show whatever sshMan has as current
		updateStatusLabel(status: sshMan!.connectionStatus)
		
		// this could not be done with KVO from Swift 4 b/c enum is not available in obj-c
		NotificationCenter.default.addObserver(forName: NSNotification.Name("\(K.Notif.SshConnectionStatusChanged)"),
		                                       object: sshMan!,
		                                       queue: OperationQueue.main, // effectively: main thread
		                                       using: { [weak self] (notif) in
												guard let state = notif.userInfo?[K.Key.ConnectionStatus] as? SshConnectionStatus else { return }
												self?.updateStatusLabel(status: state)
		})
		
		// ... but also force update
		sshMan?.getVolumeFromRemote()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		view.endEditing(true) // retracts keyboard on any textField
		NotificationCenter.default.removeObserver(self)
		super.viewWillDisappear(animated)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func performBackSegue() {
		// called from back btn when we transition back to VolumeViewCon
		performSegue(withIdentifier: "FromSettingsSegue", sender: self)
	}
	
	func updateStatusLabel(status: SshConnectionStatus) {
		// SshConnectionStatus's rawValue is String fit for display
		self.statusLabel.text = status.rawValue
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
	
	func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		
		textField.resignFirstResponder()
		
		if let settingsPr = sshMan?.settingsPr {
			switch textField {
			case deviceNameTextField:
				settingsPr.deviceName = textField.text!
			case ipTextField:
				settingsPr.ipAddress = textField.text!
			case userNameTextField:
				settingsPr.userName = textField.text!
			default:
				break
			}
		}
		sshMan?.getVolumeFromRemote() // force status update
		
		return true
	}
}

