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
	var presetVuCon: PresetTableViewController? = nil
	
	@IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var presetTableView: UITableView!
	override func updateViewConstraints() {
		print("presetTableView.contentSize.height: \(presetTableView.contentSize.height)")
		super.updateViewConstraints()
		tableViewHeightConstraint.constant = presetTableView.contentSize.height
		print("tableViewHeightConstraint.constant: \(tableViewHeightConstraint.constant)")
//		tableViewHeightConstraint.constant = 86
//		view.updateConstraints()
	}
	
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
									
									UIView.animate(withDuration: 2,
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
		
		
		presetVuCon = PresetTableViewController()
		
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	deinit
	{
		notifCtr.removeObserver(self)
	}
	
	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	@IBOutlet weak var presetButton: UIButton!
	
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
	
	@IBAction func longPressRecognizer(_ sender: UILongPressGestureRecognizer) {
		if sender.state != .began {
			return
		}
		presetButton.setTitle(volumeLabel.text, for: .normal)
	}
	
	
	@IBAction func stepped(_ stepper: UIStepper) {
//		print("stepper: \(stepper)")
		print("stepper.value: \(stepper.value)")
		stepper.value = 0.0
		
		let currPresetValue = presetButton.titleLabel?.text
		print("currPresetValue: \(currPresetValue)")
	}
	
	
	@IBAction func presetButtonTouched(_ sender: UIButton) {
		let presetValStr = (presetButton.titleLabel?.text)!
		volumeLabel.text = presetValStr
		volumeSlider.value = (presetValStr as NSString).floatValue

		sliderMoved(volumeSlider)
	}
	
	
	// MARK table view delegate
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		print("indexPath: \(indexPath)")
		return tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		updateViewConstraints()
		return 1
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		print("will display cell @ indexPath: \(indexPath)")
		if indexPath.row == ((tableView.indexPathsForVisibleRows?.last)! as IndexPath).row {
			print("last")
			updateViewConstraints()
		}
	}
	
//	-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//	{
//	if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
//	//end of loading
//	//for example [activityIndicator stopAnimating];
//	}
//	}
}

