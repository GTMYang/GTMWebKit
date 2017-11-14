//
//  CustomWebViewController.swift
//  GTMWebKitExample
//
//  Created by luoyang on 2017/11/1.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit
import GTMWebKit
import WebKit

class CustomWebViewController: GTMWebViewController {
    
    var lblJsMessage: UILabel!
    var btnCallJsMethod: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
        self.registApiForJs()
    }
    
    func setup() {
        self.title = "Native code <-> JS"
        
        let screenSize = UIScreen.main.bounds
        // message label
        self.lblJsMessage = UILabel()
        lblJsMessage.frame = CGRect.init(x: 0, y: 64, width: screenSize.width, height: 100)
        lblJsMessage.textAlignment = .center
        lblJsMessage.backgroundColor = .orange
        lblJsMessage.isHidden = true
        self.view.addSubview(self.lblJsMessage)
        // button
        self.btnCallJsMethod = UIButton.init(type: .custom)
        btnCallJsMethod.frame = CGRect.init(x: 8, y: screenSize.height - 58, width: screenSize.width - 16 , height: 50)
        btnCallJsMethod.setTitle("Swift 调用 JS 方法改变网页中控件颜色", for: .normal)
        btnCallJsMethod.setTitleColor(.black, for: .normal)
        btnCallJsMethod.backgroundColor = .white
        btnCallJsMethod.layer.borderColor = UIColor.gray.cgColor
        btnCallJsMethod.layer.borderWidth = 1
        btnCallJsMethod.addTarget(self, action: #selector(onCallJsMethod), for: .touchUpInside)
        self.view.addSubview(self.btnCallJsMethod)
    }

    func registApiForJs() {
        
        // 简单测试方法
        self.registApi(method: "test") { [weak self] (body) in
            print("\nCustomWebViewController -----> recived js message: \(body ?? "")\n\n")
            let message = "\(body ?? "")"
            self?.showMessage(message: message)
        }
        // 扫描功能API
        self.registApi(method: "scanBarcode") { [weak self] (body) in
            self?.startScanBarcode(viewTitle: "条码扫描")
        }
 
    }
    
    // MARK: - Events
    @objc func onCallJsMethod() {
        let wkwebV = self.webView as? WKWebView
        wkwebV?.evaluateJavaScript("changeColor();", completionHandler: nil)
    }
    
    // MARK: - Private
    fileprivate func showMessage(message: String) {
        self.lblJsMessage.text = message
        
        DispatchQueue.main.async {
            self.lblJsMessage.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                self.lblJsMessage.isHidden = true
            })
        }
    }

}

extension CustomWebViewController: ScanViewControllerDelegate, BarcodeScanable {
    
    // MARK: - ScanViewControllerDelegate
    func onScanSuccess(barcode: String) {
        let message = "条码内容为：\(barcode)"
        self.showMessage(message: message)
    }
}
