//
//  ModelController.swift
//  paged app
//
//  Created by Matthew J Vandergrift on 7/18/19.
//  Copyright © 2019 Matthew J Vandergrift. All rights reserved.
//

import UIKit

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 */


class ModelController: NSObject, UIPageViewControllerDataSource {

    var pageData: [String] = []


    override init() {
        super.init()
        // Create the data model.
        pageData = [SessionPages.Welcome.rawValue,
            SessionPages.Settings.rawValue,
            SessionPages.LogView.rawValue,
            SessionPages.Feedback.rawValue]
    }

    func mainViewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> MainViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }

        // Create a new view controller and pass suitable data.
        let MainViewController = storyboard.instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        MainViewController.dataObject = self.pageData[index]
        return MainViewController
    }
    
    func feedbackViewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> FeedbackViewController? {
        // Return the data view controller for the given index.
        if (self.pageData.count == 0) || (index >= self.pageData.count) {
            return nil
        }
        
        // If its a main view controller thing return nil
        if (index < 3) {
            return nil
        }
        
        // Create a new view controller and pass suitable data.
        let FeedbackViewController = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
        FeedbackViewController.dataObject = self.pageData[index]
        return FeedbackViewController
    }

    func indexOfMainViewController(_ viewController: MainViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return pageData.firstIndex(of: viewController.dataObject) ?? NSNotFound
    }
    
    func indexOfFeedbackViewController(_ viewController: FeedbackViewController) -> Int {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return pageData.firstIndex(of: viewController.dataObject) ?? NSNotFound
    }

    // MARK: - Page View Controller Data Source

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        var index = 0;
        if viewController is FeedbackViewController {
            index = self.indexOfFeedbackViewController(viewController as! FeedbackViewController)
        } else {
            index = self.indexOfMainViewController(viewController as! MainViewController)
        }
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
    
        index -= 1
        
        if (index < 3) {
            return self.mainViewControllerAtIndex(index, storyboard: viewController.storyboard!)
        } else {
            return self.feedbackViewControllerAtIndex(index, storyboard: viewController.storyboard!)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        
        var index = 0;
        if viewController is FeedbackViewController {
            index = self.indexOfFeedbackViewController(viewController as! FeedbackViewController)
        } else {
            index = self.indexOfMainViewController(viewController as! MainViewController)
        }
        
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        if index == self.pageData.count {
            return nil
        }
        
        if (index < 3) {
            return self.mainViewControllerAtIndex(index, storyboard: viewController.storyboard!)
        } else {
            return self.feedbackViewControllerAtIndex(index, storyboard: viewController.storyboard!)
        }
    }
}
