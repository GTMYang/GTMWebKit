//
//  GTMWebViewCookies.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/11/16.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import WebKit

public class GTMWebViewCookies: NSObject {

    /// 将 HTTPCookieStorage 中的 Cookies 同步到 WKWebsiteDataStore 中
    public static func shareNativeCookies(url: URLConvertible) {
        if let _url = url.url() {
            if #available(iOS 11.0, *) {
                let cookiesStorage = HTTPCookieStorage.shared
                let cookies = cookiesStorage.cookies(for: _url)
                let selfCookies = cookies!.filter({ (cookie) -> Bool in
                    return cookie.domain == _url.host
                })
                
                let dataStore = WKWebsiteDataStore.default()
                for cookie in selfCookies {
                    dataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
                }
                
            }
        }
    }
    /// 将 WKWebsiteDataStore 中的 Cookies 同步到 HTTPCookieStorage 中
    public static func shareWebViewCookies(url: URLConvertible) {
        if let _url = url.url() {
            if #available(iOS 11.0, *) {
                let dataStore = WKWebsiteDataStore.default()
                dataStore.httpCookieStore.getAllCookies({ (cookies) in
                    let selfCookies = cookies.filter({ (cookie) -> Bool in
                        return cookie.domain == _url.host
                    })
                    let cookiesStorage = HTTPCookieStorage.shared
                    for cookie in selfCookies {
                        cookiesStorage.setCookie(cookie)
                    }
                })
            }
        }
    }
}
