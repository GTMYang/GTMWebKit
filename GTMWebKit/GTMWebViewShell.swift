//
//  GTMWebViewShell.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/11/9.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import WebKit

public protocol GTMWebViewShell {
    var web_title: String? { get }
    var gtm_canGoBacK: Bool { get }
    var gtm_canGoForward: Bool { get }
    var gtm_isLoading: Bool { get }
    var gtm_url: URL? { get }
    
    func gtm_load(_ request: URLRequest)
    func gtm_reload()
    func gtm_goBack()
    func gtm_goForward()
}

extension WKWebView: GTMWebViewShell {
    public var web_title: String? {
        return self.title
    }
    public var gtm_canGoBacK: Bool {
       return self.canGoBack
    }
    public var gtm_canGoForward: Bool {
        return self.canGoForward
    }
    public var gtm_isLoading: Bool {
        return self.isLoading
    }
    public var gtm_url: URL? {
        return self.url
    }
    
    public func gtm_load(_ request: URLRequest) {
        self.load(request)
    }
    public func gtm_reload() {
        self.reload()
    }
    public func gtm_goBack() {
        if self.canGoBack {
            self.goBack()
        }
    }
    public func gtm_goForward() {
        if self.canGoForward {
            self.goForward()
        }
    }
}

extension UIWebView: GTMWebViewShell {
    public var web_title: String? {
        return self.stringByEvaluatingJavaScript(from: "document.title")
    }
    public var gtm_canGoBacK: Bool {
        return self.canGoBack
    }
    public var gtm_canGoForward: Bool {
        return self.canGoForward
    }
    public var gtm_isLoading: Bool {
        return self.isLoading
    }
    public var gtm_url: URL? {
        return self.request?.url
    }
    
    public func gtm_load(_ request: URLRequest) {
        self.loadRequest(request)
    }
    public func gtm_reload() {
        self.reload()
    }
    public func gtm_goBack() {
        if self.canGoBack {
            self.goBack()
        }
    }
    public func gtm_goForward() {
        if self.canGoForward {
            self.goForward()
        }
    }
}
