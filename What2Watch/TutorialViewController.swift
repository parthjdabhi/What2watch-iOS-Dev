//
//  TutorialViewController.swift
//  UIPageViewController Post
//
//  Created by Jeffrey Burt on 2/3/16.
//  Copyright © 2016 Seven Even. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var pageControlOption = UIPageControl.self
    var nextIndex: Int=0;
    
    var tutorialPageViewController: TutorialPageViewController? {
        didSet {
            tutorialPageViewController?.tutorialDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.addTarget(self, action: #selector(TutorialViewController.didChangePageControlValue), forControlEvents: .ValueChanged)
        pageControl.numberOfPages = 6
        self.scrollView.delegate = self
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * 6, self.scrollView.frame.size.height)
        self.initViews()
    }
    
    override func  preferredStatusBarStyle()-> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let tutorialPageViewController = segue.destinationViewController as? TutorialPageViewController {
            self.tutorialPageViewController = tutorialPageViewController
        }
    }
    
    var currentIndex: Int? = 0
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        // The view controllers will be shown in this order
        return [self.newColoredViewController("Picture"),
                self.newColoredViewController("Red"),
                self.newColoredViewController("Blue"),
                self.newColoredViewController("DOB"),
                self.newColoredViewController("Nationality"),
                self.newColoredViewController("Terms")]
    }()
    
    func initViews() {
        
        for i in 0 ... 5 {
            let viewController = orderedViewControllers[i]
            viewController.view.frame = CGRectMake(self.scrollView.frame.size.width * CGFloat(i), 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height)
            self.scrollView.addSubview(viewController.view)
        }
    }
    
    private func newColoredViewController(color: String) -> UIViewController {
        let VC = UIStoryboard(name: "Main", bundle: nil) .
            instantiateViewControllerWithIdentifier("\(color)ViewController") as! BaseViewController
        VC.delegate = self
        return VC
    }

    
    /*
    @IBAction func didTapNextButton(sender: UIButton) {
        tutorialPageViewController?.scrollToNextViewController()
    }*/
    
    /**
     Fired when the user taps on the pageControl to change its current page.
     */
    func didChangePageControlValue() {
//        tutorialPageViewController?.scrollToViewController(index: pageControl.currentPage)
    }
}

extension TutorialViewController: TutorialPageViewControllerDelegate {
    
    func tutorialPageViewController(tutorialPageViewController: TutorialPageViewController,
        didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    
    func tutorialPageViewController(tutorialPageViewController: TutorialPageViewController,
        didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
    
}

extension TutorialViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let diffFromCenter = (Float(scrollView.contentOffset.x) - (Float)(self.pageControl.currentPage)*Float(self.view.frame.size.width));
        let currentPageAlpha = 1.0 - fabs(diffFromCenter)/Float(self.view.frame.size.width);
        let sidePagesAlpha = fabs(diffFromCenter)/Float(self.view.frame.size.width);
        currentIndex = self.pageControl.currentPage
        if diffFromCenter > 0 {
            nextIndex = currentIndex! + 1
        }else {
            nextIndex = currentIndex! - 1
        }
        (orderedViewControllers[currentIndex!] as! BaseViewController).background.backgroundColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: CGFloat(sidePagesAlpha))
        if nextIndex > 0 && nextIndex < 6{
            (orderedViewControllers[nextIndex] as! BaseViewController).background.backgroundColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: CGFloat(currentPageAlpha))
        }
        
       
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        pageControl.currentPage = nextIndex
    }
}

extension TutorialViewController: BaseViewControllerDelegate {
    func hiddenPageController() {
        self.pageControl.hidden = true
    }
}
