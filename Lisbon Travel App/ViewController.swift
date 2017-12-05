//
//  ViewController.swift
//  Lisbon Travel App
//
//  Created by Kelsey Bishop on 11/22/17.
//  Copyright © 2017 Kelsey Bishop. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI

class ViewController: UIViewController {

    
    @IBOutlet weak var homeImage2: UIImageView!
    var authUI: FUIAuth!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authUI = FUIAuth.defaultAuthUI()
//        // You need to adopt a FUIDelegate protocol to receive callback
        authUI?.delegate = self
        signIn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signIn()
    }
    
    func signIn() {
        let providers: [FUIAuthProvider] = [
            FUIGoogleAuth()
        ]
        if authUI.auth?.currentUser == nil {
            self.authUI?.providers = providers
            present(authUI.authViewController(), animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEatTableView" {
            print("***")
            let destination = segue.destination as! UINavigationController
            let destination2 = destination.topViewController as! DetailEatVC
            destination2.authUI = self.authUI
        } else {
            let destination = segue.destination as! UINavigationController
            let destination2 = destination.topViewController as! DetailPlacesVC
            destination2.authUI = self.authUI
            }
        }
    
    @IBAction func unwindFromDetailVC(segue: UIStoryboardSegue) {
    }
    

    @IBAction func signOutButtonPressed(_ sender: UIBarButtonItem) {
        do {
            try authUI!.signOut()
            print("^^^ Successfully signed out!")
            signIn()
        } catch {
            print("Couldn't sign out")
        }
    }
    
    @IBAction func eatButtonPressed(_ sender: UIButton) {
        }
    
    @IBAction func placesButtonPressed(_ sender: UIButton) {
    }
    

}


extension ViewController: FUIAuthDelegate {

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }

    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        if let user = user {
            print("*** Successfully logged in with user = \(user.email!)")
        }
}

    func authPickerViewController(forAuthUI authUI: FUIAuth) -> FUIAuthPickerViewController {
        let loginViewController = FUIAuthPickerViewController(authUI: authUI)
        loginViewController.view.backgroundColor = UIColor.white
        
        let marginInset: CGFloat = 16
        let imageY = self.view.center.y - 225
        
        let logoFrame = CGRect(x: self.view.frame.origin.x + marginInset, y: imageY, width: self.view.frame.width - (marginInset*2), height: 225)
        let logoImageView = UIImageView(frame: logoFrame)
        logoImageView.image = UIImage(named: "lisbon")
        logoImageView.contentMode = .scaleAspectFit
        loginViewController.view.addSubview(logoImageView)
        
        return loginViewController
    }
    
}


