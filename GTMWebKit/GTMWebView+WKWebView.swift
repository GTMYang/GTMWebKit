//
//  GTMWebView+WKWebView.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/11/9.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import WebKit

// MARK: - WKWebView
extension GTMWebViewController: WKNavigationDelegate {
    
    public var wkWebView: WKWebView? {
        return self.webView
    }
    
    func setupWkWebView() {
        
        // init weakScriptHandler
        self.weakScriptHandler = WeakScriptMessageHandler(self)
        
        let configuration = WKWebViewConfiguration()    // 配置
        configuration.processPool = GTMWebViewController.sharedProcessPool // WkWebView 实例间共享Cookies
        configuration.preferences.minimumFontSize = 1
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsInlineMediaPlayback = true  // 允许视频播放回退
        configuration.userContentController = WKUserContentController()     // 交互对象
        configuration.userContentController.add(self.weakScriptHandler, name: "GTMWebKitAPI")
        let wkWebV = WKWebView(frame: self.view.bounds, configuration: configuration)     // WKWebView
        wkWebV.uiDelegate = self
        wkWebV.navigationDelegate = self
        wkWebV.allowsBackForwardNavigationGestures = true
        self.view.addSubview(wkWebV)
        self.webView = wkWebV
    }
    
    // MARK: - KVO
    
    public func wkwebv_addObservers() {
        wkWebView?.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        wkWebView?.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        wkWebView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    public func wkwebv_removeObservers() {
        wkWebView?.removeObserver(self, forKeyPath: "loading")
        wkWebView?.removeObserver(self, forKeyPath: "title")
        wkWebView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    public func wkwebv_observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            println("loading")
        } else if keyPath == "title" {
            if isUseWebTitle {
                self.title = self.webView.title
            }
            self.updateButtonItems() // 更新导航按钮状态
        } else if keyPath == "estimatedProgress" {
            self.progressView?.isHidden = false
            self.progressView?.setProgress(Float(wkWebView!.estimatedProgress), animated: true)
        }
        
        // 已经完成加载时，我们就可以做我们的事了
        if !wkWebView!.isLoading {
            self.progressView?.setProgress(0, animated: false)
            self.progressView?.isHidden = true
        }
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.webWillLoad()
    }
    // MARK: Initiating the Navigation
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    // MARK: Responding to Server Actions
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        println(navigation.description)
    }
    // Authentication Challenges
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var disposition: URLSession.AuthChallengeDisposition = URLSession.AuthChallengeDisposition.performDefaultHandling
        var credential: URLCredential?
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            disposition = URLSession.AuthChallengeDisposition.useCredential
            credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
        }
        
        completionHandler(disposition, credential)
    }
    // MARK: Tracking Load Progress
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        println("webView didFinish")
        // 共享 Cookies
        if isNeedShareCookies {
            if #available(iOS 11.0, *) {
                GTMWebViewCookies.shareWebViewCookies(url: webView.url!)
            }
        }
        self.webDidLoad()
    }
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // 如果出现频繁刷新的情况，说明页面占用内存确实过大，需要前端作优化处理
        if self.isTreatMemeryCrushWithReload {
            webView.reload() // 解决内存消耗过度出现白屏的问题
        }
    }
    // MARK: Permitting Navigation
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // Disable all the '_blank' target in page's target
        if let frame = navigationAction.targetFrame {
            if frame.isMainFrame {
                webView.evaluateJavaScript("var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}", completionHandler: nil)
            }
        }
        
        let components = URLComponents(string: navigationAction.request.url?.absoluteString ?? "")
        if let comp = components {
            // APP下载链接自动跳转AppStore 电话链接自动拨打电话 发邮件链接直接打开邮箱
            var predicate = NSPredicate(format: "SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'")
            if predicate.evaluate(with: comp.url?.absoluteString) { // AppStore 链接
                if let url = comp.url {
                    if UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
                decisionHandler(.cancel)
                return
            } else {
                predicate = NSPredicate(format: "SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'")
                if !predicate.evaluate(with: comp.scheme) {
                    if let url = comp.url {
                        if UIApplication.shared.canOpenURL(url) {
                            if #available(iOS 10.0, *) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            } else {
                                UIApplication.shared.openURL(url)
                            }
                        }
                    }
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        
        self.updateButtonItems() // 更新导航按钮状态
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        println("decidePolicyFor navigationResponse")
        decisionHandler(.allow)
    }
    // MARK: Reacting to Errors
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code == NSURLErrorCancelled {
            return
        }
        self.webDidLoadFail(error: nserror)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code == NSURLErrorCancelled {
            return
        }
        self.webDidLoadFail(error: nserror)
    }
}

extension GTMWebViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "GTMWebKitAPI" {
            if let body = message.body as? Dictionary<String, Any> {
                let method = body["method"] as! String
                println("\(body)")
                println("\(method)")
                
                if let handler = self.scriptHandlers[method] {
                    handler(body["body"])
                }
            }
        }
    }
}
