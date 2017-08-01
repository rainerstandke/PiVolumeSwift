//
//  Presets.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/21/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation







class SettingsProxy: NSObject
{
	var ipAddress = ""
	var userName = ""
	var password = ""
	var lastUIVolumeStr = ""
	var presetStrings = [String]()
	
	var controllerName = ""
	
	var index: Int = NSNotFound
	
	
	
	override var description: String {
		return "ip: \(ipAddress)"
	}
	
}
