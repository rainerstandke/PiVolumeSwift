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
	}
	
	struct Notif {
		static let VolChanged = "kNotif_VolumeChanged"
		static let SliderMoved = "kNotif_SliderMoved"
	}
	
	struct Key {
		static let PercentValue = "kKey_PercentValue"
	}
	
	struct UIElementTag {
		static let IpAddress = 1234
		static let UserName = 1235
		static let Password = 1236
	}
	
//	// ???: How about an enum in here? - wasn't recognized when used
//	enum UIElementTag: Int {
//		case IpAddress = 1234
//		case UserName = 1235
//		case Password = 1236
//	}
	
	
}


