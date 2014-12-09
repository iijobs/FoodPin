//
//  RestaurantTableViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 11/8/14.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

import UIKit
import CoreData

class RestaurantTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating {
    var restaurants:[Restaurant] = []
    
    var fetchResultController:NSFetchedResultsController!

    var searchController: UISearchController!
    var searchResults:[Restaurant] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Launch walkthrough screens
        let defaults = NSUserDefaults.standardUserDefaults()
        let hasViewedWalkthrough = defaults.boolForKey("hasViewedWalkthrough")
        
        if hasViewedWalkthrough == false {
            if let pageViewController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? PageViewController {
            
            self.presentViewController(pageViewController, animated: true, completion: nil)
            }
        }
        
        // Empty back button title
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Self Sizing Cells
//        self.tableView.estimatedRowHeight = 80.0;
//        self.tableView.rowHeight = UITableViewAutomaticDimension;
        
        // Retrieve content from persistent store
        var fetchRequest = NSFetchRequest(entityName: "Restaurant")
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext {
            fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
            fetchResultController.delegate = self
            
            var e: NSError?
            var result = fetchResultController.performFetch(&e)
            restaurants = fetchResultController.fetchedObjects as [Restaurant]
            
            if result != true {
                println(e?.localizedDescription)
            }
        }
        
        // Create the search controller, but we'll make sure that this SearchShowResultsInSourceViewController
        // performs the results updating.
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.tintColor = UIColor.blackColor()
//        searchController.searchBar.barTintColor = UIColor(red: 235.0/255.0, green: 73.0/255.0, blue: 27.0/255.0, alpha: 1.0)
//
//        searchController.searchBar.placeholder = "Search your restaurant"
//        searchController.searchBar.prompt = "Quick Search"

        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false

        // Make sure the that the search bar is visible within the navigation bar.
        searchController.searchBar.sizeToFit()
        
        // Include the search controller's search bar within the table's header view.
        tableView.tableHeaderView = searchController.searchBar
        
        definesPresentationContext = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.hidesBarsOnSwipe = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if searchController.active {
            return searchResults.count
        } else {
            return self.restaurants.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as CustomTableViewCell
        
        // Configure the cell...
        let restaurant = (searchController.active) ? searchResults[indexPath.row] : restaurants[indexPath.row]
        
        cell.nameLabel.text = restaurant.name
        cell.thumbnailImageView.image = UIImage(data: restaurant.image)
        cell.locationLabel.text = restaurant.location
        cell.typeLabel.text = restaurant.type
        cell.favorIconImageView.hidden = !restaurant.isVisited

        // Circular image
//        cell.thumbnailImageView.layer.cornerRadius = cell.thumbnailImageView.frame.size.width / 2
//        cell.thumbnailImageView.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if searchController.active {
            return false
        } else {
            return true
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        var shareAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: NSLocalizedString("Share", comment: "For social sharing"), handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            let shareMenu = UIAlertController(title: nil, message: NSLocalizedString("Share using", comment: "For social sharing"), preferredStyle: .ActionSheet)
            let twitterAction = UIAlertAction(title: NSLocalizedString("Twitter", comment: "For sharing on Twitter"), style: UIAlertActionStyle.Default, handler: nil)
            let facebookAction = UIAlertAction(title: NSLocalizedString("Facebook", comment: "For sharing on Facebook"), style: UIAlertActionStyle.Default, handler: nil)
            let emailAction = UIAlertAction(title: NSLocalizedString("Email", comment: "For sharing on Email"), style: UIAlertActionStyle.Default, handler: nil)
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.Cancel, handler: nil)
            
            shareMenu.addAction(twitterAction)
            shareMenu.addAction(facebookAction)
            shareMenu.addAction(emailAction)
            shareMenu.addAction(cancelAction)
            
            self.presentViewController(shareMenu, animated: true, completion: nil)
            }
        )
        
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: NSLocalizedString("Delete", comment: "For delete"),handler: {
            (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            
            // Delete the row from the data source
            if let managedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext {
                
                let restaurantToDelete = self.fetchResultController.objectAtIndexPath(indexPath) as Restaurant
                managedObjectContext.deleteObject(restaurantToDelete)
                
                var e: NSError?
                if managedObjectContext.save(&e) != true {
                    println("delete error: \(e!.localizedDescription)")
                }
            }
            
        })

        deleteAction.backgroundColor = UIColor(red: 237.0/255.0, green: 75.0/255.0, blue: 27.0/255.0, alpha: 1.0)
        shareAction.backgroundColor = UIColor(red: 215.0/255.0, green: 215.0/255.0, blue: 215.0/255.0, alpha: 1.0)

        return [deleteAction, shareAction]
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController!) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        case .Update:
            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
        default:
            tableView.reloadData()
        }
        
        restaurants = controller.fetchedObjects as [Restaurant]
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        tableView.endUpdates()
    }
    
    // MARK: - Search Controller
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let searchText = searchController.searchBar.text
        
        filterContentForSearchText(searchText)
        
        tableView.reloadData()
    }
    
    func filterContentForSearchText(searchText: String) {
        
        searchResults = restaurants.filter({ ( restaurant: Restaurant) -> Bool in
            
            let nameMatch = restaurant.name.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            //            let locationMatch = restaurant.location.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            
            return nameMatch != nil //|| locationMatch != nil
            
        })
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        
        if segue.identifier == "showRestaurantDetail" {
            if let row = tableView.indexPathForSelectedRow()?.row {
                let destinationController = segue.destinationViewController as DetailViewController
                destinationController.restaurant = (searchController.active) ? searchResults[row] : restaurants[row]
            }
        }
    }


    @IBAction func unwindToHomeScreen(segue:UIStoryboardSegue) {
    }

}
