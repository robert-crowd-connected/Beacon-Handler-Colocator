//
//  NonGeoBeaconInstallationViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 16/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class NonGeoBeaconInstallationViewController: UIViewController {

    @IBOutlet weak var mapScrollView: PassTouchesScrollView!
    @IBOutlet weak var insideScrollView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    
    var pinPointView: UIView?
    var pinPointHeight: CGFloat = 26
    var pinPointWidth: CGFloat = 26
    
    @IBOutlet weak var moveUpButton: UIButton!
    @IBOutlet weak var moveLeftButton: UIButton!
    @IBOutlet weak var moveRightButton: UIButton!
    @IBOutlet weak var moveDownButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapScrollView.isScrollEnabled = true
        mapScrollView.minimumZoomScale = 1.0
        mapScrollView.maximumZoomScale = 1.0
        
        mapScrollView.delegate = self
        mapScrollView.delegatePass = self
        
        addTapGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        insideScrollView.widthAnchor.constraint(equalToConstant: CGFloat(mapImageView.bounds.width)).isActive = true
        insideScrollView.leftAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.leftAnchor, constant: 0).isActive = true
        insideScrollView.rightAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.rightAnchor, constant: 0).isActive = true
        
        view.layoutSubviews()
    }
    
    private func addTapGestures() {
        let longTapRightButton = UILongPressGestureRecognizer(target: self,
                                                              action: #selector(longPressRightButton))
        moveRightButton.addGestureRecognizer(longTapRightButton)
        
        let longTapLeftButton = UILongPressGestureRecognizer(target: self,
                                                             action: #selector(longPressLeftButton))
        moveLeftButton.addGestureRecognizer(longTapLeftButton)
        
        let longTapUpButton = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(longPressUpButton))
        moveUpButton.addGestureRecognizer(longTapUpButton)
        
        let longTapDownButton = UILongPressGestureRecognizer(target: self,
                                                             action: #selector(longPressDownButton))
        moveDownButton.addGestureRecognizer(longTapDownButton)
    }
    
    private func addOrMoveMarker(atPosition position: CGPoint) {
        if pinPointView != nil {
            pinPointView?.removeFromSuperview()
        }
        
        print("Add/move pinpoint at \(position)")
        
        pinPointView = UIView(frame: CGRect(x: position.x,
                                            y: position.y,
                                            width: pinPointWidth,
                                            height: pinPointHeight))
        pinPointView!.layer.contents = #imageLiteral(resourceName: "pinpoint").cgImage
        mapScrollView.addSubview(pinPointView!)
    }
    
    private func moveBeacon(direction: Direction, distance: CGFloat) {
        if pinPointView == nil { return }
        
        switch direction {
        case .left:
            UIView.animate(withDuration: 0.25) {
                var origin = self.pinPointView!.frame.origin
                origin.x = origin.x - distance
                if origin.x >= 0 {
                    self.pinPointView!.frame.origin = origin
                }
            }
        case .right:
            UIView.animate(withDuration: 0.25) {
                var origin = self.pinPointView!.frame.origin
                origin.x = origin.x + distance
                if origin.x <= self.mapImageView.frame.width  - self.pinPointWidth / 2 {
                    self.pinPointView!.frame.origin = origin
                }
            }
        case .up:
            UIView.animate(withDuration: 0.25) {
                var origin = self.pinPointView!.frame.origin
                origin.y = origin.y - distance
                if origin.y >= 0 {
                    self.pinPointView!.frame.origin = origin
                }
            }
        case .down:
            UIView.animate(withDuration: 0.25) {
                var origin = self.pinPointView!.frame.origin
                origin.y = origin.y + distance
                if origin.y <= self.mapImageView.frame.height - self.pinPointHeight {
                    self.pinPointView!.frame.origin = origin
                }
            }
        }
    }
    
    @objc func longPressRightButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .right, distance: 5)
    }
    
    @objc func longPressLeftButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .left, distance: 5)
    }
    
    @objc func longPressUpButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .up, distance: 5)
    }
    
    @objc func longPressDownButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .down, distance: 5)
    }
    
    @IBAction func actionMoveBeaconRight(_ sender: Any) {
        moveBeacon(direction: .right, distance: 1)
    }
    
    @IBAction func actionMoveBeaconLeft(_ sender: Any) {
        moveBeacon(direction: .left, distance: 1)
    }
    
    @IBAction func actionMoveBeaconUp(_ sender: Any) {
        moveBeacon(direction: .up, distance: 1)
    }
    
    @IBAction func moveBeaconDown(_ sender: Any) {
        moveBeacon(direction: .down, distance: 1)
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        let metersWidth: CGFloat = 300
        let metersHeigth: CGFloat = 50
        let adjustedPointPosition = CGPoint(x: pinPointView!.frame.origin.x + pinPointWidth / 2,
                                             y:pinPointView!.frame.origin.y + pinPointHeight)
        
        let finalX = adjustedPointPosition.x * metersWidth / mapImageView.frame.width
        let finalY = adjustedPointPosition.y * metersHeigth / mapImageView.frame.height
        
        print("Map image view frame \(mapImageView.frame)")
        print("Beacon would be installed at x = \(finalX)   y = \(finalY)")
    }
}

extension NonGeoBeaconInstallationViewController: UIScrollViewDelegate, PassTouchesScrollViewDelegate {
    func touchBegan(point: CGPoint) {
        let adjustedPosition = CGPoint(x: point.x - pinPointWidth / 2,
                                       y: point.y - pinPointHeight)
        addOrMoveMarker(atPosition: adjustedPosition)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return mapImageView
    }
}
