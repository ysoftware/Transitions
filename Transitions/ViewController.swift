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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animator.scaleView = 1
        
        stackView.arrangedSubviews.forEach { view in
            view.layer.cornerRadius = 10
        }
    }
    
    @IBAction func didTap(_ sender: UIButton) {
        if cardView.isHidden {
            sender.setTitle("Prepare", for: .normal)
            
            // prepare view for snapshotting
            stackView.removeArrangedSubview(cardView)
            cardView.removeFromSuperview()
            cardView.isHidden = false
            
            // add view to hierarchy but off screen
            view.addSubview(cardView)
            cardView.trailingAnchor.constraint(
                equalTo: view.leadingAnchor).isActive = true
            cardView.topAnchor.constraint(
                equalTo: view.topAnchor).isActive = true
            
            performSegue(withIdentifier: "Present", sender: self)
        }
        else {
            sender.setTitle("Present", for: .normal)
            cardView.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? ViewController2 else { return }
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .fullScreen
        
        // create and setup snapshot
        let snapshot = cardView.snapshotView()!
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        snapshot.widthAnchor.constraint(
            equalToConstant: cardView.frame.width).isActive = true
        snapshot.heightAnchor.constraint(
            equalToConstant: cardView.frame.height).isActive = true
        vc.cardView = snapshot
        vc.cardView.layer.cornerRadius = 10
        vc.cardView.clipsToBounds = true

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
        cardView.topAnchor.constraint(
            equalTo: view.topAnchor, constant: 100).isActive = true
    }
    
    @IBAction func didTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Animator

class DigitalCardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var isPresenting: Bool = true
    public var scaleView: CGFloat = 1
    
    private let fadeDuration: TimeInterval = 0.5
    private let scaleDuration: TimeInterval = 0.8
    private let scaleDelay: TimeInterval = 0.3
    private let translateDuration: TimeInterval = 0.5
    
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        
        if isPresenting {
            return translateDuration
        }
        else {
            return fadeDuration - scaleDelay + scaleDuration
        }
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
        
        UIView.animate(withDuration: fadeDuration) {
            to.backgroundView.alpha = 1
        }
        
        UIView.animate(withDuration: scaleDuration,
                       delay: scaleDelay,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        
                        to.cardView.transform = CGAffineTransform(scaleX: self.scaleView,
                                                                  y: self.scaleView)
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
        
        // prepare views
        containerView.addSubview(toView)
        containerView.addSubview(fromView)
        
        // get frames
        let oldFrame = from.cardView.frame
        let newFrame = CGRect(origin: to.stackView.frame.origin,
                              size: to.cardView.frame.size)
        
        // create path
        let path = UIBezierPath()
        path.move(to: CGPoint(x: oldFrame.midX, y: oldFrame.midY))
        path.addQuadCurve(to: CGPoint(x: newFrame.midX, y: newFrame.midY),
                          controlPoint: CGPoint(x: newFrame.midX, y: oldFrame.midY))
        
        // setup animations
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [scaleView, 1]
        scale.duration = translateDuration
        
        let translate = CAKeyframeAnimation(keyPath: "position")
        translate.path = path.cgPath
        translate.duration = translateDuration
        
        let animations = CAAnimationGroup()
        animations.animations = [scale, translate]
        animations.duration = translateDuration
        
        // remove after animation finishes
        from.cardView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        // add animations
        from.cardView.layer.add(animations, forKey: "")
        
        // complete transition a couple of frames before screen2 goes blank
        let duration = translateDuration - 0.05
        
        // add uiview animations
        UIView.animate(withDuration: duration, animations: {
            to.cardView.isHidden = false
            from.backgroundView.alpha = 0
        }, completion: { _ in
            from.cardView.removeFromSuperview()
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
