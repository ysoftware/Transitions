//
//  ViewController.swift
//  Transitions
//
//  Created by Ерохин Ярослав Игоревич on 27/09/2019.
//  Copyright © 2019 HCFB. All rights reserved.
//

import UIKit

// MARK: - First View Controller

class ViewController: UIViewController, DigitalCardAnimatorScreen1 {
    
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
        let snapshot = cardView.snapshotView(afterScreenUpdates: true)!
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
    
    func animateIn(duration: TimeInterval) -> CGRect {
        
        // complete transition a couple of frames before screen2 goes blank
        let duration = duration - 0.05
        
        UIView.animate(
            withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
                self.cardView.isHidden = false
        }) { _ in
            self.cardView.alpha = 1
        }
        return CGRect(origin: stackView.frame.origin, size: cardView.frame.size)
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

class ViewController2: UIViewController, DigitalCardAnimatorScreen2 {
    
    private let fadeDuration: TimeInterval = 0.5
    private let scaleDuration: TimeInterval = 0.8
    private let scaleDelay: TimeInterval = 0.2
    private let translateDuration: TimeInterval = 0.7
    
    @IBOutlet weak var backgroundView: UIView!
    var cardView: UIView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addCardView()
    }
    
    func addCardView() {
        guard cardView.superview == nil else { return }
        
        view.addSubview(cardView)
        cardView.centerXAnchor.constraint(
            equalTo: view.centerXAnchor).isActive = true
        cardView.topAnchor.constraint(
            equalTo: view.topAnchor, constant: 100).isActive = true
    }
    
    @IBAction func didTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func animateInDuration() -> TimeInterval {
        return fadeDuration - scaleDelay + scaleDuration
    }
    
    func animateOutDuration() -> TimeInterval {
        return translateDuration
    }
    
    func animateIn(scale: CGFloat, completion: @escaping ()->Void) {
        
        backgroundView.alpha = 0
        cardView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        UIView.animate(withDuration: fadeDuration) {
            self.backgroundView.alpha = 1
        }
        
        UIView.animate(withDuration: scaleDuration,
                       delay: scaleDelay,
                       usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut,
                       animations: {
                        
                        let transform = CGAffineTransform(scaleX: scale, y: scale)
                        self.cardView.transform = transform
        }) { _ in
            completion()
        }
    }
    
    func animateOut(newFrame: CGRect, fromScale: CGFloat, completion: @escaping ()->Void) {
        
        // get frames
        let oldFrame = cardView.frame
        
        // create path
        let path = UIBezierPath()
        path.move(to: CGPoint(x: oldFrame.midX, y: oldFrame.midY))
        path.addQuadCurve(to: CGPoint(x: newFrame.midX, y: newFrame.midY),
                          controlPoint: CGPoint(x: newFrame.midX, y: oldFrame.midY))
        
        // setup animations
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [fromScale, 1]
        scale.duration = translateDuration
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let translate = CAKeyframeAnimation(keyPath: "position")
        translate.path = path.cgPath
        translate.duration = translateDuration
        translate.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let animations = CAAnimationGroup()
        animations.animations = [scale, translate]
        animations.duration = translateDuration
        
        // remove after animation finishes
        cardView.transform = CGAffineTransform(scaleX: 0, y: 0)
        
        // add animations
        cardView.layer.add(animations, forKey: "")
        
        // add uiview animations
        UIView.animate(
            withDuration: translateDuration, delay: 0, options: .curveEaseInOut, animations: {
                self.backgroundView.alpha = 0
        }) { _ in
            self.cardView.removeFromSuperview()
            completion()
        }
    }
}

// MARK: - Animator

protocol DigitalCardAnimatorScreen1 {
    
    func animateIn(duration: TimeInterval) -> CGRect
}

protocol DigitalCardAnimatorScreen2 {
    
    func animateInDuration() -> TimeInterval
    func animateOutDuration() -> TimeInterval
    func animateIn(scale: CGFloat, completion: @escaping ()->Void)
    func animateOut(newFrame: CGRect, fromScale: CGFloat, completion: @escaping ()->Void)
}

public class DigitalCardAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var isPresenting: Bool = true
    public var scaleView: CGFloat = 1
    
    public func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {

        if isPresenting, let screen = transitionContext?.viewController(forKey: .to)
            as? DigitalCardAnimatorScreen2 {
            return screen.animateInDuration()
        }
        else if let screen = transitionContext?.viewController(forKey: .from)
            as? DigitalCardAnimatorScreen2{
            return screen.animateOutDuration()
        }
        return 0
    }
    
    public func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning) {
        
        if isPresenting {
            animateIn(transitionContext)
        }
        else {
            animateOut(transitionContext)
        }
    }
    
    private func animateIn(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to)
            as? DigitalCardAnimatorScreen2 else { return }
        
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        
        containerView.addSubview(toView)
        
        to.animateIn(scale: scaleView) {
            transitionContext.completeTransition(true)
        }
    }
    
    private func animateOut(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let to = transitionContext.viewController(forKey: .to)
                as? DigitalCardAnimatorScreen1,
            let from = transitionContext.viewController(forKey: .from)
                as? DigitalCardAnimatorScreen2 else { return }
        
        let containerView = transitionContext.containerView
        let toView = transitionContext.view(forKey: .to)!
        let fromView = transitionContext.view(forKey: .from)!
        
        // prepare views
        containerView.addSubview(toView)
        containerView.addSubview(fromView)
        
        let duration = from.animateOutDuration()
        let newFrame = to.animateIn(duration: duration)
        
        from.animateOut(newFrame: newFrame, fromScale: scaleView) {
            transitionContext.completeTransition(true)
        }
    }
}
