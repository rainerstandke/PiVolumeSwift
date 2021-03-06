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

		static let TabCount = "kUsDef_TabCount"
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
		static let SettingsPrefix = "settings-"
	}
	
	struct UIStateRestoration {
		static let TabCount = "kTabCount"
		static let SelectedTab = "kSelectedTab"
	}

	static func prepUserDefaults() {
		// runs once, called from appDel. To init userDefs.
		
		let defaults = UserDefaults.standard
		let defaultValues = [
			K.UserDef.TabCount: 1
		]
		defaults.register(defaults: defaultValues)
		defaults.synchronize()
	}
}


enum SshConnectionStatus: String {
	case succeded = "ok"
	case failed = "failed"
	case inProgress = "…"
	case unknown = "??"
}


enum OperationMode: Int {
	case push = 1496
	case pull
}
