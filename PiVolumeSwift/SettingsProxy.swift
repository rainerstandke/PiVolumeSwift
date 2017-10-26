//
//  Presets.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/21/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation

class SettingsProxy: NSObject, Codable
{
	var deviceName = "" // the machine that we talk to, e.g. "AirPi"
	var ipAddress = ""
	var userName = ""
	
	var presetStrings = [String]() // just the preset values as single strings in the order they appear on screen

	@objc dynamic var pushVolume: String?
	@objc dynamic var confirmedVolume: String?
	
	override var description: String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted] // another option: .sortedKeys
		let jsonData = try? encoder.encode(self)
		return String(data: jsonData!, encoding: .utf8)!
	}
}
