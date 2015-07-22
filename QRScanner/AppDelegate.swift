//
//  AppDelegate.swift
//  barcode_scanner
//
//  Created by Charles Thierry on 16/01/15.
//  Copyright (c) 2015 Charles Thierry. All rights reserved.
//

import UIKit

let kHistoryStorage = "History Key"

class HistoryEntry: NSObject, NSCoding {
	var date: NSDate!
	var string: String!
	var deletionMark: Bool = false
	override init() {
		super.init()
	}

	required init(coder aDecoder: NSCoder) {
		self.date = aDecoder.decodeObjectForKey("date") as! NSDate
		self.string = aDecoder.decodeObjectForKey("string") as! String
		self.deletionMark = aDecoder.decodeBoolForKey("deletion")
	}

	func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(date, forKey: "date")
		aCoder.encodeObject(string, forKey: "string")
		aCoder.encodeBool(deletionMark, forKey: "deletion")
	}


	func toString() -> String {
		return "\(date!): \(string!)"
	}
}

var counter = 0;

class HistoryStorage {
	var cachedHistory = [HistoryEntry]()

	func loadInfo() {
		cachedHistory.removeAll(keepCapacity: true)
		let archivedHistory: NSData! = NSUserDefaults.standardUserDefaults().objectForKey(kHistoryStorage) as! NSData!
		if archivedHistory == nil { return }
		let history = NSKeyedUnarchiver.unarchiveObjectWithData(archivedHistory) as! NSArray!
		for var count = 0; count < history.count; count++ {
			if let entry = history[count] as? HistoryEntry{
				if (entry.deletionMark) {continue}
				cachedHistory.append(entry)
			}
		}
	}

	func markRowForDeletion(row: Int){
		self.cachedHistory[row].deletionMark = true
	}

	func saveInfo(entries:[HistoryEntry]!) {
		if (entries != nil) {
			for entry:HistoryEntry in entries {
				cachedHistory.append(entry)
			}
		}
		var dataForm = NSKeyedArchiver.archivedDataWithRootObject(cachedHistory)
		NSUserDefaults.standardUserDefaults().setObject(dataForm, forKey: kHistoryStorage)
		NSUserDefaults.standardUserDefaults().synchronize()
		self.loadInfo()
	}
}

let history = HistoryStorage()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		history.loadInfo()
		return true
	}

	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}

}

