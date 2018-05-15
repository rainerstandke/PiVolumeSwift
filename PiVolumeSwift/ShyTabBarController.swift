//
//  ShyTabBarController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/17/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class ShyTabBarController: UITabBarController , UITabBarControllerDelegate
{
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.delegate = self
		
		let previousTabCount = UserDefaults.standard.integer(forKey: K.UserDef.TabCount)

		if previousTabCount > 1 {
			for _: Int in 1..<previousTabCount {
				addNewVolumeVuCon()
			}
		}
		
		childViewControllers.enumerated().forEach({ (tuple: (idx: Int, vuCon: UIViewController)) in
			if let volVuCon = tuple.vuCon.descendantViewController(ofType: VolumeViewController.self) {
				volVuCon.readSettings(index: tuple.idx)
			}
		})
	}
	
	override func viewDidAppear(_ animated: Bool) {
		// position according to number of childVuCons
		// oddly, in viewWILLAppear this seems to have no effect
		updateTabBarPosition()
		super.viewDidAppear(animated)
	}
	
	@objc func addNewVolumeVuCon() {
		// really: adding volumeController wrapped in NavCon
		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let newNavCon = storyBoard.instantiateViewController(withIdentifier: "NavCon")
		self.viewControllers!.append(newNavCon)
		selectedViewController = newNavCon
		
		UserDefaults.standard.set(childViewControllers.count, forKey:K.UserDef.TabCount)
		UserDefaults.standard.synchronize()
	}
	
	@objc func removeNavCon() {
		self.viewControllers!.remove(at: self.selectedIndex)
		selectedIndex = childViewControllers.count - 1
		updateTabBarPosition()
	
		UserDefaults.standard.set(childViewControllers.count, forKey:K.UserDef.TabCount)
		UserDefaults.standard.synchronize()
	}
	
	func updateTabBarPosition() {
		let newY_Origin = tabBarOriginY()
		self.tabBar.frame.origin.y = newY_Origin
		
		// update the children's opaque... to control how far down they extend
		if viewControllers!.count > 1 {
			for viewCon in viewControllers! {
				viewCon.extendedLayoutIncludesOpaqueBars = true
			}
		} else {
			selectedViewController?.extendedLayoutIncludesOpaqueBars = false
		}
	}
	
	func tabBarOriginY(with childCount: Int? = nil) -> CGFloat {
		// the origin of the tabBar (i.e. its upper left from the screen's upper left) is either outside / just under the screen, or its frame's bottom is alligned with the bottom of the parent view
		
		let count = childCount != nil ? childCount! : childViewControllers.count

		// huh?
//		guard let count = childCount ?? childViewControllers.count else {
//			print("could not get count")
//			return self.view.frame.size.height
//		}

		var newY_Origin = self.view.frame.size.height // just outside/under parent view
		if count > 1 {
			newY_Origin -= tabBar.frame.size.height // regular setup, in view
		}
		return newY_Origin
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// force right tabBar position for current childView count, needed after rotation
		// note: block doesn't do anything
		updateTabBarPosition()
	}
	
	func indexOfDescendantVuCon(vuCon: UIViewController) -> (index: Int?, isLast: Bool?) {
		var resolvedVuCon: UIViewController
		if (viewControllers?.contains(vuCon))! {
			// vuCon is our child
			resolvedVuCon = vuCon
		} else {
			if (viewControllers?.contains(vuCon.parent!))! {
				// grandChild?
				resolvedVuCon = vuCon.parent!
			} else {
				// neither child nor grandchild
				return (nil, nil)
			}
		}
		
		let idx = viewControllers!.index(of: resolvedVuCon)
		return (idx, idx == viewControllers!.count - 1)
	}
	
	func makeVolumeVuConsSave() {
		// called from appDel before termination / going to background
		
		let volVuCons = self.descendantViewControllers(of: VolumeViewController.self)
		volVuCons.forEach { $0.saveSettings() }
	}
}
	

