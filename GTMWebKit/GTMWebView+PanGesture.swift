//
//  GTMWebView+PanGesture.swift
//  GTMWebKit
//  UIWebView 侧滑回退支持
//
//  Created by luoyang on 2017/11/10.
//  Copyright © 2017年 yang. All rights reserved.
//

import UIKit

struct GTM_SwipeLimit {
    static let limitX: CGFloat = 60
}

extension GTMWebViewController: UIGestureRecognizerDelegate {
    
    var panGesture: UIPanGestureRecognizer {
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(swipePanGestureHandler(panGesture:)))
        gesture.delegate = self
        
        return gesture
    }
    
    // MARK: - UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.location(in: self.view).x > GTM_SwipeLimit.limitX {
            return false
        } else {
            if self.uiWebView!.canGoBack {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
                return true
            } else {
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                return false
            }
        }
    }
    
    // MARK: - 侧滑手势
    
    @objc func swipePanGestureHandler(panGesture: UIPanGestureRecognizer) {
        let trans = panGesture.translation(in: self.view)
        
        switch panGesture.state {
        case .began:
           self.beginSwipeBack()
        case .changed:
            self.changeSwipeViewPosition(distance: trans.x)
        case .cancelled, .ended:
            self.endSwipeBack()
        default:
            break
        }
    }
    
    func beginSwipeBack() {
        if self.isSwipingBack == true {
            return
        }
        
        self.isSwipingBack = true
        self.currentSnapshotV = uiWebView?.snapshotView(afterScreenUpdates: true)
        
        // style
        self.currentSnapshotV?.layer.shadowColor = UIColor.black.cgColor
        self.currentSnapshotV?.layer.shadowOffset = CGSize(width: 3, height: 3)
        self.currentSnapshotV?.layer.shadowRadius = 3
        self.currentSnapshotV?.layer.shadowOpacity = 0.75
        
        // pos
        var frame = self.currentSnapshotV!.frame
        frame.origin.y = 0
        self.currentSnapshotV?.frame = frame
        
        self.previousSnapshotV = self.snapshotVs.last
        
        frame.origin.x -= GTM_SwipeLimit.limitX
        self.previousSnapshotV?.frame = frame
        self.previousSnapshotV?.alpha = 1
        
        self.view.addSubview(self.previousSnapshotV!)
        self.view.addSubview(self.currentSnapshotV!)
    }
    
    func changeSwipeViewPosition(distance: CGFloat) {
        if self.isSwipingBack == false {
            return
        }
        
        if distance <= 0 {
            return
        }
        
        let viewSize = self.view.bounds.size
        let webviewW = viewSize.width///, webviewH = viewSize.height
        
        self.currentSnapshotV?.center.x = webviewW/2 + distance
        
        self.previousSnapshotV?.center.x = (webviewW/2 - GTM_SwipeLimit.limitX) + distance/webviewW  *  GTM_SwipeLimit.limitX
    }
    
    func endSwipeBack() {
        if self.isSwipingBack == false {
            return
        }
        
        self.view.isUserInteractionEnabled = false // 暂时不响应事件
        
        let webviewW = self.view.bounds.size.width
        if currentSnapshotV!.center.x >= webviewW {
            UIView.animate(withDuration: 0.2, animations: {
                UIView.setAnimationCurve(.easeOut)
                
                self.previousSnapshotV?.center.x = webviewW/2
                self.currentSnapshotV?.center.x = webviewW/2 + webviewW
            }, completion: { (finish) in
                self.previousSnapshotV?.removeFromSuperview()
                self.currentSnapshotV?.removeFromSuperview()
                
                self.popSnapShotView()
                self.view.isUserInteractionEnabled = true
                self.isSwipingBack = false
                
                // webview goback
                self.onWebpageBack()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                UIView.setAnimationCurve(.easeOut)
                self.previousSnapshotV?.center.x = webviewW/2 - GTM_SwipeLimit.limitX
            }, completion: { (finish) in
                self.previousSnapshotV?.removeFromSuperview()
                self.currentSnapshotV?.removeFromSuperview()
                
                self.view.isUserInteractionEnabled = true
                self.isSwipingBack = false
            })
        }
        
    }
    
    // MARK: - Manage snapShotViews
    
    func pushSnapShotView() {
        let snapshotV = uiWebView?.snapshotView(afterScreenUpdates: true)
        self.snapshotVs.append(snapshotV!)
    }
    func popSnapShotView() {
        if self.snapshotVs.count > 0 {
            self.snapshotVs.remove(at: self.snapshotVs.count-1)
        }
    }
}
