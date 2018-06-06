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
			// extend notif name w/ static let
			NotificationCenter.default.post(name:NSNotification.Name(rawValue: K.Notif.SshConnectionStatusChanged),
											object:self,
											userInfo:[K.Key.ConnectionStatus : connectionStatus])
		}
	}
	
	@objc override init() {
		opQueue = OperationQueue()
		opQueue.qualityOfService = .userInteractive
		opQueue.maxConcurrentOperationCount = 1
		
		super.init()
	}
	
	deinit {
		timer?.invalidate()
	}
	
	
	func pushVolumeToRemote() {
		if opQueue.operationCount > 0 {
			// throttle - if any operation is already underway just drop this one
//			print("drop")
			return
		}
//		print("settingsPr.pushVolume: \(String(describing: settingsPr.pushVolume))")

		if settingsPr.pushVolume == lastInComingVolume {
			// new value is no change vs confirmed value
			// since the slider can move and not produce a new *Int* value (from a *different* float value), and the slider is turned grey even then, we need to turn it black here
			getVolumeFromRemote()
//			print("redundant")
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
//		print("interval: \(String(describing: interval))")
		// called from TransmitOp for automatic disconnect
		DispatchQueue.main.async {
			self.timer?.invalidate()
			
			self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: false, block: { (timer: Timer) in
//				print(" • disconnect")
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
//			print("• new session")
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
//			print("• connect")
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
		
		guard let commandStr = { () -> String? in
			switch self.mode {
			case .Push:
				guard let volStr = localSshMan.settingsPr.pushVolume else { return nil }
				return "amixer -c 0 cset numid=6 \(volStr)"
			case.Pull:
				return "amixer -c 0 cget numid=6"
			}
		}() else { localSshMan.connectionStatus = .Failed; return }
		
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
		guard let regex = try? NSRegularExpression(pattern: regexStr, options: []),
			let res = regex.firstMatch(in: inStr,
									   options: [],
									   range: NSRange(location: 0, length: inStr.utf16.count))
			else { return nil }
		
		return (inStr as NSString).substring(with: res.range)
	}
}
