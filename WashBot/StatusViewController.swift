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
    
    var selectedDocumentID: Int?
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMachines()
    }
    
    func generateFrame(forIndex index: Int, yOffset: Int) -> CGRect {
        return CGRect(x: 10 + Int(floor(Double(index % 2))) * Int(UIScreen.main.bounds.size.width  * 0.50), y: Int(150 + floor(Double(index / 2)) * 170) + yOffset, width: Int(UIScreen.main.bounds.size.width  * 0.45), height: 20)
    }

    func setupMachines(){
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
                        let label = UILabel(frame: self.generateFrame(forIndex: index, yOffset: -85))
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
                            let imageView = UIImageView(image: image!)
                            imageView.frame = CGRect(x: 45 + Int(floor(Double(index % 2))) * Int(UIScreen.main.bounds.size.width  * 0.50), y: Int(90 + floor(Double(index / 2)) * 170), width: 100, height: 100)
                            self.view.addSubview(imageView)
                            self.view.addSubview(label)
                        }
                        
                        let button = UIButton(frame: self.generateFrame(forIndex: index, yOffset: 52))
                        
                        //Determine if this particular machine is available
                        if let available = document.get("available") as? String {
                            if available == "open" {
                                button.backgroundColor = UIColor(red:0.33, green:0.70, blue:0.13, alpha:1.0)
                                button.setTitle("Reserve Now!", for: .normal)
                                button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                            }
                            else if available == "used" {
                                button.backgroundColor = UIColor(red:0.69, green:0.05, blue:0.05, alpha:1.0)
                                button.setTitle("Locked!", for: .normal)
                            }
                        } else {
                            button.backgroundColor = .darkGray
                        }
                        button.tag = Int(document.documentID) ?? 0
                        self.view.addSubview(button)
                        index = index + 1
                    }
                }
        }
    }
    
    func setupLoadStatus(){
        
    }
    
    @objc
    func buttonAction(sender: UIButton!){
        let db = Firestore.firestore()
        let docRef = db.collection("machines").document("\(sender.tag)")
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                for subUIView in self.view.subviews as [UIView] {
                    subUIView.removeFromSuperview()
                }
                
                db.collection("machines").document("\(sender.tag)").setData([ "available": "used" ], merge: true)
                
                let label = UILabel(frame: CGRect(x: 10, y: 50, width: 200, height: 20))
                label.text = ""
                
                if let type = document.get("type") as? String {
                    var imageName = "missing.jpg" //Set a default just in case something's wrong
                    if type == "washer" {
                        imageName = "washer.jpg"
                        label.text = "Washer #\(document.get("numberInRoom") as! String) is Reserved"
                    } else if type == "dryer" {
                        imageName = "dryer.jpg"
                        label.text = "Dryer #\(document.get("numberInRoom") as! String) is Reserved"
                    }
                    let image = UIImage(named: imageName)
                    let imageView = UIImageView(image: image!)
                    imageView.frame = CGRect(x: 10, y: 75, width: Int(UIScreen.main.bounds.size.width * 0.95), height: Int(UIScreen.main.bounds.size.width * 0.95))
                    self.view.addSubview(imageView)
                    self.view.addSubview(label)
                }
                
                let button = UIButton(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 40, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 30))
                
                button.backgroundColor = .yellow
                button.setTitle("Tap Here to Start", for: .normal)
                self.view.addSubview(button)
            } else {
                print("Document does not exist")
            }
        }
    }
}

