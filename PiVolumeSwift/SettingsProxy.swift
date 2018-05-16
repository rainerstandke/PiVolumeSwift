//
//  Presets.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/21/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//




/* settings and state of the raspberry pi - perhaps naming ought to reflect that */





import Foundation

class SettingsProxy: NSObject, Codable
{
	var deviceName = "" // the machine that we talk to, e.g. "AirPi"
	var ipAddress = ""
	var userName = ""
	
	var presetStrings = [String]() // just the preset values as single strings in the order they appear on screen

	// dynamic so they can be observed with KVO using objc dynamic runtime
	@objc dynamic var pushVolume: String? // the volume sent to the pi
	@objc dynamic var confirmedVolume: String? // the volume read from the pi
	
	override var description: String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted] // another option: .sortedKeys
		let jsonData = try? encoder.encode(self)
		return String(data: jsonData!, encoding: .utf8)!
	}
}
