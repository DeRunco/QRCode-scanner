//
//  HistoryController.swift
//  Barcode
//
//  Created by Charles Thierry on 26/06/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit

let historyCellId = "HistoryCellID"

//history is kept as a global variable. should be done better...

class HistoryControllerCell: UITableViewCell {
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var detail: UILabel!
}

class QRHistoryController: UITableViewController, UITableViewDelegate, UITableViewDataSource {

	func removeEntry(index: Int) {
		history.cachedHistory.removeAtIndex(index)
	}

	override	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1;
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		history.loadInfo()
		return history.cachedHistory.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier(historyCellId, forIndexPath: indexPath) as! HistoryControllerCell
//		cell.textLabel!.text = history.cachedHistory[indexPath.row].toString()
		cell.title!.text = "\(history.cachedHistory[indexPath.row].string)"
		cell.detail!.text = "\(history.cachedHistory[indexPath.row].date)"
		return cell
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 56.0
	}

	override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return true
	}

	override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		if (editingStyle == UITableViewCellEditingStyle.Delete) {
			history.cachedHistory.removeAtIndex(indexPath.row)
			history.saveInfo(nil)
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
		}
	}

	@IBAction func refreshHistory(sender: UIButton!) {
		history.loadInfo()
		self.tableView.reloadData()
	}
	@IBAction func showScanner (sender: AnyObject) {
		self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
	}

}
