//
//  WalkthroughController.swift
//  testBlur
//
//  Created by jerome on 21/09/2017.
//  Copyright © 2017 jerome. All rights reserved.
//

import UIKit

/// the mask shape to draw around the element to highlight
enum WalkthroughShape {
    case rect
    case roundRect
    case circle
}

protocol WalkthroughDelegate {
    func nextStepSelected()
    func didStop()
}

struct WalkthroughItem {
    /// the shape of the masked view
    var shape: WalkthroughShape
    /// the views to highligh through a mask
    var maskedViews: [UIView]
    /// the message to show. You must provide either a text or an attributedText
    var text: String?
    /// the message to show. You must provide either a text or an attributedText
    /// Be sure to set atrtibuted on the whole string
    var attributedText: NSAttributedString?
    //TODO: handle an image...
    var image: UIImage?
    
    /// the insets around the mask shapes
    var sideInsets: CGFloat = 5
    var topInsets: CGFloat = 5
    /// the cornerRadius used on roundRect mask shapes
    var cornerRadius: CGFloat = 5
    /// the text to read using accessibilty
    var accessibilityText: String?
    
    init(with shape: WalkthroughShape, views: [UIView], text: String? = nil, attributedText: NSAttributedString? = nil, accessibilityText: String? = nil, topInsets: CGFloat? = nil, sideInsets: CGFloat? = nil, defaultCornerRadius: CGFloat? = nil) {
        guard text != nil || attributedText != nil else {
            fatalError("you must provide either a text or an attributed string")
        }
        self.shape = shape
        self.maskedViews = views
        self.text = text
        self.attributedText = attributedText
        self.accessibilityText = accessibilityText
        if let insets = sideInsets {
            self.sideInsets = insets
        }
        if let insets = topInsets {
            self.topInsets = insets
        }
        if let radius = defaultCornerRadius {
            cornerRadius = radius
        }
    }
    
    init(with shape: WalkthroughShape, view: UIView, text: String? = nil, attributedText: NSAttributedString? = nil, accessibilityText: String? = nil, topInsets: CGFloat? = nil, sideInsets: CGFloat? = nil, defaultCornerRadius: CGFloat? = nil) {
        self.init(with: shape, views: [view], text: text, attributedText: attributedText, accessibilityText: accessibilityText, topInsets: topInsets, sideInsets: sideInsets, defaultCornerRadius: defaultCornerRadius)
    }
}

struct WalkthroughConfigurationItem {
    enum BackgroundEffect {
        case blurred(force: Force)
        case transparent(force: Force)
        
        enum Force {
            case dark, light, extraLight
        }
        
        fileprivate var backgroundColor: UIColor? {
            switch self {
            case .blurred:
                return nil
            case .transparent(let force):
                switch force {
                case .dark: return UIColor.black.withAlphaComponent(0.85)
                case .light: return UIColor.white.withAlphaComponent(0.5)
                case .extraLight: return UIColor.white.withAlphaComponent(0.75)
                }
            }
        }
        
        fileprivate var blurEffect: UIBlurEffectStyle? {
            switch self {
            case .blurred(let force):
                switch force {
                case .dark: return .dark
                case .light: return .light
                case .extraLight: return .extraLight
                }
            case .transparent:
                return nil
            }
        }
        
        fileprivate var defaultStrokeColor: UIColor {
            switch self {
            case .blurred(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            case .transparent(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            }
        }
        
        fileprivate var defaultTextColor: UIColor {
            switch self {
            case .blurred(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            case .transparent(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            }
        }
        
        fileprivate var defaultDotColor: UIColor {
            switch self {
            case .blurred(let force):
                switch force {
                case .dark: return UIColor.white.withAlphaComponent(0.3)
                default: return UIColor.black.withAlphaComponent(0.3)
                }
            case .transparent(let force):
                switch force {
                case .dark: return UIColor.white.withAlphaComponent(0.3)
                default: return UIColor.black.withAlphaComponent(0.3)
                }
            }
        }
        
        fileprivate var defaultCurrentDotColor: UIColor {
            switch self {
            case .blurred(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            case .transparent(let force):
                switch force {
                case .dark: return .white
                default: return .black
                }
            }
        }
    }
    
    let effect: BackgroundEffect
    let backgroundColor: UIColor?
    let textColor: UIColor
    let strokeColor: UIColor
    let dotColor: UIColor
    let currentDotColor: UIColor
    let strokeWidth: CGFloat
    let strokeMask: Bool
    
    init(effect: BackgroundEffect = .blurred(force: .dark),
         backgroundColor: UIColor? = nil,
         textColor: UIColor? = nil,
         strokeColor: UIColor? = nil,
         dotColor: UIColor? = nil,
         currentDotColor: UIColor? = nil,
         strokeWidth: CGFloat = 2,
         strokeMask: Bool = false) {
        self.effect = effect
        self.backgroundColor = backgroundColor ?? effect.backgroundColor
        self.textColor = textColor ?? effect.defaultTextColor
        self.strokeColor = strokeColor ?? effect.defaultStrokeColor
        self.dotColor = dotColor ?? effect.defaultDotColor
        self.currentDotColor = currentDotColor ?? effect.defaultCurrentDotColor
        self.strokeWidth = strokeWidth
        self.strokeMask = strokeMask
    }
}

class WalkthroughController: NSObject {
    /// the blur effect to apply. Setting this will change the text and stroke color
    let configurationItem: WalkthroughConfigurationItem!
    private lazy var visualEffectView: UIView? = {
        switch self.configurationItem.effect {
        case .blurred:
            guard let blurredEffect = self.configurationItem.effect.blurEffect else {
                return nil
            }
            return UIVisualEffectView(effect: UIBlurEffect(style: blurredEffect))
            
        case .transparent:
            guard let backgrounColor = self.configurationItem.effect.backgroundColor else {
                return nil
            }
            let view = UIView()
            view.backgroundColor = backgrounColor
            return view
        }
    }()
    //private lazy var vibrancy: UIVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: self.blurEffect)))
    private lazy var maskView: UIView = UIView()
    private lazy var maskLayer: CAShapeLayer = CAShapeLayer()
    private lazy var strokeLayer = CAShapeLayer()
    
    var tapToContinueText: String = "Tapez pour passer au suivant"
    var fadeDuration: Double = 0.35
    var delegate: WalkthroughDelegate?
    
    let tapLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.backgroundColor = .clear
        return $0
    } (UILabel())
    private var bottomTapLabelConstraint: NSLayoutConstraint!
    private var items: [WalkthroughItem] = []
    // init with -1 to allow a +=1 as soon as we start the loop
    private var currentItemIndex: Int = -1
    
    let closeButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(named:"ic_close"), for: .normal)
        $0.contentMode = .scaleAspectFit
        return $0
    } (UIButton(type: UIButtonType.custom))
    
    private let dots: UIPageControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    } (UIPageControl(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20))))
    private var bottomDotConstraint: NSLayoutConstraint!
    
    private func addToVisualEffectView(_ subView: UIView) {
        switch configurationItem.effect {
        case .blurred:
            guard let view = visualEffectView as? UIVisualEffectView else {
                return
            }
            view.contentView.addSubview(subView)
        case .transparent:
            visualEffectView?.addSubview(subView)
        }
    }
    
    private func effectView() -> UIView? {
        switch configurationItem.effect {
        case .blurred:
            guard let view = visualEffectView as? UIVisualEffectView else {
                return nil
            }
            return view.contentView
        case .transparent:
            return visualEffectView
        }
    }
    
    init(configurationItem: WalkthroughConfigurationItem) {
        self.configurationItem = configurationItem
    }
    
    func start(on controller: UIViewController, with items: [WalkthroughItem]) {
        
        self.items = items
        
        guard let visualView = visualEffectView else {
            return
        }
        
        visualView.frame = controller.view.bounds
        controller.view.addSubview(visualView)
        visualView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            visualView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            visualView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            visualView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
            ])
        
        // add the tap to next item
        let tap = UITapGestureRecognizer(target: self, action: #selector(WalkthroughController.jumpToNextItem))
        visualView.addGestureRecognizer(tap)
        
        maskView.frame = visualView.bounds
        maskView.backgroundColor = UIColor.black
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        // indications
        addToVisualEffectView(tapLabel)
        tapLabel.text = tapToContinueText
        tapLabel.textColor = configurationItem.textColor
        guard let contentView = effectView() else {
            return
        }
        let margins = contentView.layoutMarginsGuide
        
        bottomTapLabelConstraint = tapLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        NSLayoutConstraint.activate([
            tapLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            tapLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            self.bottomTapLabelConstraint,
            tapLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
        // close button
        addToVisualEffectView(closeButton)
        closeButton.tintColor = configurationItem.textColor
        closeButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            closeButton.topAnchor.constraint(equalTo: controller.topLayoutGuide.bottomAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
            ])
        // numberLabel
        if items.count > 0 {
            addToVisualEffectView(dots)
            dots.numberOfPages = items.count
            dots.pageIndicatorTintColor = configurationItem.dotColor
            dots.currentPageIndicatorTintColor = configurationItem.currentDotColor
            bottomDotConstraint = dots.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -tapLabel.frame.height - 20)
            NSLayoutConstraint.activate([
                dots.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                self.bottomDotConstraint
                ])
        }
        
        jumpToNextItem()
    }
    
    @objc private func jumpToNextItem() {
        currentItemIndex += 1
        guard currentItemIndex < items.count else {
            stop()
            return
        }
        
        guard let visualEffectView = visualEffectView, let contentView = effectView() else {
            return
        }
        
        let currentItem: WalkthroughItem = items[currentItemIndex]
        var englobingRect: CGRect = CGRect.null
        currentItem.maskedViews.forEach { (view) in
            let transformedFrame = visualEffectView.convert(view.frame, from: view.superview)
            englobingRect = englobingRect.union(transformedFrame)
        }
        let transformedFrame = englobingRect.insetBy(dx: -currentItem.sideInsets, dy: -currentItem.topInsets)
        // is used to get the frame of the mask shape (which can be really different for a circle shape)
        var targetFrame = transformedFrame
        
        let path = UIBezierPath(roundedRect: visualEffectView.frame, cornerRadius: 0)
        path.usesEvenOddFillRule = true
        
        var itemPath: UIBezierPath = UIBezierPath()
        switch currentItem.shape {
        case .circle:
            let radius: CGFloat = max(transformedFrame.width, transformedFrame.height)
            targetFrame = CGRect(x: min(max(0, transformedFrame.midX - radius / 2.0), visualEffectView.frame.width - radius),
                                 y: min(max(0, transformedFrame.midY - radius / 2.0), visualEffectView.frame.height - radius),
                                 width: radius,
                                 height: radius)
            itemPath = UIBezierPath(ovalIn: targetFrame)
            
        case .rect:
            itemPath = UIBezierPath(rect: transformedFrame)
            
        case .roundRect:
            itemPath = UIBezierPath(roundedRect: transformedFrame, cornerRadius: currentItem.cornerRadius)
        }
        
        itemPath.usesEvenOddFillRule = true
        path.append(itemPath)
        maskLayer.path = path.cgPath
        switch configurationItem.effect {
        case .blurred:
            maskView.layer.mask = maskLayer
            maskLayer.frame = maskView.bounds
            visualEffectView.mask = maskView
        case .transparent:
            visualEffectView.layer.mask = maskLayer
            maskLayer.frame = maskView.bounds
        }
        
        
        closeButton.isHidden = closeButton.frame.intersects(targetFrame)
        dots.isHidden = dots.frame.intersects(targetFrame)
        
        if let text = currentItem.text {
            insertLabel(with: text, accessibilityText:currentItem.accessibilityText,  targetFrame: targetFrame, in: maskView)
        } else if let attr = currentItem.attributedText {
            insertLabel(with: attr, accessibilityText:currentItem.accessibilityText, targetFrame: targetFrame, in: maskView)
        } else {
            return
        }
        
        // first animation to add some fancinesss
        if currentItemIndex == 0 {
            visualEffectView.alpha = 0
            UIView.animate(withDuration: fadeDuration, animations: {
                visualEffectView.alpha = 1
            })
            
            // move the tap label if the first mask intersects with it
            if tapLabel.frame.intersects(targetFrame) {
                bottomTapLabelConstraint.isActive = false
                tapLabel.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor).isActive = true
            }
        }
        
        if items.count > 0 {
            dots.currentPage = currentItemIndex
        }
        
        // hide the text
        if currentItemIndex == 1 {
            contentView.layoutIfNeeded()
            // since the bottomAnchor can change, we reset it here
            tapLabel.isHidden = true
            bottomDotConstraint.isActive = false
            dots.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor).isActive = true
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                self.tapLabel.alpha = 0
                contentView.layoutIfNeeded()
            }, completion: nil)
        }
        
        if configurationItem.strokeMask {
            // add the stroke
            let strokePath = itemPath
            strokePath.usesEvenOddFillRule = true
            strokeLayer.path = strokePath.cgPath
            strokeLayer.strokeColor = configurationItem.strokeColor.cgColor
            strokeLayer.fillColor = UIColor.clear.cgColor
            strokeLayer.lineWidth = configurationItem.strokeWidth
            if strokeLayer.superlayer == nil {
                visualEffectView.layer.addSublayer(strokeLayer)
            }
        }
        
        delegate?.nextStepSelected()
    }
    
    func stop() {
        UIView.animate(withDuration: fadeDuration, animations: {
            self.visualEffectView?.alpha = 0
        }) { _ in
            self.visualEffectView?.removeFromSuperview()
            self.delegate?.didStop()
        }
    }
    
    private func insertLabel(with attributedText: NSAttributedString, accessibilityText: String? = nil, targetFrame: CGRect, in view: UIView) {
        
        guard let visualEffectView = visualEffectView, let contentView = effectView() else {
            return
        }
        
        let label = defaultLabel()
        label.attributedText = attributedText
        label.tag = 666
        let margins = contentView.layoutMargins
        let aboveCenter = targetFrame.origin.y + targetFrame.height / 2.0 >= contentView.center.y
        let height: CGFloat = aboveCenter == true ? targetFrame.minY - (2 * margins.top) : contentView.frame.height - targetFrame.maxY - (2 * margins.bottom)
        let targetSize = CGSize(width: contentView.frame.width - contentView.layoutMargins.left - contentView.layoutMargins.right, height: height)
        var rect = attributedText.boundingRect(with: targetSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
        rect.size.height += 1
        label.frame = CGRect(origin: .zero, size: rect.size)
        if let access = accessibilityText {
            //            label.accessibilityTraits = UIAccessibilityTraitStaticText
            label.accessibilityLabel = access
            label.isAccessibilityElement = true
        }
        
        // remove the previous label
        visualEffectView.subviews.filter({$0.tag == 666}).forEach { (lbl) in
            lbl.removeFromSuperview()
        }
        visualEffectView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: rect.size.height),
            label.widthAnchor.constraint(equalToConstant: rect.size.width),
            label.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: aboveCenter == true ? targetFrame.minY - rect.size.height - margins.top : targetFrame.maxY + margins.top)
            ])
    }
    
    private func insertLabel(with text: String, accessibilityText: String? = nil, targetFrame: CGRect, in view: UIView) {
        let label = defaultLabel()
        label.text = text
        insert(label: label, accessibilityText: accessibilityText, targetFrame: targetFrame, in: view)
    }
    
    private func insert(label: UILabel, accessibilityText: String? = nil, targetFrame: CGRect, in view: UIView) {
        guard let visualEffectView = visualEffectView, let contentView = effectView() else {
            return
        }
        
        label.tag = 666
        
        let margins = contentView.layoutMargins
        let aboveCenter = targetFrame.origin.y + targetFrame.height / 2.0 >= contentView.center.y
        let height: CGFloat = aboveCenter == true ? targetFrame.minY - (2 * margins.top) : contentView.frame.height - targetFrame.maxY - (2 * margins.bottom)
        let size = label.systemLayoutSizeFitting(CGSize(width: contentView.frame.width - contentView.layoutMargins.left - contentView.layoutMargins.right, height: height),
                                                 withHorizontalFittingPriority: UILayoutPriorityDefaultHigh,
                                                 verticalFittingPriority: UILayoutPriorityDefaultLow)
        label.frame = CGRect(origin: .zero, size: size)
        if let access = accessibilityText {
            //            label.accessibilityTraits = UIAccessibilityTraitStaticText
            label.accessibilityLabel = access
            label.isAccessibilityElement = true
        }
        
        // remove the previous label
        visualEffectView.subviews.filter({$0.tag == 666}).forEach { (lbl) in
            lbl.removeFromSuperview()
        }
        visualEffectView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            label.heightAnchor.constraint(equalToConstant: size.height),
            label.widthAnchor.constraint(equalToConstant: size.width),
            label.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: aboveCenter == true ? targetFrame.minY - size.height - margins.top : targetFrame.maxY + margins.top)
            ])
    }
    
    private func defaultLabel() -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textColor = configurationItem.textColor
        return label
    }
}
