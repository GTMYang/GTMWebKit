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
    case both       // 同时使用两种导航按钮
    case none       // 不使用web导航按钮
}

open class GTMWebViewController: UIViewController, GTMAlertable {
    
    // MARK: - 通用属性
    public var webView: WKWebView!
    public var isShowCloseItem = true   // 是否显示关闭按钮（navigType == .navbar 时使用）
    public var isShowToolbar = true     // 是否显示工具栏（navigType == .toolbar 时使用）
    public var isNeedShareCookies = false   // 是否需要共享cookies
    public var isUseWebTitle = true        // 是否使用网页的title
    public var backIconName: String?            // 返回按钮图标，可自行设置
    public var view404: GTMWebErrorView!            // 资源不存在的时候展示的UI，可自定义
    public var netErrorView: GTMWebErrorView!   // 网络错误的时候展示的UI，可自定义
    
    
    // Private props
    private var webUrl: URL?
    /// 网页加载进度指示器
    var progressView: UIProgressView?
    
    private var navigType: GTMWK_NavigationType        // 控制网页导航的方式（导航栏，工具栏）
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

    
    // MARK: - Life Cycle
    
    var urlCovertible: URLConvertible?
    public init(with url: URLConvertible, navigType type: GTMWK_NavigationType) {
        self.navigType = type
        super.init(nibName: nil, bundle: nil)
        self.urlCovertible = url
        self.webUrl = url.url()
        self.view404 = GTMWebNetErrorView("404")
        self.netErrorView = GTMWebNetErrorView("nosingle")
    }
    
    /// 如果当前不在根页面，回到并重新加载根页面。否则什么都不做
    public func reloadToRootPage() -> Bool {
        guard let url = self.urlCovertible?.url() else {
            return false
        }
        if self.webView.url!.absoluteString == url.absoluteString {
            return false
        }
        self.loadWithUrl(url: url)
        return true
    }
    /// reload当前页面
    public func reload() {
        self.webView.reload()
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
        
        switch navigType {
        case .navbar:
            self.navigationController?.setToolbarHidden(true, animated: animated)
        case .toolbar:
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
            self.navigationController?.setToolbarHidden(false, animated: animated)
        case .both:
            self.navigationController?.setToolbarHidden(false, animated: animated)
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        case .none:
            self.navigationController?.setToolbarHidden(true, animated: animated)
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
//
        self.updateButtonItems() // 更新导航按钮状态
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setup() {
        // 导航栏不透明
        self.navigationController?.navigationBar.isTranslucent = false
        
        /// init sub views
        
        // web view
        self.setupWkWebView()
        
        self.addObservers() // KVO
        
        // progress view
        self.progressView = UIProgressView(progressViewStyle: .default)
        self.progressView?.frame = self.view.bounds
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
        println("GTMWebViewController deinit")
    }
    
    // MARK: - Public
    /// 注册API
    public func registApi(method methodName: String, with handler: @escaping (_ body: Any?) -> Void) {
        // 添加到容器
        self.scriptHandlers[methodName] = handler
    }
    /// 注入JS
    public func injectUserScript(script: WKUserScript) {
        self.webView.configuration.userContentController.addUserScript(script)
    }
    
    // MARK: - Private
    func loadWebPage() {
        guard let url = self.webUrl else {
            println("没有为GTMWebViewController提供有效的网页URL")
            return
        }
        
        self.loadWithUrl(url: url)
    }
    
    func loadWithUrl(url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    // MARK: - 钩子函数
    // web加载完成(相当于抽象函数)
    open func webWillLoad() { }
    open func webDidLoad() {
        self.view404.removeFromSuperview()
        self.netErrorView.removeFromSuperview()
    }
    // 错误处理
    open func webDidLoadFail(error: NSError) {
        self.view404.removeFromSuperview()
        self.netErrorView.removeFromSuperview()
    
        if error.code == NSURLErrorCannotFindHost ||
            error.code == NSURLErrorCannotConnectToHost ||
            error.code == NSURLErrorResourceUnavailable {
            view404.reloadHandler = { [weak self] in
                self?.loadWebPage()
            }
            self.view.addSubview(view404)
        } else {
            netErrorView.reloadHandler = { [weak self] in
                self?.loadWebPage()
            }
            self.view.addSubview(netErrorView)
        }
    }
    
    // MARK: - KVO
    func addObservers() {
        self.wkwebv_addObservers()
    }
    func removeObservers() {
        self.wkwebv_removeObservers()
    }
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        self.wkwebv_observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
    
}

extension GTMWebViewController {
    // MARK: - Web Navigation Items
    
    fileprivate func initButtonItems() {
   
        switch navigType {
        case .navbar:
            self.initNavigationBarItems()
        case .toolbar:
            self.initBottomBarItems()
        case .both:
            self.initNavigationBarItems()
            self.initBottomBarItems()
        case .none:
            break
        }
        // done
        if let navigationC = self.navigationController {
            if navigationC.isBeingPresented {
                // done item
                let title = NSLocalizedString("done", bundle: self.sourceBundle, comment: "")
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
        // 更新状态
        self.updateButtonItems()
    }
    
    // MARK: - Navigation Events
    
    @objc func onNavigationDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func onNavigationBack() {
        if webView.canGoBack {
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
        webView.goForward()
    }
    @objc func onToolbarRefresh() {
        webView.reload()
    }
    @objc func onToolbarAction() {
        if let url = webView.url {
            let activityVC = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func onWebpageBack() {
        webView.goBack()
        self.updateButtonItems()
    }
    
    // MARK: Navigation Items
    
    private func initNavigationBarItems() {
        let bundle = sourceBundle
        var iconBack = UIImage.init(named: "nav_back", in: bundle, compatibleWith: nil)
        if let image = self.navigationController?.navigationBar.backIndicatorImage {
            iconBack = image
        }
        let buttonBack = UIButton.init(type: .custom)
        buttonBack.setImage(iconBack, for: .normal)
        buttonBack.sizeToFit()
//        buttonBack.frame = CGRect(x: 0, y: 0, width: 20, height: 44)
//        if #available(iOS 11.0, *) {
//            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
//        } else {
//            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: -8, bottom: 12, right: 8)
//        }
        
        if let backIcon = backIconName {
            iconBack = UIImage(named: backIcon)
            buttonBack.setImage(iconBack, for: .normal)
        }
        // back item
        buttonBack.addTarget(self, action: #selector(onNavigationBack), for: .touchUpInside)
        self.navbarItemBack = UIBarButtonItem.init(customView: buttonBack)
       // self.navigationItem.setLeftBarButtonItems([self.navbarItemBack!], animated: false)
        
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
    }
    private func initBottomBarItems() {
        let bundle = sourceBundle
        var iconBack = UIImage.init(named: "back", in: bundle, compatibleWith: nil)
        if let image = self.navigationController?.navigationBar.backIndicatorImage {
            iconBack = image
        }
        let buttonBack = UIButton.init(type: .system)
        buttonBack.setImage(iconBack, for: .normal)
        buttonBack.sizeToFit()
        buttonBack.frame = CGRect(x: 0, y: 0, width: 20, height: 44)
        if #available(iOS 11.0, *) {
            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        } else {
            buttonBack.imageEdgeInsets = UIEdgeInsets(top: 12, left: -8, bottom: 12, right: 8)
        }
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
    
    func updateButtonItems() {
        switch navigType {
        case .navbar:
            self.updateNavbarButtonItems()
        case .toolbar:
            self.updateToolbarButtonItems()
        case .both:
            self.updateNavbarButtonItems()
            self.updateToolbarButtonItems()
        default:
            break
        }
    }
    private func updateNavbarButtonItems() {
        self.navigationItem.setLeftBarButtonItems(nil, animated: false)
        if webView.canGoBack {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
            if let navigC = self.navigationController {
                var items: [UIBarButtonItem] = self.navigationItem.leftBarButtonItems ?? []
                if navigC.viewControllers.count > 1 {
                    if self.isShowCloseItem {
                        items.insert(self.navbarItemBack!, at: 0)
                        items.append(self.navbarItemClose!)
                        self.navigationItem.setLeftBarButtonItems(items, animated: false)
                    } else {
                        for (i, item) in items.enumerated() {
                            if item == self.navbarItemClose! {
                                items.remove(at: i)
                            }
                        }
                        self.navigationItem.setLeftBarButtonItems(items, animated: false)
                    }
                } else {
                    if self.isShowCloseItem {
                        items.insert(self.navbarItemBack!, at: 0)
                        items.append(self.navbarItemClose!)
                        self.navigationItem.setLeftBarButtonItems(items, animated: false)
                    } else {
                        for (i, item) in items.enumerated() {
                            if item == self.navbarItemClose! {
                                items.remove(at: i)
                            }
                        }
                        self.navigationItem.setLeftBarButtonItems(items, animated: false)
                    }
                }
            }
        } else {
            var items: [UIBarButtonItem] = self.navigationItem.leftBarButtonItems ?? []
            items.insert(self.navbarItemBack!, at: 0)
            self.navigationItem.setLeftBarButtonItems(items, animated: false)
           // self.navigationItem.setLeftBarButtonItems(nil, animated: false)
            self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    private func updateToolbarButtonItems() {
        self.toolbarItemBack?.isEnabled = webView.canGoBack
        self.toolbarItemForward?.isEnabled = webView.canGoForward
        self.toolbarItemAction?.isEnabled = !webView.isLoading
        
        let space = UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let items = [self.toolbarItemBack!, space, self.toolbarItemForward!, space, self.toolbarItemRefresh!, space, self.toolbarItemAction!]
        self.navigationController?.toolbar.barStyle = (self.navigationController?.navigationBar.barStyle)!
        self.navigationController?.toolbar.tintColor = self.navigationController?.navigationBar.tintColor
        self.navigationController?.toolbar.barTintColor = self.navigationController?.navigationBar.barTintColor
        self.toolbarItems = items
    }
}

