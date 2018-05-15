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
		tabBar.frame.origin.y = tabBarOriginY()
		updateIncludesOpaque()
		super.viewDidAppear(animated)
	}
	
	@objc func addNewVolumeVuCon() {
		// really: adding volumeController wrapped in NavCon
		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let newNavCon = storyBoard.instantiateViewController(withIdentifier: "NavCon")
		let newChildCount = viewControllers!.count + 1
		
		showHideTabBar(addOrRemoveTab: { self.viewControllers!.append(newNavCon) }, resultingTabCount: newChildCount)
		
		selectedViewController = newNavCon
	}
	
	@objc func removeNavCon() {
		let newChildCount = viewControllers!.count - 1
		showHideTabBar( addOrRemoveTab: { self.viewControllers!.remove(at: self.selectedIndex) }, resultingTabCount: newChildCount)
		
		selectedIndex = viewControllers!.count - 1
	}
	
	func showHideTabBar(addOrRemoveTab: @escaping () -> (), resultingTabCount: Int) {
		// parm addOrRemoveTab is a block that will add or remove a tab
		// parm resultingTabCount is the count after that change - need to be told explicitly because we don't know if we're adding or removing
		
		// TODO: consider removing resultingTabCount
		// TODO: factor out shyness / tab bar hiding
		
		let newY_Origin = tabBarOriginY(with: resultingTabCount)
		self.tabBar.frame.origin.y = newY_Origin
		addOrRemoveTab()
		updateIncludesOpaque()
		
		UserDefaults.standard.set(childViewControllers.count, forKey:K.UserDef.TabCount)
		UserDefaults.standard.synchronize()
	}
	
	
	func tabBarOriginY(with childCount: Int) -> CGFloat {
		// the origin of the tabBar (i.e. its upper left from the screen's upper left) is either outside / just under the screen, or its frame's bottom is alligned with the bottom of the parent view
		var newY_Origin = self.view.frame.size.height // just outside/under parent view
		if childCount > 1 {
			newY_Origin -= tabBar.frame.size.height // regular setup, in view
		}
		return newY_Origin
	}
	
	
	func tabBarOriginY() -> CGFloat {
		// for current number of childVuCons
		return tabBarOriginY(with: childViewControllers.count)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		// force right tabBar position for current childView count, needed after rotation
		// note: block doesn't do anything
		showHideTabBar(addOrRemoveTab: {}, resultingTabCount: viewControllers!.count)
	}
	
	func updateIncludesOpaque() {
		// called by self from viewDidAppear, and when the tabBar is shown or hidden (when tabs are added/deleted)
		if viewControllers!.count > 1 {
			for viewCon in viewControllers! {
				viewCon.extendedLayoutIncludesOpaqueBars = true
			}
		} else {
			selectedViewController?.extendedLayoutIncludesOpaqueBars = false
		}
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
		
		for volVuCon in volVuCons {
			volVuCon.saveSettings()
		}
	}
}
	

