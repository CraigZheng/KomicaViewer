//
//  KomicaViewerTests.swift
//  KomicaViewerTests
//
//  Created by Craig on 9/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import XCTest

@testable import KomicaViewer
@testable import KomicaEngine

class KomicaViewerTests: XCTestCase {
    
    let animeHtmlString = "<div class=\"reply\" id=\"r88457\"><input type=\"checkbox\" name=\"88457\" value=\"delete\" /><span class=\"title\">無念</span> Name <span class=\"name\"></span> [16/04/06(水)22:54 ID:FYhAFZQ2] <a href=\"pixmicat.php?res=88400&amp;page_num=all#r88457\" class=\"qlink\">No.88457</a> &nbsp;<br />&nbsp;画像ファイル名：<a href=\"http://2cat.twbbs.org/~tedc21thc/anime/src/1459954470573.jpg\" rel=\"_blank\">1459954470573.jpg</a>-(15 KB, 640x360) <small>[サムネ表示]</small><br /><a href=\"http://2cat.twbbs.org/~tedc21thc/anime/src/1459954470573.jpg\" rel=\"_blank\"><img src=\"http://2cat.twbbs.org/~tedc21thc/anime/thumb/1459954470573s.jpg\" style=\"width: 125px; height: 71px;\" class=\"img\" alt=\"15 KB\" title=\"15 KB\" /></a><div class=\"quote\">請問OP1裡的那女孩裙中，的&quot;那女孩&quot;到底是誰??</div></div>"
    
    let forumString = "{\"name\":\"綜合學術討論\",\"header\":\"\",\"indexURL\":\"http://gzone-anime.info/UnitedSites/academic/\",\"listURL\":\"http://gzone-anime.info/UnitedSites/academic/<PAGE>.htm\",\"responseURL\":\"http://gzone-anime.info/UnitedSites/academic/pixmicat.php?res=<ID>\",\"postURL\":\"\",\"replyURL\":\"\",\"parserType\":0}"
    
    lazy var forum: KomicaForum = {
        return KomicaForum.jsonDecode(jsonDict: try! JSONSerialization.jsonObject(with: self.forumString.data(using: .utf8)!, options: .allowFragments) as! Dictionary<String, AnyObject>) as! KomicaForum
    }()
    
    lazy var thread: KomicaEngine.Thread = {
        let animeElement = ObjectiveGumbo.parseDocument(with: self.animeHtmlString).elements(withClass: "reply").first as! OGElement
        return PixmicatThreadParser.threadWithOGElement(animeElement)!
    }()
    
    lazy var bookmark: Bookmark = {
        return Bookmark(forum: self.forum, thread: self.thread)
    }()

    
    func testThreadJsonEncoding() {
        let jsonString = thread.jsonEncode()!
        let decodedThread = KomicaEngine.Thread.jsonDecode(jsonDict: try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!,
                                                           options: .allowFragments) as! Dictionary<String, AnyObject>)
        XCTAssert(decodedThread != nil)
        
        if let decodedThread = decodedThread as? KomicaEngine.Thread {
            XCTAssert(thread.title == decodedThread.title)
            XCTAssert(thread.content?.string == decodedThread.content?.string)
            XCTAssert(thread.ID == decodedThread.ID)
            XCTAssert(thread.UID == decodedThread.UID)
            XCTAssert(thread.postDateString == decodedThread.postDateString)
            XCTAssert(thread.thumbnailURL == decodedThread.thumbnailURL)
            XCTAssert(thread.imageURL == decodedThread.imageURL)
            XCTAssert(thread.warnings.count == decodedThread.warnings.count)
        } else {
            XCTFail()
        }
    }
    
    func testForumJsonEncoding() {
        let jsonString = forum.jsonEncode()!
        let decodedForum = KomicaForum.jsonDecode(jsonDict: try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!, options: .allowFragments) as! Dictionary<String, AnyObject>)
        
        XCTAssert(decodedForum != nil)
        
        if let decodedForum = decodedForum as? KomicaForum {
            XCTAssert(decodedForum == forum)
        } else {
            XCTFail()
        }
    }
    
    func testBookmarkJsonEncoding() {
        let jsonString = bookmark.jsonEncode()!
        let decodedBookmark = Bookmark.jsonDecode(jsonDict: try! JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!,
                                                                                              options: .allowFragments) as! Dictionary<String, AnyObject>) as! Bookmark
        
        XCTAssert(bookmark.date?.timeIntervalSince1970 == decodedBookmark.date?.timeIntervalSince1970)
        XCTAssert(bookmark.forum == decodedBookmark.forum)
        XCTAssert(bookmark.thread.title == decodedBookmark.thread.title)
        XCTAssert(bookmark.thread.content?.string == decodedBookmark.thread.content?.string)
        XCTAssert(bookmark.thread.ID == decodedBookmark.thread.ID)
        XCTAssert(bookmark.thread.UID == decodedBookmark.thread.UID)
        XCTAssert(bookmark.thread.postDateString == decodedBookmark.thread.postDateString)
        XCTAssert(bookmark.thread.thumbnailURL == decodedBookmark.thread.thumbnailURL)
        XCTAssert(bookmark.thread.imageURL == decodedBookmark.thread.imageURL)
        XCTAssert(bookmark.thread.warnings.count == decodedBookmark.thread.warnings.count)
    }
    
    func testBookmarkManagerAdd() {
        if BookmarkManager.shared.bookmarks.count <= 0 {
          BookmarkManager.shared.add(bookmark)
        }
        let jsonArray = BookmarkManager.shared.bookmarks.jsonEncode()!.data(using: .utf8).flatMap({ return try! JSONSerialization.jsonObject(with: $0, options: .allowFragments) }) as! [String]
        let decodedBookmarks = [Bookmark].jsonDecode(jsonString: jsonArray)
      
        XCTAssert(BookmarkManager.shared.bookmarks.jsonEncode() == decodedBookmarks?.jsonEncode())
    }
  
  func testBookmarkManagerRemove() {
    let numberOfBookmarks = BookmarkManager.shared.bookmarks.count
    if BookmarkManager.shared.bookmarks.count > 1 {
      BookmarkManager.shared.remove(bookmark)
    }
    let jsonArray = BookmarkManager.shared.bookmarks.jsonEncode()!.data(using: .utf8).flatMap({ return try! JSONSerialization.jsonObject(with: $0, options: .allowFragments) }) as! [String]
    let decodedBookmarks = [Bookmark].jsonDecode(jsonString: jsonArray)
    
    XCTAssert(numberOfBookmarks > BookmarkManager.shared.bookmarks.count)
    XCTAssert(BookmarkManager.shared.bookmarks.jsonEncode() == decodedBookmarks?.jsonEncode())
  }
}
