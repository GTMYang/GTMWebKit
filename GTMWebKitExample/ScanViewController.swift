//
//  ScanViewController.swift
//  GTMWebKitExample
//
//  Created by luoyang on 2017/11/2.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

class ScanViewController: LBXScanViewController {
    
    weak var delegate: ScanViewControllerDelegate?
    
    // MARK: - handleCodeResult
    /**
     处理扫码结果，如果是继承本控制器的，可以重写该方法,作出相应地处理
     */
    open override func handleCodeResult(arrayResult:[LBXScanResult])
    {
        let result:LBXScanResult = arrayResult[0]
        
        print("swiftScan -> scan success: barcode = \(result.strScanned!)  type = [\(String(describing: result.strBarCodeType))]")
        self.delegate?.onScanSuccess(barcode: result.strScanned!)
        
        //        self.dismiss(animated: true, completion: nil)
        let _ = self.navigationController?.popViewController(animated: true)
    }

}
