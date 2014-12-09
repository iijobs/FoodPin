//
//  FeedTableViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 18/9/14.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

import UIKit
import CloudKit

class FeedTableViewController: UITableViewController {
    var restaurants:[CKRecord] = []
    
    var spinner:UIActivityIndicatorView = UIActivityIndicatorView()

    var imageCache:NSCache = NSCache()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the activity indicator and start animating
        spinner.activityIndicatorViewStyle = .Gray
        spinner.center = self.view.center
        spinner.hidesWhenStopped = true
        self.parentViewController?.view.addSubview(spinner)
        spinner.startAnimating()
        
        // Pull To Refresh Control
        refreshControl = UIRefreshControl()
        refreshControl?.backgroundColor = UIColor.whiteColor()
        refreshControl?.tintColor = UIColor.grayColor()
        refreshControl?.addTarget(self, action: "getRecordsFromCloud", forControlEvents: UIControlEvents.ValueChanged)
        
        self.getRecordsFromCloud()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return restaurants.count
    }
    
    // MARK: - Data Methods for iCloud
    /*
    func getRecordsFromCloud() {
        // Fetch data using Convenience API
        let cloudContainer = CKContainer.defaultContainer()
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Restaurant", predicate: predicate)
        publicDatabase.performQuery(query, inZoneWithID: nil, completionHandler: {
            results, error in
            if error == nil {
                println("Completed the download of Restaurant data")
                self.restaurants = results as [CKRecord]
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            } else {
                println("Failed to retrieve data: \(error.description)")
            }
        })
    }
    */
    
    func getRecordsFromCloud() {
        // Initialize an empty restaurants array
        restaurants = []
        
        // Get the Public iCloud Database
        let cloudContainer = CKContainer.defaultContainer()
        let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        // Prepare the query
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Restaurant", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Create the query operation with the query
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["name"]
        queryOperation.queuePriority = .VeryHigh
        queryOperation.resultsLimit = 50
        queryOperation.recordFetchedBlock = { (record:CKRecord!) -> Void in
            if let restaurantRecord = record {
                self.restaurants.append(restaurantRecord)
            }
        }
        queryOperation.queryCompletionBlock = { (cursor:CKQueryCursor!, error:NSError!) -> Void in
            if self.spinner.isAnimating() {
                dispatch_async(dispatch_get_main_queue(), {
                    self.spinner.stopAnimating()
                })
            }
            
            // Hide the refresh control
            self.refreshControl?.endRefreshing()
            
            if (error != nil) {
                println("Failed to get data from iCloud - \(error.localizedDescription)")
            } else {
                println("Successfully retrieved the data from iCloud")
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                })
            }
            
        }
        
        // Execute the query
        publicDatabase.addOperation(queryOperation)
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell

        if restaurants.isEmpty {
            return cell
        }
        
        // Configure the cell...
        let restaurant = restaurants[indexPath.row]
        cell.textLabel?.text = restaurant.objectForKey("name") as? String
        
        // Set default image
        cell.imageView?.image = UIImage(named: "camera")
        
        // See if we can get the image from cache
        if let imageFileURL = imageCache.objectForKey(restaurant.recordID) as? NSURL {
            println("Get image from cache")
            cell.imageView?.image = UIImage(data: NSData(contentsOfURL: imageFileURL))
            
        } else {
            
            // Fetch Image from Cloud in background
            let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
            let fetchRecordsImageOperation = CKFetchRecordsOperation(recordIDs: [restaurant.recordID])
            fetchRecordsImageOperation.desiredKeys = ["image"]
            fetchRecordsImageOperation.queuePriority = .VeryHigh
            fetchRecordsImageOperation.perRecordCompletionBlock = {(record:CKRecord!, recordID:CKRecordID!, error:NSError!) -> Void in
                if (error != nil) {
                    println("Failed to get restaurant image: \(error.localizedDescription)")
                } else {
                    if let restaurantRecord = record {
                        dispatch_async(dispatch_get_main_queue(), {
                            let imageAsset = restaurantRecord.objectForKey("image") as CKAsset
                            self.imageCache.setObject(imageAsset.fileURL, forKey: restaurant.recordID)
                            cell.imageView?.image = UIImage(data: NSData(contentsOfURL: imageAsset.fileURL))
                        })
                    }
                }
            }
            publicDatabase.addOperation(fetchRecordsImageOperation)
        }
        
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView!, moveRowAtIndexPath fromIndexPath: NSIndexPath!, toIndexPath: NSIndexPath!) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView!, canMoveRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
