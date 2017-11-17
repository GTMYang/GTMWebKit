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

open class GTMWebViewController: UIViewController, GTMAlertable {
    
    let GTMWK_404_NOT_FOUND_RELOAD_URL = "gtmwk_404_not_found"
    let GTMWK_NET_ERROR_RELOAD_URL = "gtmwk_network_error"
    
    var GTMWK_404_NOT_FOUND_HTML_PATH: String {
        return Bundle.init(for: GTMWebViewController.self).path(forResource: "GTMWebKit.bundle/html.bundle/404", ofType: "html")!
    }
    var GTMWK_NET_ERROR_HTML_PATH: String {
        return Bundle.init(for: GTMWebViewController.self).path(forResource: "GTMWebKit.bundle/html.bundle/neterror", ofType: "html")!
    }
    
    // MARK: - 通用属性
    public var webView: GTMWebViewShell?
    public var isShowCloseItem = true   // 是否显示关闭按钮（navigType == .navbar 时使用）
    public var isShowToolbar = true     // 是否显示工具栏（navigType == .toolbar 时使用）
    public var isForcedUIWebView = false    // 强制使用 UIWebView
    public var isNeedShareCookies = false   // 是否需要共享cookies
    
    public var isUseWKWebView: Bool {
        if isForcedUIWebView {
            return false
        } else {
            if isNeedShareCookies {
                if #available(iOS 11.0, *) {
                    return true
                } else {
                    return false
                }
            } else {
                if #available(iOS 8.0, *) {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    // Private props
    private var webUrl: URL?
    /// 网页加载进度指示器
    var progressView: UIProgressView?
    
     var navigType: GTMWK_NavigationType! // 控制网页导航的方式（导航栏，工具栏）
    // MARK: Navigation Items
     var navbarItemBack: UIBarButtonItem?
     var navbarItemClose: UIBarButtonItem?
    // MARK: ToolBar Items
     var toolbarItemBack: UIBarButtonItem?
     var toolbarItemForward: UIBarButtonItem?
     var toolbarItemRefresh: UIBarButtonItem?
     var toolbarItemAction: UIBarButtonItem?
    
    
    // MARK: - WKWebView 属性
    // 是否使用reload的方式处理内存占用过大造成的白屏问题
    // 当打开的时候如果某个页面出现频繁刷新的情况，建议优化网页
    public var isTreatMemeryCrushWithReload = false
    /// 弱代理（处理内存泄漏的问题）
    public var weakScriptHandler: WeakScriptMessageHandler!
    /// 提供给JS的API容器
    var scriptHandlers: [String: (_ body: Any?) -> Void] = [:]
    // Cookies处理属性
    public static let sharedProcessPool = WKProcessPool()
    
    
    // MARK: - UIWebView 属性
    public var isSwipingBack: Bool = false      // 滑动状态标记
    public var snapshotVs: [UIView] = []
    public var currentSnapshotV: UIView?
    public var previousSnapshotV: UIView?
    var progresser: GTMWebViewProgress?
    
    // MARK: - Life Cycle
    
    public init(with url: URLConvertible, navigType type: GTMWK_NavigationType) {
        super.init(nibName: nil, bundle: nil)
        self.webUrl = url.url()
        self.navigType = type
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
        self.loadWebPage()     // 加载网页
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.isShowToolbar && self.navigType == .toolbar {
            self.navigationController?.setToolbarHidden(false, animated: animated)
        }
        self.updateButtonItems() // 更新导航按钮状态
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    private func setup() {
        // 导航栏不透明
        self.navigationController?.navigationBar.isTranslucent = false
        
        /// init sub views
        
        // web view
        if self.isUseWKWebView {
            // iOS 11 以上系统 使用 WKWebView (因为只有iOS11+中WKWebView才能彻底共享Cookies，所以只在这种情况使用WKWebView)
            // 因为iOS的更新率比较高， 所以很快大多数设备都能用上 WKWebView
            self.setupWkWebView()
        } else {
            // iOS 11 以下的系统还是使用UIWebView (UIWebView不需要做任何处理就能跟原生代码共享Cookies)
            self.setupUiWebView()
        }
        
        self.addObservers() // KVO
        
        // progress view
        self.progressView = UIProgressView(progressViewStyle: .default)
        self.progressView?.frame = self.view.bounds
//        let top = self.navigationController?.navigationBar.bounds.size.height ?? 0
//        self.progressView?.frame.origin.y = top > 0 ? top + CGFloat(20) : 0
        self.progressView?.trackTintColor = UIColor.white
        self.progressView?.tintColor = UIColor.gray
        self.view.addSubview(self.progressView!)
        
        // init button items
        self.initButtonItems()
        
        // 共享 Cookies
        if isNeedShareCookies {
            if #available(iOS 11.0, *) {
                GTMWebViewCookies.shareNativeCookies(url: self.webUrl!)
            }
        }
        
    }
    
    deinit {
        self.removeObservers()
        if !self.isUseWKWebView {
            self.progresser = nil
        }
        print("GTMWebKit -----> GTMWebViewController deinit")
    }
    
    // MARK: - Public
    /// 注册API
    public func registApi(method methodName: String, with handler: @escaping (_ body: Any?) -> Void) {
        // 添加到容器
        self.scriptHandlers[methodName] = handler
    }
    /// 注入JS
//    public func injectUserScript(script: WKUserScript) {
//        self.webView?.configuration.userContentController.addUserScript(script)
//    }
    
    // MARK: - Private
    func loadWebPage() {
        guard let url = self.webUrl else {
            fatalError("GTMWebKit ----->没有为GTMWebViewController提供网页的URL")
        }
        
        self.loadWithUrl(url: url)
    }
    
    func loadWithUrl(url: URL) {
        webView?.gtm_load(URLRequest.init(url: url))
    }
    
    // MARK: - 错误处理
    func didFailLoadWithError(error: NSError) {
        if error.code == NSURLErrorCannotFindHost {
            self.loadWithUrl(url: URL.init(fileURLWithPath: self.GTMWK_404_NOT_FOUND_HTML_PATH))
        } else {
            self.loadWithUrl(url: URL.init(fileURLWithPath: self.GTMWK_NET_ERROR_HTML_PATH))
        }
    }
    
    // MARK: - KVO
    func addObservers() {
        if self.isUseWKWebView {
            self.wkwebv_addObservers()
        }
    }
    func removeObservers() {
        if self.isUseWKWebView {
            self.wkwebv_removeObservers()
        }
    }
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if self.isUseWKWebView {
            self.wkwebv_observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
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
        buttonBack.frame = CGRect(x: 0, y: 0, width: 20, height: 44)
        if #available(iOS 11.0, *) {
            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        } else {
            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: -8, bottom: 12, right: 8)
        }
        
        if navigType == .navbar {
            // back item
            buttonBack.addTarget(self, action: #selector(onNavigationBack), for: .touchUpInside)
            self.navbarItemBack = UIBarButtonItem.init(customView: buttonBack)
            // close item
            let title = NSLocalizedString("close", bundle: bundle, comment: "")
            let closeButton = UIButton.init(type: .custom)
            closeButton.setTitle(title, for: .normal)
            closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            closeButton.setTitleColor(self.navigationController?.navigationBar.tintColor, for: .normal)
            closeButton.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
            if #available(iOS 11.0, *) {
                closeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10)
            } else {
                closeButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 5)
            }
           
            closeButton.addTarget(self, action: #selector(onNavigationClose), for: .touchUpInside)
            self.navbarItemClose = UIBarButtonItem.init(customView: closeButton)
        } else {
            // back item
            buttonBack.addTarget(self, action: #selector(onToolbarBack), for: .touchUpInside)
            self.toolbarItemBack = UIBarButtonItem.init(customView: buttonBack)
            // forward item
            let iconForward = UIImage.init(named: "forward", in: bundle, compatibleWith: nil)
            let buttonForward = UIButton.init(type: .custom)
            buttonForward.setImage(iconForward, for: .normal)
            buttonForward.frame = CGRect(x: 0, y: 0, width: 20, height: 44)
            if #available(iOS 11.0, *) {
                buttonForward.imageEdgeInsets = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
            } else {
                buttonForward.imageEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
            }
            buttonForward.addTarget(self, action: #selector(onToolbarForward), for: .touchUpInside)
            self.toolbarItemForward = UIBarButtonItem.init(customView: buttonForward)
            // refresh item
            self.toolbarItemRefresh = UIBarButtonItem.init(barButtonSystemItem: .refresh, target: self, action: #selector(onToolbarRefresh))
            // action item
            self.toolbarItemAction = UIBarButtonItem.init(barButtonSystemItem: .action, target: self, action: #selector(onToolbarAction))
        }
        
        
        // done
        if let navigationC = self.navigationController {
            if navigationC.isBeingPresented {
                // done item
                let title = NSLocalizedString("done", bundle: bundle, comment: "")
                let doneButton = UIButton.init(type: .custom)
                doneButton.frame = CGRect(x: 0, y: 0, width: 40, height: 44)
                doneButton.setTitle(title, for: .normal)
                doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                doneButton.setTitleColor(self.navigationController?.navigationBar.tintColor, for: .normal)
                doneButton.addTarget(self, action: #selector(onNavigationDone), for: .touchUpInside)
                let doneButtonItem = UIBarButtonItem.init(customView: doneButton)
                self.navigationItem.rightBarButtonItem = doneButtonItem
            }
        }
    }
    
    // MARK: - Navigation Events
    
    @objc func onNavigationDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func onNavigationBack() {
        if webView!.gtm_canGoBacK {
            self.onWebpageBack()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    @objc func onNavigationClose() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @objc func onToolbarBack() {
        self.onWebpageBack()
    }
    @objc func onToolbarForward() {
        webView?.gtm_goForward()
    }
    @objc func onToolbarRefresh() {
        webView?.gtm_reload()
    }
    @objc func onToolbarAction() {
        if let url = webView?.gtm_url {
            let activityVC = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func onWebpageBack() {
        webView?.gtm_goBack()
        if !self.isUseWKWebView {
            self.popSnapShotView()
            
            let time: TimeInterval = 1.0
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + time) {
                self.title = self.webView?.web_title
            }
            
            self.updateButtonItems()
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
        if webView!.gtm_canGoBacK {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            if let navigC = self.navigationController {
                if navigC.viewControllers.count > 1 {
                    if self.isShowCloseItem {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!, self.navbarItemClose!], animated: false)
                    } else {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!], animated: false)
                    }
                } else {
                    if self.isShowCloseItem {
                        self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!, self.navbarItemClose!], animated: false)
                    } else {
                        self.navigationItem.setLeftBarButtonItems(nil, animated: false)
                    }
                }
            }
        } else {
            self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!], animated: false)
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    func updateToolbarButtonItems() {
        self.toolbarItemBack?.isEnabled = webView!.gtm_canGoBacK
        self.toolbarItemForward?.isEnabled = webView!.gtm_canGoForward
        self.toolbarItemAction?.isEnabled = !webView!.gtm_isLoading
        
        let space = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let items = [self.toolbarItemBack!, space, self.toolbarItemForward!, space, self.toolbarItemRefresh!, space, self.toolbarItemAction!]
        self.navigationController?.toolbar.barStyle = (self.navigationController?.navigationBar.barStyle)!
        self.navigationController?.toolbar.tintColor = self.navigationController?.navigationBar.tintColor
        self.navigationController?.toolbar.barTintColor = self.navigationController?.navigationBar.barTintColor
        self.toolbarItems = items
    }
}

