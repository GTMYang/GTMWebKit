//
//  BarcodeScanable.swift
//  Olliix
//
//  Created by luoyang on 2017/9/6.
//  Copyright © 2017年 syncsoft. All rights reserved.
//

import Foundation
import swiftScan

protocol BarcodeScanable: OlliixScanViewControllerDelegate {
    func startScanBarcode(viewTitle: String)
}

extension BarcodeScanable where Self: UIViewController {
    
    /// 扫描方法
    func startScanBarcode(viewTitle: String) {
        //设置扫码区域参数
        var style = LBXScanViewStyle()
        
        style.centerUpOffset = 44
        style.photoframeAngleStyle = LBXScanViewPhotoframeAngleStyle.Inner
        style.photoframeLineW = 4
        style.photoframeAngleW = 28
        style.photoframeAngleH = 16
        style.isNeedShowRetangle = false
        
        style.anmiationStyle = LBXScanViewAnimationStyle.LineStill
        
        
        style.animationImage = createImageWithColor(color: UIColor.red)
        //非正方形
        //设置矩形宽高比
        style.whRatio = 4.3/2.18
        
        //离左边和右边距离
        style.xScanRetangleOffset = 30
        
        let scanViewController = OlliixScanViewController()
        scanViewController.title = viewTitle
        
        scanViewController.scanFor = .product
        scanViewController.delegate = self
        
        scanViewController.scanStyle = style
        
        self.navigationController?.pushViewController(scanViewController, animated: false)
    }
    
    private func createImageWithColor(color:UIColor)->UIImage {
        let rect=CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let theImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return theImage!
    }
}
