//
//  NavCon.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/22/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class NavCon: UINavigationController
{
//	override func awakeFromNib() {
//		
//	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
//		print("LOAD navigationBar.frame: \(navigationBar.frame)")
		// NOTE: this DOES make a difference in navBar jump
		navigationBar.frame = navigationBar.frame.offsetBy(dx: 0, dy: 20)
//		print("LOAD 2 navigationBar.frame: \(navigationBar.frame)")
		
		
		
		// TODO: this seems BAD, to have literal offset value
	}
	
	override func viewWillLayoutSubviews() {
		print("WILL navigationBar.frame: \(navigationBar.frame)")
		
	}
	
	override func viewDidLayoutSubviews() {
//		print("DID navigationBar.frame: \(navigationBar.frame)")
	}
	
}
