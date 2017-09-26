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
    
    /// the insets around the mask shapes in 4 directions
    var maskInsets: CGFloat = 5
    
    /// the cornerRadius used on roundRect mask shapes
    var cornerRadius: CGFloat = 5
    
    init(with shape: WalkthroughShape, views: [UIView], text: String? = nil, attributedText: NSAttributedString? = nil, insets: CGFloat? = nil, defaultCornerRadius: CGFloat? = nil) {
        guard text != nil || attributedText != nil else {
            fatalError("you must provide either a text or an attributed string")
        }
        self.shape = shape
        self.maskedViews = views
        self.text = text
        self.attributedText = attributedText
        if let insets = insets {
            maskInsets = insets
        }
        if let radius = defaultCornerRadius {
            cornerRadius = radius
        }
    }
    
    init(with shape: WalkthroughShape, view: UIView, text: String? = nil, attributedText: NSAttributedString? = nil, insets: CGFloat? = nil, defaultCornerRadius: CGFloat? = nil) {
        self.init(with: shape, views: [view], text: text, attributedText: attributedText, insets: insets, defaultCornerRadius: defaultCornerRadius)
    }
}

class WalkthroughController: NSObject {
    /// the blur effect to apply. Setting this will change the text and stroke color
    var blurEffect: UIBlurEffectStyle = .dark {
        didSet {
            switch blurEffect {
            case .dark:
                textColor = .white
                strokeColor = .white
                
            default:
                textColor = .black
                strokeColor = .black
            }
        }
    }    
    private lazy var visualEffectView: UIVisualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: self.blurEffect))
    //private lazy var vibrancy: UIVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: self.blurEffect)))
    private lazy var maskView: UIView = UIView(frame: self.visualEffectView.frame)
    private lazy var maskLayer: CAShapeLayer = CAShapeLayer()
    
    var tapToContinueText: String = "Tapez pour passer au suivant"
    var fadeDuration: Double = 0.35
    var delegate: WalkthroughDelegate?
    
    private let tapLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textAlignment = .center
        $0.numberOfLines = 1
        $0.backgroundColor = .clear
        return $0
    } (UILabel())
    private var bottomTapLabelConstraint: NSLayoutConstraint!
    
    private var textColor: UIColor = .white
    private var strokeColor: UIColor = .white
    private var dotColor: UIColor = UIColor.white.withAlphaComponent(0.3)
    var currentDotColor: UIColor = .white
    
    private var items: [WalkthroughItem] = []
    // init with -1 to allow a +=1 as soon as we start the loop
    private var currentItemIndex: Int = -1
    
    private let closeButton: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setImage(UIImage(named:"close"), for: .normal)
        $0.contentMode = .scaleAspectFit
        return $0
    } (UIButton(type: UIButtonType.custom))
    
    private let dots: UIPageControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    } (UIPageControl(frame: CGRect(origin: .zero, size: CGSize(width: 20, height: 20))))
    private var bottomDotConstraint: NSLayoutConstraint!
    
    func start(on view: UIView, with items: [WalkthroughItem]) {
        self.items = items
        
        visualEffectView.frame = view.bounds
        view.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        
        // add the tap to next item
        let tap = UITapGestureRecognizer(target: self, action: #selector(WalkthroughController.jumpToNextItem))
        visualEffectView.addGestureRecognizer(tap)
        
        maskView.backgroundColor = UIColor.black
        maskLayer.fillRule = kCAFillRuleEvenOdd
        
        // indications
        visualEffectView.contentView.addSubview(tapLabel)
        tapLabel.text = tapToContinueText
        tapLabel.textColor = textColor
        let margins = visualEffectView.contentView.layoutMarginsGuide
        bottomTapLabelConstraint = tapLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor)
        NSLayoutConstraint.activate([
            tapLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            tapLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            self.bottomTapLabelConstraint,
            tapLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
        // close button
        visualEffectView.contentView.addSubview(closeButton)
        closeButton.tintColor = textColor
        closeButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.trailingAnchor.constraint(equalTo: visualEffectView.contentView.trailingAnchor, constant: -8),
            closeButton.topAnchor.constraint(equalTo: visualEffectView.contentView.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
            ])
        // numberLabel
        if items.count > 0 {
            visualEffectView.contentView.addSubview(dots)
            dots.numberOfPages = items.count
            dots.pageIndicatorTintColor = dotColor
            dots.currentPageIndicatorTintColor = currentDotColor
            bottomDotConstraint = dots.bottomAnchor.constraint(equalTo: visualEffectView.contentView.bottomAnchor, constant: -tapLabel.frame.height - 20)
            NSLayoutConstraint.activate([
                dots.centerXAnchor.constraint(equalTo: visualEffectView.contentView.centerXAnchor),
                self.bottomDotConstraint
                ])
        }
        
        /*
        visualEffectView.contentView.addSubview(vibrancy)
        
        NSLayoutConstraint.activate([
            vibrancy.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            vibrancy.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            vibrancy.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            vibrancy.topAnchor.constraint(equalTo: visualEffectView.topAnchor)
            ])
        
        // indications
        vibrancy.contentView.addSubview(tapLabel)
        tapLabel.textColor = self.textColor
        let margins = vibrancy.contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            tapLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            tapLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            tapLabel.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
            tapLabel.heightAnchor.constraint(equalToConstant: 20)
            ])
        // close button
        vibrancy.contentView.addSubview(closeButton)
        closeButton.tintColor = textColor
        closeButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: vibrancy.contentView.leadingAnchor, constant: 8),
            closeButton.topAnchor.constraint(equalTo: vibrancy.contentView.topAnchor, constant: 8),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
            ])
        // numberLabel
        if items.count > 0 {
            vibrancy.contentView.addSubview(numberLabel)
            numberLabel.textColor = self.textColor
            NSLayoutConstraint.activate([
                numberLabel.trailingAnchor.constraint(equalTo: vibrancy.contentView.trailingAnchor, constant: -8),
                numberLabel.topAnchor.constraint(equalTo: margins.topAnchor),
                numberLabel.heightAnchor.constraint(equalToConstant: 20)
                ])
        }*/
        
        jumpToNextItem()
    }
    
    @objc private func jumpToNextItem() {
        currentItemIndex += 1
        guard currentItemIndex < items.count else {
            stop()
            return
        }
        
        let currentItem: WalkthroughItem = items[currentItemIndex]
        var englobingRect: CGRect = CGRect.null
        currentItem.maskedViews.forEach { (view) in
            let transformedFrame = self.visualEffectView.convert(view.frame, from: view.superview)
            englobingRect = englobingRect.union(transformedFrame)
        }
        let transformedFrame = englobingRect.insetBy(dx: -currentItem.maskInsets, dy: -currentItem.maskInsets)
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
        maskView.layer.mask = maskLayer
        maskLayer.frame = maskView.bounds
        visualEffectView.mask = maskView
        
        closeButton.isHidden = closeButton.frame.intersects(targetFrame)
        dots.isHidden = dots.frame.intersects(targetFrame)
        
        if let text = currentItem.text {
            insertLabel(with: text, targetFrame: targetFrame, in: maskView)
        } else if let attr = currentItem.attributedText {
            insertLabel(with: attr, targetFrame: targetFrame, in: maskView)
        } else {
            return
        }
        
        // first animation to add some fancinesss
        if currentItemIndex == 0 {
            visualEffectView.alpha = 0
            UIView.animate(withDuration: fadeDuration, animations: {
                self.visualEffectView.alpha = 1
            })
            
            // move the tap label if the first mask intersects with it
            if tapLabel.frame.intersects(targetFrame) {
                bottomTapLabelConstraint.isActive = false
                tapLabel.topAnchor.constraint(equalTo: visualEffectView.contentView.layoutMarginsGuide.topAnchor).isActive = true
            }
        }
        
        if items.count > 0 {
            dots.currentPage = currentItemIndex
        }
        
        // hide the text
        if currentItemIndex == 1 {
            visualEffectView.contentView.layoutIfNeeded()
            // since the bottomAnchor can change, we reset it here
            tapLabel.isHidden = true
            bottomDotConstraint.isActive = false
            dots.bottomAnchor.constraint(equalTo: visualEffectView.contentView.layoutMarginsGuide.bottomAnchor).isActive = true
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: UIViewAnimationOptions.curveEaseInOut, animations: {
                self.tapLabel.alpha = 0
                self.visualEffectView.contentView.layoutIfNeeded()
            }, completion: nil)
        }
        delegate?.nextStepSelected()
    }
    
    func stop() {
        UIView.animate(withDuration: fadeDuration, animations: {
            self.visualEffectView.alpha = 0
        }) { _ in
            self.visualEffectView.removeFromSuperview()
            self.delegate?.didStop()
        }
    }
    
    private func insertLabel(with attributedText: NSAttributedString, targetFrame: CGRect, in view: UIView) {
        let label = defaultLabel()
        label.attributedText = attributedText
        label.tag = 666
        let margins = visualEffectView.contentView.layoutMargins
        let aboveCenter = targetFrame.origin.y + targetFrame.height / 2.0 >= visualEffectView.contentView.center.y
        let height: CGFloat = aboveCenter == true ? targetFrame.minY - (2 * margins.top) : visualEffectView.contentView.frame.height - targetFrame.maxY - (2 * margins.bottom)
        let targetSize = CGSize(width: visualEffectView.contentView.frame.width - visualEffectView.contentView.layoutMargins.left - visualEffectView.contentView.layoutMargins.right, height: height)
        var rect = attributedText.boundingRect(with: targetSize, options: [.usesFontLeading, .usesLineFragmentOrigin], context: nil)
        rect.size.height += 1
        label.frame = CGRect(origin: .zero, size: rect.size)
        
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
    
    private func insertLabel(with text: String, targetFrame: CGRect, in view: UIView) {
        let label = defaultLabel()
        label.text = text
        insert(label: label, targetFrame: targetFrame, in: view)
    }
    
    private func insert(label: UILabel, targetFrame: CGRect, in view: UIView) {
        label.tag = 666
        
        let margins = visualEffectView.contentView.layoutMargins
        let aboveCenter = targetFrame.origin.y + targetFrame.height / 2.0 >= visualEffectView.contentView.center.y
        let height: CGFloat = aboveCenter == true ? targetFrame.minY - (2 * margins.top) : visualEffectView.contentView.frame.height - targetFrame.maxY - (2 * margins.bottom)
        let size = label.systemLayoutSizeFitting(CGSize(width: visualEffectView.contentView.frame.width - visualEffectView.contentView.layoutMargins.left - visualEffectView.contentView.layoutMargins.right, height: height),
                                                 withHorizontalFittingPriority: UILayoutPriorityDefaultHigh,
                                                 verticalFittingPriority: UILayoutPriorityDefaultLow)
        label.frame = CGRect(origin: .zero, size: size)
        
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
        label.textColor = textColor
        return label
    }
}
