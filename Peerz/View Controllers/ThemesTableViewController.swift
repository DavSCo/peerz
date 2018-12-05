//
//  ThemesTableViewController.swift
//  Peerz
//
//  Created by David Cohen on 04/12/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//

import UIKit
import CoreData

class ThemesTableViewController: UITableViewController {

    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    var appDelegate = AppDelegate()
    var context = NSManagedObjectContext()
    var darkMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DarkMode")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "isActive") as! Bool)
                darkMode = data.value(forKey: "isActive") as! Bool
            }
        } catch {
            print("Failed")
        }

        darkModeSwitch.isOn = darkMode
    }

   
    @IBAction func darkModeSwitchAction(_ sender: UISwitch) {
        print(sender.isOn)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DarkMode")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "isActive") as! Bool)
                context.delete(data)
            }
        } catch {
            print("Failed")
        }
        
        let entity = NSEntityDescription.entity(forEntityName: "DarkMode", in: context)
        let changeDarkModeStatus = NSManagedObject(entity: entity!, insertInto: context)
        changeDarkModeStatus.setValue(sender.isOn, forKey: "isActive")
        do {
            try context.save()
        } catch {
            print("Failed saving the new dark mode status")
        }
    }
    
}
