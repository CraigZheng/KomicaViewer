//
//  AFHTTPSessionManager+Util.swift
//  Exellency
//
//  Created by Craig on 4/08/2016.
//  Copyright © 2016 cz. All rights reserved.
//

import Foundation

import AFNetworking

extension AFHTTPSessionManager {
    @objc class func sessionManager() -> AFHTTPSessionManager {
        let sessionManager = AFHTTPSessionManager()
        sessionManager.responseSerializer = AFHTTPResponseSerializer()
        return sessionManager
    }
}
