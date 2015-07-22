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

	override func viewDidLoad() {
		super.viewDidLoad()
		let refresh = UIRefreshControl()
		refresh.backgroundColor = UIColor.orangeColor()
		refresh.tintColor = UIColor.whiteColor()
		refresh.addTarget(self, action: "refreshHistory:", forControlEvents: UIControlEvents.ValueChanged)
		self.refreshControl = refresh
		self.tableView.allowsMultipleSelectionDuringEditing = true
	}

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
			history.loadInfo()
			tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
		}
	}

	func refreshHistory(sender: AnyObject!) {
		history.loadInfo()
		self.tableView.reloadData()
		self.refreshControl!.endRefreshing()
	}

	@IBAction func showScanner (sender: AnyObject) {
		self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
	}

	func removeSelectedEntries() {
		if let array = self.tableView.indexPathsForSelectedRows() as! [NSIndexPath]! {
			for var i = array.count - 1; i >= 0 ; --i {
				history.markRowForDeletion(array[i].row)
			}
			history.saveInfo(nil)
			tableView.deleteRowsAtIndexPaths(array, withRowAnimation: UITableViewRowAnimation.Fade)
		}

	}


	@IBAction func startEditMode(sender: AnyObject) {
		if (self.tableView.editing){
			self.removeSelectedEntries();
			self.tableView.setEditing(false, animated: true);
		} else {
			self.tableView.setEditing(true, animated: true);
		}
	}
}
