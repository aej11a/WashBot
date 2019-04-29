//
//  TimerViewController.swift
//  WashBot
//
//  Created by Andrew Jones on 3/12/19.
//  Copyright © 2019 WashBot. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore

class TimerViewController: UIViewController {
    var timer = Timer()
    var secondsRemaining: Int = 30
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        let db = Firestore.firestore()
        db.collection("machines").document("1")
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    print("Error fetching document: \(error!)")
                    return
                }
                guard let data = document.data() else {
                    print("Document data was empty.")
                    return
                }
                if let available = document.get("available") as? String {
                    if available == "used" {
                        self.secondsRemaining = 30
                        self.scheduledTimerWithTimeInterval()
                    }
                    else if available == "open" {
                        self.timer.invalidate()
                    }
                }
        }
        label.transform = CGAffineTransform(rotationAngle: 3 * CGFloat.pi / 2)
    }
    func scheduledTimerWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateCounting), userInfo: nil, repeats: true)
    }
    
    @objc func updateCounting(){
        if secondsRemaining > 0 {
            secondsRemaining = secondsRemaining - 1
            if secondsRemaining > 9 {
                label.text = "00:\(secondsRemaining)"
            } else {
                label.text = "00:0\(secondsRemaining)"
            }
        } else if secondsRemaining <= 0 {
            label.text = "Done!"
            let db = Firestore.firestore()
            db.collection("machines").document("1").setData([ "available": "open", "takenBy": "" ], merge: true)
        }
    }
}
