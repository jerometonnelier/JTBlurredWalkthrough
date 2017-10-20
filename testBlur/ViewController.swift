//
//  ViewController.swift
//  testBlur
//
//  Created by jerome on 20/09/2017.
//  Copyright © 2017 jerome. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var items: [UIView]!
    @IBOutlet weak var imageView: UIImageView!
    lazy var visualEffectView: UIVisualEffectView = UIVisualEffectView(frame: self.view.bounds)
    var walkthrough: WalkthroughController? = nil
    var showStatusBar: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        createOverlay(at: view.center)
//        test()
        walk()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        get {
            return false//walkthrough != nil
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        get {
            return .fade
        }
    }
    
    func walk() {
        let config = WalkthroughConfigurationItem(effect: .blurred(force: .dark), strokeColor:.blue, strokeMask: true)
        walkthrough = WalkthroughController(configurationItem: config)
        // use this to animate status bar hide and present the controller
        // otherwise the first object's frame is wrong
//        UIView.animate(withDuration: 0.35, animations: {
//            self.setNeedsStatusBarAppearanceUpdate()
//        }) { (_) in
//            self.startWalkThrough()
//        }
        self.startWalkThrough()
    }
    
    func startWalkThrough() {
        
//        self.walkthrough?.blurEffect = .dark
        var items: [WalkthroughItem] = []
        let text = "Duis mollis, est non commodo luctus\nnisi erat porttitor ligula, eget lacinia odio sem nec elit."
        let attr = NSMutableAttributedString(string: text)
        let para = NSMutableParagraphStyle()
        para.alignment = .left
        attr.setAttributes([NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : UIFont.systemFont(ofSize: 19), NSParagraphStyleAttributeName : para], range: NSRange(location: 0, length: text.characters.count))
        attr.setAttributes([NSForegroundColorAttributeName : UIColor.orange, NSFontAttributeName : UIFont.boldSystemFont(ofSize: 20), NSParagraphStyleAttributeName : para], range: NSRange(location: 0, length: 35))
        
        items.append(WalkthroughItem(with: .rect, views: [self.items[0], self.items[5], self.items[6]], attributedText: attr))
        items.append(WalkthroughItem(with: .roundRect, view: self.items[1], text: "Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec id elit non mi porta gravida at eget metus."))
        items.append(WalkthroughItem(with: .roundRect, view: self.items[2], text: "Aenean eu leo quam. Pellentesque ornare sem lacinia quam venenatis vestibulum. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus."))
        items.append(WalkthroughItem(with: .circle, view: self.items[3], text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras mattis consectetur purus sit amet fermentum. Maecenas faucibus mollis interdum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.", topInsets: 20, defaultCornerRadius: 20))
        items.append(WalkthroughItem(with: .circle, view: self.items[4], text: "Hop"))
        self.walkthrough?.delegate = self
        self.walkthrough?.start(on: self, with: items)
    }
    
    func blurTest() {
        
        let visualEffectView: UIVisualEffectView = UIVisualEffectView(frame: view.bounds)
        visualEffectView.effect = UIBlurEffect(style: .dark)
        view.addSubview(visualEffectView)
        
        let path = UIBezierPath (
            roundedRect: view.frame,
            cornerRadius: 0)
        path.usesEvenOddFillRule = true
        
        let rectPath = UIBezierPath(roundedRect: CGRect(x: view.center.x - 100, y: view.center.y - 100, width: 200, height: 200), cornerRadius: 10)
        path.usesEvenOddFillRule = true
        path.append(rectPath)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = rectPath.cgPath
        maskLayer.fillRule = kCAFillRuleNonZero
        maskLayer.fillColor = UIColor.clear.cgColor
        
        let maskView = UIView(frame: view.bounds)
        maskView.layer.addSublayer(maskLayer)
        maskView.backgroundColor = .black
        maskView.layer.mask = maskLayer
        visualEffectView.layer.addSublayer(maskLayer)
//        visualEffectView.mask = maskView
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let rectPath = UIBezierPath(roundedRect: CGRect(x: 20, y: 20, width: 50, height: 50), cornerRadius: 10)
            let animation = CASpringAnimation(keyPath: "path")
            animation.fromValue = maskLayer.path
            animation.toValue = rectPath.cgPath
            animation.duration = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeBoth
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            maskLayer.path = rectPath.cgPath
            maskLayer.add(animation, forKey: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            let rectPath = UIBezierPath(ovalIn: CGRect(x: 50, y: 200, width: 120, height: 120))
            let animation = CASpringAnimation(keyPath: "path")
            animation.fromValue = maskLayer.path
            animation.toValue = rectPath.cgPath
            animation.duration = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeBoth
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            maskLayer.path = rectPath.cgPath
            maskLayer.add(animation, forKey: nil)
        }
    }

    func test() {
        
        let path = UIBezierPath (
            roundedRect: view.frame,
            cornerRadius: 0)
        path.usesEvenOddFillRule = true
        
        let rectPath = UIBezierPath(roundedRect: CGRect(x: view.center.x - 100, y: view.center.y - 100, width: 200, height: 200), cornerRadius: 10)
        rectPath.usesEvenOddFillRule = false
        path.append(rectPath)
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = rectPath.cgPath
//        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.fillColor = UIColor.white.cgColor
        
        let maskView = UIView(frame: view.bounds)
        maskView.layer.addSublayer(maskLayer)
        maskView.backgroundColor = .clear
        imageView.mask = maskView
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let rectPath = UIBezierPath(roundedRect: CGRect(x: 20, y: 20, width: 50, height: 50), cornerRadius: 10)
            let animation = CASpringAnimation(keyPath: "path")
            animation.fromValue = maskLayer.path
            animation.toValue = rectPath.cgPath
            animation.duration = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeBoth
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            maskLayer.path = rectPath.cgPath
            maskLayer.add(animation, forKey: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            let rectPath = UIBezierPath(ovalIn: CGRect(x: 50, y: 200, width: 120, height: 120))
            let animation = CASpringAnimation(keyPath: "path")
            animation.fromValue = maskLayer.path
            animation.toValue = rectPath.cgPath
            animation.duration = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = kCAFillModeBoth
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            maskLayer.path = rectPath.cgPath
            maskLayer.add(animation, forKey: nil)
        }
    }
    
    func changePath() {
        let path2 = UIBezierPath (
            roundedRect: self.view.frame,
            cornerRadius: 0)
        let rectPath = UIBezierPath(ovalIn: CGRect(x: 50, y: 200, width: 120, height: 120))
        path2.usesEvenOddFillRule = true
        path2.append(rectPath)
        let maskLayer2 = CAShapeLayer()
        maskLayer2.path = path2.cgPath
        maskLayer2.fillRule = kCAFillRuleEvenOdd
        
        let maskView2 = UIView(frame: self.view.frame)
        maskView2.backgroundColor = UIColor.black
        maskView2.layer.mask = maskLayer2
        
        visualEffectView.mask = maskView2
    }

    func createOverlay(at: CGPoint) {
//        let visualEffectView: UIVisualEffectView = UIVisualEffectView(frame: view.bounds)
        visualEffectView.effect = UIBlurEffect(style: .light)
        view.addSubview(visualEffectView)
        
        let circleSize: CGFloat = 200
//        
        let path = UIBezierPath (
            roundedRect: view.frame,
            cornerRadius: 0)

//        path.usesEvenOddFillRule = true
        
        let rectPath = UIBezierPath(roundedRect: CGRect(x: at.x - 100, y: at.y - 100, width: 200, height: 200), cornerRadius: 10)
        path.usesEvenOddFillRule = true
        path.append(rectPath)
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        let maskView = UIView(frame: self.view.frame)
        maskView.backgroundColor = UIColor.black
        maskView.layer.mask = maskLayer
        visualEffectView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changePath)))
        
//        visualEffectView.layer.addSublayer(borderLayer)
        visualEffectView.mask = maskView
        
    }
}

extension ViewController: WalkthroughDelegate {
    func didStop() {
        walkthrough = nil
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func nextStepSelected() {
        
    }
}
