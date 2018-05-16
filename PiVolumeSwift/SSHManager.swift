//
//  SSHManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//



/* manages secure shell communications with rasperry pi */



import Foundation
import NMSSH

class SSHManager: NSObject {
	
	@objc override init() {
		opQueue = OperationQueue()
		opQueue.qualityOfService = .userInteractive
		opQueue.maxConcurrentOperationCount = 1
		
		super.init()
	}
	
	var settingsPr = SettingsProxy() {
		didSet {
			opsCountObservation =  opQueue.observe(\.operationCount, options: [.new]) { (opQ, change) in
				// if all ops are done and the slider has been moved beyond the last actually pushed volume, then just push the last known volume
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
			getVolumeFromRemote()
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


/* represents one single transaction between iOS device and raspberry pi */

class TransmitVolumeOperation : Operation
{
	let mode: OperationMode
	weak var sshMan: SSHManager?
	
	init(mode: OperationMode, sshMan:SSHManager) {
		self.mode = mode // push or pull
		self.sshMan = sshMan
	}
	
	let userDefs = UserDefaults.standard
	
	override func main() {
		guard let localSshMan = sshMan else { print("no sshMan in transmit op"); return  }
		if	localSshMan.session == nil {
			localSshMan.session = NMSSHSession.connect(toHost: localSshMan.settingsPr.ipAddress,
													   withUsername: localSshMan.settingsPr.userName)
		}
		
		// local func
		func resetSession() {
			localSshMan.session = nil // need to nil out
			localSshMan.connectionStatus = .Failed;
		}
		
		guard let localSession: NMSSHSession = localSshMan.session else {
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
			if let volStr = localSshMan.settingsPr.pushVolume {
				commandStr = "amixer -c 0 cset numid=6 \(volStr)"
			}
		case.Pull:
			commandStr = "amixer -c 0 cget numid=6"
		}
		
		if commandStr == nil { localSshMan.connectionStatus = .Failed; return }
		
		// set connection timeout on sshMan
		DispatchQueue.main.async {
			localSshMan.timer?.invalidate()
			localSshMan.resetConnectionTimeOut(K.Misc.TimerInterval)
		}
		
		guard let responseStr = try? localSession.channel.execute(commandStr) else { localSshMan.connectionStatus = .Failed; return }
		
		guard let resVolStr = volumeFromRemote(outputStr: responseStr) else { localSshMan.connectionStatus = .Failed; return }
		
		// this will trigger observation in VolVuCon -> ui update
		localSshMan.settingsPr.confirmedVolume = resVolStr

		localSshMan.connectionStatus = .Succeded
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
