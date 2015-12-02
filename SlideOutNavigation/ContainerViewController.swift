//
//  ContainerViewController.swift
//  SlideOutNavigation
//
//  Created by James Frost on 03/08/2014.
//  Copyright (c) 2014 James Frost. All rights reserved.
//

import UIKit
import QuartzCore

enum SlideOutState {
    case BothCollapsed
    case LeftPanelExpanded
    case RightPanelExpanded
}

class ContainerViewController: UIViewController {
  
    var centerNavigationController: UINavigationController!
    var centerViewController: CenterViewController!
    var currentState: SlideOutState = .BothCollapsed {
        didSet {
            let shouldShowShadow = currentState != .BothCollapsed
            showShadowForCenterViewController(shouldShowShadow)
        }
    }
    var leftViewController: SidePanelViewController?
    let centerPanelExpandedOffset: CGFloat = 160
    var rightViewController: SidePanelViewController?
    
  override func viewDidLoad() {
    super.viewDidLoad()
    
    centerViewController = UIStoryboard.centerViewController()
    centerViewController.delegate = self
    
    //wrap the centerVC in a nav controller so we can push views to it and display bar button items in the nav bar
    self.centerNavigationController = UINavigationController(rootViewController: centerViewController)
    view.addSubview(centerNavigationController.view)
    addChildViewController(centerNavigationController)
    
    centerNavigationController.didMoveToParentViewController(self)
    
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
    centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    
  }
  
}

extension ContainerViewController: UIGestureRecognizerDelegate {
    func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let gestureLeftToRight = (recognizer.velocityInView(view).x > 0)
        
        switch recognizer.state {
        case .Began:
            if gestureLeftToRight {
                addLeftPanelViewController()
            } else {
                addRightPanelViewController()
            }
            
            showShadowForCenterViewController(true)
        case .Changed:
            recognizer.view!.center.x += recognizer.translationInView(view).x
        case .Ended:
            if (leftViewController != nil) {
                // animate the side panel open or closed based on whether the view has moved more or less than halfway
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x > view.bounds.size.width
                animateLeftPanel(shouldExpand: hasMovedGreaterThanHalfway)
            } else if (rightViewController != nil) {
                let hasMovedGreaterThanHalfway = recognizer.view!.center.x < 0
                animateRightPanel(shouldExpand: hasMovedGreaterThanHalfway)
            }
        default:
            break
        }
    }
}

private extension UIStoryboard {
  class func mainStoryboard() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()) }
  
  class func leftViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewControllerWithIdentifier("LeftViewController") as? SidePanelViewController
  }
  
  class func rightViewController() -> SidePanelViewController? {
    return mainStoryboard().instantiateViewControllerWithIdentifier("RightViewController") as? SidePanelViewController
  }
  
  class func centerViewController() -> CenterViewController? {
    return mainStoryboard().instantiateViewControllerWithIdentifier("CenterViewController") as? CenterViewController
  }
  
}

extension ContainerViewController: CenterViewControllerDelegate {
    func toggleLeftPanel() {
        let notExpanded = (currentState != .LeftPanelExpanded)
        
        if notExpanded {
            addLeftPanelViewController()
        }
        
        animateLeftPanel(shouldExpand: notExpanded)
    }
    
    func toggleRightPanel() {
        let notExpanded = (currentState != .RightPanelExpanded)
        
        if notExpanded {
            addRightPanelViewController()
        }
        
        animateRightPanel(shouldExpand: notExpanded)
    }
    
    func addLeftPanelViewController() {
        if leftViewController == nil {
            leftViewController = UIStoryboard.leftViewController()
            leftViewController!.animals = Animal.allCats()
            
            addChildSidePanelController(leftViewController!)
        }
    }
    
    func addChildSidePanelController(sidePanelController: SidePanelViewController) {
        view.insertSubview(sidePanelController.view, atIndex: 0)
        
        addChildViewController(sidePanelController)
        sidePanelController.didMoveToParentViewController(self)
    }
    
    func addRightPanelViewController() {
        if rightViewController == nil {
            rightViewController = UIStoryboard.rightViewController()
            rightViewController!.animals = Animal.allDogs()
            
            addChildSidePanelController(rightViewController!)
        }
    }
    
    override func addChildViewController(childController: UIViewController) {

    }
    
    func animateLeftPanel(shouldExpand shouldExpand: Bool) {
        if(shouldExpand) {
            currentState = .LeftPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: CGRectGetWidth(centerNavigationController.view.frame) - centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.currentState = .BothCollapsed
                
                self.leftViewController!.view.removeFromSuperview()
                self.leftViewController = nil
            }
        }
    }
    
    func animateCenterPanelXPosition(targetPosition targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil) {
        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            self.centerNavigationController.view.frame.origin.x = targetPosition
            }, completion: completion)
    }
    
    func animateRightPanel(shouldExpand shouldExpand: Bool) {
        if (shouldExpand) {
            currentState = .RightPanelExpanded
            
            animateCenterPanelXPosition(targetPosition: -CGRectGetWidth(centerNavigationController.view.frame) + centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { _ in
                self.currentState = .BothCollapsed
                
                self.rightViewController!.view.removeFromSuperview()
                self.rightViewController = nil;
            }
        }
    }
    
    func showShadowForCenterViewController(shouldShowShadow: Bool) {
        if(shouldShowShadow) {
            centerNavigationController.view.layer.shadowOpacity = 0.8
            
        } else {
            centerNavigationController.view.layer.shadowOpacity = 0.0
        }
    }
    
}