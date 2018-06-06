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
	
	func restoreChildViewControllers() {
		// called _before_ viewDidLoad from AppDel
		// ... so that all tabs that existed in state encoding will exist when the state is restored via UIStateRestoration
		// only the selected tab will be restored, as inherited from super
		let previousTabCount = UserDefaults.standard.integer(forKey: K.UserDef.TabCount)
		
		if previousTabCount > 1 {
			for _: Int in 1..<previousTabCount {
				addNewVolumeVuCon()
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.delegate = self
		
		childViewControllers.enumerated().forEach { (index, vuCon) in
			if let volVuCon = vuCon.descendantViewController(ofType: VolumeViewController.self) {
				volVuCon.readSettings(index: index)
			}
		}
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
		viewControllers?.append(newNavCon)
		selectedViewController = newNavCon
		
		UserDefaults.standard.set(childViewControllers.count, forKey:K.UserDef.TabCount)
		UserDefaults.standard.synchronize()
	}
	
	@objc func removeVolumeCon() {
		// really: dump volumeController wrapped in NavCon
		viewControllers?.remove(at: self.selectedIndex)
		selectedIndex = childViewControllers.count - 1
		updateTabBarPosition()
	
		UserDefaults.standard.set(childViewControllers.count, forKey:K.UserDef.TabCount)
		UserDefaults.standard.synchronize()
	}
	
	func updateTabBarPosition() {
		let newY_Origin = tabBarOriginY()
		self.tabBar.frame.origin.y = newY_Origin
		
		// update the children's opaque... to control how far down they extend
		if (viewControllers?.count ?? 0) > 1 {
			for viewCon in (viewControllers ?? []) {
				viewCon.extendedLayoutIncludesOpaqueBars = true
			}
		} else {
			selectedViewController?.extendedLayoutIncludesOpaqueBars = false
		}
	}
	
	func tabBarOriginY() -> CGFloat {
		// the origin of the tabBar (i.e. its upper left from the screen's upper left) is either outside / just under the screen, or its frame's bottom is alligned with the bottom of the parent view
		
		var newY_Origin = self.view.frame.size.height // just outside/under parent view
		if childViewControllers.count > 1 {
			newY_Origin -= tabBar.frame.size.height // regular setup, in view
		}
		return newY_Origin
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// force right tabBar position for current childView count, needed after rotation
		updateTabBarPosition()
	}
	
	func indexOfDescendantVuCon(vuCon: UIViewController) -> (index: Int, isLast: Bool)? {
		
		guard let viewCons = viewControllers else { return nil }
		
		var resolvedVuCon: UIViewController
		if viewCons.contains(vuCon) {
			// vuCon is our child
			resolvedVuCon = vuCon
		} else {
			if (viewControllers?.contains(vuCon.parent!))! {
				// grandChild?
				resolvedVuCon = vuCon.parent!
			} else {
				// neither child nor grandchild
				return nil
			}
		}
		
		guard let idx = viewControllers!.index(of: resolvedVuCon) else { return nil }
		return (idx, idx == viewCons.count - 1)
	}
	
	
	func makeVolumeVuConsSave() {
		// called from appDel before termination / going to background
		
		let volVuCons = self.descendantViewControllers(of: VolumeViewController.self)
		volVuCons.forEach { $0.saveSettings() }
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		if let count = tabBar.items?.count {
			coder.encode(Int64(count), forKey: K.UIStateRestoration.TabCount)
			coder.encode(Int64(selectedIndex), forKey: K.UIStateRestoration.SelectedTab	)
		}
		super.encodeRestorableState(with: coder)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		let tabCount = Int(coder.decodeInt64(forKey: K.UIStateRestoration.TabCount))
		let selectedTab = Int(coder.decodeInt64(forKey: K.UIStateRestoration.SelectedTab))

		if tabCount == tabBar.items?.count {
			selectedIndex = selectedTab
		}
	}
}
	

