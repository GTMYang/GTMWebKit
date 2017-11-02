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
            let webVC = GTMWebViewController.init(with: "https://github.com", navigType: .navbar)
            webVC.isShowCloseItem = false
            
            self.navigationController?.pushViewController(webVC, animated: true)
        } else if indexPath.row == 3 {
            // Native <-> JS
            
            let url = Bundle.main.url(forResource: "test", withExtension: "html")
            let webVC = CustomWebViewController.init(with: url!, navigType: .navbar)
            self.navigationController?.pushViewController(webVC, animated: true)
        }
    }

}

