//
//  GTMAlertable.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/10/26.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

public protocol GTMAlertable {
    func alert(_ message: String)
}

extension GTMAlertable where Self: UIViewController {
    public func alert(_ message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
}
