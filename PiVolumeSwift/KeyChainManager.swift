//
//  KeyChainManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 10/25/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//




/*


handle public private key pair for ssh into Pis, storing in KeyChain
limited to one key pair used for any and all raspberry pis


*/




import Foundation


class KeyChainManager {
	
	// prevent init from outside
	private init() {
	}
	
	static let shared = KeyChainManager()
	
	
	func landing() {
		// for debug... / UNUSED
		writeKeyFiles()
		print("read: \(String(describing: readKeys()))")
	}
	
	func writeKeyFiles() {
		// see if there are exactly 2 files in our doc folder - put there by iTunes file sharing - that are likely enough to be a public/private key pair
		// if so read them as data and put them into keyChain, afterwards delete file
		// assumptions: no password on private key, same key for all Pis
		
		guard let urlResultTuple = documentURLs() else { return }

		// return type : Alamo fire / make tuple ingredients non optional, tuple optional
		func writeKey(for keyClass: PVKeyClass, with readURL: URL) {
			
			// try to just write, regardless of what may be there already
			guard let data = dataFrom(url: readURL) else { return }
			let query = keyPutQueryDict(keyClass: keyClass, payloadData: data)
			let status = SecItemAdd(query as CFDictionary, nil)
			
			switch status {
			case noErr:
				// delete file from disk
				try? FileManager.default.removeItem(at: readURL)
				break
			case errSecDuplicateItem:
				// update existing key
				var attributesToUpdate = [String : AnyObject]()
				attributesToUpdate[kSecValueData as String] = data as AnyObject?
				let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
				
				if status != noErr {
					print("Error updating Keychain: \(status)")
					return
				}
				try? FileManager.default.removeItem(at: readURL)
			default:
				print("Error writing to Keychain: \(status)")
			}
		}
		
		writeKey(for: .privateKey, with:urlResultTuple.privateKeyURL)
		writeKey(for: .publicKey, with:urlResultTuple.privateKeyURL)
	}
	
	
	func readKeys() -> (privateKeyStr: String, publicKeyString: String)? {
		// read keys from keychain
		
		// Note:  wanted use kSecAttrApplicationLabel to see if the 2 keys belong together, since the value of this attribute is supposedly the hash of the public key. BUT does not work, returns '<>'? Maybe the doc only applies to symetric key pairs, or to generated key pairs?
		
		// local func to return key as string
		func keyStr(for keyClass: PVKeyClass) -> String?  {
			let query = keyPullDict(keyClass: keyClass)
			
			// Try to fetch the existing keychain item that matches the query.
			var queryResult: AnyObject?
			let status = withUnsafeMutablePointer(to: &queryResult) {
				SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
			}
			
			guard status == noErr else {
				print("key read error: \(status)")
				return nil
			}
			
			guard let resDict = queryResult as? [String : AnyObject],
				let keyData = resDict[kSecValueData as String],
				let keyStr = String.init(data: keyData as! Data, encoding: .utf8)
				else { return nil }
			
			return keyStr
		}
		
		// enum instance lower case
		if let privKeyStr = keyStr(for: .privateKey),
			let pubKeyStr =  keyStr(for: .publicKey) {
			return (privKeyStr, pubKeyStr)
		} else {
			return nil
		}
	}
	
	func deleteItem(keyClass: PVKeyClass) throws {
		// UNUSED
		// Delete the existing item from the keychain.
		let query = keyQueryDict(keyClass: keyClass)
		let status = SecItemDelete(query as CFDictionary)
		if status != noErr {
			print("delete error: \(status)")
		}
	}
	
	
	private func dataFrom(url: URL) -> Data? {
		// convenience
		return try? Data.init(contentsOf: url)
	}
	
	private func documentURLs() -> (privateKeyURL: URL, publicKeyURL: URL)? {
		// go look for exactly 2 files in all of doc dir. Need to be a private and a public key (based on text prefix)
		let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		
		// guard let try?
		guard let fileURLs = try? FileManager.default.contentsOfDirectory(at: docDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else { return nil }
		
		var pubReturnURL: URL?
		var privReturnURL: URL?
		for fileURL in fileURLs {
			if fileURL.pathExtension == "pub" {
				let pubKey = try! String.init(contentsOf: fileURL)
				if pubKey.hasPrefix("ssh-rsa ") {
					pubReturnURL = fileURL
					continue
				}
			}  else if fileURL.pathExtension == "" {
				let privKey = try! String.init(contentsOf: fileURL)
				if privKey.hasPrefix("-----BEGIN RSA PRIVATE KEY-----") {
					privReturnURL = fileURL
				}
			}
		}
		
		guard let privURL = privReturnURL,
			let pubURL = pubReturnURL else { return nil }
		
		return (privURL, pubURL)
	}
	
	private func keyQueryDict(keyClass: PVKeyClass) -> [String: AnyObject] {
		// make a dictionary to be used in a generic query
		var keyClassStr: CFString? = nil
		var label = "PiVolume - "
		switch keyClass {
		case .privateKey:
			keyClassStr = kSecAttrKeyClassPrivate
			label += "Private Key"
		case .publicKey:
			keyClassStr = kSecAttrKeyClassPublic
			label += "Public Key"
		}
		
		let queryDict: [String: AnyObject] = [
			kSecClass as String: kSecClassKey, // we're talking about a Key (not a Cert, or so)
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
			kSecAttrKeyClass as String: keyClassStr!,
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrLabel as String: label as AnyObject
		]
		// Could add label designating different Pis... but won't -> relying on one key only for all possible Pis
		
		return queryDict
	}
	
	private func keyPutQueryDict(keyClass: PVKeyClass, payloadData: Data) -> [String: AnyObject] {
		// make a dictionary to be used in a writing query
		var queryDict = keyQueryDict(keyClass: keyClass)
		queryDict[kSecValueData as String] = payloadData as AnyObject
		return queryDict
	}
	
	private func keyPullDict(keyClass: PVKeyClass) -> [String: AnyObject] {
		// make a dictionary to be used in a search query
		var queryDict = keyQueryDict(keyClass: keyClass)
		queryDict[kSecMatchLimit as String] = kSecMatchLimitOne
		queryDict[kSecReturnAttributes as String] = kCFBooleanTrue
		queryDict[kSecReturnData as String] = kCFBooleanTrue
		return queryDict
	}
	
	enum PVKeyClass: Int {
		case privateKey = 10
		case publicKey
	}
}

