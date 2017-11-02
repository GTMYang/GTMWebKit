//
//  GTMWebView+Bundle.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/10/30.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

extension GTMWebViewController {
    
    var sourceBundle: Bundle {
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
}
