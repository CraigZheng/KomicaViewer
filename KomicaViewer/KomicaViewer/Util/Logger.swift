//
//  Logger.swift
//  Exellency
//
//  Created by Craig Zheng on 9/07/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

func DLog(_ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
        NSLog("%@","[\((filename as NSString).lastPathComponent):\(line)] \(function) - \(message)")
    #endif
}

func DLog(_ error: Error?, filename: String = #file, function: String = #function, line: Int = #line) {
    if let error = error {
        DLog("\(error)", filename: filename, function: function, line: line)
    } else {
        DLog("Unknown Error", filename: filename, function: function, line: line)
    }
}
