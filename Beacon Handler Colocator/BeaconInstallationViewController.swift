//
//  BeaconInstallationViewController.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 25/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import UIKit

class BeaconInstallationViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var beaconDataLabel: UILabel!
    @IBOutlet weak var beaconUUIDLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var moveUpButton: UIButton!
    @IBOutlet weak var moveRightButton: UIButton!
    @IBOutlet weak var moveDownButton: UIButton!
    @IBOutlet weak var moveLeftButton: UIButton!
    
    @IBOutlet weak var installButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    public var beacon: CLBeacon!
    public var delegate: ScannerViewControllerDelegate?
    
    private var beaconAnnotation: BeaconAnnotation? {
        didSet {
            changeMoveBeaconButtonsVisibility(to: beaconAnnotation != nil)
        }
    }
    
    var tileRenderer: MKTileOverlayRenderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beaconDataLabel.text = " Major \(String(format: "%04d", beacon.major))  Minor \(beacon.minor)"
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
        
        addTapGestures()
        setupMap()
        setupLocationManager()
    }
    
    private func setupMap() {
        mapView.delegate = self
        changeMoveBeaconButtonsVisibility(to: false)
        
        UpdatingServerBeaconsService.shared.getSurfaceTileName() { success, tileName in
            if success, tileName != nil {
                guard let appKey = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String else { return }
                
                let template = "https://d36oublijzdizs.cloudfront.net/\(appKey)/\(tileName!)/{z}/{x}/{y}.png"
                let overlay = MKTileOverlay(urlTemplate: template)
                overlay.canReplaceMapContent = false
                
                self.mapView.addOverlay(overlay, level: .aboveLabels)
                self.tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)
            }
        }
    }
    
    private func addTapGestures() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapOnMap))
       mapView.addGestureRecognizer(tapGesture)
       
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
    
    private func changeMoveBeaconButtonsVisibility(to state: Bool) {
        moveUpButton.isHidden = !state
        moveRightButton.isHidden = !state
        moveDownButton.isHidden = !state
        moveLeftButton.isHidden = !state
    }
    
    private func setupLocationManager() {
        let locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if let userLocation = locationManager.location?.coordinate {
            let viewRegion = MKCoordinateRegion(center: userLocation,
                                                latitudinalMeters: 100,
                                                longitudinalMeters: 100)
            mapView.setRegion(viewRegion, animated: false)
        }
    }
    
    @objc func tapOnMap(sender: UIGestureRecognizer){
        let locationInView = sender.location(in: mapView)
        let locationOnMap = mapView.convert(locationInView,
                                            toCoordinateFrom: mapView)
        addAnnotation(location: locationOnMap)
    }

    func addAnnotation(location: CLLocationCoordinate2D){
        beaconAnnotation = BeaconAnnotation(location: location, beacon: beacon)
        addOrEditBeaconAnnotation()
    }
    
    private func addOrEditBeaconAnnotation() {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        self.mapView.addAnnotation(beaconAnnotation!)
    }

    private func moveBeacon(direction: Direction, distance: Double) {
        if beaconAnnotation == nil { return }
        
        switch direction {
        case .left:
            UIView.animate(withDuration: 0.25) {
                var loc = self.beaconAnnotation!.coordinate
                loc.longitude = loc.longitude - distance
                self.beaconAnnotation!.coordinate = loc
            }
        case .right:
            UIView.animate(withDuration: 0.25) {
                var loc = self.beaconAnnotation!.coordinate
                loc.longitude = loc.longitude + distance
                self.beaconAnnotation!.coordinate = loc
            }
        case .up:
            UIView.animate(withDuration: 0.25) {
                var loc = self.beaconAnnotation!.coordinate
                loc.latitude = loc.latitude + distance
                self.beaconAnnotation!.coordinate = loc
            }
        case .down:
            UIView.animate(withDuration: 0.25) {
                var loc = self.beaconAnnotation!.coordinate
                loc.latitude = loc.latitude - distance
                self.beaconAnnotation!.coordinate = loc
            }
        }
    }
    
    @objc func longPressRightButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .right, distance: 0.000005)
    }
    
    @objc func longPressLeftButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .left, distance: 0.000005)
    }
    
    @objc func longPressUpButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .up, distance: 0.000005)
    }
    
    @objc func longPressDownButton(sender: UIGestureRecognizer) {
        moveBeacon(direction: .down, distance: 0.000005)
    }
    
    @IBAction func actionMoveBeaconRight(_ sender: Any) {
        moveBeacon(direction: .right, distance: 0.000001)
    }
    
    @IBAction func actionMoveBeaconLeft(_ sender: Any) {
        moveBeacon(direction: .left, distance: 0.000001)
    }
    
    @IBAction func actionMoveBeaconUp(_ sender: Any) {
        moveBeacon(direction: .up, distance: 0.000001)
    }
    
    @IBAction func moveBeaconDown(_ sender: Any) {
        moveBeacon(direction: .down, distance: 0.000001)
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        if beaconAnnotation == nil {
            let alert = UIAlertController(title: "Location missing",
                                                 message: "Add place of installment  on the map before submit", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            self.present(alert, animated: false, completion: { })
            return
        }
        
        BeaconHandlingService.shared.install(iBeacon: beacon, at: beaconAnnotation!.coordinate) { success, erroMessage in
            if success {
                let successAlert = UIAlertController(title: "iBeacon successfully installed!",
                                                     message: "Latitude \(self.beaconAnnotation!.coordinate.latitude)\nLongitude \(self.beaconAnnotation!.coordinate.longitude)", preferredStyle: .alert)
                self.present(successAlert, animated: false, completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        self.dismiss(animated: true, completion: {
                            self.delegate?.stopMonitoringBeacon(beacon: self.beacon)
                            self.delegate?.startScanner()
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
    
    @IBAction func actionCancelInstallation(_ sender: Any) {
        self.delegate?.startScanner()
        navigationController?.popViewController(animated: true)
    }
}

extension BeaconInstallationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is BeaconAnnotation else { return nil }

        let pinView = MKPinAnnotationView(annotation: BeaconAnnotation(location: annotation.coordinate, beacon: beacon), reuseIdentifier: "pin")
        pinView.canShowCallout = true
        pinView.rightCalloutAccessoryView = UIButton(type: .infoDark)
        pinView.pinTintColor = UIColor.wizardPurple
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            if let annotation = view.annotation as? BeaconAnnotation {
                let alert = UIAlertController(title: "iBeacon Coordinates",
                                              message: "Major \(annotation.beacon.major)   Minor \(annotation.beacon.minor)\nLatitude \(annotation.coordinate.latitude)\nLongitude \(annotation.coordinate.longitude)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKTileOverlay && tileRenderer != nil {
            return tileRenderer
        }
        return MKOverlayRenderer()
    }
}
