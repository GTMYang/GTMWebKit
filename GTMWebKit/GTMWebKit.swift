//
//  GTMWebKit.swift
//  GTMWebKit
//
//  Created by 骆扬 on 2018/9/11.
//  Copyright © 2018年 yang. All rights reserved.
//

import Foundation

struct GTMWebKitConfig {
    static var debug: Bool = false
}

func println(_ msg: String) {
    if GTMWebKitConfig.debug {
        print("GTMWebKit -----> \(msg)")
    }
}
