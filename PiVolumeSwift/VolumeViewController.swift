//
//  FirstViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/9/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit

class VolumeViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


	@IBOutlet weak var volumeLabel: UILabel!
	@IBOutlet weak var volumeSlider: UISlider!
	
	
	@IBAction func sliderMoved(_ sender: UISlider) {
		print("xxx")
		print(sender)
		
	}
}

