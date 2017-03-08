//
//  Constants.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation

// see: http://www.luby.info/2015/02/15/swift-constants-files.html - using structures with constant type properties
// type props are like class props in ObjC (if those existed) - static makes them global, let makes them constant
// type props are accessible without an instance

struct K {
	struct UserDef {
		static let IpAddress = "kUsDef_IpAdress"
		static let UserName = "kUsDef_UserName"
		static let Password = "kUsDef_Password"
		
		static let LastUIVolumeStr = "kUsDef_LastUIVolumeStr"
		static let PresetStrArray = "kPresetStrArray"
		
		static let PresetDicts = "kPresetDicts"
	}
	
	struct Notif {
		static let VolChanged = "kNotif_VolumeChanged"
		static let SliderMoved = "kNotif_SliderMoved"
		static let ConfirmedVolume = "kNotif_ConfirmedVolume"
		static let SshConnectionStatusChanged: NSNotification.Name = "kSshConnectionStatusChanged"
		static let AddTabBarItem = "kAddTabBarItem"
		static let DeleteTabBarItem = "kDeleteTabBarItem"
	}
	
	struct Key {
		static let PercentValue = "kKey_PercentValue"
		static let ConnectionStatus = "kConnectionStatus"
	}
	
	struct UIElementTag {
		static let IpAddress = 1234
		static let UserName = 1235
		static let Password = 1236
		
		static let PresetButton = 9958
	}
	
	struct CellID {
		static let PresetTableViewCell = "kPresetTableViewCell"
	}
	
	struct Misc {
		static let ShortTimerInterval = 2 // TODO: make 30 again
		static let LongTimerInterval = 30
		static let TransitionDuration = 1 // TODO: make 0.3
	}
	
	
//	???: How about an enum in here? - wasn't recognized when used
// see https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/NestedTypes.html ???
//	enum UIElementTag: Int {
//		case IpAddress = 1234
//		case UserName = 1235
//		case Password = 1236
//	}
	
	init()
	{
		// runs once, called from appDel.
		
		let defaults = UserDefaults.standard
		let defaultValues = [
			UserDef.IpAddress : "??",
			UserDef.UserName : "??",
			UserDef.Password : "??",
			UserDef.LastUIVolumeStr : "??",
			UserDef.PresetStrArray : [String](),
			UserDef.PresetDicts: [Dictionary<Int, Any>]()
		] as [String : Any]
		defaults.register(defaults: defaultValues)
		defaults.synchronize()
	}
}


enum SshConnectionStatus: Int {
	case Succeded = 7845
	case Failed
	case InProgress
	case Unknown
}


enum OperationMode: Int {
	case Push = 1496
	case Pull
}
