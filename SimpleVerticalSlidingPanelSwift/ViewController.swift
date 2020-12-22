//
//  ViewController.swift
//  SimpleVerticalSlidingPanelSwift
//
//  Created by Glenn Posadas on 12/21/20.
//

import UIKit

let topPanelContainerHeight: CGFloat = DeviceUtility.isIphoneXType ? -270.0 : -259.0

class ViewController: UIViewController {

    var constraint_PanelViewTop: NSLayoutConstraint?
    var constraint_SlidingPanelHeight: NSLayoutConstraint?
    
    // MARK: Sliding Filter/Panel Properties
    
    var slidingFilter: SlidingFilterViewController?
    var originalPanelPosition: CGFloat = 0
    var lastPoint: CGPoint = .zero
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        return panGestureRecognizer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupSlidingPanel()
    }
    
    @IBAction func presentSlidingFilter(_ sender: Any) {
        // The most appropriate value for maximize. Don't change this.
        let originalPanelHeight: CGFloat = DeviceUtility.isIphoneXType ? -170.0 : -159.0
        let offset = -(abs(originalPanelHeight) + view.frame.height)
        
        print("\(self) ➤ MaximizeSlidingPanel ---- Offset: \(offset)")
        
        constraint_PanelViewTop?.constant = offset
        bounceAnimate()
    }
    
    @IBAction func minimizeOrDismiss(_ sender: Any) {
        if slidingFilter != nil {
            constraint_PanelViewTop?.constant = topPanelContainerHeight
            bounceAnimate()
        }
    }
    
    private func bounceAnimate() {
        UIView.animate(withDuration: 0.7, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [.curveEaseIn], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func setupSlidingPanel() {
        let mainSB = UIStoryboard(name: "Main", bundle: nil)
        slidingFilter = mainSB.instantiateViewController(identifier: "SlidingFilterViewController")
        slidingFilter!.view.addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.isEnabled = true
        
        guard let slidingFilter = self.slidingFilter else { return }
        
        // Add the panel as child controller
        slidingFilter.rootContainerReference = self
        
        addChild(slidingFilter)
        view.addSubview(slidingFilter.view)
        
        let topOffset: CGFloat = topPanelContainerHeight
        
        // Uncomment to hide panel
        // topOffset = (self.view.frame.height - topPanelContainerHeight) * -1
        
        slidingFilter.view.translatesAutoresizingMaskIntoConstraints = false
        
        constraint_PanelViewTop = slidingFilter.view.topAnchor.constraint(equalTo: view.bottomAnchor)
        constraint_PanelViewTop?.constant = topOffset
        
        let totalHeight: CGFloat = view.frame.height + abs(topPanelContainerHeight)
        constraint_SlidingPanelHeight = slidingFilter.view.heightAnchor.constraint(equalToConstant: totalHeight)
        
        
        NSLayoutConstraint.activate([
            constraint_PanelViewTop!,
            constraint_SlidingPanelHeight!,
            slidingFilter.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            slidingFilter.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        _ = panGestureRecognizer // lazily init.
        originalPanelPosition = constraint_PanelViewTop?.constant ?? 0
    }
}

// MARK: - Gesture Selector

extension ViewController {
    @objc func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let topConstraintConstant = constraint_PanelViewTop?.constant else { return }

        let point = gestureRecognizer.location(in: view)
        let screenHeight = view.bounds.height
        let centerRatio = (-topConstraintConstant + originalPanelPosition) / (screenHeight + originalPanelPosition)

        print("\(self) ➤ panGesture ➤ DIRECTION: \(gestureRecognizer.direction) 📙📙📙")

        let isMaximized = (view.frame.height + abs(topPanelContainerHeight)) == abs(topConstraintConstant)

        if gestureRecognizer.direction.isHorizontal, isMaximized { return }
        if gestureRecognizer.direction == .bottomToTop, isMaximized { return }

        switch gestureRecognizer.state {
        case .changed:
            let yDelta = point.y - lastPoint.y
            var newOffset = topConstraintConstant + yDelta
            newOffset = newOffset > originalPanelPosition ? originalPanelPosition : newOffset
            newOffset = newOffset < -screenHeight ? -screenHeight : newOffset

            print("\(self) ➤ panGesture ➤ STATE: CHANGED ❇️ ➤ yDelta: \(point.y - lastPoint.y) | lastPointY: \(lastPoint.y) | newOffset: \(newOffset)")

            constraint_PanelViewTop?.constant = newOffset

        case .ended:
            let newPanelTopConstraint = (centerRatio < 0.5 ? originalPanelPosition : -screenHeight)
            print("\(self) ➤ panGesture ➤ STATE: ENDED ✅ ➤ (SELF.VIEW HEIGHT: \(view.frame.height) | NewPanelTopCosntraint: \(newPanelTopConstraint) | Constraint constant: \(newPanelTopConstraint == 0 ? topPanelContainerHeight : (newPanelTopConstraint + topPanelContainerHeight))")

            var newOffset: CGFloat = topPanelContainerHeight

            // If the newPanelTopConstraint is doubled (Due to the adding of -topPanelContainerHeight), then reset it to -topPanelContainerHeight.
            if newPanelTopConstraint == 0 || newPanelTopConstraint == (topPanelContainerHeight * 2.0) {
                newOffset = topPanelContainerHeight
            } else if newPanelTopConstraint != topPanelContainerHeight {
                // We're adding -topPanelContainerHeight to move the panel to the top to hide the topContainer of the panel
                newOffset = newPanelTopConstraint + topPanelContainerHeight
            }

            print("\(self) ➤ panGesture ➤ STATE: ENDED ✅ ➤ NEW OFFSET: --->\(newOffset)")

            constraint_PanelViewTop?.constant = newOffset
            bounceAnimate()

        default:
            break
        }

        lastPoint = point
    }
}
