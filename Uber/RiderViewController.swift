//
//  RiderViewController.swift
//  Uber
//
//  Created by zappycode on 6/16/17.
//  Copyright © 2017 Nick Walter. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth
import GoogleMobileAds

class RiderViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callAnUberButton: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var uberHasBeenCalled = false
    var driverOnTheWay = false
    var driverLocation = CLLocationCoordinate2D()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bannerView.adUnitID = "ca-app-pub-3940256099942544/6300978111"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = FIRAuth.auth()?.currentUser?.email {
            FIRDatabase.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                self.uberHasBeenCalled = true
                self.callAnUberButton.setTitle("Cancel Uber", for: .normal)
                FIRDatabase.database().reference().child("RideRequests").removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndRider()
                            
                            if let email = FIRAuth.auth()?.currentUser?.email { FIRDatabase.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: { (snapshot) in
                                if let rideRequestDictionary = snapshot.value as? [String:AnyObject] {
                                    if let driverLat = rideRequestDictionary["driverLat"] as? Double {
                                        if let driverLon = rideRequestDictionary["driverLon"] as? Double {
                                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                            self.driverOnTheWay = true
                                            self.displayDriverAndRider()
                                        }
                                    }
                                }
                            })
                            }
                        }
                    }
                }
            })
        }
    }
    
    func displayDriverAndRider() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        callAnUberButton.setTitle("Your driver is \(roundedDistance)km away!", for: .normal)
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        riderAnno.coordinate = userLocation
        riderAnno.title = "Your Location"
        map.addAnnotation(riderAnno)
        
        let driverAnno = MKPointAnnotation()
        driverAnno.coordinate = driverLocation
        driverAnno.title = "Your Driver"
        map.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coord.latitude, longitude: coord.longitude)
            userLocation = center
            
            
            if uberHasBeenCalled {
                displayDriverAndRider()
                
            } else {
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                map.setRegion(region, animated: true)
                map.removeAnnotations(map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "Your Location"
                map.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func callUberTapped(_ sender: Any) {
        if !driverOnTheWay {
            if let email = FIRAuth.auth()?.currentUser?.email {
                
                if uberHasBeenCalled {
                    uberHasBeenCalled = false
                    callAnUberButton.setTitle("Call an Uber", for: .normal)
                    FIRDatabase.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { (snapshot) in
                        snapshot.ref.removeValue()
                        FIRDatabase.database().reference().child("RideRequests").removeAllObservers()
                    })
                } else {
                    let rideRequestDictionary : [String:Any] = ["email":email,"lat":userLocation.latitude,"lon":userLocation.longitude]
                    FIRDatabase.database().reference().child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
                    uberHasBeenCalled = true
                    callAnUberButton.setTitle("Cancel Uber", for: .normal)
                }
                
            }
        }
    }
    @IBAction func logoutTapped(_ sender: Any) {
        try? FIRAuth.auth()?.signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
}
