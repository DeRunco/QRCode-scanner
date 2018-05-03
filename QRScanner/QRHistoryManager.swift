//
//  QRHistory.swift
//  QRScanner
//
//  Created by Charles Thierry on 02/05/2018.
//  Copyright © 2018 Weemo, Inc. All rights reserved.
//

import Foundation

let kHistoryStorage = "kHistoryStorage"
let kHistoryEntryUpdate = "kHistoryEntryUpdate"
func ==(lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
    return lhs.string == rhs.string
}


class HistoryEntry: NSObject, NSCoding{
    var date: Date!
    var string: String!
    var deletionMark: Bool = false
    var favorited: Bool = false {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(kHistoryEntryUpdate), object: nil)
        }
    }
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.date = aDecoder.decodeObject(forKey: "date") as! Date
        self.string = aDecoder.decodeObject(forKey:"string") as! String
        self.deletionMark = aDecoder.decodeBool(forKey:"deletion")
        self.favorited = aDecoder.decodeBool(forKey:"favorited")
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(date, forKey: "date")
        aCoder.encode(string, forKey: "string")
        aCoder.encode(deletionMark, forKey: "deletion")
        aCoder.encode(favorited, forKey: "favorited")
    }
    
    func toString() -> String {
        return "\(date!): \(string!)"
    }
}

var counter = 0;

class HistoryStorage{
    var cachedHistory = [HistoryEntry]()
    
    func isThereFavorites() -> Bool {
        self.loadInfo()
        let bob = self.cachedHistory
        for b in bob {
            if b.favorited { return true }
        }
        return false
    }
    
    func isAlreadySaved(his: HistoryEntry) -> Bool {
        self.loadInfo()
        let bob = self.cachedHistory
        for b in bob {
            if b.string == his.string { return true }
        }
        return false
    }
    
    func loadInfo() {
        cachedHistory.removeAll(keepingCapacity: true)
        let archivedHistory: Data? = UserDefaults.standard.object(forKey:kHistoryStorage) as! Data?
        guard let _  = archivedHistory else { return }
        let history = NSKeyedUnarchiver.unarchiveObject(with:archivedHistory!) as! [HistoryEntry]
        for entry in history {
            if (entry.deletionMark) {continue}
            cachedHistory.append(entry)
        }
        
    }
    
    func removeHistory(historyDescription: HistoryEntry){
        for bob in self.cachedHistory {
            if bob.string == historyDescription.string {
                bob.deletionMark = true
            }
        }
        self.saveInfo(entries:nil)
    }
    
    func markRowForDeletion(row: Int){
        self.cachedHistory[row].favorited = false
        self.cachedHistory[row].deletionMark = true
    }
    
    func saveInfo(entries:[HistoryEntry]!) {
        if (entries != nil) {
            for entry in entries {
                cachedHistory.append(entry)
            }
        }
        
        let dataForm = NSKeyedArchiver.archivedData(withRootObject:cachedHistory)
        UserDefaults.standard.set(dataForm, forKey: kHistoryStorage)
        UserDefaults.standard.synchronize()
        self.loadInfo()
    }
}

let history = HistoryStorage()
