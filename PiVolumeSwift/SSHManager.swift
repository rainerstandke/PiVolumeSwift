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
	
	@objc override init() {
		
		opQueue = OperationQueue()
		
		super.init()
		
		opQueue.qualityOfService = .userInteractive
		opQueue.maxConcurrentOperationCount = 1
	}
	
	var settingsPr = SettingsProxy() {
		didSet {
			opsCountObservation =  opQueue.observe(\.operationCount, options: [.new]) { (opQ, change) in
				// if all ops are done and the slider has been moved beyond the last actually pushed volume, then just push the last know volume
				if change.newValue == 0 {
					if self.settingsPr.pushVolume != self.lastInComingVolume {
						self.pushVolumeToRemote()
					}
				}
			}
		}
	}
	
	let opQueue: OperationQueue
	var opsCountObservation: NSKeyValueObservation?
	
	var session: NMSSHSession?
	var lastInComingVolume: String?
	var timer: Timer?
	var connectionStatus: SshConnectionStatus = .Unknown {
		// whenever the status changes send notif - SettingsVuCon could be listening
		didSet {
			NotificationCenter.default.post(name:NSNotification.Name(rawValue: K.Notif.SshConnectionStatusChanged),
			                                object:self,
			                                userInfo:[K.Key.ConnectionStatus : connectionStatus])
		}
	}
	
	deinit {
		timer?.invalidate()
	}
	
	
	func pushVolumeToRemote() {
		if opQueue.operationCount > 0 {
			// throttle - if any operation is already underway just drop this one
			return
		}
		
		if settingsPr.pushVolume == lastInComingVolume {
			// new value is no change vs confirmed value
			// since the slider can move and not produce a new *Int* value (from a *different* float value), and the slider is turned grey even then, we need to turn it black here
			settingsPr.confirmedVolume = lastInComingVolume
			return
		}
		
		// remember this one for next time around
		lastInComingVolume = settingsPr.pushVolume
		
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
	
	func resetConnectionTimeOut(_ interval: Double) {
		// called from TransmitOp for automatic disconnect
		DispatchQueue.main.async {
			self.timer?.invalidate()
			
			self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false, block: { (timer: Timer) in
				self.session?.disconnect()
				self.session = nil
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

		if	sshMan.session == nil {
			sshMan.session = NMSSHSession.connect(toHost: sshMan.settingsPr.ipAddress,
			                                      withUsername: sshMan.settingsPr.userName)
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
			let keyPair = KeyChainManager.shared.readKeys()
			if let privKey = keyPair?.privateKeyStr,
				let pubKey = keyPair?.publicKeyString {
				
				if !localSession.authenticateBy(inMemoryPublicKey: pubKey,
				                                privateKey: privKey,
				                                andPassword: "") {
					resetSession()
					return
				}
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
			
			self.sshMan.resetConnectionTimeOut(K.Misc.TimerInterval)
		}
		
		/* ???: how deal with this more succinctly - want to get a hold of error and guard let at the same time*/
//		do... catch
		guard let responseStr = try? localSession.channel.execute(commandStr) else { sshMan.connectionStatus = .Failed; return }
		
		guard let resVolStr = volumeFromRemote(outputStr: responseStr) else { sshMan.connectionStatus = .Failed; return }
		
		// this will trigger observation in VolVuCon -> ui update
		sshMan.settingsPr.confirmedVolume = resVolStr

		sshMan.connectionStatus = .Succeded
	}
	
	
	func volumeFromRemote(outputStr: String) -> String?
	{
		return regexMatch(inStr: outputStr, regexStr: "(?<=: values=)[0-9]{1,3}(?=,)")
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
