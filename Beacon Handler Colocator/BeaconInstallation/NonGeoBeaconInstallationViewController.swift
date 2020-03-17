//
//  NonGeoBeaconInstallationViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 16/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class NonGeoBeaconInstallationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var beaconDataLabel: UILabel!
    @IBOutlet weak var beaconUUIDLabel: UILabel!
    
    @IBOutlet weak var mapScrollView: PassTouchesScrollView!
    @IBOutlet weak var insideScrollView: UIView!
    @IBOutlet weak var mapImageView: UIImageView!
    
    @IBOutlet weak var moveUpButton: UIButton!
    @IBOutlet weak var moveLeftButton: UIButton!
    @IBOutlet weak var moveRightButton: UIButton!
    @IBOutlet weak var moveDownButton: UIButton!
    
    @IBOutlet weak var installButton: UIButton!
    @IBOutlet weak var deleteAndInstallButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    var pinPointView: UIView?
    var pinPointHeight: CGFloat = 26
    var pinPointWidth: CGFloat = 26
    
    var tileHeight: Int?
    var tileWidth: Int?
    
    public var beacon: CLBeacon!
    public var delegate: ScannerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if DEBUG
        deleteAndInstallButton.isHidden = false
        #endif
        
        configureUI()
        configureScrollView()
        addTapGestures()
        
        UpdatingServerBeaconsService.shared.getNonGeoSurface { (success, tileName, height, width) in
            if success && tileName != nil && height != nil && width != nil {
                self.tileWidth = width!
                self.tileHeight = height!
                
                self.mapImageView.contentMode = .scaleAspectFit
                let fullDownloadString = "https://colocator-tiles.s3-eu-west-1.amazonaws.com/surfacete/" + tileName!
                
                Downloader.downloadImage(from: fullDownloadString) { image in
                    self.resizeUIImageView(forImage: image)
                }
            }
        }
    }
    
    private func configureUI() {
        beaconDataLabel.text = " Major \(beacon.major)  Minor \(beacon.minor)"
        beaconUUIDLabel.text = "UUID \(beacon.uuid)"
        
        titleLabel.textColor = UIColor.wizardPurple
        cancelButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        beaconDataLabel.textColor = UIColor.wizardMiddleColor
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: installButton.frame.size.width, height: installButton.frame.size.height)
        gradient.colors = [UIColor.wizardPurple.cgColor, UIColor.wizardBlue.cgColor]
        gradient.startPoint = CGPoint(x: 0.0,y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0,y: 0.5)
        installButton.layer.insertSublayer(gradient, at: 0)
    }
    
    private func configureScrollView() {
        mapScrollView.isScrollEnabled = true
        mapScrollView.minimumZoomScale = 1.0
        mapScrollView.maximumZoomScale = 1.0
    
        mapScrollView.delegate = self
        mapScrollView.delegatePass = self
    }
    
    private func resizeUIImageView(forImage image: UIImage) {
        let ratio = image.size.width / image.size.height
        
        // Standard Height: 320
        // Zoom x2 640
        
        let newWidth = insideScrollView.frame.height * ratio
        // let newWidth = 640 * ratio
        mapImageView.image = image
        
        mapImageView.frame.size = CGSize(width: newWidth, height: insideScrollView.frame.height)
        mapImageView.frame = CGRect(x: 0, y: 0, width: newWidth, height: insideScrollView.frame.height)
        
        insideScrollView.widthAnchor.constraint(equalToConstant: CGFloat(newWidth)).isActive = true
        insideScrollView.leftAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.leftAnchor, constant: 0).isActive = true
        insideScrollView.rightAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.rightAnchor, constant: 0).isActive = true
        
//         mapScrollView.frameLayoutGuide.heightAnchor.constraint(equalToConstant: 640).isActive = true
//         insideScrollView.heightAnchor.constraint(equalToConstant: CGFloat(640)).isActive = true
//         insideScrollView.topAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.topAnchor, constant: 0).isActive = true
//         insideScrollView.bottomAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
        mapImageView.leftAnchor.constraint(equalTo: insideScrollView.leftAnchor, constant: 0).isActive = true
        mapImageView.rightAnchor.constraint(equalTo: insideScrollView.rightAnchor, constant: 0).isActive = true
        
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
                if origin.x >= 0  - self.pinPointWidth / 2 {
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
                if origin.y >= 0 - self.pinPointHeight {
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
    
    private func calculateNonGeoPosition() -> CGPoint? {
        if pinPointView == nil { return nil }
        
        if tileHeight == nil || tileWidth == nil {
            print("The dimension of the tile is unknown at this moment")
            return nil
        }
        let adjustedPointPosition = CGPoint(x: pinPointView!.frame.origin.x + pinPointWidth / 2,
                                             y:pinPointView!.frame.origin.y + pinPointHeight)
        
        let finalX = adjustedPointPosition.x * CGFloat(tileWidth!) / mapImageView.frame.width
        let finalY = adjustedPointPosition.y * CGFloat(tileHeight!) / mapImageView.frame.height
        
        let nonGeoPosition = CGPoint(x: finalX, y: finalY)
        return nonGeoPosition
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        if pinPointView == nil {
            let alert = UIAlertController(title: "Location missing",
                                          message: "Add place of installment  on the map before submit", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        guard let nonGeoPosition = calculateNonGeoPosition() else { return }
        
        BeaconHandlingService.shared.install(iBeacon: beacon, nonGeoPosition: nonGeoPosition) { success, erroMessage in
            if success {
                let successAlert = UIAlertController(title: "iBeacon successfully installed!",
                                                     message: "Non-Geo \(nonGeoPosition)", preferredStyle: .alert)
                self.present(successAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        self.delegate?.stopMonitoringBeacon(beacon: self.beacon)
                        self.delegate?.startScanner()
                        self.dismiss(animated: true, completion: {
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                })
            } else {
                let failureAlert = UIAlertController(title: "iBeacon installation failed!",
                                                     message: erroMessage ?? kDefaultRequestErrorMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "Okay", style: .default) { _ in
                    self.dismiss(animated: true, completion: {
                        self.delegate?.startScanner()
                        self.navigationController?.popViewController(animated: true)
                    })
                }
                failureAlert.addAction(action)
                self.present(failureAlert, animated: false, completion: nil)
            }
        }
    }
    
    @IBAction func actionDeleteAndInstallBeacon(_ sender: Any) {
        #if DEBUG
        
        if pinPointView == nil {
            let alert = UIAlertController(title: "Location missing",
                                          message: "Add place of installment  on the map before submit", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        guard let nonGeoPosition = calculateNonGeoPosition() else { return }
        
        BeaconHandlingService.shared.deleteAndInstallBeacon(iBeacon: beacon, nonGeoPosition: nonGeoPosition) { success, erroMessage in
            if success {
                let successAlert = UIAlertController(title: "iBeacon successfully deleted + installed!",
                                                     message: "Non-Geo \(nonGeoPosition)", preferredStyle: .alert)
                self.present(successAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        self.delegate?.stopMonitoringBeacon(beacon: self.beacon)
                        self.delegate?.startScanner()
                        self.dismiss(animated: true, completion: {
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                })
            } else {
                let failureAlert = UIAlertController(title: "iBeacon delete + installation failed!",
                                                     message: erroMessage ?? kDefaultRequestErrorMessage, preferredStyle: .alert)
                let action = UIAlertAction(title: "Okay", style: .default) { _ in
                    self.dismiss(animated: true, completion: {
                        self.delegate?.startScanner()
                        self.navigationController?.popViewController(animated: true)
                    })
                }
                failureAlert.addAction(action)
                self.present(failureAlert, animated: false, completion: nil)
            }
        }
        
        #endif
    }
    
    @IBAction func actionCancelInstallation(_ sender: Any) {
        self.delegate?.startScanner()
        navigationController?.popViewController(animated: true)
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
