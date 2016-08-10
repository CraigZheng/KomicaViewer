//
//  ThreadTableViewProtocol.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine

protocol ThreadTableViewControllerProtocol: class {
    var forum: KomicaForum? { get }
    var threads: [Thread] { get set }
    var downloader: KomicaDownloader? { get }
    var completion: KomicaDownloaderHandler? { get }
    func refreshWithPage(page: Int)
}

extension ThreadTableViewControllerProtocol where Self: UITableViewController {
    
    var forum: KomicaForum? { return Forums.selectedForum }
    var downloader: KomicaDownloader? { return KomicaDownloader() }
    var completion: KomicaDownloaderHandler? {
        return { (success, result) in
            if success, let t = result?.threads {
                self.threads.appendContentsOf(t)
            }
            self.tableView.reloadData()
        }
    }
    func loadThreadsWithPage(page: Int) {
        if let forum = forum,
            let downloader = downloader
        {
            downloader.downloadListForRequest(KomicaDownloaderRequest(url: forum.listURLForPage(page), parser: forum.parserType, completion: completion))
        }
    }
    
    func loadResponsesWithThreadID(threadID: Int) {
        if let forum = forum, let downloader = downloader {
            downloader.downloadRepliesForRequest(KomicaDownloaderRequest(url: forum.responseURLForThreadID(threadID), parser: forum .parserType, completion: completion))
        }
    }
}