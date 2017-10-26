//
//  KeyChainManager.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 10/25/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import Foundation


struct KeyChainManager {
	func landing() {
//		readKeys()
//		try! deleteItem(keyClass: .Private)
//		try! deleteItem(keyClass: .Public)
		writeKeyFiles()
//		print("read: \(String(describing: readKeys()))")
	}
	
	func writeKeyFiles() {
		let urlResultTuple = documentURLs()
		if urlResultTuple.success == false {
			print("no key files found")
			return
		}
		print("urlResultTuple: \(urlResultTuple)")
		
		
		
//		writeKey(for: .Private)
		writeKey(for: .Public, with:urlResultTuple)
	}
	
	func writeKey(for keyClass: PVKeyClass, with urlResultTuple: (privateKeyURL: URL?, publicKeyURL: URL?, success: Bool)) {
		
		var readURL: URL?
		switch keyClass {
		case .Private:
			readURL = urlResultTuple.privateKeyURL!
		case .Public:
			readURL = urlResultTuple.publicKeyURL!
		}
		
		// try to just write, regardless of what may be there already
		guard let data = dataFrom(url: readURL!) else { return }
		let query = keyPutQueryDict(keyClass: .Private, payloadData: data)
		let status = SecItemAdd(query as CFDictionary, nil)
		
		switch status {
		case noErr:
			// delete file from disk
			try! FileManager.default.removeItem(at: readURL!)
		case errSecDuplicateItem:
			// update existing key
			var attributesToUpdate = [String : AnyObject]()
			attributesToUpdate[kSecValueData as String] = data as AnyObject?
			let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
			
			if status != noErr {
				print("Error updating Keychain: \(status)")
				return
			}
			try! FileManager.default.removeItem(at: readURL!)
		default:
			print("Error writing to Keychain: \(status)")
		}
	}
	
	
	func readKeys() -> (privateKeyStr: String, publicKeyString: String)? {
		//
		
		// Note:  wanted use kSecAttrApplicationLabel to see if the 2 keys belong together, since the value of this attribute is supposedly the hash of the public key. BUT does not work, returns '<>'?
		
		// local func to return key as string
		func keyStr(for keyClass: PVKeyClass) -> String?  {
			let query = keyPullDict(keyClass: keyClass)
			
			// Try to fetch the existing keychain item that matches the query.
			var queryResult: AnyObject?
			let status = withUnsafeMutablePointer(to: &queryResult) {
				SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
			}
			if status != noErr {
				print("key read error: \(status)")
				return nil
			}
			
			guard let resDict = queryResult as? [String : AnyObject],
				let keyData = resDict[kSecValueData as String],
				let keyStr = String.init(data: keyData as! Data, encoding: .utf8)
				else { return nil}
			
			return keyStr
		}
		
		if let privKeyStr = keyStr(for: .Private),
			let pubKeyStr =  keyStr(for: .Public) {
			return (privKeyStr, pubKeyStr)
		} else {
			return nil
		}
	}
	
	func deleteItem(keyClass: PVKeyClass) throws {
		// Delete the existing item from the keychain.
		let query = keyPullDict(keyClass: keyClass)
		let status = SecItemDelete(query as CFDictionary)
		print("delete status: \(status)")
	}
	
	
	private func dataFrom(url: URL) -> Data? {
		return try? Data.init(contentsOf: url)
	}
	
	private func documentURLs() -> (privateKeyURL: URL?, publicKeyURL: URL?, success: Bool) {
		// go look for exactly 2 files in all of doc dir. Need to be a private and a public key (based on text prefix)
		let docDirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//		print("docDirURL: \(docDirURL)")
		
		let fileURLs = try! FileManager.default.contentsOfDirectory(at: docDirURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
		
		var pubReturnURL: URL? = nil
		var privReturnURL: URL? = nil
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
			
		let success = fileURLs.count == 2 && pubReturnURL != nil && privReturnURL != nil
		
		return (privReturnURL, pubReturnURL, success)
	}
	
	private func keyQueryDict(keyClass: PVKeyClass) -> [String: AnyObject] {
		// make a dictionary to be used in a search query
		var keyClassStr: CFString? = nil
		var label = "PiVolume - "
		switch keyClass {
		case .Private:
			keyClassStr = kSecAttrKeyClassPrivate
			label += "Private Key"
		case .Public:
			keyClassStr = kSecAttrKeyClassPublic
			label += "Public Key"
		}
		
		let queryDict: [String: AnyObject] = [
			kSecClass as String: kSecClassKey, // we're talking about a Key
			kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
			kSecAttrKeyClass as String: keyClassStr!,
			kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
			kSecAttrLabel as String: label as AnyObject
		]
		// Could add label designating different Pis... but won't
		
		return queryDict
	}
	
	private func keyPutQueryDict(keyClass: PVKeyClass, payloadData: Data) -> [String: AnyObject] {
		// make a dictionary to be used in a writing query
		var queryDict = keyQueryDict(keyClass: keyClass)
		queryDict[kSecValueData as String] = payloadData as AnyObject
		return queryDict
	}
	
	private func keyPullDict(keyClass: PVKeyClass) -> [String: AnyObject] {
		// make a dictionary to be used in a generic query
		var queryDict = keyQueryDict(keyClass: keyClass)
		queryDict[kSecMatchLimit as String] = kSecMatchLimitOne
		queryDict[kSecReturnAttributes as String] = kCFBooleanTrue
		queryDict[kSecReturnData as String] = kCFBooleanTrue
		return queryDict
	}
	
	enum PVKeyClass: Int {
		case Private = 10
		case Public
	}
}

