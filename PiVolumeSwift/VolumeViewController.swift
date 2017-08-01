//
//  FirstViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit
import CoreGraphics


// TODO: needs tabbaritem


class VolumeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{

	let notifCtr = NotificationCenter.default
	var firstVolumeUpdateSinceDidLoad = true
	
	var presetIndex: Int = 0 // OBSOLETE ??
	var settingsProxy = SettingsProxy()
		
	@IBOutlet weak var presetTableView: UITableView!

	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var longPressGR: UILongPressGestureRecognizer!
	
	@IBOutlet weak var doneTableEditBtn: UIButton!
	
	@IBOutlet weak var tableViewBottomToSuperViewConstraint: NSLayoutConstraint!
	
	
	// MARK: - life cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "⚙", style: .plain, target: self, action: #selector(segueToSettings))
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let tabBarCon = self.tabBarController as? ShyTabBarController {
			let idx = tabBarCon.indexOfDescendantVuCon(vuCon: self)
			settingsProxy = SettingsManager.sharedInstance.settingsWithIndex(idx.index!)
			print("settingsProxy: \(settingsProxy)")
		}
		
		volumeLabel.text = settingsProxy.lastUIVolumeStr
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		
		presetTableView.allowsMultipleSelectionDuringEditing = false
		print("settingsProxy.presetStrings: \(settingsProxy.presetStrings)")
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.VolChanged)"),
		                     object: nil,
		                     queue: OperationQueue.main) { notif in
								
								let newVolInt = notif.userInfo![K.Key.PercentValue]! as! Int
								self.volumeLabel.text = String(describing: newVolInt)
								self.volumeLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
								if	self.firstVolumeUpdateSinceDidLoad {
									// move the slider if this is the first time we get an actual Vol value over the wire
									self.firstVolumeUpdateSinceDidLoad = false
									UIView.animate(withDuration: 0.3,
									               animations: {
													self.volumeSlider.setValue(Float(newVolInt), animated: true)
									})
								}
		}
		
		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.ConfirmedVolume)"),
		                     object: nil,
		                     queue: OperationQueue.main) { notif in
								// runs when SSHMan decides not to send a redundant value to pi
								self.volumeLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		}
		

		if let tabBarCon = tabBarController as? ShyTabBarController {
			let idxIsLast = tabBarCon.indexOfDescendantVuCon(vuCon: self)
			
			if let index = idxIsLast.index, let isLast = idxIsLast.isLast {
				
				// TODO: get settings obj here
				// TODO: set navItem.title
				
				if isLast && index > 0 {
					navigationItem.leftBarButtonItem = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(notifyDeleteTabItem))
				} else {
					navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(notifyAddTabItem))
				}
			}
			
			// for the new, incoming one (huh??):
			tableViewBottomToSuperViewConstraint.constant = tabBarCon.bottomEdge
		}
		
//		guard let tabBarCon = tabBarController as? ShyTabBarController else { return }
//		guard let tabBarVuCons = tabBarCon.viewControllers else { return }
//		
//		let count = tabBarVuCons.count
//		guard let idx = tabBarVuCons.index(of: (self.parent! as UIViewController)) else { return }
//		
//		if idx > 0 && idx == count - 1 {
//			navigationItem.leftBarButtonItem = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(notifyDeleteTabItem))
//		} else {
//			navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(notifyAddTabItem))
//		}
		
		// TODO set title for IP address or pi name
//		let suffix = " (\(idx + 1) of \(count))"
//		navigationItem.title = "Pi Volume" + (count > 1 ? suffix : "")
		
		
	}
	
	func notifyAddTabItem() {
		// runs when user adds a new vuCon by way of + button
		notifCtr.post(
			name: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: self
		)
	}
	
	func notifyDeleteTabItem() {
		// runs when user deletes this vuCon by way of - button
		notifCtr.post(
			name: NSNotification.Name("\(K.Notif.DeleteTabBarItem)"),
			object: self.parent // b/c we're in NavBarCon
		)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// read actual volume from wire
		SSHManager.sharedInstance.getVolumeFromRemote()
		
		self.presetTableView.flashScrollIndicators()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
//		UserDefaults.standard.set(presetArray, forKey:K.UserDef.PresetStrArray)
		
		notifCtr.removeObserver(self)
	}


	// MARK: -
	
	func segueToSettings() {
		// called from right NavBarItem to trigger segue to SettingsCon
		performSegue(withIdentifier: "ToSettingsSegue", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called when we transition to SettingsViewCon
		print("segue: \(segue)")
		
		
		if let settingsCon = segue.destination as? SettingsViewController {
			settingsCon.settingsProxy = self.settingsProxy
			print("settingsCon: \(settingsCon)")
		}
		
		// (found) NEXT: grab destination from segue, set settings obj
	
	
	
	
	}
	
	@IBAction func unwindFromSettings(unwindSegue: UIStoryboardSegue){
		// called when we transition back to here from SettingsViewCon
	}
	
	
	// MARK: -
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		
		
		firstVolumeUpdateSinceDidLoad = false
		
		let newStr = String(Int(floor(sender.value)))
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		volumeLabel.text = newStr
		
		
		settingsProxy.lastUIVolumeStr = newStr
		print("settingsProxy.lastUIVolumeStr: \(settingsProxy.lastUIVolumeStr)")
		
		// this triggers SSHMan to talk to pi
		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"),
		              object: self,
		              userInfo: [K.Key.PercentValue: sender.value]
		)
	}
	
	
	// MARK: - preset
	
	@IBAction func longPressRecognizer(_ lpGestRecog: UILongPressGestureRecognizer) {
		// long press on tableView gets us into edit mode - i.e. moving rows, or set preset value
		if lpGestRecog.state != .began {
			return
		}
		
		let lpLocation = lpGestRecog.location(in: lpGestRecog.view)
		
		guard let tableView = lpGestRecog.view as? UITableView else { return }
		
		guard let idxPath = tableView.indexPathForRow(at: lpLocation) else {return }
		
		guard let pressedView = lpGestRecog.view?.hitTest(lpLocation, with: nil) else {return }
		
		if pressedView.tag == K.UIElementTag.PresetButton {
			// long touch on preset button to aquire new preset value
			let presetBtn = pressedView as! UIButton
			presetBtn.setTitle(volumeLabel.text, for: .normal)

			settingsProxy.presetStrings[idxPath.row] = volumeLabel.text!
		} else {
			//long press on row to reorder - toggle tv isEditing
			tableView.setEditing(!tableView.isEditing, animated: true)
			updateDoneTableEditBtn()
		}
		
	}
	
	func updateDoneTableEditBtn() {
		let visibileFrame = doneTableEditBtn.frame
		let hiddenFrame = visibileFrame.offsetBy(dx: 10, dy: 0)
		
		var targetFrame = visibileFrame
		var targetAlpha: CGFloat = 1;
		
		if presetTableView.isEditing {
			// btn is hidden, frame set in IB = visibleFrame
			doneTableEditBtn.frame = hiddenFrame
			doneTableEditBtn.alpha = 0
			targetAlpha = 1
			targetFrame = visibileFrame
			
			// has to happen before animation
			self.doneTableEditBtn.isHidden = false
		} else {
			// btn is visible
			targetAlpha = 0
			targetFrame = hiddenFrame
		}
		
		UIView.transition(with: doneTableEditBtn,
		                  duration: 0.3,
		                  options: [],
		                  animations: {
							self.doneTableEditBtn.frame = targetFrame
							self.doneTableEditBtn.alpha = targetAlpha
		}) { (completed: Bool) in
			if self.doneTableEditBtn.alpha == 0 {
				// has to happen after animation
				self.doneTableEditBtn.isHidden = true
			}
			self.doneTableEditBtn.frame = visibileFrame
		}
	}
	
	@IBAction func contentViewTap(_ tapRecog: UITapGestureRecognizer) {
		// tap somewhere in the main contentView to get tableView out of edit mode
		if tapRecog.state != .ended || tapRecog.view != view {
			return
		}
		if presetTableView.isEditing {
			tableViewEndEditing(self)
		}
	// NOTE we are getting into edit mode w/ left-swipe (or long touch) 'automatically'
	}
	
	
	@IBAction func tableViewEndEditing(_ sender: Any) {
		presetTableView .setEditing(false, animated: true)
		updateDoneTableEditBtn()
	}
	
	@IBAction func stepped(_ stepper: UIStepper) {
		
		let presetButton = stepper.superview!.subviews.first { siblingOrSelf -> Bool in
			return siblingOrSelf.tag == K.UIElementTag.PresetButton
		} as! UIButton
		
		var newPreset: Int?
		if let currPreset = Int((presetButton.titleLabel?.text)!) {
			newPreset = currPreset + Int(stepper.value)
		} else {
			stepper.value = 0.0
			return
		}
		
		stepper.value = 0.0
		
		if newPreset! < 0 || newPreset! > 151 {
			return
		}
		
		presetButton.setTitle(String(newPreset!), for: .normal)
		
		UIView.animate(withDuration: 0.3,
		               animations: {
						self.volumeSlider.setValue(Float(newPreset!), animated: true)
						self.volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		})
		
		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"),
		              object: self,
		              userInfo: [K.Key.PercentValue: Float(newPreset!)]
		)
		
		
		if let tv = stepper.superview(of: UITableView.self) {
			let tvLocation = tv.convert(stepper.center, from: stepper.superview)
			guard let idxPath = tv.indexPathForRow(at: tvLocation) else {
				return }
			settingsProxy.presetStrings[idxPath.row] = String(newPreset!)
		}
		
	}
	
	
	@IBAction func presetButtonTouched(_ thisPresetButton: UIButton) {
		if let presetValStr = thisPresetButton.titleLabel?.text {
			if let presetFloat = Float(presetValStr) {
				volumeSlider.value = presetFloat
				volumeLabel.text = presetValStr
				sliderMoved(volumeSlider)
			}
		}
	}
	
	
	@IBAction func addPreset(_ plusBtn: Any) {
		settingsProxy.presetStrings.append("Preset")
		presetTableView.reloadData()
		presetTableView.flashScrollIndicators()
	}

	
	// MARK: - table view delegate / datasource
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
		
		if let presetBtn = cell.viewWithTag(K.UIElementTag.PresetButton) as? UIButton {
			if settingsProxy.presetStrings.count >= indexPath.row + 1 {
				presetBtn.setTitle(settingsProxy.presetStrings[indexPath.row] as String, for: .normal)
			} else {
				presetBtn.setTitle("Preset", for: .normal)
			}
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		updateViewConstraints()
		return settingsProxy.presetStrings.count
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
		if tableView.isEditing {
			return .none // to suppress ⛔️ on left
		} else {
			return .delete // for swipe left
		}
	}
	
	func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
	func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		let removedStr = settingsProxy.presetStrings.remove(at: sourceIndexPath.row)
		settingsProxy.presetStrings.insert(removedStr, at: destinationIndexPath.row)
		// seems like this method being here enables swipe-left to delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			settingsProxy.presetStrings.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		}
	}
	
}


extension UIView {
	// from: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	// returns either superview if of type T, or recursively superView's superViews
	
	func superview<T>(of type: T.Type) -> T? {
		return superview as? T ?? superview.flatMap { $0.superview(of: T.self) }
	}
}


extension UIViewController {
	// based on: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	
	
	func ancestorViewController<T>(of type: T.Type) -> T? {
		return parent as? T ?? parent.flatMap { $0.ancestorViewController(of: T.self) }
	}
}





