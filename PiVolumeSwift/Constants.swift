//
//  Constants.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation

struct K {
	struct UserDef {
		static let IpAddress = "kUsDef_IpAdress"
		static let UserName = "kUsDef_UserName"
		static let Password = "kUsDef_Password"
		
		static let LastUIVolumeStr = "kUsDef_LastUIVolumeStr"
	}
	
	struct Notif {
		static let VolChanged = "kNotif_VolumeChanged"
		static let SliderMoved = "kNotif_SliderMoved"
		static let ConfirmedVolume = "kNotif_ConfirmedVolume"
	}
	
	struct Key {
		static let PercentValue = "kKey_PercentValue"
	}
	
	struct UIElementTag {
		static let IpAddress = 1234
		static let UserName = 1235
		static let Password = 1236
	}
	
	struct CellID {
		static let PresetTableViewCell = "kPresetTableViewCell"
	}
	
	
//	// ???: How about an enum in here? - wasn't recognized when used
//	enum UIElementTag: Int {
//		case IpAddress = 1234
//		case UserName = 1235
//		case Password = 1236
//	}
	
	// ???: this construct a good idea?
	init()
	{
		let defaults = UserDefaults.standard
		let defaultValues = [
			UserDef.IpAddress : "??",
			UserDef.UserName : "??",
			UserDef.Password : "??",
			UserDef.LastUIVolumeStr : "??"
		]
		defaults.register(defaults: defaultValues)
		defaults.synchronize()
	}
	
}

