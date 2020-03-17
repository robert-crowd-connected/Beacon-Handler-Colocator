//
//  PassTouchesScrollView.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 16/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

protocol PassTouchesScrollViewDelegate {
    func touchBegan(point: CGPoint)
}

class PassTouchesScrollView: UIScrollView {
    var delegatePass : PassTouchesScrollViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: self)
            self.delegatePass?.touchBegan(point: position)
        }
        
        if self.isDragging == true {
            self.next?.touchesBegan(touches, with: event)
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        print("Touched moved set: \(touches)")
        
        if self.isDragging == true {
            self.next?.touchesMoved(touches, with: event)
        } else {
            super.touchesMoved(touches, with: event)
        }
    }
}
