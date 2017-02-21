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
	
	var bottomEdge : CGFloat {
		get {
			return self.view.frame.size.height - tabBar.frame.origin.y
		}
		
//		set (){
//			
//		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		print("tabBar.frame: \(tabBar.frame)")
		
		
		print("self.view.frame: \(self.view.frame)")
		print("bottomEdge: \(bottomEdge)")
		
		if (tabBar.items?.count)! < 2 {
			tabBar.frame = tabBar.frame.offsetBy(dx: 0, dy: tabBar.frame.size.height)
			tabBar.isHidden = true
			
			// TODO: animate up & unhide when adding
		}
		
		print("self.view.frame: \(self.view.frame)")
		print("bottomEdge: \(bottomEdge)")
		
		NotificationCenter.default.addObserver(
			forName: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: nil,
			queue: OperationQueue.main) { (notif) in
				self.addNewVolumeVuCon()
				
				// TODO: split user defs into arrays
				
		}
		
		NotificationCenter.default.addObserver(
			forName: NSNotification.Name("\(K.Notif.DeleteTabBarItem)"),
			object: nil,
			queue: OperationQueue.main) { (notif) in
				if let tbdNavVuCon = notif.object as? UINavigationController {
					self.removeNavCon(navVuCon: tbdNavVuCon)
				}
		}
		
		edgesForExtendedLayout = UIRectEdge.bottom
	}
	
	func addNewVolumeVuCon() {
		// volumeController wrapped in NavCon
		
		self.tabBar.isHidden = false

		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		
		let newNavCon = storyBoard.instantiateViewController(withIdentifier: "NavCon")
		print("newNavCon.childViewControllers: \(newNavCon.childViewControllers)")
		
		
		if let newVolumeVuCon = newNavCon.childViewControllers.first as? VolumeViewController {
			print("newVolumeVuCon.tableViewBottomToSuperViewConstraint: \(newVolumeVuCon.tableViewBottomToSuperViewConstraint)")
		}
		
		var vuCons = viewControllers!
		
		vuCons.append(newNavCon)
		
		
		if tabBar.items?.count == 1 {
			
			UIView.animate(
				withDuration: 1,
				animations: {
					self.tabBar.frame = self.tabBar.frame.offsetBy(dx: 0, dy: -(self.tabBar.frame.size.height))
					self.setViewControllers(vuCons, animated: false)
			},
				completion: { (completed) in
					self.selectedIndex = vuCons.count - 1
			})
			
			if let currVuCon = self.selectedViewController as? UINavigationController {
				if let currVolumeVuCon = currVuCon.childViewControllers.first as? VolumeViewController {
					print("bottomEdge: \(bottomEdge)")
					currVolumeVuCon.tableViewBottomToSuperViewConstraint.constant = bottomEdge
					
					
					UIView.animate(
						withDuration: 1,
						animations: {
							
							currVolumeVuCon.view.layoutIfNeeded()
					},
						completion: { (completed) in
							
					})
				}
			}
			
		}
		
		
		
		
		// TODO: figure out why crash when shown before notif arrives - or so
		
		// TODO: make title bar + L/R items appear, give name (ending IP address)
		// copy presets from last visible into new
		
		
		
		print("self.view.frame: \(self.view.frame)")
		
	}

	func removeNavCon(navVuCon: UINavigationController) {
		if let idx = self.viewControllers?.index(of: navVuCon) {
			self.viewControllers?.remove(at: idx)
			
			// TODO: remove from user defs  arrays
			print("self.view.frame: \(self.view.frame)")
			
		}
	}
}





