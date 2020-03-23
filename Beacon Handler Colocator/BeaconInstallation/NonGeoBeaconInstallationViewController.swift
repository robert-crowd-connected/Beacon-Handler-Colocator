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
import SwiftSpinner

class NonGeoBeaconInstallationViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var beaconDataLabel: UILabel!
    @IBOutlet weak var beaconUUIDLabel: UILabel!
    
    @IBOutlet weak var zoomLevellabel: UILabel!
    
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
    
    var imageMap: UIImage? = nil
    
    var zoomFactor: CGFloat = 1 {
        didSet {
            zoomLevellabel.text = "Zoom \(Double(round(1000 * zoomFactor) / 1000))x"
            let oldImageViewFrame = self.mapImageView.frame
           
            resizeUIImageView(zoomLevelChanged: true)
            movePinPointAtZoom(oldFrame: oldImageViewFrame)
        }
    }
    
    let standardDimension: CGFloat = 320  // maximum height for ScrollView
    var maximumZoomLevel: CGFloat = 7
    
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
        addGestureRecognizers()
        
        self.mapImageView.contentMode = .scaleAspectFit
        
        maximumZoomLevel = CGFloat(UserDefaults.standard.value(forKey: kZoomLevelStorageKey) as? Int ?? 7) + 0.01
        
        if Downloader.mapImage == nil || SurfaceService.shared.mapWidth == nil || SurfaceService.shared.mapHeight == nil {
            let alert = UIAlertController(title: "Download failed!",
                                          message: "Failed to get map surface details. Retry again later", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        self.tileWidth = SurfaceService.shared.mapWidth
        self.tileHeight = SurfaceService.shared.mapHeight
        self.imageMap = Downloader.mapImage
        self.resizeUIImageView()
    }
    
    private func configureUI() {
        beaconDataLabel.text = " Major \(beacon.major)  Minor \(beacon.minor)"
        beaconUUIDLabel.text = "UUID \(beacon.uuid)"
        
        titleLabel.textColor = UIColor.wizardPurple
        cancelButton.setTitleColor(UIColor.wizardPurple, for: .normal)
        zoomLevellabel.textColor = UIColor.wizardPurple
        
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
    
    private func resizeUIImageView(zoomLevelChanged: Bool = false) {
        if imageMap == nil { return }
        let ratio = imageMap!.size.width / imageMap!.size.height
        let finalDimension = standardDimension * zoomFactor
     
        if ratio == 1 {         // square
            mapImageView.frame = CGRect(x: 0, y: 0, width: finalDimension, height: finalDimension)
            
            if zoomLevelChanged {
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = finalDimension
                }
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .width }.first) {
                    constraint.constant = finalDimension
                }
                if let constraint = (mapScrollView.contentLayoutGuide.constraintsAffectingLayout(for: .vertical).filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = finalDimension
                }
            } else {
                insideScrollView.heightAnchor.constraint(equalToConstant: finalDimension).isActive = true
                insideScrollView.widthAnchor.constraint(equalToConstant: finalDimension).isActive = true
                mapScrollView.contentLayoutGuide.heightAnchor.constraint(equalToConstant: finalDimension).isActive = true
            }
            
        } else if ratio > 1 {   // landscape
            let newWidth = finalDimension * ratio
            mapImageView.frame = CGRect(x: 0, y: 0, width: newWidth, height: finalDimension)
            
            if zoomLevelChanged {
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = finalDimension
                }
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .width }.first) {
                    constraint.constant = newWidth
                }
                if let constraint = (mapScrollView.contentLayoutGuide.constraintsAffectingLayout(for: .vertical).filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = finalDimension
                }
            } else {
                insideScrollView.heightAnchor.constraint(equalToConstant: finalDimension).isActive = true
                insideScrollView.widthAnchor.constraint(equalToConstant: newWidth).isActive = true
                mapScrollView.contentLayoutGuide.heightAnchor.constraint(equalToConstant: finalDimension).isActive = true
            }
            
        } else {                // portrait
            let newHeight = finalDimension / ratio
            mapImageView.frame = CGRect(x: 0, y: 0, width: finalDimension, height: newHeight)
            
            if zoomLevelChanged {
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = newHeight
                }
                if let constraint = (insideScrollView.constraints.filter{ $0.firstAttribute == .width }.first) {
                    constraint.constant = finalDimension
                }
                if let constraint = (mapScrollView.contentLayoutGuide.constraintsAffectingLayout(for: .vertical).filter{ $0.firstAttribute == .height }.first) {
                    constraint.constant = newHeight
                }
            } else {
                insideScrollView.heightAnchor.constraint(equalToConstant: CGFloat(newHeight)).isActive = true
                insideScrollView.widthAnchor.constraint(equalToConstant: CGFloat(finalDimension)).isActive = true
                mapScrollView.contentLayoutGuide.heightAnchor.constraint(equalToConstant: newHeight).isActive = true
            }
        }
        
        mapImageView.image = imageMap!
        
        insideScrollView.leftAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.leftAnchor, constant: 0).isActive = true
        insideScrollView.rightAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.rightAnchor, constant: 0).isActive = true
        insideScrollView.topAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.topAnchor, constant: 0).isActive = true
        insideScrollView.bottomAnchor.constraint(equalTo: mapScrollView.contentLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
        mapImageView.leftAnchor.constraint(equalTo: insideScrollView.leftAnchor, constant: 0).isActive = true
        mapImageView.rightAnchor.constraint(equalTo: insideScrollView.rightAnchor, constant: 0).isActive = true
        
        view.layoutSubviews()
    }
    
    private func movePinPointAtZoom(oldFrame: CGRect) {
        if pinPointView == nil { return }
        
        UIView.animate(withDuration: 0.001) {
            var origin = self.pinPointView!.frame.origin
            
            let widthPerncentage = origin.x / oldFrame.width
            let heightPerncentage = origin.y / oldFrame.height
            
            // adjust depending on how much % represents the width and height of the pinpoint view
            let oldPinPointMapPercentage = self.pinPointWidth / oldFrame.width
            let newPinPointMapPercentage = self.pinPointWidth / self.mapImageView.frame.width
            let pinPointPerncetageDifference = newPinPointMapPercentage - oldPinPointMapPercentage
            
            let invertedAspectRadio = self.mapImageView.frame.height / self.mapImageView.frame.width
            
            origin.x = (widthPerncentage - pinPointPerncetageDifference / 2) * self.mapImageView.frame.width
            origin.y = (heightPerncentage - pinPointPerncetageDifference / invertedAspectRadio) * self.mapImageView.frame.height
            
            self.pinPointView!.frame.origin = origin
        }
    }
    
    private func addGestureRecognizers() {
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
        
        let pinchMapImage = UIPinchGestureRecognizer(target: self, action:#selector(zoomMap(_:)))
        mapImageView.addGestureRecognizer(pinchMapImage)
    }
    
    @objc func zoomMap(_ pinch: UIPinchGestureRecognizer) {
        if pinch.scale < 0.95 {
            if zoomFactor >= 1.049 {
                zoomFactor -= 0.05
                pinch.scale = 1
            }
        } else if pinch.scale > 1.05 {
            if zoomFactor <= maximumZoomLevel - 0.05 {
                zoomFactor += 0.05
                pinch.scale = 1
            }
        }
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
        moveBeacon(direction: .right, distance: 6)
    }
    
    @objc func longPressLeftButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .left, distance: 6)
    }
    
    @objc func longPressUpButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .up, distance: 6)
    }
    
    @objc func longPressDownButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .down, distance: 6)
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
            let alert = UIAlertController(title: "Unknown dimension!",
                                          message: "The dimension of the tile is unknown at this moment", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            
            return nil
        }
        
        if pinPointView!.frame.origin.x > self.mapImageView.frame.width || pinPointView!.frame.origin.y > self.mapImageView.frame.height {
            let alert = UIAlertController(title: "Outside map!",
                                          message: "The pinpoint is outside map area. Please move it accordingly", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            
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
            let alert = UIAlertController(title: "Location missing!",
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
            let alert = UIAlertController(title: "Location missing!",
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
