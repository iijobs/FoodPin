//
//  AddTableViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 3/9/14.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class AddTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var nameTextField:UITextField!
    @IBOutlet weak var typeTextField:UITextField!
    @IBOutlet weak var locationTextField:UITextField!
    @IBOutlet weak var imageView:UIImageView!
    @IBOutlet weak var yesButton:UIButton!
    @IBOutlet weak var noButton:UIButton!
    
    var isVisited = true
    
    var restaurant:Restaurant!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

/*    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 5
    }
*/
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 0 {
            if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.allowsEditing = false
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                
                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        imageView.image = image
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func save() {
        
        // Form validation
        var errorField = ""
        
        if nameTextField.text == "" {
            errorField = "name"
        } else if locationTextField.text == "" {
            errorField = "location"
        } else if typeTextField.text == "" {
            errorField = "type"
        }
        
        if errorField != "" {
            
            let alertController = UIAlertController(title: "Oops", message: "We can't proceed as you forget to fill in the restaurant " + errorField + ". All fields are mandatory.", preferredStyle: .Alert)
            let doneAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(doneAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
            return
        }

        // If all fields are correctly filled in, extract the field value
        // Create Restaurant Object and save to data store
        if let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext {
            
            restaurant = NSEntityDescription.insertNewObjectForEntityForName("Restaurant",
                inManagedObjectContext: managedObjectContext) as Restaurant
            restaurant.name = nameTextField.text
            restaurant.type = typeTextField.text
            restaurant.location = locationTextField.text
            restaurant.image = UIImagePNGRepresentation(imageView.image)
            restaurant.isVisited = NSNumber.convertFromBooleanLiteral(isVisited)
            
            var e: NSError?
            if managedObjectContext.save(&e) != true {
                println("insert error: \(e!.localizedDescription)")
                return
            }
        }
        
        // Save record to the cloud and share the restaurant with others
        saveRecordToCloud(restaurant)
        
        // Execute the unwind segue and go back to the home screen
        performSegueWithIdentifier("unwindToHomeScreen", sender: self)
    }
    
    @IBAction func updateIsVisited(sender: AnyObject) {
        // Yes button clicked
        let buttonClicked = sender as UIButton
        if buttonClicked == yesButton {
            isVisited = true
            yesButton.backgroundColor = UIColor(red: 235.0/255.0, green: 73.0/255.0, blue: 27.0/255.0, alpha: 1.0)
            noButton.backgroundColor = UIColor.grayColor()
        } else if buttonClicked == noButton {
            isVisited = false
            yesButton.backgroundColor = UIColor.grayColor()
            noButton.backgroundColor = UIColor(red: 235.0/255.0, green: 73.0/255.0, blue: 27.0/255.0, alpha: 1.0)
        }
    }

    func saveRecordToCloud(restaurant:Restaurant!) -> Void {
        // Prepare the record to save
        var record = CKRecord(recordType: "Restaurant")
        record.setValue(restaurant.name, forKey: "name")
        record.setValue(restaurant.type, forKey: "type")
        record.setValue(restaurant.location, forKey: "location")
        
        // Resize the image
        var originalImage = UIImage(data: restaurant.image)
        var scalingFactor = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
        var scaledImage = UIImage(data: restaurant.image, scale: scalingFactor)
        
        // Write the image to local file for temporary use
        let imageFilePath = NSTemporaryDirectory() + restaurant.name
        UIImageJPEGRepresentation(scaledImage, 0.8).writeToFile(imageFilePath, atomically: true)

        // Create image asset for upload
        let imageFileURL = NSURL(fileURLWithPath: imageFilePath)
        var imageAsset = CKAsset(fileURL: imageFileURL)
        record.setValue(imageAsset, forKey: "image")
        
        // Get the Public iCloud Database
        let cloudContainer = CKContainer.defaultContainer()
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase

        // Save the record to iCloud
        publicDatabase.saveRecord(record, completionHandler: { (record:CKRecord!, error:NSError!) -> Void  in
            
            // Remove temp file
            NSFileManager.defaultManager().removeItemAtPath(imageFilePath, error: nil)
        
            if (error != nil) {
                println("Failed to save record to the cloud: \(error.description)")
            }
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    func navigationController(navigationController: UINavigationController!, willShowViewController viewController: UIViewController!, animated: Bool) {
        UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }
}
