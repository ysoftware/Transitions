//
//  ViewController.swift
//  Transitions
//
//  Created by Ерохин Ярослав Игоревич on 27/09/2019.
//  Copyright © 2019 HCFB. All rights reserved.
//

import UIKit

// MARK: - First View Controller

class ViewController: UIViewController {
    
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet var cardView: UIView!
    let animator = DigitalCardAnimator()
    
    @IBAction func didTap(_ sender: Any) {
        performSegue(withIdentifier: "Present", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ViewController2 else { return }
        vc.transitioningDelegate = self
        
        // prepare view for snapshotting
        stackView.removeArrangedSubview(cardView)
        cardView.removeFromSuperview()
        cardView.isHidden = false
        
        view.addSubview(cardView)
        cardView.trailingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cardView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        let snapshot = cardView.snapshotView()!
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        snapshot.widthAnchor.constraint(equalToConstant: 100)
        snapshot.heightAnchor.constraint(equalToConstant: 150)
        vc.cardView = snapshot

        // prepare view for transitioning
        cardView.isHidden = true
        cardView.alpha = 0
        cardView.removeFromSuperview()
        stackView.insertArrangedSubview(cardView, at: 0)
    }
}

extension ViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        animator.isPresenting = true
        return animator
    }
    
    func animationController(forDismissed
        dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        animator.isPresenting = false
        return animator
    }
}

// MARK: - Second View Controller

class ViewController2: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    var cardView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addCardView()
    }
    
    func addCardView() {
        guard cardView.superview == nil else { return }
        
        view.addSubview(cardView)
        cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        view.layoutIfNeeded()
    }
    
    @IBAction func didTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Animator

class DigitalCardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var isPresenting: Bool = true
    private let duration:TimeInterval = 0.7
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        return 1
    }
    
    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning) {
        
        if isPresenting {
            animateIn(transitionContext)
        }
        else {
            animateOut(transitionContext)
        }
    }
    
    private func animateIn(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let to = transitionContext.viewController(forKey: .to) as! ViewController2
        let toView = transitionContext.view(forKey: .to)!
        
        containerView.addSubview(toView)
        to.backgroundView.alpha = 0
        to.cardView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: duration) {
            to.backgroundView.alpha = 1
        }
        
        UIView.animate(withDuration: duration,
                       delay: duration,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        
                        to.cardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            transitionContext.completeTransition(true)
        }
    }
    
    private func animateOut(_ transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let to = transitionContext.viewController(forKey: .to) as! ViewController
        let toView = transitionContext.view(forKey: .to)!
        let from = transitionContext.viewController(forKey: .from) as! ViewController2
        let fromView = transitionContext.view(forKey: .from)!
        
        containerView.addSubview(toView)
        containerView.addSubview(fromView)
        
        let cardViewOrigin = to.stackView.frame.origin
        let cardViewFrame = CGRect(origin: cardViewOrigin, size: to.cardView.frame.size)
        
        UIView.animate(withDuration: duration, animations: {
            to.cardView.isHidden = false
            from.backgroundView.alpha = 0
            from.cardView.frame = cardViewFrame
        }, completion: { _ in
            to.cardView.alpha = 1
            transitionContext.completeTransition(true)
        })
    }
}

public extension UIView {
    
    func snapshotImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let snapshotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImage
    }
    
    func snapshotView() -> UIView? {
        if let snapshotImage = snapshotImage() {
            return UIImageView(image: snapshotImage)
        } else {
            return nil
        }
    }
}
