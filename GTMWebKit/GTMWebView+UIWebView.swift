//
//  GTMWebView+UIWebView.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/11/9.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import JavaScriptCore

// MARK: - UIWebView
extension GTMWebViewController: UIWebViewDelegate {
    
    var uiWebView: UIWebView? {
        return self.webView as? UIWebView
    }
    
    func setupUiWebView() {
        // uiwebview
        let uiWebV = UIWebView.init(frame: self.view.bounds)
        uiWebV.backgroundColor = UIColor.white
        self.progresser = GTMWebViewProgress()
        self.progresser?.originWebViewDelegate = self
        self.progresser?.progressRenderDelegate = self
        uiWebV.delegate = self.progresser
        uiWebV.scalesPageToFit = true
        uiWebV.addGestureRecognizer(self.panGesture)
        self.view.addSubview(uiWebV)
        
        self.webView = uiWebV
    }
    
    // MARK: - UIWebViewDelegate
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let components = URLComponents(string: request.url?.absoluteString ?? "")
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
                return false
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
                    return false
                }
            }
        }
        
        if let url = request.url?.absoluteString {
            if url.hasSuffix(GTMWK_NET_ERROR_RELOAD_URL) || url.hasSuffix(GTMWK_404_NOT_FOUND_RELOAD_URL) {
                self.loadWebPage()
                print("GTMWebKit -----> do reload the web page")
                return false
            }
        }
        
        // snapShotView manage
        switch navigationType {
        case .linkClicked:
            self.pushSnapShotView()
        case .formSubmitted:
            self.pushSnapShotView()
        case .other:
            self.pushSnapShotView()
        default:
            break
        }
        // items update
        self.updateButtonItems()
        
        return true
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        // items update
        self.updateButtonItems()
        // api regist
        self.doApiRegist()
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        let nserror = error as NSError
        if nserror.code == NSURLErrorCancelled {
            return
        }

        self.didFailLoadWithError(error: nserror)
    }
    
    // MARK: - Private
    func uiwebv_onWebpageBack() {
        self.popSnapShotView()
        
        if isUseWebTitle {
            let time: TimeInterval = 1.0
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                self.title = self.webView?.web_title
            }
        }
        
        self.updateButtonItems()
    }
    
    func doApiRegist() {
        if let context = uiWebView?.value(forKey: "documentView.webView.mainFrame.javaScriptContext") as? JSContext {
//            for (key, val) in self.scriptHandlers {
//                context.setValue(val, forKey: key)
//            }
            // js 异常处理
            context.exceptionHandler = { (context, exceptionValue) in
                self.alert(String(describing: exceptionValue))
            }
        }
    }
    
}

extension GTMWebViewController: WebProgressRenderDelegate {
    func webViewProgressChanged(progress: Float) {
        self.progressView?.setProgress(progress, animated: true)
        let time: TimeInterval = 2.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
            self.progressView?.isHidden = (progress == 1)
        }
        if progress == 1 {
            print("GTMWebKit ---- > progress == 1")
            if isUseWebTitle {
                self.title = self.webView?.web_title
            }
        }
    }
}






