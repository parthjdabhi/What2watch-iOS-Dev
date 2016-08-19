//
//  MyProfileViewController.swift
//  What2Watch
//
//  Created by iParth on 8/16/16.
//  Copyright © 2016 Harloch. All rights reserved.
//

import UIKit
import FirebaseDatabase

class MyProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet var btnMenu: UIButton?
    @IBOutlet var imgProfile: UIImageView!
    @IBOutlet var lblDisplayName: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    private var currentPage: Int = 1
    
    private var movieWatched:Array<[String:AnyObject]> = []
    
    private var pageSize: CGSize {
        let layout = self.collectionView.collectionViewLayout as! PDCarouselFlowLayout
        var pageSize = layout.itemSize
        if layout.scrollDirection == .Horizontal {
            pageSize.width += layout.minimumLineSpacing
        } else {
            pageSize.height += layout.minimumLineSpacing
        }
        return pageSize
    }
    
    var ref = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if let revealVC = self.revealViewController() {
            self.btnMenu?.addTarget(revealVC, action: #selector(revealVC.revealToggle(_:)), forControlEvents: .TouchUpInside)
            self.view.addGestureRecognizer(revealVC.panGestureRecognizer());
            //self.navigationController?.navigationBar.addGestureRecognizer(revealVC.panGestureRecognizer())
        }
        
        self.collectionView.showsHorizontalScrollIndicator = false
        let layout = self.collectionView.collectionViewLayout as! PDCarouselFlowLayout
        layout.spacingMode = PDCarouselFlowLayoutSpacingMode.overlap(visibleOffset: 120)
        layout.scrollDirection = .Horizontal
        
        if currentPage > 0 {
            let indexPath = NSIndexPath(forItem: currentPage, inSection: 0)
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: false)
        }
        
        imgProfile.layer.cornerRadius = max(imgProfile.frame.size.width, imgProfile.frame.size.height) / 2
        imgProfile.layer.borderWidth = 3
        imgProfile.layer.masksToBounds = true
        imgProfile.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).CGColor
        
        lblDisplayName.text = AppState.sharedInstance.displayName
        imgProfile.image = AppState.sharedInstance.myProfile
        
        self.fetchMovieWatched()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
//    @IBAction func actionBack(sender: AnyObject) {
//        self.navigationController?.popViewControllerAnimated(true)
//    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - Card Collection Delegate & DataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Set Static values 5 here for test purpose
        return 5
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(SliderCollectionViewCell.identifier, forIndexPath: indexPath) as! SliderCollectionViewCell
        
        cell.image.image = UIImage(named: "")
        cell.image.layer.cornerRadius = max(cell.image.frame.size.width, cell.image.frame.size.height) / 2
        cell.image.layer.borderWidth = 10
        cell.image.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1).CGColor
        cell.lblValue.text = "\(self.movieWatched.count)"
        
        cell.selectedBackgroundView = nil
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //let character = items[indexPath.row]
//        if currentPage != indexPath.row {
//            //let indexPath = NSIndexPath(forItem: currentPage, inSection: 0)
//            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredHorizontally, animated: true)
//            return
//        }
//        currentPage = indexPath.row
        
//        let alert = UIAlertController(title: "Option \(indexPath.row+1)", message: nil, preferredStyle: .Alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
//        presentViewController(alert, animated: true, completion: nil)
        
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        let movieWatchedVC:MovieWatchedVC = self.storyboard?.instantiateViewControllerWithIdentifier("MovieWatchedVC") as! MovieWatchedVC
        movieWatchedVC.movieWatched = self.movieWatched
        self.navigationController?.pushViewController(movieWatchedVC, animated: true)
    }
    
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let layout = self.collectionView.collectionViewLayout as! PDCarouselFlowLayout
        let pageSide = (layout.scrollDirection == .Horizontal) ? self.pageSize.width : self.pageSize.height
        let offset = (layout.scrollDirection == .Horizontal) ? scrollView.contentOffset.x : scrollView.contentOffset.y
        currentPage = Int(floor((offset - pageSide / 2) / pageSide) + 1)
        print("currentPage = \(currentPage)")
    }
    
    func fetchMovieWatched() {
        ref.child("swiped").child(AppState.MyUserID()).observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            CommonUtils.sharedUtils.hideProgress()
            self.movieWatched.removeAll()

            if snapshot.exists() {
                
                print(snapshot.childrenCount)
                //let swiped = snapshot.valueInExportFormat() as? NSDictionary
                let enumerator = snapshot.children
                while let rest = enumerator.nextObject() as? FIRDataSnapshot {
                    //print("rest.key =>>  \(rest.key) =>>   \(rest.value)")
                    if var dic = rest.value as? [String:AnyObject] {
                        dic["key"] = rest.key
                        self.movieWatched.append(dic)
                    }
                }
                
                if self.movieWatched.count > 0 {
                    self.collectionView.reloadData()
                }
            } else {
                // Not found any movie
            }
            
            }, withCancelBlock: { error in
                print(error.description)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
        })
    }
}
