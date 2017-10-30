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
//		static let PresetStrArray = "kPresetStrArray"
		
//		static let PresetDicts = "kPresetDicts"
	}
	
	struct Notif {
		static let SliderMoved = "kNotif_SliderMoved"
		static let SshConnectionStatusChanged = "kSshConnectionStatusChanged"
	}
	
	struct Key {
		static let ConnectionStatus = "kConnectionStatus"
	}
	
	struct UIElementTag {
		static let PresetButton = 9958
	}
	
	struct CellID {
		static let PresetTableViewCell = "kPresetTableViewCell"
	}
	
	struct Misc {
	static let TimerInterval: Double = 3 // TODO: make 30 again
	}
	
	
	init() {
		// runs once, called from appDel. To init userDefs.
		
		let defaults = UserDefaults.standard
		let defaultValues = [
//			UserDef.IpAddress : "??",
//			UserDef.UserName : "??",
//			UserDef.Password : "??",
//			UserDef.LastUIVolumeStr : "??",
//			UserDef.PresetStrArray : [String](),
//			UserDef.PresetDicts: [Dictionary<Int, Any>]()
			:] as [String : Any]
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
