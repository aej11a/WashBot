//
//  FirstViewController.swift
//  WashBot
//
//  Created by Andrew Jones on 2/22/19.
//  Copyright © 2019 WashBot. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class StatusViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var selectedDocumentID: Int?
    var timer = Timer()
    var docIndex : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMachines()
        
        // Add a Listener so that if someone picks a machine while you're looking at the app, you'll see updated machine availability data
        Firestore.firestore().collection("machines").addSnapshotListener { querySnapshot, error in
            self.clearView()
            self.setupMachines()
        }
    }
    
    func generateFrame(forIndex index: Int, yOffset: Int) -> CGRect {
        return CGRect(x: 10 + Int(floor(Double(index % 2))) * Int(UIScreen.main.bounds.size.width  * 0.50), y: Int( floor(Double(index / 2)) * 170) + yOffset, width: Int(UIScreen.main.bounds.size.width  * 0.45), height: 20)
    }
    
    func clearView(){
        for subUIView in self.scrollView.subviews as [UIView] {
            subUIView.removeFromSuperview()
        }
    }

    func setupMachines(){
        
        let clearbutton = UIButton.init(frame: CGRect(x: 10, y: 500, width: 300, height: 40))
        clearbutton.backgroundColor = .red
        clearbutton.setTitle("TESTING ONLY", for: .normal)
        clearbutton.addTarget(self, action: #selector(unlockAll), for: .touchUpInside)
        self.scrollView.addSubview(clearbutton)
        
        var index : Int = 0
        let db = Firestore.firestore()
        // Query the database for all machines at Stevens.
        // In reality, this query would prob be setup in a Settings page on the app
        // Also, locations would be much more specific
        db.collection("machines").whereField("location", isEqualTo: "stevensTech")
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    
                    // for-loop goes through each document found with above query and sets up the UI
                    // A 'document' corresponds to a real-world machine
                    for document in querySnapshot!.documents {
                        let label = UILabel(frame: self.generateFrame(forIndex: index, yOffset: 5))
                        let imageButton = UIButton(frame: CGRect(x: 45 + Int(floor(Double(index % 2))) * Int(UIScreen.main.bounds.size.width  * 0.50), y: Int(35 + floor(Double(index / 2)) * 170), width: 100, height: 100))
                        label.text = ""
                        // Set image based on machine type
                        // Set text based on machine type and machine number in its room (so that users know which physical machine they're trying to use)
                        if let type = document.get("type") as? String {
                            var imageName = "missing.jpg" //Set a default just in case something's wrong
                            if type == "washer" {
                                imageName = "washer.jpg"
                                label.text = "Washer #\(document.get("numberInRoom") as! String)"
                            } else if type == "dryer" {
                                imageName = "dryer.jpg"
                                label.text = "Dryer #\(document.get("numberInRoom") as! String)"
                            }
                            let image = UIImage(named: imageName)
                            //let imageView = UIImageView(image: image!)
                            //imageView.frame = CGRect(x: 45 + Int(floor(Double(index % 2))) * Int(UIScreen.main.bounds.size.width  * 0.50), y: Int(35 + floor(Double(index / 2)) * 170), width: 100, height: 100)
                            
                            imageButton.setImage(image, for: .normal)
                            //self.scrollView.addSubview(imageView)
                            self.scrollView.addSubview(label)
                        }
                        
                        let button = UIButton(frame: self.generateFrame(forIndex: index, yOffset: 150))
                        
                        //Determine if this particular machine is available
                        if let available = document.get("available") as? String {
                            if available == "open" {
                                button.backgroundColor = UIColor(red:0.33, green:0.70, blue:0.13, alpha:1.0)
                                button.setTitle("Reserve Now!", for: .normal)
                                button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                                imageButton.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                            }
                            else if available == "used" {
                                button.backgroundColor = UIColor(red:0.69, green:0.05, blue:0.05, alpha:1.0)
                                button.setTitle("Locked!", for: .normal)
                            }
                        } else {
                            button.backgroundColor = .darkGray
                        }
                        imageButton.tag = Int(document.documentID) ?? 0
                        button.tag = Int(document.documentID) ?? 0
                        self.scrollView.addSubview(imageButton)
                        self.scrollView.addSubview(button)
                        index = index + 1
                    }
                }
        }
    }
    
    func updateMachineStatus(docId : String, machineStatus : String){
        for i: UIView? in view.subviews {
            if (i is UIButton) {
                let button = i as? UIButton
                if "\(button?.tag ?? 0)" == docId {
                    if machineStatus == "used" {
                        button?.removeTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                        button?.backgroundColor = UIColor(red:0.69, green:0.05, blue:0.05, alpha:1.0)
                        //button?.setTitle("Locked!", for: .normal)
                    } else if machineStatus == "open" {
                        button?.backgroundColor = UIColor(red:0.33, green:0.70, blue:0.13, alpha:1.0)
                        //button.setTitle("Reserve Now!", for: .normal)
                        button?.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                    }
                }
            }
        }
    }
    
    func setupLoadStatus(){
        
    }
    
    @objc
    func unlockAll(){
        let db = Firestore.firestore()
        db.collection("machines").whereField("location", isEqualTo: "stevensTech")
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    db.collection("machines").document("\(document.documentID)").setData([ "available": "open" ], merge: true)
                }
            }
        }
        clearView()
        setupMachines()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearView()
        setupMachines()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!){
        
        if segue.identifier == "showMachineView" {
            let destinationNavigationController = segue.destination as! UINavigationController
                let dest = destinationNavigationController.topViewController as! MachineViewController
                dest.docIndex = self.docIndex!
            }
    }
    
    @objc
    func buttonAction(sender: UIButton!){
        self.docIndex = sender.tag
        performSegue(withIdentifier: "showMachineView", sender: nil)
        /*let db = Firestore.firestore()
        let docRef = db.collection("machines").document("\(sender.tag)")
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.clearView()
                
                db.collection("machines").document("\(sender.tag)").setData([ "available": "used" ], merge: true)
                
                let label = UITextView(frame: CGRect(x: 10, y: 0, width: UIScreen.main.bounds.size.width - 20, height: 70))
                label.text = ""
                label.font = UIFont(name: "ArialMT", size: 16)
                
                if let type = document.get("type") as? String {
                    var imageName = "missing.jpg" //Set a default just in case something's wrong
                    if type == "washer" {
                        imageName = "washer.jpg"
                        label.text = "You reserved Washer #\(document.get("numberInRoom") as! String). You have 5 minutes to start your load before the reservation is cancelled!"
                    } else if type == "dryer" {
                        imageName = "dryer.jpg"
                        label.text = "You reserved Dryer #\(document.get("numberInRoom") as! String). You have 5 minutes to start your load before the reservation is cancelled!"
                    }
                    let image = UIImage(named: imageName)
                    let imageView = UIImageView(image: image!)
                    imageView.frame = CGRect(x: 10, y: 115, width: Int(UIScreen.main.bounds.size.width * 0.95), height: Int(UIScreen.main.bounds.size.width * 0.95))
                    self.scrollView.addSubview(imageView)
                    self.scrollView.addSubview(label)
                }
                
                let button = UIButton(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 70, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 30))
                
                button.backgroundColor = UIColor(red:0.01, green:0.20, blue:0.54, alpha:0.9)
                button.setTitleColor(.white, for: .normal)
                button.setTitle("Tap Here to Start", for: .normal)
                self.scrollView.addSubview(button)
            } else {
                print("Document does not exist")
            }
        }*/
    }
}
