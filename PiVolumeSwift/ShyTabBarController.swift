//
//  ShyTabBarController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/17/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class ShyTabBarController: UITabBarController , UITabBarControllerDelegate, UIViewControllerAnimatedTransitioning
{
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.delegate = self
		
		
		// TODO: this needs to go into viewWillAppear, after state restoration
		if (tabBar.items?.count)! < 2 {
			// push tabBar out of bottom no need to animate, we're not on screen yet
			putTabBarOffScreen()
		}
	}
	
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		// runs after viewDidLoad
		super.decodeRestorableState(with: coder)
		
		if let previousChildCount = coder.decodeObject(forKey: "childCount") as? Int {
			// add child vuCons, but not the first one
			for _: Int in 1..<previousChildCount {
				addNewVolumeVuCon()
			}
		}
		
		// select the childViewCon at last index
		selectedIndex = coder.decodeInteger(forKey: "selIndex")
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		// just add current child vuCon count, selectedIndex
		coder.encode(viewControllers?.count, forKey: "childCount")
		coder.encode(selectedIndex as NSInteger, forKey: "selIndex")
		
		super.encodeRestorableState(with: coder)
	}
	
	
	@objc func addNewVolumeVuCon() {
		// really: adding volumeController wrapped in NavCon
		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let newNavCon = storyBoard.instantiateViewController(withIdentifier: "NavCon")
		
		// vuCons is ref to an existing object - vuCons and viewControllers! share a memory address
		// but without creating vuCons, and accessing viewCons! directly, the new tab never shows - ???: why not?
		// Josh: see if they share memory address after changing vuCons
		var vuCons = viewControllers!
		vuCons.append(newNavCon)
		
		let newChildCOunt = viewControllers!.count + 1
		showHideTabBar(addOrRemoveTab: {self.setViewControllers(vuCons, animated: false)}, resultingTabCount: newChildCOunt)

	}
	
	
	func showHideTabBar(addOrRemoveTab: @escaping () -> (), resultingTabCount: Int) {
		// parm addOrRemoveTab is a block that will add or remove a tab
		// parm resultingTabCount is the count after that change
		
		// the origin of the tabBaer (i.e. its upper left from the screen's upper left) is either outside / just under the screen, or at the bottom
		var newY_Origin = self.view.frame.size.height // regular setup, in view
		if resultingTabCount > 1 {
			newY_Origin -= tabBar.frame.size.height // just under view
		}

		UIView.animate(withDuration: 0.3) {
			self.tabBar.frame.origin.y = newY_Origin
			addOrRemoveTab()
		}
		
		// TODO: NEXT: look at constraining the contentView to the to of the tabBar -> bg color!
		// play with fuller, scrolling! preset table!
		
	}

	
	@objc func removeNavCon() {
		let newChildCount = viewControllers!.count - 1
		showHideTabBar( addOrRemoveTab: { self.viewControllers!.remove(at: self.selectedIndex) }, resultingTabCount: newChildCount)
	}
	
//	@objc func removeNavCon(navVuCon: UINavigationController) {
//		// ALMOST OBSOLETE
//
//		guard let idx = self.viewControllers?.index(of: navVuCon) else { return }
//
//		var vuCons = viewControllers!
//
//		if tabBar.items?.count == 2 {
//			// need to move tabBar in from bottom
//
//			self.selectedIndex = vuCons.count - 1 // show only one
//
//			UIView.animate(
//				withDuration: TimeInterval(K.Misc.TransitionDuration),
//				animations: {
//					self.putTabBarOffScreen()
//
//					if let currVuCon = self.selectedViewController as? UINavigationController,
//						let currVolumeVuCon = currVuCon.childViewControllers.first as? VolumeViewController {
//						// tableView bottomConstraint
//						currVolumeVuCon.tableViewBottomToSuperViewConstraint.constant = 0
//						currVolumeVuCon.view.setNeedsUpdateConstraints()
//
//						currVolumeVuCon.view.layoutIfNeeded()
//					}
//			},
//				completion: { (completed) in
//					vuCons.remove(at: idx)
//					self.setViewControllers(vuCons, animated: false)
//			})
//
//		} else if (tabBar.items?.count)! > 2 {
//			self.selectedIndex = vuCons.count - 2 // show the one that will be the last one
//			vuCons.remove(at: idx)
//			self.setViewControllers(vuCons, animated: true)
//		}
//	}
	
	func putTabBarOffScreen() {
		let tabBarOriginY = self.view.frame.size.height
		tabBar.frame.origin.y = tabBarOriginY
	}
	
	func putTabBarOnScreen() {
		let tabBarOriginY = self.view.frame.size.height - tabBar.frame.size.height
		tabBar.frame.origin.y = tabBarOriginY
	}
	
	var bottomEdge : CGFloat {
		// i.e. distance between bottom of window and upper edge of tabBar
		get {
			return self.view.frame.size.height - tabBar.frame.origin.y
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
		print("volVuCons: \(volVuCons)")
		
		for volVuCon in volVuCons {
			volVuCon.saveSettings()
		}
	}
	
	
	
	
	// MARK: delegate
	
	func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return self
	}
	
	
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return TimeInterval(K.Misc.TransitionDuration)
	}
	
	
	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		let fromView: UIView = transitionContext.view(forKey: .from)!
		let toView  : UIView = transitionContext.view(forKey: .to)!

		UIView.transition(from: fromView, to: toView, duration: 1, options: UIViewAnimationOptions.transitionCrossDissolve) { (finished:Bool) in
			transitionContext.completeTransition(finished)
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
		return retArr.flatMap{ item in item }
	}
}



extension UITabBarController { // OBSOLETE
	
	//	see: https://stackoverflow.com/questions/20935228/how-to-hide-tab-bar-with-animation-in-ios
	
	private struct AssociatedKeys {
		// Declare a global var to produce a unique address as the assoc object handle
		static var orgFrameView:     UInt8 = 0
		static var movedFrameView:   UInt8 = 1
	}
	
	var orgFrameView:CGRect? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys.orgFrameView) as? CGRect }
		set { objc_setAssociatedObject(self, &AssociatedKeys.orgFrameView, newValue, .OBJC_ASSOCIATION_COPY) }
	}
	
	var movedFrameView:CGRect? {
		get { return objc_getAssociatedObject(self, &AssociatedKeys.movedFrameView) as? CGRect }
		set { objc_setAssociatedObject(self, &AssociatedKeys.movedFrameView, newValue, .OBJC_ASSOCIATION_COPY) }
	}
	
	override open func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if let movedFrameView = movedFrameView {
			view.frame = movedFrameView
		}
	}
	
	func setTabBarVisible(visible:Bool, animated:Bool) {
		// bail if the current state matches the desired state
		if (tabBarIsVisible() == visible) { return }
		
		//we should show it
		if visible {
			tabBar.isHidden = false
			UIView.animate(withDuration: animated ? 0.3 : 0.0) {
				//restore form or frames
				self.view.frame = self.orgFrameView!
				//errase the stored locations so that...
				self.orgFrameView = nil
				self.movedFrameView = nil
				//...the layoutIfNeeded() does not move them again!
				self.view.layoutIfNeeded()
			}
		}
			//we should hide it
		else {
			//safe org positions
			orgFrameView   = view.frame
			// get a frame calculation ready
			let offsetY = self.tabBar.frame.size.height
			movedFrameView = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + offsetY)
			//animate
			UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
				self.view.frame = self.movedFrameView!
				self.view.layoutIfNeeded()
			}) {
				(_) in
				self.tabBar.isHidden = true
			}
		}
	}
	
	func tabBarIsVisible() ->Bool {
		return orgFrameView == nil
	}
}


