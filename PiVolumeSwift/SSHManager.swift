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


class SSHManager: NSObject {
	
	let notifCtr = NotificationCenter.default
	let userDefs = UserDefaults.standard
	
	let serialQueue = DispatchQueue(label: "biz.xmil.ssh_submission.serialQ", qos: .userInteractive)
	let opQueue = OperationQueue()
	
	var session: NMSSHSession?
	var lastInComingVolume: Float?
	var lastProcessedVolume: Float?
	var timer: Timer?
	var connectionStatus: SshConnectionStatus = .Unknown {
		didSet {
			print("SSHMan connectionStatus: \(connectionStatus)")
			// ???: alternative syntax? Complicated, long...
			NotificationCenter.default.post(name:NSNotification.Name("\(K.Notif.SshConnectionStatusChanged)"),
			                                object:self,
			                                userInfo:[K.Key.ConnectionStatus : connectionStatus])
		}
	}
	
	// ???: construct OK for singleton?
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
		// NOTE: incoming volume is float, like:133.958 - given to alsa on pi the post comma part is ignored - slider in UI seems to do the same
		
		if let inComingVolume = notif?.userInfo?[K.Key.PercentValue] as? Float {
			lastInComingVolume = floor(inComingVolume)
			print("lastInComingVolume: \(lastInComingVolume!)")
		} else { return }
		
		if opQueue.operationCount > 0 {
			// throttle
			return
		}
		
		if lastInComingVolume == lastProcessedVolume {
			// would be redundant, but confirm - turn black - whatever value is currently displayed in UI
			self.notifCtr.post(name: NSNotification.Name("\(K.Notif.ConfirmedVolume)"), object: self, userInfo: nil)
			return
		}
		
		
		let transmitOp = TransmitVolumeOperation(mode: .Push, sshMan: self)
		opQueue.addOperation(transmitOp)
		
		self.connectionStatus = .InProgress;
	}
	
	func getVolumeFromRemote()
	{
		let transmitOp = TransmitVolumeOperation(mode: .Pull, sshMan: self)
		opQueue.addOperation(transmitOp)
		
		self.connectionStatus = .InProgress;
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
		sshMan.lastProcessedVolume = sshMan.lastInComingVolume
		
		if	sshMan.session == nil {
			sshMan.session = NMSSHSession.connect(toHost: self.userDefs.string(forKey: K.UserDef.IpAddress),
			                                    withUsername: self.userDefs.string(forKey: K.UserDef.UserName))
		}
		
		// ??: good construct? - 'local' function?
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
			if !localSession.authenticate(byPassword: self.userDefs.string(forKey:K.UserDef.Password)) {
				resetSession()
				return
			}
		}
		

		var commandStr : String? = nil
		switch mode {
		case .Push:
			commandStr = "amixer -c 0 cset numid=6 \(sshMan.lastInComingVolume!)"
		case.Pull:
			commandStr = "amixer -c 0 cget numid=6"
		}
		
		if commandStr == nil { sshMan.connectionStatus = .Failed; return }
		
		/* ???: how deal with this more succinctly - want to get a hold of error and guard let at the same time*/
		guard let response = try? localSession.channel.execute(commandStr) else { sshMan.connectionStatus = .Failed; return }
		
		DispatchQueue.main.async {
			self.sshMan.timer?.invalidate()
			
			var ti = Double(K.Misc.ShortTimerInterval)
			if self.mode == .Push {
				ti = Double(K.Misc.LongTimerInterval)
			}
			self.sshMan.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(ti), repeats: false, block: { (timer: Timer) in
				self.sshMan.serialQueue.async {
					print("timer fired")
					self.sshMan.session?.disconnect()
					self.sshMan.session = nil
					// NOTE: no connectionStatus change
				}
			})
		}
		
		guard let resVol = volumeFromRemote(outputStr: response) else { sshMan.connectionStatus = .Failed; return }
		print("push resVol: \(resVol)")
		
		sshMan.notifCtr.post(name: NSNotification.Name("\(K.Notif.VolChanged)"), object: sshMan, userInfo: [K.Key.PercentValue: resVol])
		
		sshMan.connectionStatus = .Succeded
	}
	
	
	func volumeFromRemote(outputStr: String) -> Int?
	{
		let volStr = regexMatch(inStr: outputStr, regexStr: "(?<=: values=)[0-9]{1,3}(?=,)")
		
		if volStr == nil {
			return nil
		}
		
		return Int(volStr!)
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
