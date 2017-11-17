
<p align="center">
<a href="https://github.com/GTMYang/GTMWebKit"><img src="https://raw.githubusercontent.com/GTMYang/GTMWebKit/master/logo.png"></a>
</p>

<p align="center">
<a href="https://github.com/GTMYang/GTMWebKit"><img src="https://img.shields.io/badge/platform-ios-lightgrey.svg"></a>
<a href="https://github.com/GTMYang/GTMWebKit"><img src="https://img.shields.io/github/license/johnlui/Pitaya.svg?style=flat"></a>
<a href="https://github.com/GTMYang/GTMWebKit"><img src="https://img.shields.io/badge/language-Swift%203-orange.svg"></a>
<a href="https://travis-ci.org/GTMYang/GTMWebKit"><img src="https://img.shields.io/travis/johnlui/Pitaya.svg"></a>
</p>

<br>

GTMWebKit
===================
`GTMWebKit` swift 针对 WKWebView 的封装

# Introduction

- 使得在App内嵌网页变得非常简单
- 实现了类似微信里面的网页导航控制功能
- 注册JS使用的API方法变得简单
- 支持Swift4
- 支持与原生代码共享Cookies

# 关于Cookies共享
## 方法1: 将 isNeedShareCookies 属性至为true
    此种方式在iOS 11.0以后的系统中使用WKWebView，在iOS 11.0之前的系统中使用UIWebView
在使用WKWebView会自动同步WKWebsiteDataStore和HTTPCookieStorage中的Cookies
PS：此种方式我目前没经过详细测试，如果你们发现此种方式不同，建议告诉我，暂时先切到方法2
  ## 方法2: 将isForcedUIWebView 属性至为true
            此种方式强制使用UIWebView，Cookies共享没问题


# Demo
直接下载代码，里面详细的使用例子

# Installation

## Cocoapods

Install Cocoapods if need be.

```bash
$ gem install cocoapods
```

Add `GTMWebKit` in your `Podfile`.

```ruby
use_frameworks!

pod 'GTMWebKit'
```

Then, run the following command.

```bash
$ pod install
```


## Manual

Copy `GTMWebKit` folder to your project. That's it.

_**Note:** Make sure that all files in `GTMWebKit` included in Compile Sources in Build Phases._

# 版本

## Vesrion 0.0.3

This version requires Xcode 8.0 and Swift 3.

# 使用帮助

Firstly, import `GTMWebKit`.

```swift
import GTMWebKit
```

## Push方式内嵌网页
```swift
// Push
let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .navbar)
self.navigationController?.pushViewController(webVC, animated: true)
```

## Present方式内嵌网页
```swift
let webVC = GTMWebViewController.init(with: "https://www.baidu.com", navigType: .toolbar)
let navigationC = UINavigationController.init(rootViewController: webVC)
navigationC.navigationBar.tintColor = UIColor.gray
self.present(navigationC, animated: true, completion: nil)
```

## 注册JS使用的API

```swift
// 详细代码见Demo中CustomWebViewController.swift

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
```

## 配置项

```swift
public enum GTMWK_NavigationType {
    case navbar     // web导航控制按钮放在导航栏
    case toolbar    // web导航控制按钮放在底部工具栏
}

 var navigType: GTMWK_NavigationType!   // 控制网页导航的方式（导航栏，工具栏）
 var isShowCloseItem = true             // 是否显示关闭按钮（navigType == .navbar 时使用）
 var isShowToolbar = true               // 是否显示工具栏（navigType == .toolbar 时使用）
 var isForcedUIWebView = false      // 强制使用 UIWebView
 var isNeedShareCookies = false     // 是否需要共享cookies

```



#参与开源
欢迎提交 issue 和 PR，大门永远向所有人敞开。

#开源协议
本项目遵循 MIT 协议开源，具体请查看根目录下的 [LICENSE](https://raw.githubusercontent.com/GTMYang/GTMWebKit/master/LICENSE) 文件。


