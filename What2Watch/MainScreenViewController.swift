//
//  ViewController.swift
//  What2Watch
//
//  Created by Dustin Allen on 7/15/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import Firebase
import SDWebImage
import SWRevealViewController
import UIActivityIndicator_for_SDWebImage

class MainScreenViewController: UIViewController {
 
    @IBOutlet var profileInfo: UILabel!
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var poster: UIImageView!
    @IBOutlet var btnMenu: UIButton?
    @IBOutlet weak var sliderImgPorgress: UISlider!
    
    var currentIndex:Int = 0   /// current image index
    var numberOfItems: Int = 0  /// number of images
    
    var ref:FIRDatabaseReference!
    var user: FIRUser!
    
    var movies:Array<[String:AnyObject]> = []
    var lastSwipedMovie:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //try! FIRAuth.auth()?.signOut()
        // Init menu button action for menu
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
//            self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
//            self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        ref = FIRDatabase.database().reference()
        
        if let lastSwiped_top2000 = NSUserDefaults.standardUserDefaults().objectForKey("lastSwiped_top2000") as? String {
            self.getMoviewRecord(lastSwiped_top2000)
        } else {
            CommonUtils.sharedUtils.showProgress(self.view, label: "Updating details..")
            ref.child("users").child(AppState.MyUserID()).child("lastSwiped").observeSingleEventOfType(.Value, withBlock: { snapshot in
                CommonUtils.sharedUtils.hideProgress()
                if snapshot.exists() {
                    
                    print(snapshot.childrenCount)
                    
                    if let lastSwipedMovie = snapshot.valueInExportFormat() as? NSDictionary {
                        let imdbID_top2000 = lastSwipedMovie["top2000"] as? String ?? ""
                        NSUserDefaults.standardUserDefaults().setObject(imdbID_top2000, forKey: "lastSwiped_top2000")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        self.getMoviewRecord(imdbID_top2000)
                    } else {
                        self.getMoviewRecord(nil)
                    }
                    
                } else {
                    // Not found any movie
                    self.getMoviewRecord(nil)
                }
                
                }, withCancelBlock: { error in
                    print(error.description)
                    //MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.getMoviewRecord(nil)
            })
        }
        
        //let draggableBackground: DraggableViewBackground = DraggableViewBackground(frame: self.view.frame)
        //self.view.addSubview(draggableBackground)
    }
    
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        //self.LoadMoreMovieRecords(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /**
     Action
     */
    @IBAction func logoutButton(sender: AnyObject) {
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            AppState.sharedInstance.signedIn = false
            dismissViewControllerAnimated(true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        }
        let loginViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SignInViewController") as! FirebaseSignInViewController!
        self.navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    @IBAction func menuButton(sender: AnyObject) {
        
    }
    
    /**
     Custom functions
     */
    func getMoviewRecord(skipToMovie:String?) {
        if let top2000 = NSUserDefaults.standardUserDefaults().objectForKey("top2000") as? Array<[String:AnyObject]> {
            self.movies = top2000
            self.currentIndex = skipIndexToMovie(skipToMovie)
            self.getImage(self.currentIndex)
            self.numberOfItems += top2000.count
        } else {
            //Load  Data first time from firebase
            CommonUtils.sharedUtils.showProgress(self.view, label: "We are loading the first poster!")
            ref.child("movies").child("top2000").queryOrderedByKey().observeSingleEventOfType(.Value, withBlock: { snapshot in
                CommonUtils.sharedUtils.hideProgress()
                if snapshot.exists() {
                    
                    print(snapshot.childrenCount)
                    let top2000 = snapshot.valueInExportFormat() as? NSDictionary
                    if top2000 != nil {
                        NSUserDefaults.standardUserDefaults().setObject(top2000, forKey: "top2000")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
                    
                    let enumerator = snapshot.children
                    while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                        //print("rest.key =>>  \(rest.key) =>>   \(rest.value)")
                        if var dic = rest.value as? [String:AnyObject] {
                            dic["key"] = rest.key
                            self.movies.append(dic)
                        }
                    }
                    
                    if self.movies.count > 0 {
                        NSUserDefaults.standardUserDefaults().setObject(self.movies, forKey: "top2000")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
                    
                    self.currentIndex = self.skipIndexToMovie(skipToMovie)
                    self.getImage(self.currentIndex)
                    self.numberOfItems += Int(snapshot.childrenCount)
                } else {
                    // Not found any movie
                }
                
                }, withCancelBlock: { error in
                    print(error.description)
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
            })
        }
    }
    
    func skipIndexToMovie(skipToMovie:String?) -> Int {
        if skipToMovie == nil {
            return 0
        }
        for (index, element) in self.movies.enumerate() {
            print("Item \(index): \(element)")
            if let imdbId = element["imdbID"] as? String where imdbId == skipToMovie! {
                return index+1
            }
        }
        return 0
    }
    
//    respondToSwipe
//    if self.currentIndex <= movies.count {
//        //var Movie =  movies[self.currentIndex]
//        let imdbID = movies[self.currentIndex]["imdbID"] as? String ?? ""
//        FIRDatabase.database().reference().child("users").child(AppState.MyUserID()).child("lastSwiped").child("top2000").setValue(imdbID)
//        NSUserDefaults.standardUserDefaults().setObject(imdbID, forKey: "lastSwiped_top2000")
//        NSUserDefaults.standardUserDefaults().synchronize()
//    }
    
    
    /*      */
    
    func getImage(forIndex: Int)
    {
        if forIndex >= movies.count {
            return
        }
        
        let imdbID = movies[forIndex]["imdbID"] as? String ?? ""
        let posterURL = "http://img.omdbapi.com/?i=\(imdbID)&apikey=57288a3b&h=1000"
        let posterNSURL = NSURL(string: "\(posterURL)")

        //print("Movie: \(imdbID) , Image: \(posterURL)")
        
        self.poster.sd_cancelCurrentImageLoad()
        //self.poster.setImageWithURL(posterNSURL, placeholderImage: UIImage(named: "placeholder"), usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        
        self.poster.setImageWithURL(posterNSURL, placeholderImage: UIImage(named: "placeholder"), options: SDWebImageOptions.AllowInvalidSSLCertificates, progress: { (receivedSize, expectedSize) in
            //print("receivedSize : \(receivedSize) expectedSize : \(expectedSize) ")
            
            if receivedSize == 0 && expectedSize == -1 {
               self.sliderImgPorgress.hidden = false
            }
            if receivedSize != 0 && receivedSize != -1 && expectedSize != -1 && expectedSize != 0 {
                let progress = Float(receivedSize/expectedSize)
                self.sliderImgPorgress.value = progress
                //print("Progress : \(progress)");
            }
        }, completed: { (imgPoster, error, cacheType, urlPoster) in
            if error != nil {
                print(error)
            }
            self.sliderImgPorgress.hidden = true
            self.sliderImgPorgress.value = 0
        }, usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
    }
    /*
    func swipeLeft() {
        SaveSwipeEntry(self.currentIndex, Status: "Liked")
        if self.currentIndex < self.numberOfItems-1 {
            self.currentIndex = self.currentIndex + 1
            self.getImage(self.currentIndex)
        }
        else if self.currentIndex == self.numberOfItems-1 {
            // We have to Load Next set of records
            self.LoadMoreMovieRecords(false)
        }
    }
    
    func swipeRight() {
        SaveSwipeEntry(self.currentIndex, Status: "Disliked")
        if self.currentIndex < self.numberOfItems-1 {
            self.currentIndex = self.currentIndex + 1
            self.getImage(self.currentIndex)
        }
//        if self.currentIndex > 0 {
//            self.currentIndex = self.currentIndex - 1
//            self.getImage(self.currentIndex)
//        }
    }
    
    func swipeUp() {
        SaveSwipeEntry(self.currentIndex, Status: "Haven't Watched")
        if self.currentIndex < self.numberOfItems-1 {
            self.currentIndex = self.currentIndex + 1
            self.getImage(self.currentIndex)
        }    }
    
    func swipeDown() {
        SaveSwipeEntry(self.currentIndex, Status: "Watchlist")
        if self.currentIndex < self.numberOfItems-1 {
            self.currentIndex = self.currentIndex + 1
            self.getImage(self.currentIndex)
        }
    }
    
    func tappedMe()
    {
        
        let movieDescriptionViewController = self.storyboard?.instantiateViewControllerWithIdentifier("MovieDescriptionViewController") as! MovieDescriptionViewController!
        movieDescriptionViewController.movieDetail = movies[currentIndex] as? [String:String]
        self.navigationController?.pushViewController(movieDescriptionViewController, animated: true)
        
    }*/
    
    func SaveSwipeEntry(forIndex: Int,Status: String)
    {
        if forIndex >= movies.count {
            return
        }
        
        var Movie =  movies[forIndex]
        Movie["status"] = Status
        
        FIRDatabase.database().reference().child("swiped").child(FIRAuth.auth()?.currentUser?.uid ?? "").child(Movie["key"] as? String ?? "").setValue(Movie)
    }
    
}
