//
//  LoopedContentsViewCell.swift
//  InfiniteScrollView
//
//  Created by naru on 2016/07/15.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit

open class LoopedContentsViewCell: UIView {
    
    // MARK: Constants
    
    public enum State: Int {
        case none
        case selected
    }
    
    fileprivate struct Constants {
        static let DefaultSelectedColor: UIColor = UIColor(white: 0.9, alpha: 1.0)
    }
    
    // MARK: Life Cycle
    
    public required convenience init() {
        self.init(frame: UIScreen.main.bounds)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColors[.selected] = Constants.DefaultSelectedColor
        
        self.addSubview(self.contentView)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Elements
    
    open var index: Int = 0
    
    open var itemIndex: Int = 0
    
    fileprivate(set) var selected: Bool = false
    
    open lazy var contentView: UIView = {
        let view: UIView = UIView(frame: self.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()
    
    fileprivate var backgroundColors: [State: UIColor] = [:]
    
    fileprivate var state: State {
        if self.selected {
            return .selected
        } else {
            return .none
        }
    }
    
    // MARK: Control
    
    fileprivate func updateBackgroundColor(_ animated: Bool) {
        
        let color: CGColor? = self.backgroundColors[self.state]?.cgColor
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.layer.backgroundColor = color
            })
        } else {
            self.layer.backgroundColor = color
        }
    }
    
    open func setBackgroundColor(_ backgroundColor: UIColor, forState state: State) {
        
        self.backgroundColors[state] = backgroundColor
        if self.state == state {
            self.updateBackgroundColor(false)
        }
    }
    
    open func setSelected(_ selected: Bool, animated: Bool) -> Void {

        self.selected = selected
        self.updateBackgroundColor(animated)
    }

}
