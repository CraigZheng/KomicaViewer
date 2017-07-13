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
