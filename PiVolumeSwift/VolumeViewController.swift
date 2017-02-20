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
	
	var presetArray: Array <String> = [] {
		didSet {
			UserDefaults.standard.set(presetArray, forKey: K.UserDef.PresetStrArray)
			UserDefaults.standard.synchronize()
		}
	}
	
	@IBOutlet weak var presetTableView: UITableView!

	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var longPressGR: UILongPressGestureRecognizer!
	
	@IBOutlet weak var doneTableEditBtn: UIButton!
	
	// MARK: - life cycle
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.VolChanged)"),
		                     object: nil,
		                     queue: OperationQueue.main) { notif in
								
								let newVolInt = notif.userInfo![K.Key.PercentValue]! as! Int
								self.volumeLabel.text = String(describing: newVolInt)
								self.volumeLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
								if	self.firstVolumeUpdateSinceDidLoad {
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
		
		navigationItem.title = "Pi Volume"

		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "⚙", style: .plain, target: self, action: #selector(segueToSettings))
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+", style: .plain, target: self, action: #selector(notifyAddTabItem))
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		volumeLabel.text = UserDefaults.standard.string(forKey: K.UserDef.LastUIVolumeStr)
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		
		presetArray = (UserDefaults.standard.stringArray(forKey: K.UserDef.PresetStrArray))!
		
		presetTableView.allowsMultipleSelectionDuringEditing = false
		self.automaticallyAdjustsScrollViewInsets = false
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.presetTableView.flashScrollIndicators()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		UserDefaults.standard.set(presetArray, forKey:K.UserDef.PresetStrArray)
	}

	deinit
	{
		notifCtr.removeObserver(self)
	}
	
	
	func notifyAddTabItem() {
		notifCtr.post(
			name: NSNotification.Name("\(K.Notif.AddTabBarItem)"),
			object: self
		)
	}
	
	
	// MARK: -
	
	
	func segueToSettings() {
		// called from right NavBarItem
		performSegue(withIdentifier: "ToSettingsSegue", sender: self)
	}
	
	@IBAction func unwindFromSettings(unwindSegue: UIStoryboardSegue){
		// called when we are transitioned back to from SettingsViewCon
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		// called when we transition SettingsViewCon
	}
	
	
	// MARK: -
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		firstVolumeUpdateSinceDidLoad = false
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		
		UserDefaults.standard.set(String(Int(floor(sender.value))), forKey: K.UserDef.LastUIVolumeStr)
		UserDefaults.standard.synchronize()
		
		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"),
		              object: self,
		              userInfo: [K.Key.PercentValue:
						sender.value]
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

			presetArray[idxPath.row] = volumeLabel.text!
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
			presetArray[idxPath.row] = String(newPreset!)
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
		presetArray.append("Preset")
		presetTableView.reloadData()
		presetTableView.flashScrollIndicators()
	}

	
	// MARK: - table view delegate / datasource
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
		
		if let presetBtn = cell.viewWithTag(K.UIElementTag.PresetButton) as? UIButton {
			if presetArray.count >= indexPath.row + 1 {
				presetBtn.setTitle(presetArray[indexPath.row] as String, for: .normal)
			} else {
				presetBtn.setTitle("Preset", for: .normal)
			}
		}
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		updateViewConstraints()
		return presetArray.count
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
		let removedStr = presetArray.remove(at: sourceIndexPath.row)
		presetArray.insert(removedStr, at: destinationIndexPath.row)
		// seems like this method being here enables swipe-left to delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			presetArray.remove(at: indexPath.row)
			tableView.deleteRows(at: [indexPath], with: .fade)
		}
	}
	
}


extension UIView {
	// from: http://stackoverflow.com/questions/37705819/swift-find-superview-of-given-class-with-generics
	// returns either superview if of type T, or recursively superView's superViews
	
	// ???: explain this better - why does it stop recursing, why does it only return one, and is it the first of type?
	
	func superview<T>(of type: T.Type) -> T? {
		return superview as? T ?? superview.flatMap { $0.superview(of: T.self) }
	}
}
