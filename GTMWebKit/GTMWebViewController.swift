//
//  GTMWebViewController.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/10/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import WebKit

public enum GTMWK_NavigationType {
    case navbar     // web导航控制按钮放在导航栏
    case toolbar    // web导航控制按钮放在底部工具栏
}

public class GTMWebViewController: UIViewController, GTMAlertable {
    
    let GTMWK_404_NOT_FOUND_RELOAD_URL = "gtmwk_404_not_found"
    let GTMWK_NET_ERROR_RELOAD_URL = "gtmwk_network_error"
    
    var GTMWK_404_NOT_FOUND_HTML_PATH: String {
        return Bundle.init(for: GTMWebViewController.self).path(forResource: "GTMWebKit.bundle/html.bundle/404", ofType: "html")!
    }
    var GTMWK_NET_ERROR_HTML_PATH: String {
        return Bundle.init(for: GTMWebViewController.self).path(forResource: "GTMWebKit.bundle/html.bundle/neterror", ofType: "html")!
    }
    
    // MARK: - public props
    public var webView: WKWebView?
    public var isShowCloseItem = true
    public var isShowToolbar = true
    
    // MARK: - private props
    private var webUrl: URL?
    /// 网页加载进度指示器
    private var progressView: UIProgressView?
    
    private var navigType: GTMWK_NavigationType!
    // MARK: Navigation Items
    private var navbarItemBack: UIBarButtonItem?
    private var navbarItemClose: UIBarButtonItem?
    // MARK: ToolBar Items
    private var toolbarItemBack: UIBarButtonItem?
    private var toolbarItemForward: UIBarButtonItem?
    private var toolbarItemRefresh: UIBarButtonItem?
    private var toolbarItemAction: UIBarButtonItem?
    
    /// 弱代理（处理内存泄漏的问题）
    private var weakScriptHandler: WeakScriptMessageHandler!
    /// 提供给JS的API容器
    private var scriptHandlers: [String: (_ body: Any?) -> Void] = [:]
    
    // MARK: - Life Cycle
    
    public init(with url: URLConvertible, navigType type: GTMWK_NavigationType) {
        super.init(nibName: nil, bundle: nil)
        self.webUrl = url.url()
        self.navigType = type
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
        self.load()     // 加载网页
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isShowToolbar && self.navigType == .toolbar {
            self.navigationController?.setToolbarHidden(false, animated: animated)
        }
        self.updateButtonItems() // 更新导航按钮状态
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    private func setup() {
        // init weakScriptHandler
        self.weakScriptHandler = WeakScriptMessageHandler(self)
        
        /// init sub views
        // web view
        let configuration = WKWebViewConfiguration()    // 配置
        configuration.preferences.minimumFontSize = 10
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsInlineMediaPlayback = true  // 允许视频播放回退
        configuration.userContentController = WKUserContentController()     // 交互对象
        self.webView = WKWebView(frame: self.view.bounds, configuration: configuration)     // WKWebView
        self.webView?.uiDelegate = self
        self.webView?.navigationDelegate = self
        self.webView?.allowsBackForwardNavigationGestures = true
        self.view.addSubview(self.webView!)
        
        // progress view
        self.progressView = UIProgressView(progressViewStyle: .default)
        self.progressView?.frame = self.view.bounds
        let top = self.navigationController?.navigationBar.bounds.size.height ?? 0
        self.progressView?.frame.origin.y = top > 0 ? top + CGFloat(20) : 0
        self.progressView?.trackTintColor = UIColor.white
        self.progressView?.tintColor = UIColor.orange
        self.view.addSubview(self.progressView!)
        
        // add observers
        self.addObservers()
        
        // init button items
        self.initButtonItems()
    }
    
    deinit {
        print("GTMWebKit -----> GTMWebViewController deinit")
        self.removeObservers()
    }
    
    // MARK: - Public
    /// 注册API
    public func registApi(for name: String, with handler: @escaping (_ body: Any?) -> Void) {
        // 添加到容器
        self.scriptHandlers[name] = handler
        // 注册
        self.webView?.configuration.userContentController.add(self.weakScriptHandler, name: name)
    }
    /// 注入JS
    public func injectUserScript(script: WKUserScript) {
        self.webView?.configuration.userContentController.addUserScript(script)
    }
    
    // MARK: - Private
    private func load() {
        guard let url = self.webUrl else {
            fatalError("GTMWebKit ----->没有为GTMWebViewController提供网页的URL")
        }
        
        self.loadUrl(url: url)
    }
    
    private func loadUrl(url: URL) {
        webView?.load(URLRequest.init(url: url))
    }
    
}

extension GTMWebViewController: WKScriptMessageHandler {
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let handler = self.scriptHandlers[message.name] {
            handler(message.body)
        }
    }
}

// MARK: - 加载进度
extension GTMWebViewController: WKNavigationDelegate {
    
    private func addObservers() {
        self.webView?.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        self.webView?.addObserver(self, forKeyPath: "title", options: .new, context: nil)
        self.webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    private func removeObservers() {
        self.webView?.removeObserver(self, forKeyPath: "loading")
        self.webView?.removeObserver(self, forKeyPath: "title")
        self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    // MARK: - KVO
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            print("GTMWebKit ----->loading")
        } else if keyPath == "title" {
            self.title = self.webView?.title
            self.updateButtonItems() // 更新导航按钮状态
        } else if keyPath == "estimatedProgress" {
            self.progressView?.isHidden = false
            self.progressView?.setProgress(Float(webView!.estimatedProgress), animated: true)
        }
        
        // 已经完成加载时，我们就可以做我们的事了
        if !webView!.isLoading {
            self.progressView?.setProgress(0, animated: false)
            self.progressView?.isHidden = true
        }
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    // MARK: Initiating the Navigation
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    // MARK: Responding to Server Actions
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
        print(navigation.description)
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
        
    }
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
    // MARK: Permitting Navigation
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
//        print("GTMWebKit ----->\(navigationAction.request.url?.absoluteString ?? "")\n")
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
        
        if let url = navigationAction.request.url?.absoluteString {
            if url.hasSuffix(GTMWK_NET_ERROR_RELOAD_URL) || url.hasSuffix(GTMWK_404_NOT_FOUND_RELOAD_URL) {
                self.load()
                print("GTMWebKit -----> do reload the web page")
                decisionHandler(.cancel)
                return
            }
        }
        
//        self.updateButtonItems() // 更新导航按钮状态
        decisionHandler(.allow)
    }
    public func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        print("GTMWebKit ----->decidePolicyFor navigationResponse")
        decisionHandler(.allow)
    }
    // MARK: Reacting to Errors
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code == NSURLErrorCancelled {
            return
        }
        self.didFailLoadWithError(error: nserror)
    }
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nserror = error as NSError
        if nserror.code == NSURLErrorCancelled {
            return
        }
        self.didFailLoadWithError(error: nserror)
    }
    // MARK: - 错误处理
    private func didFailLoadWithError(error: NSError) {
        if error.code == NSURLErrorCannotFindHost {
            self.loadUrl(url: URL.init(fileURLWithPath: self.GTMWK_404_NOT_FOUND_HTML_PATH))
        } else {
            self.loadUrl(url: URL.init(fileURLWithPath: self.GTMWK_NET_ERROR_HTML_PATH))
        }
    }
}

extension GTMWebViewController {
    // MARK: - Web Navigation Items
    
    fileprivate func initButtonItems() {
        let bundle = self.sourceBundle
        
        // back button
        var iconBack = UIImage.init(named: "back", in: bundle, compatibleWith: nil)
        if let image = self.navigationController?.navigationBar.backIndicatorImage {
            iconBack = image
        }
        let buttonBack = UIButton.init(type: .custom)
        buttonBack.setImage(iconBack, for: .normal)
        buttonBack.sizeToFit()
        
        if navigType == .navbar {
            // back item
            buttonBack.addTarget(self, action: #selector(onNavigationBack), for: .touchUpInside)
            self.navbarItemBack = UIBarButtonItem.init(customView: buttonBack)
            // close item
            let title = NSLocalizedString("close", bundle: bundle, comment: "")
            self.navbarItemClose = UIBarButtonItem.init(title: title, style: .plain, target: self, action: #selector(onNavigationClose))
        } else {
            // back item
            buttonBack.addTarget(self, action: #selector(onToolbarBack), for: .touchUpInside)
            self.toolbarItemBack = UIBarButtonItem.init(customView: buttonBack)
            // forward item
            let iconForward = UIImage.init(named: "forward", in: bundle, compatibleWith: nil)
            let buttonForward = UIButton.init(type: .custom)
            buttonForward.setImage(iconForward, for: .normal)
            buttonForward.sizeToFit()
            buttonForward.addTarget(self, action: #selector(onToolbarForward), for: .touchUpInside)
            self.toolbarItemForward = UIBarButtonItem.init(customView: buttonForward)
            // refresh item
            self.toolbarItemRefresh = UIBarButtonItem.init(barButtonSystemItem: .refresh, target: self, action: #selector(onToolbarRefresh))
            // action item
            self.toolbarItemAction = UIBarButtonItem.init(barButtonSystemItem: .action, target: self, action: #selector(onToolbarAction))
        }
    }
    
    // MARK: - Navigation Events
    
    @objc func onNavigationBack() {
        if webView!.canGoBack {
            webView?.goBack()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    @objc func onNavigationClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func onToolbarBack() {
        if webView!.canGoBack {
            webView?.goBack()
        }
    }
    @objc func onToolbarForward() {
        if webView!.canGoForward {
            webView?.goForward()
        }
    }
    @objc func onToolbarRefresh() {
        webView?.reload()
    }
    @objc func onToolbarAction() {
        if let url = webView?.url {
            let activityVC = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: Update Items
    
    func updateButtonItems() {
        if navigType == .navbar {
            self.updateNavbarButtonItems()
        } else {
            self.updateToolbarButtonItems()
        }
    }
    func updateNavbarButtonItems() {
        self.navigationItem.setLeftBarButtonItems(nil, animated: false)
        if webView!.canGoBack {
            print("GTMWebKit -----> disable interactivePopGestureRecognizer ")
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            if let navigC = self.navigationController {
                let space = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                space.width = 10
                if navigC.viewControllers.count > 1 {
                    if self.isShowCloseItem {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!, space, self.navbarItemClose!, space], animated: false)
                    } else {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!, space], animated: false)
                    }
                } else {
                    if self.isShowCloseItem {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!, space, self.navbarItemClose!, space], animated: false)
                    } else {
                        self.navigationItem.setLeftBarButtonItems(nil, animated: false)
                    }
                }
            }
        } else {
            print("GTMWebKit -----> enable interactivePopGestureRecognizer ")
            self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!], animated: false)
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    func updateToolbarButtonItems() {
        self.toolbarItemBack?.isEnabled = webView!.canGoBack
        self.toolbarItemForward?.isEnabled = webView!.canGoForward
        self.toolbarItemAction?.isEnabled = !webView!.isLoading
        
        let space = UIBarButtonItem.init(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        let items = [self.toolbarItemBack!, space, self.toolbarItemForward!, space, self.toolbarItemRefresh!, space, self.toolbarItemAction!]
        self.navigationController?.toolbar.barStyle = (self.navigationController?.navigationBar.barStyle)!
        self.navigationController?.toolbar.tintColor = self.navigationController?.navigationBar.tintColor
        self.navigationController?.toolbar.barTintColor = self.navigationController?.navigationBar.barTintColor
        self.toolbarItems = items
    }
}

