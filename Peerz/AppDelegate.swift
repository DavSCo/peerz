//
//  AppDelegate.swift
//  Peerz
//
//  Created by David Cohen on 19/11/2018.
//  Copyright © 2018 Peerz. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context =  appDelegate.persistentContainer.viewContext
       
        let userDefaults = UserDefaults.standard
        let defaultValues = ["firstRun" : true]
        userDefaults.register(defaults: defaultValues)
        
        var deviceID: NSManagedObject? = nil
        var darkMode: NSManagedObject? = nil
        
        let requestVerify = NSFetchRequest<NSFetchRequestResult>(entityName: "DeviceID")
        requestVerify.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(requestVerify)
            for data in result as! [NSManagedObject] {
                print(data.value(forKey: "name") as! String)
                deviceID = data
            }
        } catch {
            print("Failed")
        }
        
        let requestVerifyForDarkMode = NSFetchRequest<NSFetchRequestResult>(entityName: "DarkMode")
        requestVerifyForDarkMode.returnsObjectsAsFaults = false
        do {
            let resultDarkMode = try context.fetch(requestVerifyForDarkMode)
            for dataDark in resultDarkMode as! [NSManagedObject] {
                print(dataDark.value(forKey: "isActive") as! Bool)
                darkMode = dataDark
            }
        } catch {
            print("Failed")
        }

        
        if deviceID == nil {
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
            changeDeviceId.setValue(UIDevice.current.name, forKey: "name")
            changeDeviceId.setValue(userDefaults.bool(forKey: "firstRun"), forKey: "firstConnection")
            do {
                try context.save()
            } catch {
                print("Failed saving the new Device ID")
            }
        }
        
        if darkMode == nil {
            let requestDarkMode = NSFetchRequest<NSFetchRequestResult>(entityName: "DarkMode")
            requestDarkMode.returnsObjectsAsFaults = false
            do {
                let resultDark = try context.fetch(requestDarkMode)
                for dataDark in resultDark as! [NSManagedObject] {
                    print(dataDark.value(forKey: "isActive") as! String)
                    context.delete(dataDark)
                }
            } catch {
                print("Failed")
            }
            
            let entityDarkMode = NSEntityDescription.entity(forEntityName: "DarkMode", in: context)
            let changeDarkModeStatus = NSManagedObject(entity: entityDarkMode!, insertInto: context)
            changeDarkModeStatus.setValue(false, forKey: "isActive")
            do {
                try context.save()
            } catch {
                print("Failed saving the new dark mode status")
            }
        }

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "PeerzCoreData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}

