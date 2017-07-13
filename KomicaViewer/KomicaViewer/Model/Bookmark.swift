//
//  Bookmark.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

import KomicaEngine

class Bookmark {
  
  var forum: KomicaForum
  var thread: KomicaEngine.Thread
  
  init(forum: KomicaForum, thread: KomicaEngine.Thread) {
    self.forum = forum
    self.thread = thread
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
  
  func jsonEncode() -> String? {
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
