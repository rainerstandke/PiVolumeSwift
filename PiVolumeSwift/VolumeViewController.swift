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


class VolumeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate
{
	let sshMan = SSHManager()
	
	var tabIndex: Int = NSNotFound // may be OBSOLETE - only needed for re-ordering?
	var settingsPr = SettingsProxy() // this one is used if none can be gotten from userDefs
	
	let pushedColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
	let confirmedColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
	
	var confirmedVolumeObservation: NSKeyValueObservation?
	
	var lightImpactFeedbackGenerator: UIImpactFeedbackGenerator?
	var lastScrolledToRow: CGFloat?
	
	@IBOutlet weak var presetTableView: UITableView!
	@IBOutlet weak var tableVuHeightConstraint: NSLayoutConstraint!
	
	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var longPressGestRec: UILongPressGestureRecognizer!
	
	@IBOutlet weak var doneTableEditBtn: UIButton!
	
	
	// MARK: - life cycle
	override func awakeFromNib() {
		super.awakeFromNib()
		// add go to settings button
		navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "gear"),
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
			
			// try to load settings from userDefs (fall back on virgin created in 'init'
			if let settings = SettingsProxy.settingsProxyAt(tabIndex: index) {
				self.title = settings.deviceName // redundant... 
				sshMan.settingsPr = settings
				settingsPr = settings
			}
		}
		
		if settingsPr.confirmedVolume != nil {
			volumeLabel.text = settingsPr.confirmedVolume
		} else if settingsPr.pushVolume != nil {
			volumeLabel.text = settingsPr.pushVolume
		} else {
			volumeLabel.text = "??"
		}
		volumeLabel.textColor = pushedColor
		
		presetTableView.allowsMultipleSelectionDuringEditing = false
		
		// observe volume confirmation -> update UI
		confirmedVolumeObservation = settingsPr.observe(\.confirmedVolume) { (setPr, change) in
			DispatchQueue.main.async {
				self.volumeLabel.text = setPr.confirmedVolume // possibly redundant
				self.volumeLabel.textColor = self.confirmedColor
			}
		}
		
		presetTableView.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// add +/- nav item in UL ( to add or remove more tabs )
		if let tabBarCon = tabBarController as? ShyTabBarController {
			
			let idxIsLast = tabBarCon.indexOfDescendantVuCon(vuCon: self)
			if let index = idxIsLast.index, let isLast = idxIsLast.isLast {
				if isLast && index > 0 {
					navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "-Pi"),
					                                                   style: .plain,
					                                                   target: self,
					                                                   action: #selector(deleteTab))
				} else {
					navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "+Pi"),
					                                                   style: .plain,
					                                                   target: self,
					                                                   action: #selector(addTabItem))
				}
			}
		}
	}
	
	@objc func addTabItem() {
		// runs when user adds a new vuCon by way of + leftBarButtonItem
		if let tabBarCon = tabBarController as? ShyTabBarController {
			tabBarCon.addNewVolumeVuCon()
		}
	}
	
	@objc func deleteTab() {
		// runs when user deletes this vuCon by way of - leftBarButtonItem
		if let tabBarCon = tabBarController as? ShyTabBarController {
			tabBarCon.removeNavCon()
		}
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
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		// to force update after rotation
		viewSafeAreaInsetsDidChange()
	}
	
	override func viewSafeAreaInsetsDidChange() {
		if #available(iOS 11.0, *) {
			// called automatically when tabVuCon changes our property extendedLayoutIncludesOpaqueBars
			// ... as well as after layouts for rotations
			// manually set the height constraint on presetTableVu to a whole multiple of its row height
			
			if presetTableView == nil {
				// this seems to happen when we're not on screen
				return
			}
			
			let rowHt = presetTableView.rowHeight
			let availableHeight = view.bounds.size.height - view.safeAreaInsets.bottom - presetTableView.frame.origin.y
			let rowCount = Int(availableHeight / rowHt)
			tableVuHeightConstraint.constant = (CGFloat(rowCount) * rowHt)
		
			super.viewSafeAreaInsetsDidChange()
		} else {
			// Fallback on earlier versions
			
			// use topLayoutGuide on vuCon, with manual trigger
		}
	}

	
	// MARK: - scrollView snap
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		// snap scroll position to table rows (at the top of the table)
		
		let rowHeight = presetTableView.rowHeight
		
		// make sure targetOffset is a whole multiple of rowHeight
		let divided = targetContentOffset.pointee.y / rowHeight
		let rounded = divided.rounded(.toNearestOrAwayFromZero)
		let newTargetY = rounded * rowHeight
		targetContentOffset.pointee.y = newTargetY
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		if lightImpactFeedbackGenerator == nil {
			lightImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
		}
	}
	
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		// haptic feedback during tableVu scroll
		// are we in a new row now?
		let currRow = (scrollView.contentOffset.y / presetTableView.rowHeight).rounded(.down)
		
		if lastScrolledToRow != nil {
			if currRow != lastScrolledToRow {
				lightImpactFeedbackGenerator?.impactOccurred()
			}
		}
		
		lastScrolledToRow = currRow
	}
	
	func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		lightImpactFeedbackGenerator = nil
	}
	
	// MARK: -
	
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
			
			UserDefaults.standard.set(try? PropertyListEncoder().encode(settingsPr), forKey:String(index))
		}
	}
	
	func updateSlider() {
		// if there is a value in the UI animate the slider
		if let floatVal = Float(volumeLabel.text!){
			UIView.animate(withDuration: 0.3,
			               animations: {self.volumeSlider.setValue(floatVal, animated: true)})
		}
	}
	
	
	// MARK: - segue
	
	@objc func segueToSettings() {
		// called from right NavBarItem to trigger segue to SettingsCon
		performSegue(withIdentifier: "ToSettingsSegue", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called when we transition to SettingsViewCon
		// pass settingPr to SettingsCon
		if let settingsCon = segue.destination as? SettingsViewController {
			settingsCon.settingsPr = settingsPr
			settingsCon.sshMan = sshMan
		}
	}
	
	@IBAction func unwindFromSettings(unwindSegue: UIStoryboardSegue){
		// called when we transition back to here from SettingsViewCon
		// set in IB menu on segue
		// our settingsPr was passsed by ref to SettingsCon
		// deviceName might be changed -> just in case update
		self.title = settingsPr.deviceName
		
		saveSettings()
		
		(tabBarController as! ShyTabBarController).updateTabNames()
	}
	
	
	// MARK: -
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		// action method for slider: called directly from UI
		
		// make String, omitting post-comma digits
		let newVal = Int(floor(sender.value))
		
		updateVolume(to: newVal)
	}
	
	func updateVolume(to newVal: Int) {
		let newStr = String(newVal)
		volumeLabel.textColor = pushedColor
		volumeLabel.text = newStr
		
		// set on settingsPr for sshMan to find & push
		settingsPr.pushVolume = newStr
		
		sshMan.pushVolumeToRemote()
	}
	
	
	// MARK: - preset
	
	@IBAction func addPreset(_ plusBtn: Any) {
		// called when + btn is pressed
		settingsPr.presetStrings.append("Preset")
		presetTableView.reloadData()
		presetTableView.flashScrollIndicators()
		saveSettings()
	}
	
	
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

			settingsPr.presetStrings[idxPath.row] = volumeLabel.text!
			
			saveSettings()
		} else {
			//long press on row to reorder - toggle tv isEditing
			tableView.setEditing(!tableView.isEditing, animated: true)
			updateDoneTableEditBtn()
		}
	}
	
	func updateDoneTableEditBtn() {
		// show or hide the 'Done' btn for table view editing
		// animate sideways movement, to visually connect btn to tableVu
		
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
		
		saveSettings()
	}
	
	@IBAction func contentViewTap(_ tapRecog: UITapGestureRecognizer) {
		// tap somewhere in the main contentView to get tableView out of edit mode
		if tapRecog.state != .ended || tapRecog.view != self.view {
			return
		}
		if presetTableView.isEditing {
			tableViewEndEditing(self)
		}
	// NOTE we are getting into edit mode w/ left-swipe (or long touch) 'automatically'
	}
	
	
	@IBAction func tableViewEndEditing(_ sender: Any) {
		// called from Done btn in tableView when editing of when tapped on main contentView
		presetTableView .setEditing(false, animated: true)
		updateDoneTableEditBtn()
	}
	
	@IBAction func stepped(_ stepper: UIStepper) {
		// stepper + or - was pressed
		
		let presetButton = stepper.superview!.subviews.first { siblingOrSelf -> Bool in
			return siblingOrSelf.tag == K.UIElementTag.PresetButton
		} as! UIButton
		
		var newPresetVal: Int
		if let currPreset = Int((presetButton.titleLabel?.text)!) {
			newPresetVal = currPreset + Int(stepper.value)
		} else {
			stepper.value = 0.0
			return
		}
		
		stepper.value = 0.0
		
		if newPresetVal < 0 || newPresetVal > 151 {
			return
		}
		
		// update preset value in button
		presetButton.setTitle(String(newPresetVal), for: .normal)
		
		updateVolume(to: newPresetVal)
		updateSlider()
		
		// update our preset in settings
		if let tv = stepper.ancestorView(ofType: UITableView.self) {
			let tvLocation = tv.convert(stepper.center, from: stepper.superview)
			guard let idxPath = tv.indexPathForRow(at: tvLocation) else {
				return }
			settingsPr.presetStrings[idxPath.row] = String(newPresetVal)
		}
		
	}
	
	
	@IBAction func presetButtonTouched(_ thisPresetButton: UIButton) {
		if let presetStr = thisPresetButton.titleLabel?.text, let presetInt = Int(presetStr) {
				updateVolume(to: Int(presetInt))
				updateSlider()
		}
	}
	
	
	// MARK: - table view delegate / datasource
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
		
		if let presetBtn = cell.viewWithTag(K.UIElementTag.PresetButton) as? UIButton {
			if settingsPr.presetStrings.count >= indexPath.row + 1 {
				presetBtn.setTitle(settingsPr.presetStrings[indexPath.row] as String, for: .normal)
			} else {
				presetBtn.setTitle("Preset", for: .normal)
			}
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		updateViewConstraints()
		return settingsPr.presetStrings.count
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
		let removedStr = settingsPr.presetStrings.remove(at: sourceIndexPath.row)
		settingsPr.presetStrings.insert(removedStr, at: destinationIndexPath.row)
		// seems like this method being here enables swipe-left to delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			settingsPr.presetStrings.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		}
	}
}


extension UIView {
	// from: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	// returns either superview if of type T, or recursively superView's superViews
	
	func ancestorView<T>(ofType type: T.Type) -> T? {
		return superview as? T ?? superview.flatMap { $0.ancestorView(ofType: T.self) }
	}
}


// OBSOLETE
extension UIViewController {
	// based on: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	
	func ancestorViewController<T>(of type: T.Type) -> T? {
		return parent as? T ?? parent.flatMap { $0.ancestorViewController(of: T.self) }
	}
}





