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
    func refresh()
    func refreshWithPage(page: Int)
}

extension ThreadTableViewControllerProtocol where Self: UITableViewController {
    
    var forum: KomicaForum? { return Forums.selectedForum }
    var downloader: KomicaDownloader? { return KomicaDownloader() }
    var completion: KomicaDownloaderHandler? {
        return { (success, page, result) in
            if success, let t = result?.threads {
                if page == 0 {
                    // If page is 0, reset the threads.
                    self.threads.removeAll()
                }
                self.threads.appendContentsOf(t)
            }
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }
    func loadThreadsWithPage(page: Int) {
        if let forum = forum,
            let downloader = downloader
        {
            downloader.downloadListForRequest(KomicaDownloaderRequest(url: forum.listURLForPage(page), page: page, parser: forum.parserType, completion: completion))
        }
    }
    
    func loadResponsesWithThreadID(threadID: Int) {
        showLoading()
        if let forum = forum, let downloader = downloader {
            downloader.downloadRepliesForRequest(KomicaDownloaderRequest(url: forum.responseURLForThreadID(threadID), page: 0, parser: forum .parserType, completion: completion))
        }
    }
}