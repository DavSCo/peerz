//
//  SecondViewController.swift
//  Peerz
//
//  Created by David Cohen on 19/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UITableViewController {

    @IBOutlet weak var deviceIdLabel: UILabel!
    
    var appDelegate = AppDelegate()
    var context = NSManagedObjectContext()
    var deviceId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DeviceID")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                deviceId = data.value(forKey: "name") as! String
            }
        } catch {
            print("Failed")
        }
        
        deviceIdLabel.text = deviceId
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DeviceID")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                deviceId = data.value(forKey: "name") as! String
            }
        } catch {
            print("Failed")
        }
        
        deviceIdLabel.text = deviceId
        tableView.reloadData()
    }
}

