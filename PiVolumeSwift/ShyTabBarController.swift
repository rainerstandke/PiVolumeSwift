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
		// only the slected tab will be restored, as inherited from super
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
	
	@objc func removeVolumeCon() {
		// really: dump volumeController wrapped in NavCon
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

		var newY_Origin = self.view.frame.size.height // just outside/under parent view
		if count > 1 {
			newY_Origin -= tabBar.frame.size.height // regular setup, in view
		}
		return newY_Origin
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// force right tabBar position for current childView count, needed after rotation
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
	

