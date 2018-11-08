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

func GTM_bundle() -> Bundle {
    let bundle = Bundle.init(for: GTMWebViewController.self)
    
    let resourcePath = bundle.path(forResource: "GTMWebKit", ofType: "bundle")
    if let path = resourcePath {
        let bundle2 = Bundle.init(path: path)
        if let bundle = bundle2 {
            return bundle
        }
    }
    
    return bundle
}
