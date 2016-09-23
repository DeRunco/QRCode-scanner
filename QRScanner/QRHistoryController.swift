//
//  HistoryController.swift
//  Barcode
//
//  Created by Charles Thierry on 26/06/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit

//history is kept as a global variable. should be done better...
let historyCellId = "HistoryCellID"

//This notification is fired on selecting a line while not editing
let kEntrySelectedFromHistoryNotification = "EntrySelectedFromHistory"
let kEntryUserInfo = "entry"


class HistoryControllerCell: UITableViewCell {
	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var detail: UILabel!
}

class QRHistoryController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		let refresh = UIRefreshControl()
		refresh.backgroundColor = UIColor.orange
		refresh.tintColor = UIColor.white
		refresh.addTarget(self, action: #selector(self.refreshHistory(sender:)),
		                  for: UIControlEvents.valueChanged)
		self.refreshControl = refresh
		self.tableView.allowsMultipleSelectionDuringEditing = true
	}
	


	func removeEntry(index: Int) {
		history.cachedHistory.remove(at:index)
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		history.loadInfo()
		return history.isThereFavorites() ? 2 : 1;
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		history.loadInfo()
		return history.cachedHistory.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier:historyCellId, for: indexPath) as! HistoryControllerCell
		cell.title!.text = "\(history.cachedHistory[indexPath.row].string)"
		let dateFor = DateFormatter()
		dateFor.dateFormat = "YYYY-MM-dd HH:mm"
		let dateDisplay = dateFor.stringFromDate(history.cachedHistory[indexPath.row].date)
		cell.detail!.text = "\(dateDisplay)"
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

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if tableView.editing {return}
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		//display the overlay
		let entry = history.cachedHistory[indexPath.row]
		NSNotificationCenter.defaultCenter().postNotificationName(kEntrySelectedFromHistoryNotification, object: nil, userInfo:[kEntryUserInfo:entry])
		self.performSegueWithIdentifier("removePopover", sender: self)
	}

	func refreshHistory(sender: AnyObject!) {
		history.loadInfo()
		self.tableView.reloadData()
		self.refreshControl!.endRefreshing()
	}

	@IBAction func showScanner (sender: AnyObject) {
	    self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
	}
	
	@IBAction func cancel(sender: UIBarButtonItem) {
		self.performSegueWithIdentifier("removePopover", sender: self)
	}
	
	
	func removeSelectedEntries() {
		if let array = self.tableView.indexPathsForSelectedRows as [NSIndexPath]! {
			//for i in array.indices.reversed() { //swift 3
			for i in (array.count ... 0) {
				history.markRowForDeletion(array[i].row)
			}
			history.saveInfo(nil)
			tableView.deleteRowsAtIndexPaths(array, withRowAnimation: UITableViewRowAnimation.Fade)
		}

	}


	@IBAction func startEditMode(sender: AnyObject) {
		if (self.tableView.editing){
			if let butSender: UIBarButtonItem = sender as? UIBarButtonItem {
				butSender.tintColor = nil
			}

			self.removeSelectedEntries();
			self.tableView.setEditing(false, animated: true);
		} else {
			if let butSender: UIBarButtonItem = sender as? UIBarButtonItem {
				butSender.tintColor = UIColor.redColor()
			}
			self.tableView.setEditing(true, animated: true);
		}
	}
}
