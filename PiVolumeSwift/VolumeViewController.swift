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
	let sshMan = SSHManager()
	
	let notifCtr = NotificationCenter.default // OBSOLETE?
	
	var tabIndex: Int = NSNotFound // may be OBSOLETE - only needed for re-ordering?
	var settingsProxy = SettingsProxy() // this one is used if none can be gotten from userDefs
	
	let pushedColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
	let confirmedColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
	
	var confirmedVolumeObservation: NSKeyValueObservation?
	
	@IBOutlet weak var presetTableView: UITableView!

	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var longPressGestRec: UILongPressGestureRecognizer!
	
	@IBOutlet weak var doneTableEditBtn: UIButton!
	
	@IBOutlet weak var tableViewBottomToSuperViewConstraint: NSLayoutConstraint!
	
	
	// MARK: - life cycle
	override func awakeFromNib() {
		super.awakeFromNib()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "⚙",
		                                                    style: .plain,
		                                                    target: self,
		                                                    action: #selector(segueToSettings))
	}
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		
		// load settings based on our position in tabBarCon's childVuCons array
		if let index = indexInTabBarCon() {
			// record index so that we can write our settings into userDefs when we disappear
			tabIndex = index
			
			// try to load settings from userDefs
			if let data = UserDefaults.standard.value(forKey: String(index)) as? Data {
				if let settings = try? PropertyListDecoder().decode(SettingsProxy.self, from: data) {
					print("settings: \(settings)")
					self.title = settings.deviceName
					sshMan.settingsPr = settings
					settingsProxy = settings
				}
			}
		}
		
		if settingsProxy.confirmedVolume != nil {
			volumeLabel.text = settingsProxy.confirmedVolume
		} else if settingsProxy.pushVolume != nil {
			volumeLabel.text = settingsProxy.pushVolume
		} else {
			volumeLabel.text = "??"
		}
		volumeLabel.textColor = pushedColor
		
		presetTableView.allowsMultipleSelectionDuringEditing = false
		
		// observe volume confirmation -> update UI
		confirmedVolumeObservation = settingsProxy.observe(\.confirmedVolume) { (setPr, change) in
			DispatchQueue.main.async {
				self.volumeLabel.text = setPr.confirmedVolume // possibly redundant
				self.volumeLabel.textColor = self.confirmedColor
				
				if setPr.confirmedVolume != setPr.pushVolume {
					self.updateSlider()
				}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// add back item in UL
		if let tabBarCon = tabBarController as? ShyTabBarController {
			
			let idxIsLast = tabBarCon.indexOfDescendantVuCon(vuCon: self)
			if let index = idxIsLast.index, let isLast = idxIsLast.isLast {
				if isLast && index > 0 {
					navigationItem.leftBarButtonItem = UIBarButtonItem(title: "-", style: .plain, target: self, action: #selector(notifyDeleteTabItem))
				} else {
					navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(notifyAddTabItem))
				}
			}
			
			// for the new, incoming one (huh??):
			tableViewBottomToSuperViewConstraint.constant = tabBarCon.bottomEdge
		}
	}
	
	@objc func notifyAddTabItem() {
		// runs when user adds a new vuCon by way of + button
		notifCtr.post(
			name: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: self
		)
	}
	
	@objc func notifyDeleteTabItem() {
		// runs when user deletes this vuCon by way of - button
		notifCtr.post(
			name: NSNotification.Name("\(K.Notif.DeleteTabBarItem)"),
			object: self.parent // b/c we're in NavBarCon
		)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// update UI
		updateSlider()
		
		// read actual volume from wire
		sshMan.getVolumeFromRemote()
		
		self.presetTableView.flashScrollIndicators()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		saveSettings()
		super.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		notifCtr.removeObserver(self)
	}


	func indexInTabBarCon() -> Int? {
		// in short: our position in tabBarCon's childVuCons array
		// this assumes we are in a NavigationCon which is inside a TabBarCon
		return tabBarController?.viewControllers?.index(of: navigationController!)
	}
	
	func saveSettings() {
		// store our settings object in userDefs, using our index in tabBarCon as key
		if let index = indexInTabBarCon() {
			// store our index as we leave screen - just in case we get re-ordered -- OBSOLETE?
			tabIndex = index
			
			UserDefaults.standard.set(try? PropertyListEncoder().encode(settingsProxy), forKey:String(index))
		}
	}
	
	func updateSlider() {
		// if there is a value in the UI animate the slider
		if let floatVal = Float(volumeLabel.text!){
			UIView.animate(withDuration: 0.3,
			               animations: {self.volumeSlider.setValue(floatVal, animated: true)})
		}
	}
	
	
	// MARK: -
	
	@objc func segueToSettings() {
		// called from right NavBarItem to trigger segue to SettingsCon
		performSegue(withIdentifier: "ToSettingsSegue", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called when we transition to SettingsViewCon
		// pass settingPr to SettingsCon
		if let settingsCon = segue.destination as? SettingsViewController {
			settingsCon.settingsProxy = self.settingsProxy
		}
	}
	
	@IBAction func unwindFromSettings(unwindSegue: UIStoryboardSegue){
		// called when we transition back to here from SettingsViewCon
		// our settingsPr was passsed by ref to SettingsCon
		// deviceName might be changed -> just in case update
		self.title = settingsProxy.deviceName
	}
	
	
	// MARK: -
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		// action method for slider: called directly from ui
		
		// make String, omitting post-comma digits
		let newStr = String(Int(floor(sender.value)))
		volumeLabel.textColor = pushedColor
		volumeLabel.text = newStr
		
		// set on settingsPr for sshMan to find & push
		settingsProxy.pushVolume = newStr

		sshMan.pushVolumeToRemote()
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
						self.volumeLabel.textColor = self.pushedColor
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





