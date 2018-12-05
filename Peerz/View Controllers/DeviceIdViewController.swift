//
//  DeviceIdViewController.swift
//  Peerz
//
//  Created by David Cohen on 04/12/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//

import UIKit
import CoreData

class DeviceIdViewController: UITableViewController {

    @IBOutlet weak var deviceIdTextField: UITextField!
    
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
        
        deviceIdTextField.text = deviceId
        
         navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(changeDeviceId))
    }

    @objc func changeDeviceId() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DeviceID")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                context.delete(data)
            }
        } catch {
            print("Failed")
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "DeviceID", in: context)
        let changeDeviceId = NSManagedObject(entity: entity!, insertInto: context)
        changeDeviceId.setValue(deviceIdTextField.text, forKey: "name")
        
        do {
            try context.save()
            deviceIdTextField.endEditing(true)
        } catch {
            print("Failed saving the new Device ID")
        }
    }

}
