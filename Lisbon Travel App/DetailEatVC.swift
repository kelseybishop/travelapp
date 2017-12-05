//
//  DetailEatVC.swift
//  Lisbon Travel App
//
//  Created by Kelsey Bishop on 11/25/17.
//  Copyright © 2017 Kelsey Bishop. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FirebaseAuthUI
import FirebaseGoogleAuthUI
import FirebaseStorage

class DetailEatVC: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!
    var eatPlaces = [PlacesData]()
    var db: Firestore!
    var storage: Storage!
    var authUI: FUIAuth!
    var newImages = [UIImage]()
    
    
    //    var theMill = PlacesData(placeName: "The Mill", address: "R. do Poço dos Negros 1, 1200-335 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "themill")!, placeDescription: "Small cafe with great iced coffee and eggs.")
    //    var cerealBarCafe = PlacesData(placeName: "Pop Cereal Bar", address: "R. do Norte 64, 1200-365 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "cerealbar")!, placeDescription: "With walls covered in every cereal box you could imagine, the Cereal Bar Cafe has a huge selection of cereal bowls, most of which are topped with chocolate bars.")
    //    var chapito = PlacesData(placeName: "Chapito a Mesa", address: "Costa do Castelo 7, 1149-079 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "chapito")!, placeDescription: "A traditional Portuguese restaurant that overlooks a beautiful miradouro, or lookout, to the entire city of Lisbon. Good for small groups.")
    //    var fabrica = PlacesData(placeName: "Fabrica da Nata", address: "Praça dos Restauradores 62 -68, 1250-110 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "fabrica")!, placeDescription: "Central location in downtown Lisbon, Fabrica da Nata has some of the best pateis da nata in Lisbon, only second to the famous Pasteis de Belem in Belem, Portugal.")
    //    var lxFactory = PlacesData(placeName: "LX Factory", address: "R. Rodrigues de Faria 103, 1300 - 501 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "lxfactory")!, placeDescription: "The LX Factory used to be a huge manufacturing facility, and is now converted to small boutique shops and art galleries.")
    //    var miniBar = PlacesData(placeName: "Mini Bar Teatro", address: "R. António Maria Cardoso 58, 1200-026 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "minibar")!, placeDescription: "This upscale restaurant is one of Lisbon's most famous and is known for it's tasting menu featuing small plates. Located in Chiado, a neighborhood full of expensive restaurants and shops.")
    //    var pistola = PlacesData(placeName: "Pistola y Corazon", address: "Rua da Boavista 16, 1200-066 Lisboa, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "pistolaycorazon")!, placeDescription: "A treasure for Mexican food lovers - Pistola y Corazon is usually packed for dinner, but all the locals know to take advantage of their 9 euro lunch special.")
    //    var timeOut = PlacesData(placeName: "Time Out Market", address: "Av. 24 de Julho 49, 1200-479 Lisbon, Portugal", coordinate: CLLocationCoordinate2D(), postingUserID: "", placeDocumentID: "", placeImage: UIImage.init(named: "timeoutmarket")!, placeDescription: "Time Out Market is a must see - it's a wide open space that feature different foods and chefs of Lisbon. Opt for the stands on the back wall, which feature top chefs in the city.")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        storage = Storage.storage()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
        loadData()
    }
    
    
    func loadData() {
        db.collection("eatPlaces").getDocuments { (querySnapshot, error) in
            guard error == nil else {
                print("ERROR: reading documents \(error!.localizedDescription)")
                return
            }
            //        self.eatPlaces = []
            for document in querySnapshot!.documents {
                let placeDocumentID = document.documentID
                let docData = document.data()
                let placeName = docData["placeName"] as! String? ?? ""
                let address = docData["address"] as! String? ?? ""
                let postingUserID = docData["postingUserID"] as! String? ?? ""
                let latitude = docData["latitude"] as! CLLocationDegrees? ?? 0.0
                let longitude = docData["longitude"] as! CLLocationDegrees? ?? 0.0
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                let placeImage = docData["placeImage"] as! String? ?? ""
                let placeDescription = docData["placeDescription"] as! String? ?? ""
                self.eatPlaces.append(PlacesData(placeName: placeName, address: address, coordinate: coordinate, postingUserID: postingUserID, placeDocumentID: placeDocumentID, placeImage: placeImage, placeDescription: placeDescription))
            }
            self.tableView.reloadData()
        }
    }
    
    func saveData(index: Int) {
        // Grab the unique userID
        print(authUI)
        if let postingUserID = (authUI.auth?.currentUser?.email) {
            eatPlaces[index].postingUserID = postingUserID
            print("%%%%^^^^^^^")
        } else {
            eatPlaces[index].postingUserID = "unknown user"
        }
        let latitude = eatPlaces[index].coordinate.latitude
        let longitude = eatPlaces[index].coordinate.longitude
        
        // Create the dictionary representing data we want to save
        print("&&&&&")
        let dataToSave: [String: Any] = ["placeName": eatPlaces[index].placeName, "address": eatPlaces[index].address, "postingUserID": eatPlaces[index].postingUserID, "placeDescription": eatPlaces[index].placeDescription, "latitude": latitude, "longitude": longitude]
        print("......>")
        // if we HAVE saved a record, we'll have an ID
        if eatPlaces[index].placeDocumentID != "" {
            let ref = db.collection("eatPlaces").document(eatPlaces[index].placeDocumentID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("ERROR: updating document \(error.localizedDescription)")
                } else {
                    print("Document updated with reference ID \(ref.documentID)")
                    self.saveImages(placeDocumentID: self.eatPlaces[index].placeDocumentID)
                }
            }
            print("-------")
        } else { // Otherwise we don't have a document ID so we need to create the ref ID and save a new document
            var ref: DocumentReference? = nil // Firestore will creat a new ID for us
            print("***/////")
            ref = db.collection("eatPlaces").addDocument(data: dataToSave) { (error) in
                if let error = error {
                    print("ERROR: adding document \(error.localizedDescription)")
                } else {
                    print("Document added with reference ID \(ref!.documentID)")
                    self.eatPlaces[index].placeDocumentID = "\(ref!.documentID)"
                    self.saveImages(placeDocumentID: self.eatPlaces[index].placeDocumentID)
                    print("%%%%%%")
                }
            }
        }
    }
    
    
    func saveImages(placeDocumentID: String) {
        // imagesRef now pointsn to a bucket to hold all images for place named: "placeDocumentID"
        let imagesRef = storage.reference().child(placeDocumentID)
        
        for image in newImages {
            let imageName = NSUUID().uuidString+".jpg" // always creates a unique string in part based on time/date
            // Convert image to type Data so it can be saved to Storage
            guard let imageData = UIImageJPEGRepresentation(image, 0.8) else {
                print("ERROR creating imageData from JPEGRepresentation")
                return
            }
            // Create a ref to the file you want to upload
            let uploadedImageRef = imagesRef.child(imageName)
            let uploadTask = uploadedImageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                guard error == nil else {
                    print("ERROR: \(error!.localizedDescription)")
                    return
                }
                let downloadURL = metadata!.downloadURL
                print("%%% successfully uploaded - the downloadURL is \(downloadURL)")
                
                let postingUserID = Auth.auth().currentUser?.email ?? ""
                self.db.collection("places").document(placeDocumentID).collection("images").document(imageName).setData(["postingUserID": postingUserID]) { (error) in
                    if let error = error {
                        print("ERROR: adding document \(error.localizedDescription)")
                    } else {
                        print("Document added for place \(placeDocumentID) and image \(imageName)")
                    }
                }
            })
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEatDetail" {
            print("***")
            let destination = segue.destination as! UINavigationController
            let destination2 = destination.topViewController as! ItemEatVC
            let selectedRow = tableView.indexPathForSelectedRow?.row
            destination2.placesData = eatPlaces[selectedRow!]
        } else {
            if let selectedIndexPath = tableView.indexPathForSelectedRow {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
    
    
    @IBAction func unwindFromDetail(segue: UIStoryboardSegue) {
        let source = segue.source as! ItemEatVC
        newImages = source.newImages
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            eatPlaces[selectedIndexPath.row] = (source.placesData)!
            tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
            saveData(index: selectedIndexPath.row)
        } else {
            let newIndexPath = IndexPath(row: eatPlaces.count, section: 0)
            eatPlaces.append((source.placesData)!)
            tableView.insertRows(at: [newIndexPath], with: .bottom)
            tableView.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
            saveData(index: newIndexPath.row)
        }
    }
}

extension DetailEatVC:  UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eatPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eatCell", for: indexPath)
        cell.textLabel?.text = eatPlaces[indexPath.row].placeName
        //  cell.detailTextLabel?.text = places[indexPath.row].address
        cell.detailTextLabel?.text = eatPlaces[indexPath.row].postingUserID
        return cell
    }
    
}

