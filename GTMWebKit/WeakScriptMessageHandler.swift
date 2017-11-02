z//
//  WeakScriptMessageDelegate.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/10/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation
import WebKit

class WeakScriptMessageHandler:NSObject, WKScriptMessageHandler {
    weak var realHandler: WKScriptMessageHandler?
    
    init(_ realHandler: WKScriptMessageHandler) {
        super.init()
        self.realHandler = realHandler
    }
    
    // MARK:- WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.realHandler?.userContentController(userContentController, didReceive: message)
    }
}
