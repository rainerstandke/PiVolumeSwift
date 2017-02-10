//
//  FirstViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class VolumeViewController: UIViewController {

	let notifCtr = NotificationCenter.default
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		notifCtr.addObserver(forName: NSNotification.Name("\(K.Notif.VolChanged)"),
		                     object: nil,
		                     queue: OperationQueue.main) { (notif) in
			print(notif);
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
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
	
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		print("xxx")
		print(sender)
		
		notifCtr.post(name: NSNotification.Name("\(K.Notif.SliderMoved)"), object: self, userInfo: [K.Key.PercentValue: sender.value])
		
	}
}

