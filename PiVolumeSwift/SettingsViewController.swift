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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		ipTextField.text = userDefs.string(forKey: K.UserDef.IpAddress)
		userTextField.text = userDefs.string(forKey: K.UserDef.UserName)
		passTextField.text = userDefs.string(forKey: K.UserDef.Password)
	
	
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBOutlet weak var ipTextField: UITextField!
	@IBOutlet weak var userTextField: UITextField!
	@IBOutlet weak var passTextField: UITextField!

	
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		print("textFieldShouldReturn")
		
		textField.resignFirstResponder()
		
		return true
	}
	
	func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		print("textFieldShouldEndEditing")
		
		switch textField.tag {
		case K.UIElementTag.IpAddress:
			userDefs.set(textField.text, forKey: K.UserDef.IpAddress)
		case K.UIElementTag.UserName:
			userDefs.set(textField.text, forKey: K.UserDef.UserName)
		case K.UIElementTag.Password:
			userDefs.set(textField.text, forKey: K.UserDef.Password)
		default:
			break
		}

		return true
	}
	

}

