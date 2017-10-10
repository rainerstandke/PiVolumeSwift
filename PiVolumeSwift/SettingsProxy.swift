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
	var ipAddress = ""
	var userName = ""
	var password = ""
	var lastUIVolumeStr = ""
	var controllerName = ""
	
	var presetStrings = [String]()
	
	var index: Int = NSNotFound // OBSOLETE
	
	
//	convenience init(_ dictRep: [String:Any]) {
//		self.init()
//		ipAddress = dictRep["ipAddress"] as! String
//		userName = dictRep["userName"] as! String
//		password = dictRep["password"] as! String
//		lastUIVolumeStr = dictRep["lastUIVolumeStr"] as! String
//		controllerName = dictRep["controllerName"] as! String
//		
//		presetStrings = dictRep["presetStrings"] as! [String]
//		index = dictRep["index"] as! Int
//	}
//	
//	
//	func dictionaryRepresentation() -> [String:Any] {
//		var dict = [String:Any]()
//		dict["ipAddress"] = ipAddress
//		dict["userName"] = userName
//		dict["password"] = password
//		dict["lastUIVolumeStr"] = lastUIVolumeStr
//		dict["presetStrings"] = presetStrings
//		
//		dict["controllerName"] = controllerName
//		dict["index"] = index
//		
//		return dict
//	}
	
	override var description: String {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted] // another option: .sortedKeys
		let jsonData = try? encoder.encode(self)
		return String(data: jsonData!, encoding: .utf8)!
	}
	
}
