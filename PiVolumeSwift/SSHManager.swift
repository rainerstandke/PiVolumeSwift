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
	
		instance.getVolumeFromRemote() // to populate label
		
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
		// can be called with and w/o notif
		// w/ notif - update lastIncoming, then work on authenticate
		// w/o notif - just use lastIncoming as last scheduledTimer
		// should only be called w/o after op ran at least once, so that lastIncoming was set fer sure
		
		if let inComingVolume = notif?.userInfo?[K.Key.PercentValue] as? Float {
			lastInComingVolume = inComingVolume
			print("lastInComingVolume: \(lastInComingVolume!)")
		}
		
		if opQueue.operationCount > 0 {
			// throttle
			return;
		}
		
		if lastInComingVolume == lastProcessedVolume {
			// would be redundant, but confirm - turn black - whatever value is currently displayed in UI
			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.ConfirmedVolume)"), object: self, userInfo: nil)
			return;
		}
		
		opQueue.addOperation {
			self.lastProcessedVolume = self.lastInComingVolume
			
			if	self.session == nil {
				self.session = NMSSHSession.connect(toHost: self.userDefs.string(forKey: K.UserDef.IpAddress),
				                                    withUsername: self.userDefs.string(forKey: K.UserDef.UserName))
			}
			
			guard let localSession: NMSSHSession = self.session else { return }
			
			if !localSession.isConnected {
				if !localSession.connect() { return } // TODO: tell user
			}
			
			if !localSession.isAuthorized {
				if !localSession.authenticate(byPassword: self.userDefs.string(forKey:K.UserDef.Password)) { return }  // TODO: tell user
			}
			
			guard let commandStr = String("amixer -c 0 cset numid=6 \(self.lastInComingVolume!)%") else { return }
			print("commandStr: \(commandStr)")
			
			/*???: how deal with this more succinctly - want to get a hold of error and guard let at the same time*/
			guard let response = try? localSession.channel.execute(commandStr) else { return }
			
			DispatchQueue.main.async {
				self.timer?.invalidate()
				self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (timer: Timer) in
					self.serialQueue.async {
						print("push timer fired")
						self.session?.disconnect()
						self.session = nil
					}
				})
			}
			
			guard let resVol = self.volumeFromRemote(outputStr: response) else { return }
			print("push resVol: \(resVol)")
			
			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.VolChanged)"), object: self, userInfo: [K.Key.PercentValue: resVol])
		}
	}
	
	func getVolumeFromRemote()
	{
		opQueue.addOperation {
			
			if	self.session == nil {
				self.session = NMSSHSession.connect(toHost: self.userDefs.string(forKey: K.UserDef.IpAddress),
				                                    withUsername: self.userDefs.string(forKey: K.UserDef.UserName))
			}
			
			guard let localSession: NMSSHSession = self.session else { return }
			
			if !localSession.isConnected {
				if !localSession.connect() { return }
			}
			
			if !localSession.isAuthorized {
				if !localSession.authenticate(byPassword: self.userDefs.string(forKey:K.UserDef.Password)) { return }
			}
			
			/*???: how deal with this more succinctly - want to get a hold of error and guard let at the same time*/
			guard let response = try? localSession.channel.execute("amixer -c 0 cget numid=6") else { return }
			
			DispatchQueue.main.async {
				self.timer?.invalidate()
				self.timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (timer: Timer) in
					self.serialQueue.async {
						print("get timer fired")
						self.session?.disconnect()
						self.session = nil
					}
				})
			}
			
			guard let resVol = self.volumeFromRemote(outputStr: response) else { return }
			print("get resVol: \(resVol)")
			
			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.VolChanged)"), object: self, userInfo: [K.Key.PercentValue: resVol])
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



