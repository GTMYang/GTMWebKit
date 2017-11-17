//
//  WKWebViewCookiesVC.swift
//  GTMWebKitExample
//
//  Created by luoyang on 2017/11/16.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import WebKit
import GTMWebKit

class WKWebViewCookiesVC: GTMWebViewController {

    var lblCookies: UILabel!
    var btnShowCookies: UIButton!
    var btnShowNativeCookies: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup()
    }
    
    func setup() {
        self.title = "WKWebView Cookies"
        
        let screenSize = UIScreen.main.bounds
        // message label
        self.lblCookies = UILabel()
        lblCookies.frame = CGRect.init(x: 20, y: 84, width: screenSize.width - 40, height: 300)
        lblCookies.textAlignment = .left
        lblCookies.backgroundColor = .orange
        lblCookies.numberOfLines = 0
        lblCookies.isHidden = true
        self.view.addSubview(self.lblCookies)
        // button web cookies
        self.btnShowCookies = UIButton.init(type: .custom)
        btnShowCookies.frame = CGRect.init(x: 8, y: screenSize.height - 122, width: screenSize.width - 16 , height: 50)
        btnShowCookies.setTitle("WKWebsiteDataStore Cookies", for: .normal)
        btnShowCookies.setTitleColor(.white, for: .normal)
        btnShowCookies.backgroundColor = .gray
        btnShowCookies.layer.borderColor = UIColor.gray.cgColor
        btnShowCookies.layer.borderWidth = 1
        btnShowCookies.addTarget(self, action: #selector(onCallCookies), for: .touchUpInside)
        self.view.addSubview(self.btnShowCookies)
        // button native cookies
        self.btnShowNativeCookies = UIButton.init(type: .custom)
        btnShowNativeCookies.frame = CGRect.init(x: 8, y: screenSize.height - 180, width: screenSize.width - 16 , height: 50)
        btnShowNativeCookies.setTitle("HTTPCookieStorage Cookies", for: .normal)
        btnShowNativeCookies.setTitleColor(.white, for: .normal)
        btnShowNativeCookies.backgroundColor = .gray
        btnShowNativeCookies.layer.borderColor = UIColor.gray.cgColor
        btnShowNativeCookies.layer.borderWidth = 1
        btnShowNativeCookies.addTarget(self, action: #selector(onCallNativeCookies), for: .touchUpInside)
        self.view.addSubview(self.btnShowNativeCookies)
    }
//    
//    override func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//        
//        super.webView(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
//        
//        guard #available(iOS 11.0, *) else {
//            if let response = navigationResponse.response as? HTTPURLResponse {
//                let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as! [String : String], for: response.url!)
//                self.showCookies(cookies)
//            }
//            return
//        }
//    }
    
    // MARK: - Events
    
    @objc func onCallCookies() {
        // WKWebView 获取Cookies
        if #available(iOS 11.0, *) {
            let dataStore = WKWebsiteDataStore.default()
//            let dataStore = self.wkWebView?.configuration.websiteDataStore
            dataStore.httpCookieStore.getAllCookies({ (cookies) in
                let selfCookies = cookies.filter({ (cookie) -> Bool in
                    return cookie.domain == self.webView!.gtm_url!.host
                })
                self.showCookies(selfCookies)
            })
        }
    }
    
    @objc func onCallNativeCookies() {
        // UIWebView 获取Cookies
        let cookiesStorage = HTTPCookieStorage.shared
        let cookies = cookiesStorage.cookies(for: webView!.gtm_url!)
        
        let selfCookies = cookies!.filter({ (cookie) -> Bool in
            return cookie.domain == self.webView!.gtm_url!.host
        })
        
        self.showCookies(selfCookies)
    }
    
    
    // MARK: - Private
    fileprivate func showCookies(_ cookies: [HTTPCookie]) {
        let cookiesString = cookies.reduce("", { (re, cookie) -> String in
            return re + "     \(cookie.name): \(cookie.value)\n"
        })
        self.lblCookies.text = cookiesString
        
        DispatchQueue.main.async {
            self.lblCookies.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15, execute: {
                self.lblCookies.isHidden = true
            })
        }
    }

}

