//
//  WebViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 16/9/14.
//  Copyright (c) 2014 AppCoda. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    @IBOutlet weak var webView:UIWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load web content
        let url = NSURL(string: "http://www.appcoda.com")
        let request = NSURLRequest(URL: url)
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
