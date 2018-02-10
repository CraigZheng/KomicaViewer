//
//  Jsonable.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 13/7/17.
//  Copyright © 2017 Craig. All rights reserved.
//

import Foundation

protocol Jsonable {
  
  static func jsonDecode(jsonDict: Dictionary<String, AnyObject>) -> Jsonable?
  func jsonEncode() -> String?
  
}
