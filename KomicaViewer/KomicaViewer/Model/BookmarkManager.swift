//
//  BookmarkManager.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

class BookmarkManager {
    static let shared = BookmarkManager()
    let userDefault = UserDefaults.standard
    private let bookmarkKey = "bookmarkKey"
    
    var bookmarks: [Bookmark] {
        guard let jsonString = userDefault.string(forKey: bookmarkKey),
            let jsonArray = jsonString.data(using: .utf8)
                .flatMap({ return try? JSONSerialization.jsonObject(with: $0, options: .allowFragments) }) as? [String] else {
                  return []
        }
        return [Bookmark].jsonDecode(jsonString: jsonArray) ?? []
    }
    
    func add(_ bookmark: Bookmark) {
        var bookmarks = self.bookmarks
        bookmarks.append(bookmark)
        if let jsonString = bookmarks.jsonEncode() {
            userDefault.set(jsonString, forKey: bookmarkKey)
        }
    }
    
    func remove(_ bookmark: Bookmark) {
        var bookmarks = self.bookmarks
        if let index = bookmarks.index(where: { storedBookmark -> Bool in
            return storedBookmark.jsonEncode() == bookmark.jsonEncode()
        }) {
            bookmarks.remove(at: index)
        }
        if let jsonString = bookmarks.jsonEncode() {
            userDefault.set(jsonString, forKey: bookmarkKey)
        }
    }
}
