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
    var threads: [KomicaEngine.Thread] { get set }
    var downloader: KomicaDownloader? { get }
    var completion: KomicaDownloaderHandler? { get }
    var postCompletion: KomicaDownloaderHandler? { get set }
    func refresh()
    func refreshWithPage(_ page: Int)
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
                self?.threads.append(contentsOf: t)
            }
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
                self?.hideLoading()
                self?.postCompletion?(success, page, result)
            }
        }
    }
    func loadThreadsWithPage(_ page: Int) {
        if let forum = forum,
            let downloader = downloader
        {
            showLoading()
            if let targetURL = forum.listURLForPage(page) {
                let request = KomicaDownloaderRequest(url: targetURL, page: page, parser: forum.parserType, completion: completion)
                request.preferredEncoding = forum.textEncoding
                if forum.parserType == FutabaListParser.self {
                    request.preferredBaseURLString = targetURL.host
                }
                _ = downloader.downloadListForRequest(request)
            } else {
                completion?(false, 0, nil)
            }
        } else {
            completion?(false, 0, nil)
        }
    }
    
    func loadResponsesWithThreadID(_ threadID: Int) {
        showLoading()
        if let forum = forum, let downloader = downloader, let targetURL = forum.responseURLForThreadID(threadID)
        {
            let request = KomicaDownloaderRequest(url: targetURL, page: 0, parser: forum.parserType, completion: completion)
            request.preferredEncoding = forum.textEncoding
            if forum.parserType == FutabaListParser.self {
                request.preferredBaseURLString = targetURL.host
            }
            _ = downloader.downloadRepliesForRequest(request)
        } else {
            completion?(false, 0, nil)
        }
    }
}
