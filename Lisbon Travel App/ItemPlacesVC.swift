//
//  ItemPlacesVC.swift
//  Lisbon Travel App
//
//  Created by Kelsey Bishop on 11/28/17.
//  Copyright © 2017 Kelsey Bishop. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import GooglePlaces
import Firebase
import FirebaseStorage


class ItemPlacesVC: UIViewController {
    
    
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeDescription: UITextView!
    @IBOutlet weak var placeImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    var placesData: PlacesData?
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    var regionRadius = 1000.0 // 1 km
    var imagePicker = UIImagePickerController()
    var newImages = [UIImage]()
    var db: Firestore!
    var storage: Storage!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        
        db = Firestore.firestore()
        storage = Storage.storage()
        print("%%%%")
        mapView.delegate = self
        if let placesData = placesData {
            centerMap(mapLocation: placesData.coordinate, regionRadius: regionRadius)
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(placesData)
            mapView.selectAnnotation(placesData, animated: true)
            print("*****&&&")
            loadImages()
            print("$$$$$")
            updateUserInterface()
            print("^^^^^^")
        } else {
            placesData = PlacesData(placeName: "", address: "", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: "", placeDescription: "")
            print("^^^^%%%%%")
            getLocation()
            print("$$$$#####")
            
        }
    }
    
    
    func loadImages() {
        getImageReferences{ (imageReferences) in
            guard let bucketRef = self.placesData?.placeDocumentID else {
                print("Couldn't read bucketRef")
                return
            }
            for imageReference in imageReferences {
                let imageReference = self.storage.reference().child(bucketRef+"/"+imageReference)
                imageReference.getData(maxSize: 10 * 1024 * 1024) { data, error in
                    guard error == nil else {
                        print("Error occered while reading data from file ref")
                        return
                    }
                    let image = UIImage(data: data!)
                    self.placeImageView.image = image
                }
            }
        }
    }
    
    func getImageReferences(completion: @escaping ([String]) -> ()) {
        var imagesReferences = [String]()
        db.collection("seePlaces").document((placesData?.placeDocumentID)!).collection("images").getDocuments
            { (querySnapshot, error) in
                if error != nil {
                    print("Error reading documents at \(error!.localizedDescription)")
                } else {
                    for document in querySnapshot!.documents {
                        imagesReferences.append(document.documentID)
                    }
                }
                completion(imagesReferences)
        }
    }
    
    // CHECK THIS*****
    
    func updateUserInterface() {
        placeName.text = placesData?.placeName
        placeDescription.text = placesData?.placeDescription
        //  placeImage!.image = placesData?.placeImage
    }
    
    func centerMap(mapLocation: CLLocationCoordinate2D, regionRadius: CLLocationDistance) {
        let region = MKCoordinateRegionMakeWithDistance(mapLocation, regionRadius, regionRadius)
        mapView.setRegion(region, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        placesData?.placeName = placeName.text!
        placesData?.placeDescription = placeDescription.text!
        
    }
    
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func lookupButtonPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (cameraAction) in
            self.accessCamera()
        }
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { (libraryAction) in
            self.accessLibrary()
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        alertController.addAction(cameraAction)
        alertController.addAction(libraryAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    
}

extension ItemPlacesVC: CLLocationManagerDelegate {
    
    func getLocation(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func handleLocationAuthorizationStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            showAlertToPrivacySettings(title: "User has not authorized location services", message: "Select 'Settings' below to open device settings and enable location services for this app.")
        case .restricted:
            showAlert(title: "Location services denied", message: "It may be that parental controls are restricting location use in this app")
        }
    }
    
    func showAlertToPrivacySettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let settingsURL = URL(string: UIApplicationOpenSettingsURLString) else {
            print("Something went wrong getting the UIApplicationOpenSettingsURLString")
            return
        }
        let settingsActions = UIAlertAction(title: "Settings", style: .default) { value in
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsActions)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationStatus(status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let geoCoder = CLGeocoder()
        currentLocation = locations.last
        let currentLatitude = currentLocation.coordinate.latitude
        let currentLongitude = currentLocation.coordinate.longitude
        geoCoder.reverseGeocodeLocation(currentLocation, completionHandler: {placemarks, error in
            if placemarks != nil {
                let placemark = placemarks?.last
                self.placesData?.placeName = (placemark?.name)!
                self.placesData?.address = placemark?.thoroughfare ?? "unknown"
                self.placesData?.coordinate = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
                self.centerMap(mapLocation: (self.placesData?.coordinate)!, regionRadius: self.regionRadius)
                self.updateUserInterface()
                self.mapView.addAnnotation(self.placesData!)
                self.mapView.selectAnnotation(self.placesData!, animated: true)
                self.updateUserInterface()
            } else {
                print("Error retrieving place. Error code: \(error!)")
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location.")
    }
}

extension ItemPlacesVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifer = "Marker"
        var view: MKPinAnnotationView
        if let dequedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifer) as? MKPinAnnotationView {
            dequedView.annotation = annotation
            view = dequedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .custom)
        }
        return view
    }
    
}

extension ItemPlacesVC: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        placesData?.placeName = place.name
        placesData?.coordinate = place.coordinate
        placesData?.address = place.formattedAddress ?? "unknown"
        centerMap(mapLocation: (placesData?.coordinate)!, regionRadius: regionRadius)
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(self.placesData!)
        mapView.selectAnnotation(self.placesData!, animated: true)
        updateUserInterface()
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension ItemPlacesVC: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        placeImageView.image = selectedImage
        newImages.append(selectedImage)
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func accessLibrary() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
    
}













