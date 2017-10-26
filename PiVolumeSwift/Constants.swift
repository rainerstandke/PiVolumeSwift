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
		static let SshConnectionStatusChanged = "kSshConnectionStatusChanged"
		static let AddTabBarItem = "kAddTabBarItem"
		static let DeleteTabBarItem = "kDeleteTabBarItem"
	}
	
	struct Key {
		static let PercentValue = "kKey_PercentValue"
		static let ConnectionStatus = "kConnectionStatus"
	}
	
	struct UIElementTag { // OBSOLETE?
		static let IpAddress = 1234
		static let UserName = 1235
		static let Password = 1236
		
		static let PresetButton = 9958
	}
	
	struct CellID {
		static let PresetTableViewCell = "kPresetTableViewCell"
	}
	
	struct Misc {

		static let TimerInterval: Double = 30 // TODO: make 30 again
		static let TransitionDuration = 1 // TODO: make 0.3
	}
	
	
	init() {
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


enum SshConnectionStatus: String {
	case Succeded = "ok"
	case Failed = "failed"
	case InProgress = "…"
	case Unknown = "??"
}


enum OperationMode: Int {
	case Push = 1496
	case Pull
}
