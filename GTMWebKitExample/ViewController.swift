//
//  ViewController.swift
//  GTMWebKitExample
//
//  Created by luoyang on 2017/10/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import GTMWebKit

class ViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "nav_back")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Push
            let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .navbar)
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 1 {
            // Present
            let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .toolbar)
            let navigationC = UINavigationController.init(rootViewController: webVC)
            navigationC.navigationBar.tintColor = UIColor.gray
            self.present(navigationC, animated: true, completion: nil)
        } else if indexPath.row == 2 {
            // Github
            let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .both)
            self.navigationController?.pushViewController(webVC, animated: true)
        }   else if indexPath.row == 3 {
            // Github
            let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .none)
            self.navigationController?.pushViewController(webVC, animated: true)
        }  else if indexPath.row == 4 {
            // Github
            let webVC = GTMWebViewController.init(with: "https://github.com", navigType: .navbar)
            webVC.isShowCloseItem = false
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 5 {
            // WKWebView Native <-> JS
            let url = Bundle.main.url(forResource: "test", withExtension: "html")
            let webVC = CustomWebViewController.init(with: url!, navigType: .navbar)
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 6 {
            // WKWebView Cookies
            let webVC = WKWebViewCookiesVC.init(with: cookieTestUrl, navigType: .navbar)
            webVC.isShowCloseItem = false
            webVC.isShowToolbar = false
            webVC.isNeedShareCookies = true
            
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 7 {
            // 404
            let webVC = GTMWebViewController.init(with: "https://www.baidu1.com", navigType: .navbar)
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 8 {
            // back icon
            let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .navbar)
            webVC.backIconName = "cus_back"
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }
    
    var cookieTestUrl = "http://192.168.85.168" //"https://www.baidu.com" //

}

