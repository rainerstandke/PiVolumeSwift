//
//  OutlinedButton.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/17/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit


@IBDesignable
class OutlinedButton: UIButton {
	// add outline to button
	
	@IBInspectable var cornerRadius: CGFloat {
		get {
			return layer.cornerRadius
		}
		set {
			layer.cornerRadius = newValue
			layer.masksToBounds = newValue > 0
		}
	}
	
	@IBInspectable var borderWidth: CGFloat {
		get {
			return layer.borderWidth
		}
		set {
			layer.borderWidth = newValue
			layer.masksToBounds = newValue > 0
		}
	}
	
	@IBInspectable var borderColor: UIColor {
		get {
			return UIColor.init(cgColor: layer.borderColor!)
		}
		set {
			layer.borderColor = newValue.cgColor
		}
	}
}
