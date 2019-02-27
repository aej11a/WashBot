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
    
    var docIndex : Int?
    
    @IBAction func close(_ sender: Any) {
        let db = Firestore.firestore()
        db.collection("machines").document("\(self.docIndex!)").setData([ "available": "open" ], merge: true)
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
        
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Your load is finished!"
        notificationContent.body = "Unlock your machine in the app. If you wait too long, it will automatically unlock."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: (10), repeats: false)
        let uuidString = UUID().uuidString
        // Create notification request
        let request = UNNotificationRequest(identifier: uuidString,
                                            content: notificationContent, trigger: trigger)
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                print(error)
            }
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("machines").document("\(self.docIndex!)")
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                self.clearView()
                
                db.collection("machines").document("\(self.docIndex!)").setData([ "available": "used" ], merge: true)
                
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
            } else {
                print("Document does not exist")
            }
        }
    }
    
    @objc
    func startLoad(){
        let started = UILabel(frame: CGRect(x: 10, y: Int(UIScreen.main.bounds.size.width * 0.95) + 125, width: Int(UIScreen.main.bounds.size.width * 0.95), height: 20))
        started.text = "You'll be notified when your laundry is done!"
        self.scrollView.addSubview(started)
        
        
        doneButton.isEnabled = true
        cancelButton.isEnabled = false
    }
}
