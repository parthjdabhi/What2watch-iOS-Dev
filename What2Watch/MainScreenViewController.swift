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

import Koloda
import pop

//private let numberOfCards: UInt = 5
private let frameAnimationSpringBounciness: CGFloat = 9
private let frameAnimationSpringSpeed: CGFloat = 16
private let kolodaCountOfVisibleCards = 2
private let kolodaAlphaValueSemiTransparent: CGFloat = 0.05

class MainScreenViewController: UIViewController {
 
    @IBOutlet var profileInfo: UILabel!
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var poster: UIImageView!
    @IBOutlet var btnMenu: UIButton?
    //@IBOutlet var draggableBackground: DraggableViewBackground!
    @IBOutlet weak var cardHolderView: CustomKolodaView!
    
    var currentIndex:Int = 0   /// current image index
    var numberOfItems: Int = 0  /// number of images
    
    var ref:FIRDatabaseReference!
    var user: FIRUser!
    
    //var draggableBackground: DraggableViewBackground!
    
    var movies:Array<[String:AnyObject]> = []
    var lastSwipedMovie:String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardHolderView.alphaValueSemiTransparent = kolodaAlphaValueSemiTransparent
        cardHolderView.countOfVisibleCards = kolodaCountOfVisibleCards
        cardHolderView.delegate = self
        cardHolderView.dataSource = self
        cardHolderView.animator = BackgroundKolodaAnimator(koloda: cardHolderView)
        cardHolderView.backgroundColor = UIColor.blackColor()
        
        //draggableBackground = DraggableViewBackground(frame: CGRectMake(0, 69, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        //self.view.addSubview(draggableBackground)
        
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
        
        
        //draggableBackground.cardMovies = self.movies
        //draggableBackground.loadCards()
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
            //self.getImage(self.currentIndex)
            self.numberOfItems += top2000.count
            
            if self.currentIndex > 0 {
                self.movies.removeFirst(self.currentIndex)
            }
            cardHolderView.reloadData()
            
//            draggableBackground.movies = self.movies
//            draggableBackground.loadCardsFromIndex(skipIndexToMovie(skipToMovie))
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
//                    self.getImage(self.currentIndex)
//                    self.numberOfItems += Int(snapshot.childrenCount)
                    
                    if self.currentIndex > 0 {
                        self.movies.removeFirst(self.currentIndex-1)
                    }
                    self.cardHolderView.reloadData()
                    
//                    self.draggableBackground.movies = self.movies
//                    self.draggableBackground.loadCardsFromIndex(self.skipIndexToMovie(skipToMovie))
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
        
        let imdbID = Movie["imdbID"] as? String ?? ""
        FIRDatabase.database().reference().child("users").child(AppState.MyUserID()).child("lastSwiped").child("top2000").setValue(imdbID)
        NSUserDefaults.standardUserDefaults().setObject(imdbID, forKey: "lastSwiped_top2000")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
}

//MARK: KolodaViewDelegate
extension MainScreenViewController: KolodaViewDelegate {
    
    func kolodaDidRunOutOfCards(koloda: KolodaView) {
        cardHolderView.resetCurrentCardIndex()
    }
    
    func koloda(koloda: KolodaView, didSelectCardAtIndex index: UInt) {
        let movieDescriptionViewController = self.storyboard?.instantiateViewControllerWithIdentifier("MovieDescriptionViewController") as! MovieDescriptionViewController!
        movieDescriptionViewController.movieDetail = movies[Int(index)] as? [String:String]
        self.navigationController?.pushViewController(movieDescriptionViewController, animated: true)
    }
    

    
    func kolodaShouldApplyAppearAnimation(koloda: KolodaView) -> Bool {
        return true
    }
    
    func kolodaShouldMoveBackgroundCard(koloda: KolodaView) -> Bool {
        return false
    }
    
    func kolodaShouldTransparentizeNextCard(koloda: KolodaView) -> Bool {
        return true
    }
    
    func koloda(kolodaBackgroundCardAnimation koloda: KolodaView) -> POPPropertyAnimation? {
        let animation = POPSpringAnimation(propertyNamed: kPOPViewFrame)
        animation.springBounciness = frameAnimationSpringBounciness
        animation.springSpeed = frameAnimationSpringSpeed
        return animation
    }
    
    func koloda(koloda: KolodaView, allowedDirectionsForIndex index: UInt) -> [SwipeResultDirection] {
        return [.Left, .Right, .Up, .Down]
    }
    
    
    func koloda(koloda: KolodaView, didSwipeCardAtIndex index: UInt, inDirection direction: SwipeResultDirection) {
        
        switch direction {
        case .Left, .TopLeft, .BottomLeft:
            print("Liked")
            SaveSwipeEntry(Int(index), Status: "Liked")
            break
        case .Right, .TopRight, .BottomRight:
            print("Disliked")
            SaveSwipeEntry(Int(index), Status: "Disliked")
            break
        case .Up:
            print("Dislike")
            SaveSwipeEntry(Int(index), Status: "Haven't Watched")
            break
        case .Down:
            print("Watchlist")
            SaveSwipeEntry(Int(index), Status: "Watchlist")
            break
        }
    }
}

//MARK: KolodaViewDataSource
extension MainScreenViewController: KolodaViewDataSource {
    
    func kolodaNumberOfCards(koloda: KolodaView) -> UInt {
        return UInt(movies.count)
    }
    
    func koloda(koloda: KolodaView, viewForCardAtIndex index: UInt) -> UIView {
        let imgPoster = UIImageView(frame: koloda.frame)
        let imdbID = movies[Int(index)]["imdbID"] as? String ?? ""
        let posterURL = "http://img.omdbapi.com/?i=\(imdbID)&apikey=57288a3b&h=1000"
        let posterNSURL = NSURL(string: "\(posterURL)")
        
        print(" \(index) Movie: \(imdbID) , Image: \(posterURL)")
        imgPoster.setImageWithURL(posterNSURL, placeholderImage: UIImage(named: "placeholder"), options: SDWebImageOptions.AllowInvalidSSLCertificates, usingActivityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        return imgPoster
//        return UIImageView(image: UIImage(named: "cards_\(index + 1)"))
    }
    
    func koloda(koloda: KolodaView, viewForCardOverlayAtIndex index: UInt) -> OverlayView? {
        return NSBundle.mainBundle().loadNibNamed("CustomOverlayView",
                                                  owner: self, options: nil)[0] as? OverlayView
    }
}