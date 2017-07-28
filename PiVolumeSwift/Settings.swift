//
//  Presets.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/21/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation

/*
static let IpAddress = "kUsDef_IpAdress"
static let UserName = "kUsDef_UserName"
static let Password = "kUsDef_Password"

static let LastUIVolumeStr = "kUsDef_LastUIVolumeStr"
static let PresetStrArray = "kPresetStrArray"

*/


class Settings
{
	var masterDict = [String: Any]()
	var settingsIndex = 0
	
	var userDefs = UserDefaults.standard
	
	
	var ipAddress: String? {
		get { return masterDict[K.UserDef.IpAddress] as? String }
		set (inStr){ masterDict[K.UserDef.IpAddress] = inStr }
	}
	
	var userName: String? {
		get { return masterDict[K.UserDef.UserName] as? String }
		set (inStr){ masterDict[K.UserDef.UserName] = inStr }
	}
	
	var password: String? {
		get { return masterDict[K.UserDef.Password] as? String }
		set (inStr){ masterDict[K.UserDef.Password] = inStr }
	}
	
	var lastUIVolumeStr: String? {
		get { return masterDict[K.UserDef.LastUIVolumeStr] as? String }
		set (inStr){ masterDict[K.UserDef.LastUIVolumeStr] = inStr }
	}
	
	var presetStrings: Array<String?>? {
		get { return masterDict[K.UserDef.LastUIVolumeStr] as? Array }
		set (inArr){ masterDict[K.UserDef.LastUIVolumeStr] = inArr }
	}
	
	
	func writeToUserDefs() {
		var currDicts = userDefs.array(forKey: K.UserDef.PresetDicts)
//		print("settingsIndex: \(settingsIndex)")
		
		currDicts?.append(masterDict)
		
		// TODO: insert at right index
		
		
		userDefs.set(currDicts, forKey:K.UserDef.PresetDicts)
	}
	
	
	func readFromUserDefs() {
		if let dict = userDefs.object(forKey: K.UserDef.PresetDicts) as? [String: Any]  {
			masterDict = dict
		} else {
			masterDict = [ : ] as [String : Any]
		}
		print("masterDict: \(masterDict)")
	}
	
}
