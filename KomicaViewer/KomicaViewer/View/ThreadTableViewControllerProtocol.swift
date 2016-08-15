//
//  ThreadTableViewProtocol.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 10/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

import KomicaEngine
import SVPullToRefresh

protocol ThreadTableViewControllerProtocol: class {
    var forum: KomicaForum? { get }
    var threads: [Thread] { get set }
    var downloader: KomicaDownloader? { get }
    var completion: KomicaDownloaderHandler? { get }
    var postCompletion: KomicaDownloaderHandler? { get set }
    func refresh()
    func refreshWithPage(page: Int)
}

extension ThreadTableViewControllerProtocol where Self: UITableViewController {
    
    var forum: KomicaForum? { return Forums.selectedForum }
    var downloader: KomicaDownloader? { return KomicaDownloader() }
    var completion: KomicaDownloaderHandler? {
        return { [weak self ](success, page, result) in
            if success, let t = result?.threads {
                if page == 0 {
                    // If page is 0, reset the threads.
                    self?.threads.removeAll()
                }
                self?.threads.appendContentsOf(t)
            }
            self?.tableView.reloadData()
            self?.refreshControl?.endRefreshing()
            self?.hideLoading()
            self?.tableView.pullToRefreshView?.stopAnimating()
            self?.postCompletion?(success: success, page: page, result: result)
        }
    }
    func loadThreadsWithPage(page: Int) {
        if let forum = forum,
            let downloader = downloader
        {
            showLoading()
            if let targetURL = forum.listURLForPage(page) {
                downloader.downloadListForRequest(KomicaDownloaderRequest(url: targetURL, page: page, parser: forum.parserType, completion: completion))
            } else {
                completion?(success: false, page: 0, result: nil)
            }
        }
    }
    
    func loadResponsesWithThreadID(threadID: Int) {
        showLoading()
        if let forum = forum, let downloader = downloader, let targetURL = forum.responseURLForThreadID(threadID)
        {
            downloader.downloadRepliesForRequest(KomicaDownloaderRequest(url: targetURL, page: 0, parser: forum .parserType, completion: completion))
        } else {
            completion?(success: false, page: 0, result: nil)
        }
    }
}