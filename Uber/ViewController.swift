//
//  ViewController.swift
//  Uber
//
//  Created by zappycode on 6/16/17.
//  Copyright © 2017 Nick Walter. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleMobileAds

class ViewController: UIViewController {
    
    @IBOutlet weak var driverLabel: UILabel!
    @IBOutlet weak var riderLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var riderDriverSwitch: UISwitch!
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    
    var signUpMode = true
    var interstitial: GADInterstitial!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        interstitial = GADInterstitial(adUnitID: "ca-app-pub-3940256099942544/1033173712")
        let request = GADRequest()
        interstitial.load(request)
    }
    
    @IBAction func topTapped(_ sender: Any) {
        if emailTextfield.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Missing Information", message: "You must provide both a email and password")
        } else {
            if let email = emailTextfield.text {
                if let password = passwordTextField.text {
                    if signUpMode {
                        // SIGN UP
                        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                
                                if self.riderDriverSwitch.isOn {
                                    // DRIVER
                                    let req = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                                    req?.displayName = "Driver"
                                    req?.commitChanges(completion: nil)
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                } else {
                                    // RIDER
                                    let req = FIRAuth.auth()?.currentUser?.profileChangeRequest()
                                    req?.displayName = "Rider"
                                    req?.commitChanges(completion: nil)
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                            }
                        })
                    } else {
                        // LOG IN
                        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            } else {
                                if user?.displayName == "Driver" {
                                    // DRIVER
                                    self.performSegue(withIdentifier: "driverSegue", sender: nil)
                                } else {
                                    // RIDER
                                    self.performSegue(withIdentifier: "riderSegue", sender: nil)
                                }
                            }
                        })
                    }
                }
            }
        }
    }
    
    func displayAlert(title:String, message:String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func bottomTapped(_ sender: Any) {
        
        if interstitial.isReady {
            interstitial.present(fromRootViewController: self)
        } else {
            print("Ad wasn't ready")
        }
        
        if signUpMode {
            topButton.setTitle("Log In", for: .normal)
            bottomButton.setTitle("Switch to Sign Up", for: .normal)
            riderLabel.isHidden = true
            driverLabel.isHidden = true
            riderDriverSwitch.isHidden = true
            signUpMode = false
        } else {
            topButton.setTitle("Sign Up", for: .normal)
            bottomButton.setTitle("Switch to Log In", for: .normal)
            riderLabel.isHidden = false
            driverLabel.isHidden = false
            riderDriverSwitch.isHidden = false
            signUpMode = true
        }
    }
    
}

