//
//  UIViewController+Extensions.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 5/15/18.
//  Copyright © 2018 Rainer Standke. All rights reserved.
//

import UIKit


extension UIViewController {
	// based on: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	
	func descendantViewControllers<T>(of type: T.Type) -> [T] {
		var retArr = [T]()
		for vuCon in childViewControllers {
			if vuCon is T {
				retArr.append(vuCon as! T)
			}
			retArr.append(contentsOf: vuCon.descendantViewControllers(of: T.self))
		}
		return retArr.compactMap{ $0 }
	}
	
	
	func descendantViewController<T>(ofType type:T.Type) -> T? {
		//
		for childVuCon in childViewControllers {
			if let typedVuCon = childVuCon as? T {
				return typedVuCon
			} else {
				return childVuCon.descendantViewControllers(of: T.self) as? T
			}
		}
		
		return nil
	}
}


extension UIViewController {
	// based on: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	
	func ancestorViewController<T>(of type: T.Type) -> T? {
		return parent as? T ?? parent.flatMap { $0.ancestorViewController(of: T.self) }
	}
}


