//
//  GTMWebViewProgress.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/11/10.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

protocol WebProgressRenderDelegate: class {
    func webViewProgressChanged(progress: Float)
}

struct ProgressSimulationValue {
    static let initial: Float = 0.1
    static let interactive: Float = 0.5
    static let final: Float = 0.9
}

class GTMWebViewProgress: NSObject {
    
    static let completeRPCURLPath: String = "/njkwebviewprogressproxy/complete"
    
    weak var progressRenderDelegate: WebProgressRenderDelegate?
    weak var originWebViewDelegate: UIWebViewDelegate?
    var loadingCount: Float = 0
    var maxLoadCount: Float = 0
    var isInteractive: Bool = false
    var currentURL: URL?
    var value: Float = 0 {
        didSet {
            self.progressRenderDelegate?.webViewProgressChanged(progress: value)
        }
    }
    
    // MARK: - Progress
    /// 开始进度
    func start() {
        if value < ProgressSimulationValue.initial {
            self.value = ProgressSimulationValue.initial
        }
    }
    /// 模拟进度
    func simulation() {
        var progress = self.value
        let maxProgress = isInteractive ? ProgressSimulationValue.final : ProgressSimulationValue.interactive
        let precent = loadingCount / maxLoadCount
        let increment = (maxProgress - progress) * precent
        progress += increment
        self.value = fminf(maxProgress, progress)
    }
    /// 完成进度
    func complete() {
        self.value = 1
    }
    /// 重置
    func reset() {
        self.maxLoadCount = 0
        self.loadingCount = 0
        self.isInteractive = false
        self.value = 0
    }
    
}

extension GTMWebViewProgress: UIWebViewDelegate {
    
    // MARK: - UIWebViewDelegate
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        if (request.url?.path ?? "") == GTMWebViewProgress.completeRPCURLPath {
            self.complete()
            return false
        }
        
        var ret = true
        if let delegate = self.originWebViewDelegate {
            ret = delegate.webView!(webView, shouldStartLoadWith: request, navigationType: navigationType)
        }
        
        var isFragmentJump = false
        if let _ = request.url?.fragment {
            isFragmentJump = true
        }
        
        var isTopLevelNavigation = false
        if let mainUrl = request.mainDocumentURL, let url = request.url {
            isTopLevelNavigation = (mainUrl == url)
        }
        
        let scheme = request.url?.scheme ?? ""
        let isHTTPOrLocalFile = (scheme == "http") || (scheme == "https") || (scheme == "file")
        
        if ret && !isFragmentJump && isHTTPOrLocalFile && isTopLevelNavigation {
            self.currentURL = request.url
            self.reset()
        }
        
        return ret
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
        self.originWebViewDelegate?.webViewDidStartLoad?(webView)
        
        self.loadingCount += 1
        self.maxLoadCount = fmaxf(loadingCount, maxLoadCount)
        
        self.start()
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        self.originWebViewDelegate?.webViewDidFinishLoad?(webView)
        
        self.progressWithStateOfWebView(webV: webView, error: nil)
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.originWebViewDelegate?.webView?(webView, didFailLoadWithError: error)
        
        self.progressWithStateOfWebView(webV: webView, error: error)
    }
    
    // Private
    func progressWithStateOfWebView(webV: UIWebView, error: Error?) {
        if let _ = error {
            self.complete()
            return
        }
        self.loadingCount -= 1
        self.simulation() // 设置模拟进度
        
        let readyState = webV.stringByEvaluatingJavaScript(from: "document.readyState")!
        if readyState == "interactive" {
            self.isInteractive = true
            if let req = webV.request {
                let mainURL = req.mainDocumentURL!
                let waitForCompleteJS = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '\(mainURL.scheme ?? "")://\(mainURL.host ?? "")\(GTMWebViewProgress.completeRPCURLPath)'; document.body.appendChild(iframe);  }, false);"
                webV.stringByEvaluatingJavaScript(from: waitForCompleteJS)
            }
        }
        
        var isNotRedirect = false
        if let cureentUrl = currentURL, let mainUrl = webV.request?.mainDocumentURL {
            isNotRedirect = (cureentUrl == mainUrl)
        }
        
        if readyState == "complete" && isNotRedirect {
            self.complete()
        }
        
    }
}
