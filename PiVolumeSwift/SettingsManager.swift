//
//  SettingsManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 7/31/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation


class SettingsManager
{
	
	static let sharedInstance: SettingsManager = {
		let instance = SettingsManager()
		
		return instance
	}()

	init() {
		// we'll be asked for SettingsProxies soon, when the VolVuCons load their views
		readFromUserDefs()
	}
	
	var masterArray = [SettingsProxy]()
	
	var userDefs = UserDefaults.standard
	
	
	func settingsWithIndex(_ idx: Int) -> SettingsProxy {
		
		if !(idx < masterArray.count) {
			let setPr = SettingsProxy()
			setPr.index = idx
			
			return setPr
		}
		
		return masterArray[idx]
	}
	
	func writeToUserDefsForVulVuCons(_ volVuCons: [VolumeViewController?]) {
		let allSettingsDicts = volVuCons.map{ $0?.settingsProxy.dictionaryRepresentation() }
		print("saving allSettingsDicts: \(allSettingsDicts)")
		userDefs.set(allSettingsDicts, forKey:K.UserDef.PresetDicts)
	}

	func writeToUserDefs() {
		// TODO: OBSOLETE
	}

	
	func readFromUserDefs() {
		if let arr = userDefs.object(forKey: K.UserDef.PresetDicts) as? [[String: Any]]  {
			
			masterArray = arr.map { SettingsProxy($0) }
			
		} else {
			masterArray = [SettingsProxy]()
		}
		print("masterArray: \(masterArray)")
	}
	
}
