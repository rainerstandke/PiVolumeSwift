//
//  PresetTableViewController.swift
//  PiVolumeSwift
//
//  Created by Rainer Standke on 2/12/17.
//  Copyright © 2017 Rainer Standke. All rights reserved.
//

import UIKit


class PresetTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate
{
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return tableView.dequeueReusableCell(withIdentifier: K.CellID.PresetTableViewCell)!
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	
}
