//
//  URLConvertible.swift
//  GTMWebKit
//
//  Created by luoyang on 2017/10/25.
//  Copyright © 2017年 yang. All rights reserved.
//

import Foundation

public protocol URLConvertible {
    func url() -> URL?
}

extension String: URLConvertible {
    public func url() -> URL? {
        return URL.init(string: self)
    }
}

extension URL: URLConvertible {
    public func url() -> URL? {
        return self
    }
}
