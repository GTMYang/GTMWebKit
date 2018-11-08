//
//  GTMWebControls.swift
//  GTMWebKit
//
//  Created by 骆扬 on 2018/11/8.
//  Copyright © 2018 yang. All rights reserved.
//

import UIKit

public protocol GTMWebErrorViewReloadHandler {
    /// 自定义View 可以通过此 block 刷新页面
    var reloadHandler: ()->Void { get set }
}

public typealias GTMWebErrorView = UIView & GTMWebErrorViewReloadHandler

class GTMWebNetErrorView: GTMWebErrorView {
    var reloadHandler: () -> Void = {}
    private var iconName: String?
    private var iconImageV: UIImageView!
    private var reloadButton: UIButton!
    
    convenience init(_ iconName: String) {
        let size = UIScreen.main.bounds.size
        self.init(frame: CGRect.init(x: (size.width - 320)/2, y: (size.height - 200)/2 - 64, width: 320, height: 200))
        self.iconName = iconName
        setup()
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        // icon
        let icon = UIImageView()
        let iconImage = UIImage.init(named: iconName ?? "", in: GTM_bundle(), compatibleWith: nil)
        icon.image = iconImage
        icon.sizeToFit()
        self.iconImageV = icon
        self.addSubview(iconImageV)
        // button
        let button = UIButton(type: .custom)
        button.setTitle("重新加载", for: .normal)
        button.setTitleColor(.gray, for: .normal)
        button.sizeToFit()
        button.addTarget(self, action: #selector(onReload), for: .touchUpInside)
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        self.reloadButton = button
        self.addSubview(reloadButton)
    }
    
    // MARK: - Event
    @objc func onReload() {
        self.reloadHandler()
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = self.bounds
        var y: CGFloat = 0
        if var size = iconImageV.image?.size {
            iconImageV.frame = CGRect(x: (frame.size.width - size.width)/2, y: y, width: size.width, height: size.height)
            y = size.height + 30
            size = CGSize.init(width: 200, height: 40)
            reloadButton.frame = CGRect(x: (frame.size.width - size.width)/2, y: y, width: size.width, height: size.height)
        }
        
    }
    
}

