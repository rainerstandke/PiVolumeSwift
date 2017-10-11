//
//  SSHManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation
import NMSSH


// TODO: have long timeout during normal ops, short when doing settings










// NEXT: need to use settingsObject for connection parms - passin w/ notif • figure out when push is called w/o notif & why
// (deleayed til back home:) need access to pi - don't really understand when pushVolume is called w/ and w/o notifs. 2 possible avenues: could try to ALWAYS call with notif, and send volCon with notif, or possibly have one SSHMan for each volVuCon. GO WITH LATTER, make direct calls, ditch notifs












class SSHManager: NSObject {
	
	@objc override init() {
		
		opQueue = OperationQueue()
//		serialQueue = DispatchQueue(label: "biz.xmil.ssh_submission.serialQ", qos: .userInteractive)
		
		super.init()
		
//		opQueue.addObserver(self, forKeyPath: "operationCount", options: NSKeyValueObservingOptions.new, context: nil)
		opQueue.qualityOfService = .userInteractive
		opQueue.maxConcurrentOperationCount = 1
		
		
//		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.SliderMoved)"), object: nil, queue: OperationQueue.main, using: { [unowned self] (notif) in
//			self.pushVolumeToRemote(notif: notif)
//		})
		
		getVolumeFromRemote() // to populate label
	}
	
	var settingsPr = SettingsProxy()
	
//	let notifCtr = NotificationCenter.default
	let userDefs = UserDefaults.standard
	
//	let serialQueue: DispatchQueue
	let opQueue: OperationQueue
	
	var session: NMSSHSession?
	var lastInComingVolume: Float?
	var lastConfirmedVolume: Float?
	var timer: Timer?
	var connectionStatus: SshConnectionStatus = .Unknown {
		didSet {
//			print("SSHMan connectionStatus: \(connectionStatus)")
			// ???: alternative syntax? Complicated, long...
			NotificationCenter.default.post(name:NSNotification.Name(rawValue: K.Notif.SshConnectionStatusChanged),
			                                object:self,
			                                userInfo:[K.Key.ConnectionStatus : connectionStatus])
		}
	}
	
	// sharedInstance is a property on type SSHMan
	// block below runs once during first access, not afterwards - ???: why not?
//	static let sharedInstance: SSHManager = {
//		let instance = SSHManager()
//		
//		instance.opQueue.underlyingQueue = instance.serialQueue
//		instance.opQueue.qualityOfService = .userInteractive
//		instance.opQueue.maxConcurrentOperationCount = 1
//		
//		instance.opQueue.addObserver(instance, forKeyPath: "operationCount", options: NSKeyValueObservingOptions.new, context: nil)
//		
//		instance.notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.SliderMoved)"), object: nil, queue: OperationQueue.main, using: { [unowned instance] (notif) in
//			instance.pushVolumeToRemote(notif: notif)
//		})
//	
//		instance.getVolumeFromRemote() // to populate label
//		
//		return instance
//	}()
	
	
	deinit {
//		notifCtr.removeObserver(self)
		timer?.invalidate()
//		opQueue .removeObserver(self, forKeyPath: "operationCount")
	}
	
	
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
//		print("change: \(change)")
//		if change?[NSKeyValueChangeKey.newKey] as! Float == 0 {
//			pushVolumeToRemote(notif: nil)
//		}
//	}
	
//	func pushVolumeToRemote(notif: Notification?)
//	{
//		// can be called with and w/o notif
//		// w/ notif - update lastIncoming, then work on authenticate
//		// w/o notif - just use lastIncoming as last scheduledTimer
//		// should only be called w/o after op ran at least once, so that lastIncoming was set fer sure
//		// NOTE: incoming volume is float, like:133.958 - given to alsa on pi the post comma part is ignored - slider in UI seems to do the same
//
//		if let inComingVolume = notif?.userInfo?[K.Key.PercentValue] as? Float {
//			lastInComingVolume = floor(inComingVolume)
////			print("lastInComingVolume: \(lastInComingVolume!)")
//		} else { return }
//
//
//
//	}
	
	func pushVolumeToRemote() {
		if opQueue.operationCount > 0 {
			// throttle - if any operation is already underway just drop this one
			return
		}
		
//		if lastInComingVolume == lastConfirmedVolume {
//			// would be redundant, but confirm - turn black - whatever value is currently displayed in UI
//			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.ConfirmedVolume)"), object: self, userInfo: nil)
//			return
//		}
		
		
		let transmitOp = TransmitVolumeOperation(mode: .Push, sshMan: self)
		opQueue.addOperation(transmitOp)
		
		self.connectionStatus = .InProgress;
	}
	
	func getVolumeFromRemote()
	{
		
		return
		
		
		
		let transmitOp = TransmitVolumeOperation(mode: .Pull, sshMan: self)
		opQueue.addOperation(transmitOp)
		
		self.connectionStatus = .InProgress;
	}
	
	func resetConnectionTimeOut(_ interval: Double) {
		DispatchQueue.main.async {
			self.timer?.invalidate()
			
			//			var ti = Double(K.Misc.ShortTimerInterval)
			//			if self.mode == .Push {
			//				ti = Double(K.Misc.LongTimerInterval)
			//			}
			self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false, block: { (timer: Timer) in
				//				self.sshMan.serialQueue.async {
				print("connection timeout fired")
				self.session?.disconnect()
				self.session = nil
				// NOTE: no connectionStatus change // TODO?
				//				}
			})
		}
	}
}


class TransmitVolumeOperation : Operation
{
	let mode: OperationMode
	let sshMan: SSHManager
	
	init(mode: OperationMode, sshMan:SSHManager) {
		self.mode = mode
		self.sshMan = sshMan
	}
	
	let userDefs = UserDefaults.standard
	
	override func main() {
//		sshMan.lastConfirmedVolume = sshMan.lastInComingVolume
		
		if	sshMan.session == nil {
			let ipAdress = sshMan.settingsPr.ipAddress
			let userName = sshMan.settingsPr.userName
			
			sshMan.session = NMSSHSession.connect(toHost: ipAdress,
			                                      withUsername: userName)
		}
		
		func resetSession() {
			sshMan.session = nil // need to nil out
			sshMan.connectionStatus = .Failed;
		}
		
		guard let localSession: NMSSHSession = sshMan.session else {
			resetSession()
			return
		}
		
		if !localSession.isConnected {
			if !localSession.connect() {
				resetSession()
				return
			}
		}
		
		if !localSession.isAuthorized {
			let passWord = sshMan.settingsPr.password
			if !localSession.authenticate(byPassword: passWord) {
				resetSession()
				return
			}
		}
		

		var commandStr : String? = nil
		switch mode {
		case .Push:
			if let volStr = sshMan.settingsPr.pushVolume {
				commandStr = "amixer -c 0 cset numid=6 \(volStr)"
			}
		case.Pull:
			commandStr = "amixer -c 0 cget numid=6"
		}
		
		if commandStr == nil { sshMan.connectionStatus = .Failed; return }
		
		// set connection timeout on sshMan
		DispatchQueue.main.async {
			self.sshMan.timer?.invalidate()
			
			var ti: Double
			switch self.mode {
			case .Push:
				ti = K.Misc.ShortTimerInterval
			case .Pull:
				ti = K.Misc.ShortTimerInterval
			}
			
			self.sshMan.resetConnectionTimeOut(ti)
		}
		
		/* ???: how deal with this more succinctly - want to get a hold of error and guard let at the same time*/
//		do... catch
		guard let responseStr = try? localSession.channel.execute(commandStr) else { sshMan.connectionStatus = .Failed; return }
		print("responseStr: \(responseStr)")
		
		guard let resVolStr = volumeFromRemote(outputStr: responseStr) else { sshMan.connectionStatus = .Failed; return }
		print("push resVol: \(resVolStr)")
		
		sshMan.settingsPr.confirmedVolume = resVolStr
		
//		sshMan.notifCtr.post(name: NSNotification.Name("\(K.Notif.VolChanged)"), object: sshMan, userInfo: [K.Key.PercentValue: resVolStr])
		
		sshMan.connectionStatus = .Succeded
	}
	
	
	func volumeFromRemote(outputStr: String) -> String?
	{
		return regexMatch(inStr: outputStr, regexStr: "(?<=: values=)[0-9]{1,3}(?=,)")
		
//		let volStr = regexMatch(inStr: outputStr, regexStr: "(?<=: values=)[0-9]{1,3}(?=,)")
//
//		if volStr == nil {
//			return nil
//		}
//
//		return Int(volStr!)
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
