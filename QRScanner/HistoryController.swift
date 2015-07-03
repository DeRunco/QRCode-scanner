//
//  HistoryController.swift
//  Barcode
//
//  Created by Charles Thierry on 26/06/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit


let kHistoryStorage = "History Key"
let historyCellId = "HistoryCellID"



class HistoryController: UITableViewController {
	let history: HistoryStorage

	func addEntry(sender: String) {
		
	}

	required init(coder: NSCoder) {
		history = HistoryStorage()
		history.loadInfo()
		super.init(coder: coder)
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return history.cachedHistory.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("") as! UITableViewCell!
		if cell == nil {
			cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: historyCellId)
		}
		cell!.textLabel!.text = history.cachedHistory[indexPath.row].toString()
		return cell!
	}

	@IBAction func refreshHistory(sender: UIButton!) {
		history.loadInfo()
		self.tableView.reloadData()
	}
	@IBAction func showScanner (sender: AnyObject) {
		self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
	}

}
