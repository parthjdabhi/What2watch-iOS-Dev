//
//  WatchlistViewController.swift
//  What2Watch
//
//  Created by iParth on 8/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController

        
class WatchlistViewController: UIViewController {
    
    @IBOutlet var btnMenu: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
            self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
            //            self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
