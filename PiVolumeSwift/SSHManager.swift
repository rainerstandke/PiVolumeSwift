//
//  SSHManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation
import NMSSH

class SSHManager: NSObject {
	
	let notifCtr = NotificationCenter.default
	let userDefs = UserDefaults.standard
	
	let serialQueue = DispatchQueue(label: "biz.xmil.ssh_submission.serialQ", qos: .userInteractive)
	let opQueue = OperationQueue()
	
	var session: NMSSHSession?
	var lastInComingVolume: Float?
	var lastProcessedVolume: Float?
	var timer: Timer?
	
	static let sharedInstance: SSHManager = {
		let instance = SSHManager()
		
		instance.opQueue.underlyingQueue = instance.serialQueue
		instance.opQueue.qualityOfService = .userInteractive
		instance.opQueue.maxConcurrentOperationCount = 1
		
		instance.opQueue.addObserver(instance, forKeyPath: "operationCount", options: NSKeyValueObservingOptions.new, context: nil)
		
		instance.notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.SliderMoved)"), object: nil, queue: OperationQueue.main, using: { [unowned instance] (notif) in
			instance.pushVolumeToRemote(notif: notif)
		})
		
		return instance
	}()
	
	deinit {
		notifCtr.removeObserver(self)
		timer?.invalidate()
		opQueue .removeObserver(self, forKeyPath: "operationCount")
	}
	
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if change?[NSKeyValueChangeKey.newKey] as! Float == 0 {
			pushVolumeToRemote(notif: nil)
		}
	}
	
	func pushVolumeToRemote(notif: Notification?)
	{
		
		if let inComingVolume = notif?.userInfo?[K.Key.PercentValue] as? Float {
			lastInComingVolume = inComingVolume
			print("lastInComingVolume: \(lastInComingVolume)")
		}
		
		
		if ( lastInComingVolume! < 0) {
			// should not happen, but still...
			return
		}
		
		if opQueue.operationCount > 0 {
			// throttle
			return;
		}
		
		if lastInComingVolume == lastProcessedVolume {
			// would be redundant
			return;
		}
		
		
		opQueue.addOperation { 
			self.lastProcessedVolume = self.lastInComingVolume

			if	self.session == nil {
				self.session = NMSSHSession.connect(toHost: self.userDefs.string(forKey: K.UserDef.IpAddress),
				                                    withUsername: self.userDefs.string(forKey: K.UserDef.UserName))
			}
			
			if !(self.session?.isConnected)! {
				if	!(self.session?.connect())! {
					return
				}
			}
			
			if !(self.session?.isAuthorized)! {
				if !(self.session?.authenticate(byPassword: self.userDefs.string(forKey:K.UserDef.Password)))! {
					return
				}
			}
			
			let commandStr = String("amixer -c 0 cset numid=6 \(self.lastInComingVolume!)%")
			
			let response = try! self.session?.channel.execute(commandStr)
			
			let resVol = self.volumeFromRemote(outputStr: response!)
			print("resVol: \(resVol!)")
			
			if resVol == nil {
				return
			}

			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.VolChanged)"), object: self, userInfo: [K.Key.PercentValue: resVol!])
			
			DispatchQueue.main.async {
				self.timer?.invalidate()
				self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (t: Timer) in
					print("t: \(t)")
					self.serialQueue.async {
						self.session?.disconnect()
						self.session = nil
					}
				})
			}
		}
	}

	
	func volumeFromRemote(outputStr: String) -> Int?
	{
		let volStr = regexMatch(inStr: outputStr, regexStr: "(?<=: values=)[0-9]{1,3}(?=,)")
		
		if volStr == nil {
			return nil
		}
		
		let perCent = ((volStr! as NSString).floatValue) * 100 / 151
		
		return Int(perCent.rounded(.toNearestOrAwayFromZero))
	}
	
	
	func regexMatch(inStr: String, regexStr: String) -> String?
	{
		let regex = try! NSRegularExpression(pattern: regexStr, options: [])
		
		let res = regex.firstMatch(in: inStr,
		                           options: [],
		                           range: NSRange(location: 0, length: inStr.utf16.count))
		
		if res == nil {
			return nil
		}
		
		return (inStr as NSString).substring(with: res!.range)
	}
	
}



