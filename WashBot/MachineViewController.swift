//
//  MachineViewController.swift
//  WashBot
//
//  Created by Andrew Jones on 2/25/19.
//  Copyright © 2019 WashBot. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
import UserNotifications

class MachineViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var timerLabel: UILabel!
    
    var docIndex : Int?
    var cachedDoneButton : UIBarButtonItem?
    var cachedCancelButton : UIBarButtonItem? 

    @IBAction func close(_ sender: Any) {
        let db = Firestore.firestore()
        db.collection("machines").document("\(self.docIndex!)").setData([ "available": "open", "takenBy": "" ], merge: true)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func clearView(){
        for subUIView in self.scrollView.subviews as [UIView] {
            subUIView.removeFromSuperview()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let db = Firestore.firestore()
        db.collection("machines").document("\(self.docIndex!)")
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard document.data() != nil else {
                    print("Document data was empty.")
                    return
                }
                if (document.get("available") as? String) != nil {
                    for subUIView in self.scrollView.subviews as [UIView] {
                        subUIView.removeFromSuperview()
                    }
                    self.render()
                }
        }
        
        cachedDoneButton = doneButton
        render()
    }
    
    func render() {
        let db = Firestore.firestore()
        let docRef = db.collection("machines").document("\(self.docIndex!)")
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.clearView()
                
                if let isTakenBy = document.get("takenBy") as? String {
                    if isTakenBy == UIDevice.current.identifierForVendor!.uuidString {
                        
                        // ***** VIEW MACHINE IN USE HERE *****
                        
                        let label = UITextView(frame: CGRect(x: 10, y: 0, width: UIScreen.main.bounds.size.width - 20, height: 70))
                        label.font = UIFont(name: "ArialMT", size: 16)
                        self.scrollView.addSubview(label)
                        if let type = document.get("type") as? String {
                            var imageName = "missing.jpg" //Set a default just in case something goes wrong
                            if type == "washer" {
                                imageName = "washer.jpg"
                                label.text = "You are using Washer #\(document.get("numberInRoom") as! String)."
                            } else if type == "dryer" {
                                imageName = "dryer.jpg"
                                label.text = "You are using Dryer #\(document.get("numberInRoom") as! String)."
                            }
                            let image = UIImage(named: imageName)
                            let imageView = UIImageView(image: image!)
                            imageView.frame = CGRect(x: 10, y: 80, width: Int(UIScreen.main.bounds.size.width * 0.95), height: Int(UIScreen.main.bounds.size.width * 0.95))
                            self.scrollView.addSubview(imageView)
                            
                        }
                        let button = UIButton(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 90, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 30))
                        
                        button.backgroundColor = UIColor(red:0.8, green:0.10, blue:0.10, alpha:0.9)
                        button.setTitleColor(.white, for: .normal)
                        button.setTitle("Stop and Unlock Machine", for: .normal)
                        button.addTarget(self, action: #selector(self.stopLoad), for: .touchUpInside)
                        self.scrollView.addSubview(button)
                        
                        self.navigationItem.rightBarButtonItem = nil
                        self.navigationItem.leftBarButtonItem = nil
                        
                        document.get("timeWillFinish")
                        // END OF IN-USE MACHINE VIEW
                        
                    } else {
                        
                        // ***** RESERVE MACHINE SCREEN HERE *****
                        
                        self.doneButton.isEnabled = false
                        self.cancelButton.isEnabled = true
                        
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
                            imageView.frame = CGRect(x: 10, y: 80, width: Int(UIScreen.main.bounds.size.width * 0.95), height: Int(UIScreen.main.bounds.size.width * 0.95))
                            self.scrollView.addSubview(imageView)
                            self.scrollView.addSubview(label)
                        }
                        
                        let button = UIButton(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 90, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 30))
                        
                        button.backgroundColor = UIColor(red:0.01, green:0.20, blue:0.54, alpha:0.9)
                        button.setTitleColor(.white, for: .normal)
                        button.setTitle("Tap Here to Start", for: .normal)
                        button.addTarget(self, action: #selector(self.startLoad), for: .touchUpInside)
                        self.scrollView.addSubview(button)
                    }
                }
            }
        }
    }
    
    @objc
    func startLoad(){
        let db = Firestore.firestore()
        
        let started = UILabel(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 125, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 20))
        started.text = "You'll be notified when your laundry is done!"
        self.scrollView.addSubview(started)
        
        db.collection("machines").document("\(self.docIndex!)").setData([ "available": "used", "takenBy": UIDevice.current.identifierForVendor!.uuidString ], merge: true)
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Your load is finished!"
        notificationContent.body = "Unlock your machine in the app. If you wait too long, it will automatically unlock."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (30), repeats: false)
        let uuidString = UUID().uuidString
        // Create notification request
        let request = UNNotificationRequest(identifier: "washbotNotification",
                                            content: notificationContent, trigger: trigger)
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                print(error ?? "Error")
            }
        }
        
        doneButton.isEnabled = true
        cancelButton.isEnabled = false
    }
    
    @objc
    func stopLoad(){
        let alert = UIAlertController(
            title: "Are you sure you want to stop your load?",
            message: "This will also unlock the machine immediately.",
            preferredStyle: .alert)
        let noAction = UIAlertAction(
            title: "No",
            style: .default,
            handler: nil)
        let yesAction = UIAlertAction(
            title: "Yes",
            style: .destructive,
            handler: {(alert: UIAlertAction!) in
                let stopped = UITextView(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 125, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 50))
                stopped.text = "Your load was stopped. The machine is now unlocked."
                stopped.font = UIFont(name: "ArialMT", size: 16)
                self.scrollView.addSubview(stopped)
                
                let db = Firestore.firestore()
                db.collection("machines").document("\(self.docIndex!)").setData(["available": "open", "takenBy": ""], merge: true)
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["washbotNotification"])
                
                self.navigationItem.rightBarButtonItem = self.cachedDoneButton!
                self.navigationItem.rightBarButtonItem!.isEnabled = true
        })
        alert.addAction(noAction)
        alert.addAction(yesAction)
        present(alert, animated: true, completion: nil)


    }
}
