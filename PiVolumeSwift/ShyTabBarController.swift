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
		print("tab vu didLoad")
		super.viewDidLoad()
		
		self.delegate = self
	}
	
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		// get titles for all tabs, not just the one that'll appear on screen
		print("tab vu willAppear")
		
		
		
		// TODO: check _here_ that all child Vol Cons have found their settings, make them load otherwise
		
		
		
		updateTabNames()

		super.viewWillAppear(animated)
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		print("tab vu didAppear")
		// position according to number of childVuCons
		// oddly, in viewWILLAppear this seems to have no effect
		tabBar.frame.origin.y = tabBarOriginY()
		updateIncludesOpaque()
		super.viewDidAppear(animated)
	}
	
	
	override func decodeRestorableState(with coder: NSCoder) {
		print("tab vu decodeRestorableState")
		// runs after viewDidLoad
		super.decodeRestorableState(with: coder)
		
		if let previousChildCount = coder.decodeObject(forKey: "childCount") as? Int {
			print("previousChildCount: \(String(describing: previousChildCount))")
			// add child vuCons, but not the first one
			for _: Int in 1..<previousChildCount {
				addNewVolumeVuCon()
			}
		}
		
		// NOTE: restoring for selectedIndex works automagically, but all childVuCons after the first have to be added manually
		
		// select the childViewCon at last index
//		selectedIndex = coder.decodeInteger(forKey: "selIndex")
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		print("tabVu encode")
		print("viewControllers: \(String(describing: viewControllers))")
		
		// just add current child vuCon count, selectedIndex
		coder.encode(viewControllers?.count, forKey: "childCount")
		coder.encode(selectedIndex as NSInteger, forKey: "selIndex")
		
		super.encodeRestorableState(with: coder)
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
		
		let remove = {
			let goner = self.viewControllers![self.selectedIndex]
			goner.willMove(toParentViewController: nil)
			goner.view.removeFromSuperview()
			goner.removeFromParentViewController()
//			self.viewControllers!.remove(at: self.selectedIndex)
			
		}
		showHideTabBar( addOrRemoveTab: { remove() }, resultingTabCount: newChildCount)
		
		
		selectedIndex = viewControllers!.count - 1
	}
	
	func showHideTabBar(addOrRemoveTab: @escaping () -> (), resultingTabCount: Int) {
		// parm addOrRemoveTab is a block that will add or remove a tab
		// parm resultingTabCount is the count after that change - need to be told explicitly because we don't know if we're adding or removing
		
		let newY_Origin = tabBarOriginY(with: resultingTabCount)
		self.tabBar.frame.origin.y = newY_Origin
		addOrRemoveTab()
		updateIncludesOpaque()
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
	
	func updateTabNames() {
		// grab names from each VolumeVuCon, at launch, after an update
		if let tabBarItems = self.tabBar.items {
			for tabBarItem in (tabBarItems.enumerated()) {
				if let settingsPr = SettingsProxy.settingsProxyAt(tabIndex: tabBarItem.offset) {
					let title = settingsPr.deviceName
					tabBarItem.element.title = title
				}
			}
		}
	}
}
	
	
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
}


