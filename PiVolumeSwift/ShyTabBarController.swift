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
	
	
	// TODO: split user defs into arrays
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		self.delegate = self
		
		if (tabBar.items?.count)! < 2 {
			// push tabBar out of bottom no need to animate, we're not on screen yet
			putTabBarOffScreen()
		}
		
		NotificationCenter.default.addObserver(
			forName: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: nil,
			queue: OperationQueue.main) { (notif) in
				self.addNewVolumeVuCon()
		}
		
		NotificationCenter.default.addObserver(
			forName: NSNotification.Name("\(K.Notif.DeleteTabBarItem)"),
			object: nil,
			queue: OperationQueue.main) { (notif) in
				if let tbdNavVuCon = notif.object as? UINavigationController {
					self.removeNavCon(navVuCon: tbdNavVuCon)
				}
		}
	}
	
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	func addNewVolumeVuCon() {
		// really: adding volumeController wrapped in NavCon
		
		let storyBoard = UIStoryboard(name: "Main", bundle: nil)
		let newNavCon = storyBoard.instantiateViewController(withIdentifier: "NavCon")
		
		if let newVolCon = newNavCon.childViewControllers.first as? VolumeViewController {
			print("newVolCon: \(newVolCon)")
			newVolCon.presetIndex = (self.viewControllers?.count)! // ??? better syntax?
			
		}
		
		
		
		var vuCons = viewControllers! // ???: this array is a COPY, right?
		
		vuCons.append(newNavCon)
		
		
		/*******

		???: added vuCon snap into place - why? -> new NavCon?
		
		*******/
		
		if tabBar.items?.count == 1 {
			// need to move tabBar in from bottom
			
			UIView.animate(
				withDuration: TimeInterval(K.Misc.TransitionDuration),
				animations: {
					// move tabBar
					self.tabBar.frame = self.tabBar.frame.offsetBy(dx: 0, dy: -(self.tabBar.frame.size.height))
					self.setViewControllers(vuCons, animated: false)
					
					if let currVuCon = self.selectedViewController as? UINavigationController,
						let currVolumeVuCon = currVuCon.childViewControllers.first as? VolumeViewController {
						// tableView bottomConstraint
						print("self.bottomEdge before: \(self.bottomEdge)")
						
						currVolumeVuCon.tableViewBottomToSuperViewConstraint.constant = self.bottomEdge
						currVolumeVuCon.view.setNeedsUpdateConstraints()
						
						currVolumeVuCon.view.layoutIfNeeded()
					}
			},
				completion: { (completed) in
					self.selectedIndex = vuCons.count - 1 // show new
					// NOTE: showing after animation is complete prevents the jump in NavBar position
			})
			
		} else {
			// tabBar already in place
			self.setViewControllers(vuCons, animated: true)
			self.selectedIndex = vuCons.count - 1 // show new
		}
		
		// TODO: figure out why crash when shown before notif arrives - or so
		
		// TODO: make title bar + L/R items appear, give name (ending IP address)
		// copy presets from last visible into new
	}

	
	func removeNavCon(navVuCon: UINavigationController) {
		
		
		guard let idx = self.viewControllers?.index(of: navVuCon) else { return }
		
		// TODO: remove from user defs  arrays
		
		
		var vuCons = viewControllers!
		
		if tabBar.items?.count == 2 {
			// need to move tabBar in from bottom
			
			UIView.animate(
				withDuration: TimeInterval(K.Misc.TransitionDuration),
				animations: {
					self.putTabBarOffScreen()
					
					if let currVuCon = self.selectedViewController as? UINavigationController,
						let currVolumeVuCon = currVuCon.childViewControllers.first as? VolumeViewController {
						// tableView bottomConstraint
						currVolumeVuCon.tableViewBottomToSuperViewConstraint.constant = 0
						currVolumeVuCon.view.setNeedsUpdateConstraints()
						
						currVolumeVuCon.view.layoutIfNeeded()
					}
			},
				completion: { (completed) in
					vuCons.remove(at: idx)
					self.setViewControllers(vuCons, animated: false)
			})
		} else if (tabBar.items?.count)! > 2 {
			vuCons.remove(at: idx)
			self.setViewControllers(vuCons, animated: true)
		}
	}
	
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


