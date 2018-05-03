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
		refresh.addTarget(self, action: #selector(refreshHistory(sender:)),
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
        var content: String
        if history.cachedHistory[indexPath.row].string == nil {
            content = "No Text"
        } else {
            content = history.cachedHistory[indexPath.row].string!
        }
        cell.title!.text = "\(content)"
		let dateFor = DateFormatter()
		dateFor.dateFormat = "YYYY-MM-dd HH:mm"
		let dateDisplay = dateFor.string(from:history.cachedHistory[indexPath.row].date)
		cell.detail!.text = "\(dateDisplay)"
		return cell
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 56.0
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
		if (editingStyle == UITableViewCellEditingStyle.delete) {
			history.cachedHistory.remove(at:indexPath.row)
			history.saveInfo(entries: nil)
			history.loadInfo()
			tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if tableView.isEditing {return}
		tableView.deselectRow(at: indexPath, animated: true)
		//display the overlay
		let entry = history.cachedHistory[indexPath.row]
		self.removeHistoryPopup()
        NotificationCenter.default.post(name: Notification.Name(kEntrySelectedFromHistoryNotification), object: nil, userInfo:[kEntryUserInfo:entry])
	}

	@objc func refreshHistory(sender: AnyObject!) {
		history.loadInfo()
		self.tableView.reloadData()
		self.refreshControl!.endRefreshing()
	}

	@IBAction func showScanner (sender: AnyObject) {
	    self.splitViewController!.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryHidden
	}
		
    func removeHistoryPopup () {
        self.dismiss(animated: true) {}
    }
	
	func removeSelectedEntries() {
		if let array = self.tableView.indexPathsForSelectedRows {
			for i in array.indices.reversed() {
				history.markRowForDeletion(row:array[i].row)
			}
			history.saveInfo(entries: nil)
			tableView.deleteRows(at:array, with: UITableViewRowAnimation.fade)
		}

	}

	@IBAction func startEditMode(sender: AnyObject) {
		if (self.tableView.isEditing){
			if let butSender: UIBarButtonItem = sender as? UIBarButtonItem {
				butSender.tintColor = nil
			}

			self.removeSelectedEntries();
			self.tableView.setEditing(false, animated: true);
		} else {
			if let butSender: UIBarButtonItem = sender as? UIBarButtonItem {
				butSender.tintColor = UIColor.red
			}
			self.tableView.setEditing(true, animated: true);
		}
	}
}
