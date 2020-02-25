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
    
    @IBOutlet weak var beaconDataLabel: UILabel!
    @IBOutlet weak var beaconUUIDLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    public var beacon: CLBeacon!
    
    private var beaconAnnotation: BeaconAnnotation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        beaconDataLabel.text = "iBeacon Major \(beacon.major)  Minor \(beacon.minor)"
        beaconUUIDLabel.text = "UUID \(beacon.uuid)"
        
        mapView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(tapOnMap))
        mapView.addGestureRecognizer(tapGesture)
        
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
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
    
    //
    
    //Testing long press on button
    
    
    
    //
    
    @IBAction func actionMoveBeaconRight(_ sender: Any) {
        if beaconAnnotation == nil { return }
        UIView.animate(withDuration: 0.25) {
            var loc = self.beaconAnnotation!.coordinate
            
            loc.longitude = loc.longitude + 0.000001
            self.beaconAnnotation!.coordinate = loc
        }
    }
    
    @IBAction func actionMoveBeaconLeft(_ sender: Any) {
        if beaconAnnotation == nil { return }
        UIView.animate(withDuration: 0.25) {
            var loc = self.beaconAnnotation!.coordinate
            loc.longitude = loc.longitude - 0.000001
            self.beaconAnnotation!.coordinate = loc
        }
    }
    
    @IBAction func actionMoveBeaconUp(_ sender: Any) {
        if beaconAnnotation == nil { return }
        UIView.animate(withDuration: 0.25) {
            var loc = self.beaconAnnotation!.coordinate
            
            loc.latitude = loc.latitude + 0.000001
            self.beaconAnnotation!.coordinate = loc
        }
    }
    
    @IBAction func moveBeaconDown(_ sender: Any) {
        if beaconAnnotation == nil { return }
        UIView.animate(withDuration: 0.25) {
            var loc = self.beaconAnnotation!.coordinate
            loc.latitude = loc.latitude - 0.000001
            self.beaconAnnotation!.coordinate = loc
        }
    }
    
    @IBAction func actionInstall(_ sender: Any) {
        let successAlert = UIAlertController(title: "iBeacon successfully installed!",
                                      message: nil, preferredStyle: .alert)
        self.present(successAlert, animated: false, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func actionCancelInstallation(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension BeaconInstallationViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is BeaconAnnotation else { return nil }

        let pinView = MKPinAnnotationView(annotation: BeaconAnnotation(location: annotation.coordinate, beacon: beacon), reuseIdentifier: "pin")
        pinView.canShowCallout = true
        pinView.rightCalloutAccessoryView = UIButton(type: .infoDark)
        pinView.pinTintColor = UIColor.darkGray
        
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
}


extension BeaconInstallationViewController: CLLocationManagerDelegate { }
