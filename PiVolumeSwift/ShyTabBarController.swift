//
//  ShyTabBarController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/17/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class ShyTabBarController: UITabBarController
{
	
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("tabBar.frame: \(tabBar.frame)")
		
		
		print("tabBar.items: \(tabBar.items)")
		
		if (tabBar.items?.count)! < 2 {
			tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: tabBar.frame.size.height)
			tabBar.isHidden = true
			
			// TODO: animate up & unhide when adding
		}
		
		
		NotificationCenter.default.addObserver(
			forName: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: nil,
			queue: OperationQueue.main) { (notif) in
				print("need to add item")
				
				
				
				// NEXT: add another one
				// then split user defs into arrays
				
		}

	}
}





