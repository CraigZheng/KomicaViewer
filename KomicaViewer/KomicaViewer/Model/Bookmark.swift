//
//  Bookmark.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

import KomicaEngine

class Bookmark: Equatable {
    
    var forum: KomicaForum
    var thread: KomicaEngine.Thread
    var date: Date?
    
    init(forum: KomicaForum, thread: KomicaEngine.Thread) {
        self.forum = forum
        self.thread = thread
        date = Date()
    }
  
    static func ==(left: Bookmark, right: Bookmark) -> Bool {
        return left.forum.isEqual(right.forum)
          && left.thread == right.thread
    }
  
}

fileprivate extension KomicaEngine.Thread {
    
    static func ==(left: KomicaEngine.Thread, right: KomicaEngine.Thread) -> Bool {
        return left.ID == right.ID &&
        left.UID == right.UID &&
        left.name == right.name &&
        left.email == right.email
    }
    
}

extension KomicaForum: Jsonable {
    
    static func jsonDecode(jsonDict: Dictionary<String, AnyObject>) -> Jsonable? {
        return KomicaForum.init(jsonDict: jsonDict)
    }
    
}

extension KomicaEngine.Thread: Jsonable {
    
    static func jsonDecode(jsonDict: Dictionary<String, AnyObject>) -> Jsonable? {
        let thread = KomicaEngine.Thread()
        thread.title = jsonDict["title"] as? String
        thread.rawHtmlContent = jsonDict["rawHtmlContent"] as? String
        thread.ID = jsonDict["ID"] as? String
        thread.UID = jsonDict["UID"] as? String
        thread.name = jsonDict["name"] as? String
        thread.email = jsonDict["email"] as? String
        if let thumbnailString = jsonDict["thumbnailURL"] as? String {
            thread.thumbnailURL = URL(string: thumbnailString)
        }
        if let imageURLString = jsonDict["imageURL"] as? String {
            thread.imageURL = URL(string: imageURLString)
        }
        thread.postDateString = jsonDict["postDateString"] as? String
        thread.warnings = jsonDict["warnings"] as? [String] ?? []
        thread.pushPost = jsonDict["pushPost"] as? [String]
        thread.videoLinks = jsonDict["videoLinks"] as? [String]
        
        return thread
    }
    
    @objc func jsonEncode() -> String? {
        var jsonDict = Dictionary<String, Any>()
        jsonDict["title"] = title
        jsonDict["rawHtmlContent"] = rawHtmlContent
        jsonDict["ID"] = ID
        jsonDict["UID"] = UID
        jsonDict["name"] = name
        jsonDict["email"] = email
        jsonDict["thumbnailURL"] = thumbnailURL?.absoluteString
        jsonDict["imageURL"] = imageURL?.absoluteString
        jsonDict["postDateString"] = postDateString
        jsonDict["warnings"] = warnings
        jsonDict["pushPost"] = pushPost
        jsonDict["videoLinks"] = videoLinks
        
        if jsonDict.count > 0,
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
        {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
}

extension Bookmark: Jsonable {
    
    static func jsonDecode(jsonDict: Dictionary<String, AnyObject>) -> Jsonable? {
        guard let thread = (jsonDict["thread"] as? String)
            .flatMap({ return $0.data(using: .utf8) })
            .flatMap({ return (try? JSONSerialization.jsonObject(with: $0,
                                                                options: .allowFragments)) as? Dictionary<String, AnyObject>  })
            .flatMap({ return KomicaEngine.Thread.jsonDecode(jsonDict: $0) }) as? KomicaEngine.Thread,
            let forum = (jsonDict["forum"] as? String)
                .flatMap({ return $0.data(using: .utf8) })
                .flatMap({ return (try? JSONSerialization.jsonObject(with: $0,
                                                                    options: .allowFragments)) as? Dictionary<String, AnyObject> })
                .flatMap({ return KomicaForum.jsonDecode(jsonDict: $0) }) as? KomicaForum,
            let date = jsonDict["date"] as? Double
            else {
                return nil
        }
        let bookmark = Bookmark(forum: forum, thread: thread)
        bookmark.date = Date(timeIntervalSince1970: date)
        return bookmark
    }
    
    func jsonEncode() -> String? {
        var jsonDict = Dictionary<String, Any>()
        jsonDict["forum"] = forum.jsonEncode()
        jsonDict["thread"] = thread.jsonEncode()
        jsonDict["date"] = date?.timeIntervalSince1970
        if jsonDict.count > 0,
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
}

extension Sequence where Iterator.Element == Bookmark {
    
    func jsonEncode() -> String? {
        var jsonArray = [String]()
        self.forEach { bookmark in
            if let jsonString = bookmark.jsonEncode() {
                jsonArray.append(jsonString)
            }
        }
        if jsonArray.count > 0,
            let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        {
            return String(data: jsonData, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    static func jsonDecode(jsonString: [String]) -> [Bookmark]? {
        let bookmarks = jsonString.compactMap { string -> Bookmark? in
            guard let jsonData = string.data(using: .utf8)
                , let jsonDict = (try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)) as? Dictionary<String, AnyObject> else { return nil }
            return Bookmark.jsonDecode(jsonDict: jsonDict) as? Bookmark
        }
        return bookmarks
    }
    
}
