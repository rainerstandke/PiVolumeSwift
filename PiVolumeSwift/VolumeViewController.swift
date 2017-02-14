//
//  FirstViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit


class VolumeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{

	let notifCtr = NotificationCenter.default
	var firstVolumeUpdateSinceDidLoad = true
	
	@IBOutlet weak var presetTableView: UITableView!
	
	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var presetButton: UIButton! // OBSOLETE
	
	let presets = Array<String>()
	
	
	// MARK:
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
													self.volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
													
									})
								}
		}
		
		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.ConfirmedVolume)"),
		                     object: nil,
		                     queue: OperationQueue.main) { notif in
								self.volumeLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
		}
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		volumeLabel.text = UserDefaults.standard.string(forKey: K.UserDef.LastUIVolumeStr)
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.presetTableView.flashScrollIndicators()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	deinit
	{
		notifCtr.removeObserver(self)
	}
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		firstVolumeUpdateSinceDidLoad = false
		volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"),
		              object: self,
		              userInfo: [K.Key.PercentValue:
						sender.value]
		)
	}
	
	
	
	// MARK preset
	
	@IBAction func longPressRecognizer(_ lpGestRecog: UILongPressGestureRecognizer) {
		print("lpGestRecog: \(lpGestRecog)")
		
		
		// NEXT: check to see if tag == 9958 for preset btn, then set preset to int of curr text
		// THEN: make model in this con to store presets -> array of strings (for label texts)
		
		
		
		if lpGestRecog.state != .began {
			return
		}
		
		
		if lpGestRecog.view!.tag == 9958 {
			let presetBtn = lpGestRecog.view! as! UIButton
			presetBtn.setTitle(volumeLabel.text, for: .normal)
		}
		
		
	}
	
	
	@IBAction func stepped(_ stepper: UIStepper) {
		
		
		let presetButton = stepper.superview!.subviews.first { siblingOrSelf -> Bool in
			print("siblingOrSelf: \(siblingOrSelf)")
			return siblingOrSelf.tag == 9958
		} as! UIButton
		
		var newPreset: Int?
		if let currPreset = Int((presetButton.titleLabel?.text)!) {
			newPreset = currPreset + Int(stepper.value)
		} else {
			stepper.value = 0.0
			return
		}
		
		stepper.value = 0.0
		
		if newPreset! < 0 || newPreset! > 100 {
			return
		}
		print("newPreset: \(newPreset)")
		
		presetButton.setTitle(String(describing: newPreset), for: .normal)
		
		UIView.animate(withDuration: 0.3,
		               animations: {
						self.volumeSlider.setValue(Float(newPreset!), animated: true)
						self.volumeLabel.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
		})
		
		

		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"),
		              object: self,
		              userInfo: [K.Key.PercentValue: Float(newPreset!)]
		)

		
		
//		let currPresetValue = presetButton.titleLabel?.text
//		print("currPresetValue: \(currPresetValue)")
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
	
	
	// MARK table view delegate
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		print("indexPath: \(indexPath)")
		return tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		updateViewConstraints()
		return 2
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		print("will display cell @ indexPath: \(indexPath)")
		if indexPath.row == ((tableView.indexPathsForVisibleRows?.last)! as IndexPath).row {
			print("last")
			updateViewConstraints()
		}
	}


}

