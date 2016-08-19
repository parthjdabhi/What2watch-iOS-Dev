//
//  MySlideMenuController.swift
//  What2Watch
//
//  Created by iParth on 8/3/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import SWRevealViewController
import Firebase

enum LeftMenu: Int {
    case Main = 0
    case Watchlist
    case What2watch
    case ImproveAccu
    case ShareWat2Watch
}

protocol LeftMenuProtocol : class {
    func changeViewController(menu: LeftMenu)
}

class MySlideMenuController : UIViewController {
    
    @IBOutlet weak var txtSearchbar: UITextField?
    @IBOutlet weak var btnSearch: UIButton?
    @IBOutlet weak var imgProfile: UIImageView?
    @IBOutlet weak var lblName: UILabel?
    @IBOutlet weak var lblWachCount: UILabel?
    @IBOutlet weak var lblTimeWaste: UILabel?
    
    @IBOutlet weak var lblCount: UILabel?
    @IBOutlet weak var btnWatchlist: UIButton?
    @IBOutlet weak var btnWhat2Watch: UIButton?
    @IBOutlet weak var btnImproveAccu: UIButton?
    @IBOutlet weak var btnShareWhat2W: UIButton?
    @IBOutlet weak var btnHelp: UIButton?
    @IBOutlet weak var btnMainScreen: UIButton!
    @IBOutlet weak var btnLogout: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        txtSearchbar?.layer.cornerRadius = (txtSearchbar?.frame.size.height)!/2
        txtSearchbar?.layer.masksToBounds = true
        
        lblCount?.layer.cornerRadius = (lblCount?.frame.size.height)!/2
        lblCount?.layer.borderColor = lblCount!.textColor.CGColor
        lblCount?.layer.borderWidth = 1.0
        lblCount?.layer.masksToBounds = true
        
        imgProfile?.layer.cornerRadius = (imgProfile?.frame.width ?? 1) / 2
        imgProfile?.layer.borderWidth = 3
        imgProfile?.layer.masksToBounds = true
        imgProfile?.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        btnMainScreen.layer.borderWidth = 1
        btnMainScreen.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        btnLogout.layer.borderWidth = 1
        btnLogout.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        let ref = FIRDatabase.database().reference()
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        ref.child("users").child(userID!).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.exists() {
                AppState.sharedInstance.currentUser = snapshot
                if let base64String = snapshot.value!["image"] as? String {
                    // decode image
                    self.imgProfile?.image = CommonUtils.sharedUtils.decodeImage(base64String)
                    AppState.sharedInstance.myProfile = CommonUtils.sharedUtils.decodeImage(base64String)
                }
                let userFirstName = AppState.sharedInstance.currentUser?.value?["userFirstName"] as? String ?? ""
                let userLastName = AppState.sharedInstance.currentUser?.value?["userLastName"] as? String ?? ""
                AppState.sharedInstance.displayName = "\(userFirstName) \(userLastName)"
                self.lblName?.text =  AppState.sharedInstance.displayName
                
                AppState.sharedInstance.movieWatched = snapshot.value?["movieWatched"] as? String ?? "0"
                AppState.sharedInstance.timeWatched = snapshot.value?["timeWatched"] as? String ?? "0"
                AppState.sharedInstance.watchlistCount = snapshot.value?["watchlistCount"] as? String ?? "0"
                
                self.lblWachCount?.text = "Watched Movies : \(AppState.sharedInstance.movieWatched ?? "0")"
                self.lblTimeWaste?.text = "Wasted \(AppState.sharedInstance.timeWatched ?? "0") hours of my life on watching movies"
                
                self.lblCount?.text = AppState.sharedInstance.movieWatched
                if (AppState.sharedInstance.movieWatched ?? "0") == 0 {
                    //self.lblCount?.hidden = false
                } else {
                    //self.lblCount?.hidden = true
                }
            }
        })
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let watchlistVC = storyboard.instantiateViewControllerWithIdentifier("TermsViewController") as! TermsViewController
//        self.watchlistVC = UINavigationController(rootViewController: watchlistVC)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    @IBAction func actionMainScreen(sender: AnyObject) {
        self.performSegueWithIdentifier("segueMainScreen", sender: self)
    }
    
    @IBAction func actionMyProfile(sender: AnyObject) {
        self.performSegueWithIdentifier("segueMyProfile", sender: self)
    }
    
    @IBAction func actionLogout(sender: AnyObject) {
        AppState.Logout()
        try! FIRAuth.auth()?.signOut()
        //self.performSegueWithIdentifier("segueLogin", sender: self)
    }
    
    @IBAction func actionWatchlist(sender: AnyObject) {
        self.performSegueWithIdentifier("segueWatchlist", sender: self)
    }
    
    @IBAction func actionWhat2watch(sender: AnyObject) {
        self.performSegueWithIdentifier("segueWhat2Watch", sender: self)
    }
    
    @IBAction func actionImproveAccuracy(sender: AnyObject) {
        self.performSegueWithIdentifier("segueWatchlist", sender: self)
    }
    
    @IBAction func actionShareWhat2Watch(sender: AnyObject) {
        self.performSegueWithIdentifier("segueWhat2Watch", sender: self)
    }
    
    @IBAction func actionHelp(sender: AnyObject) {
        self.performSegueWithIdentifier("segueWatchlist", sender: self)
    }
}

