//
//  LoopedContentsView.swift
//  LoopedContentsView
//
//  Created by naru on 2016/07/14.
//  Copyright © 2016年 naru. All rights reserved.
//

import UIKit
import Foundation

public protocol LoopedContentsViewDataSource {
    /// Return 
    func loopedContentsViewNumberOfContents(_ loopedContentsView: LoopedContentsView) -> Int
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, cellAtIndex index: Int) -> LoopedContentsViewCell
}

public protocol LoopedContentsViewDelegate {
    // Required
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, lengthOfContentAtIndex index: Int) -> CGFloat
    // Optional
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willSelectContentAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didSelectContentAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willDeselectContentAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didDeselectContentAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willDisplayCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didEndDisplaying cell: LoopedContentsViewCell, forItemAtIndex index: Int)
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didFocusCell cell: LoopedContentsViewCell, forItemAtIndex index: Int)
}

extension LoopedContentsViewDelegate {
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willSelectContentAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didSelectContentAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willDeselectContentAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didDeselectContentAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, willDisplayCell cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didEndDisplaying cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
    func loopedContentsView(_ loopedContentsView: LoopedContentsView, didFocusCell cell: LoopedContentsViewCell, forItemAtIndex index: Int) { }
}

open class LoopedContentsView: UIView, UIScrollViewDelegate {
    
    // MARK: Constants
    
    public enum Orientation {
        case horizontal
        case vertical
    }
    
    fileprivate struct Constants {
        
        static let ScrollLength: CGFloat = 1.0E+7
        static let DefaultScrollEndDraggingFactor: CGFloat = 350.0
        static let MaxStoredCellCount: Int = 5
        
        static let Padding: CGFloat = 2.0
        static let DefaultIndicatorColor: UIColor = UIColor(white: 0.3, alpha: 1.0)
    }
    
    // MARK: Life Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.scrollView)
        self.addSubview(self.horizontalScrollIndicator)
        self.addSubview(self.verticalScrollIndicator)
        
        self.setScrollPosition(0, animated: true)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Element
    
    open var delegate: LoopedContentsViewDelegate? = nil
    
    open var dataSource: LoopedContentsViewDataSource? = nil
    
    open var allowsMultipleSelection: Bool = false
    
    open var pagingEnabled: Bool = true
    
    open var scrollEndDraggingFactor: CGFloat = Constants.DefaultScrollEndDraggingFactor
    
    open var cellTransform: ((_ range: CGFloat) -> CGAffineTransform)? = nil
    
    open var cellAlpha: ((_ range: CGFloat) -> CGFloat)? = nil
    
    fileprivate var totalItemLength: CGFloat = 0.0
    
    fileprivate var numberOfItems: Int = 0
    
    fileprivate var lengthOfItems: [CGFloat] = []
    
    fileprivate var activeCells: [Int: LoopedContentsViewCell] = [:]
    
    fileprivate var reusedClassStore: [String: AnyClass] = [:]
    
    fileprivate var reusedCellStore: [String: [LoopedContentsViewCell]] = [:]
    
    fileprivate var visibleCellIndexSet: Set<Int> = Set<Int>()
    
    fileprivate var selectedItemIndexSet: Set<Int> = Set<Int>()
    
    fileprivate var centerItem: (itemIndex: Int, index: Int, origin: CGFloat) = (0, 0, 0.0)
    
    fileprivate lazy var scrollView: UIScrollView = {
        let frame: CGRect = self.bounds
        let scrollView: UIScrollView = UIScrollView(frame: frame)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self
        scrollView.contentSize = self.contentSize
        scrollView.isExclusiveTouch = true
        return scrollView
    }()
    
    open lazy var horizontalScrollIndicator: UIView  = {
        let frame: CGRect = CGRect(x: 0.0, y: 0.0, width: 4.0, height: 4.0)
        let view: UIView = UIView(frame: frame)
        view.frame = frame
        view.layer.cornerRadius = 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = Constants.DefaultIndicatorColor
        view.alpha = 0.0
        view.isHidden = true
        return view
    }()
    
    open lazy var verticalScrollIndicator: UIView  = {
        let frame: CGRect = CGRect(x: 0.0, y: 0.0, width: 4.0, height: 4.0)
        let view: UIView = UIView(frame: frame)
        view.frame = frame
        view.layer.cornerRadius = 2.0
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.gray
        view.alpha = 0.0
        view.isHidden = true
        return view
    }()
    
    // MARK: Access
    
    func next(itemIndex: Int) -> Int {
        return itemIndex == self.numberOfItems - 1 ? 0 : itemIndex + 1
    }
    
    func previous(itemIndex: Int) -> Int {
        return itemIndex == 0 ? self.numberOfItems - 1 : itemIndex - 1
    }
    
    // MARK: Computed Variable
    
    fileprivate var horizontalScrollIndicatorCenter: CGPoint {
        let ratio: CGFloat = self.scrollView.contentOffset.x/(self.scrollView.contentSize.width - self.scrollView.frame.size.width)
        let center: CGPoint = {
            let indicatorSize: CGSize = self.horizontalScrollIndicator.frame.size
            let x: CGFloat = Constants.Padding + indicatorSize.width/2.0 + (self.frame.size.width - Constants.Padding*2 - indicatorSize.width)*ratio
            let y: CGFloat = self.frame.size.height - Constants.Padding - self.horizontalScrollIndicator.frame.size.height/2.0
            return CGPoint(x: x, y: y)
        }()
        return center
    }
    
    fileprivate var verticalScrollIndicatorCenter: CGPoint {
        let ratio: CGFloat = self.scrollView.contentOffset.y/(self.scrollView.contentSize.height - self.scrollView.frame.size.height)
        let center: CGPoint = {
            let indicatorSize: CGSize = self.horizontalScrollIndicator.frame.size
            let x: CGFloat = self.frame.size.width - Constants.Padding - self.horizontalScrollIndicator.frame.size.width/2.0
            let y: CGFloat = Constants.Padding + indicatorSize.height/2.0 + (self.frame.size.height - Constants.Padding*2 - indicatorSize.height)*ratio
            return CGPoint(x: x, y: y)
        }()
        return center
    }

    open var selectedIndexSet: Set<Int> {
        return self.selectedItemIndexSet
    }
    
    open var scrollPosition : CGFloat {
        get {
            switch self.orientation {
            case .horizontal:
                return self.scrollView.contentOffset.x + (self.frame.size.width - Constants.ScrollLength)/2.0
            case .vertical:
                return self.scrollView.contentOffset.y + self.frame.size.height/2.0 - Constants.ScrollLength/2.0
            }
        }
        set {
            self.setScrollPosition(newValue, animated: false)
        }
    }
    
    open var orientation: Orientation = .horizontal {
        didSet {
            self.scrollView.contentSize = self.contentSize
            self.horizontalScrollIndicator.alpha = 0.0
            self.verticalScrollIndicator.alpha = 0.0
            self.setScrollPosition(0, animated: true)
        }
    }
    
    fileprivate var contentSize: CGSize {
        switch self.orientation {
        case .horizontal:
            return CGSize(width: Constants.ScrollLength, height: self.frame.height)
        case .vertical:
            return CGSize(width: self.frame.height, height: Constants.ScrollLength)
        }
    }
    
    fileprivate var controlledScrollIndicator: UIView {
        switch self.orientation {
        case .horizontal:
            return self.horizontalScrollIndicator
        case .vertical:
            return self.verticalScrollIndicator
        }
    }
    
    override open var frame: CGRect {
        didSet {
            self.updateVisibleCells()
        }
    }
    
    // MARK: Control
    
    open func setScrollPosition(_ position: CGFloat, animated: Bool) {
        let offset: CGPoint
        switch self.orientation {
        case .horizontal:
            offset = CGPoint(x: (Constants.ScrollLength - self.frame.size.width)/2.0 + position, y: 0.0)
        case .vertical:
            offset = CGPoint(x: 0.0, y: (Constants.ScrollLength - self.frame.size.height)/2.0 + position)
        }
        self.scrollView.setContentOffset(offset, animated: animated)
    }
    
    open func selectItem(atIndex index: Int, animated: Bool) {
        
        // Deselect Item if Multiple Selectin is Not Allowed
        if !self.allowsMultipleSelection {
            let deselectedItemIndexSet: [Int] = self.selectedItemIndexSet.filter { _index -> Bool in
                return _index != index
            }
            for _index in deselectedItemIndexSet {
                self.deselectItem(atIndex: _index, animated: animated)
            }
        }
        
        let willSelect: Bool = !self.selectedItemIndexSet.contains(index)
        if !willSelect {
            return
        }
        
        // Call Delegate Method (Will)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, willSelectContentAtIndex: index)
        }
        
        self.selectedItemIndexSet.insert(index)
        
        for (_, cell) in self.activeCells where cell.itemIndex == index {
            cell.setSelected(true, animated: true)
        }
        
        // Call Delegate Method (Did)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, didSelectContentAtIndex: index)
        }
    }
    
    open func deselectItem(atIndex index: Int, animated: Bool) {
        
        let willDeselect: Bool = self.selectedItemIndexSet.contains(index)
        if !willDeselect {
            return
        }
        
        // Call Delegate Method (Will)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, willDeselectContentAtIndex: index)
        }
    
        self.selectedItemIndexSet.remove(index)
        
        for (_, cell) in self.activeCells where cell.itemIndex == index {
            cell.setSelected(false, animated: true)
        }
        
        // Call Delegate Method (Did)
        if let delegate: LoopedContentsViewDelegate = self.delegate {
            delegate.loopedContentsView(self, didDeselectContentAtIndex: index)
        }
    }
    
    fileprivate func adjustScrollIndicator() {
        switch self.orientation {
        case .horizontal:
            self.horizontalScrollIndicator.center = self.horizontalScrollIndicatorCenter
        case .vertical:
            self.verticalScrollIndicator.center = self.verticalScrollIndicatorCenter
        }
    }
    
    // MARK: Reuse
    
    open func registerClass(class _class: AnyClass, forCellReuseIdentifier identifier: String) {
        self.reusedClassStore[identifier] = _class
    }
    
    open func dequeueReusableCellWithIdentifier(_ identifier: String) -> LoopedContentsViewCell {
    
        let _class: LoopedContentsViewCell.Type? = self.reusedClassStore[identifier] as? LoopedContentsViewCell.Type
        if _class == nil {
            assertionFailure("Reusable Class is Not Registered for Identifier '\(identifier)'")
        }
        
        let name: String = NSStringFromClass(_class!) as String
        if let cell: LoopedContentsViewCell = self.reusedCellStore[name]?.last {
            // Return Stored Cell
            self.reusedCellStore[name]?.removeLast()
            return cell
        } else {
            // Return New Cell
            let cell: LoopedContentsViewCell = _class!.init()
            return cell
        }
    }
    
    // MARK: Update
    
    open func reloadData() {
        
        self.numberOfItems = self.dataSource?.loopedContentsViewNumberOfContents(self) ?? 0
        self.lengthOfItems = (0..<self.numberOfItems).map { (index: Int) -> CGFloat in
            return self.delegate?.loopedContentsView(self, lengthOfContentAtIndex: index) ?? 0.0
        }
        self.totalItemLength = self.lengthOfItems.reduce(0.0) { $0 + $1 }
        
        self.visibleCellIndexSet = Set<Int>()
        self.activeCells = [:]
        self.reusedCellStore = [:]
        
        self.updateVisibleCells()
    }
    
    fileprivate func updateVisibleCells() {
        
        if self.numberOfItems <= 0 {
            return
        }
        guard let dataSource: LoopedContentsViewDataSource = self.dataSource else {
            return
        }
        
        let position: CGFloat = self.scrollPosition + self.lengthOfItems[0]/2.0
        let multiple: Int = {
            let num: Int = Int(position)/Int(self.totalItemLength)
            return position < 0 ? num - 1 : num
        }()
        
        // Get Index and Origin of Center Item
        self.centerItem = {
            var value: CGFloat = position - self.totalItemLength*CGFloat(multiple)
            if value >= 0 {
                for (itemIndex, length) in self.lengthOfItems.enumerated() {
                    if value - length <= 0 {
                        return (itemIndex, itemIndex + self.numberOfItems*multiple, -value)
                    }
                    value = value - length
                }
            } else {
                value = abs(value)
                for (itemIndex, length) in self.lengthOfItems.reversed().enumerated() {
                    value = value - length
                    if value <= 0 {
                        let _itemIndex: Int = self.numberOfItems - itemIndex - 1
                        return (_itemIndex, _itemIndex + self.numberOfItems*multiple, value)
                    }
                }
            }
            return (0, 0, 0.0)
        }()
        
        // Find Visible Next Index
        let nextItemIndexes: [Int] = {
            var indexes: [Int] = []
            var itemIndex: Int = centerItem.itemIndex
            var origin: CGFloat = centerItem.origin + self.lengthOfItems[itemIndex]
            while origin < self.frame.size.width/2.0 {
                itemIndex = self.next(itemIndex: itemIndex)
                origin = origin + self.lengthOfItems[itemIndex]
                indexes.append(itemIndex)
            }
            return indexes
        }()
        
        var origin: CGFloat = centerItem.origin
        
        // Find Visible Previous Index
        let previousItemIndexes: [Int] = {
            var indexes: [Int] = []
            var itemIndex: Int = centerItem.itemIndex
            while origin > -self.frame.size.width/2.0 {
                itemIndex = self.previous(itemIndex: itemIndex)
                origin = origin - self.lengthOfItems[itemIndex]
                indexes.insert(itemIndex, at: 0)
            }
            return indexes
        }()
        
        let itemIndexes: [Int] = previousItemIndexes + [self.centerItem.itemIndex] + nextItemIndexes
        
        // Get Visible Indexes in Whole Scroll View
        let previousIndexes: [Int] = (0..<(previousItemIndexes.count)).enumerated().map { (index: Int, value: Int) -> Int in
            return self.centerItem.index - index - 1
        }.reversed()
        let nextIndexes: [Int] = (0..<(nextItemIndexes.count)).enumerated().map { (index: Int, value: Int) -> Int in
            return self.centerItem.index + index + 1
        }
        
        // Get New/Disable Cell Indexes
        let indexes: [Int] = previousIndexes + [self.centerItem.index] + nextIndexes
        let indexSet: Set<Int> = Set(indexes)
        let newCellIndexSet: Set<Int> = indexSet.subtracting(self.visibleCellIndexSet)
        let disableCellIndexSet: Set<Int> = self.visibleCellIndexSet.subtracting(indexSet)
        self.visibleCellIndexSet = indexSet
        
        // Convert Origin Value for Scroll View
        origin = {
            switch self.orientation {
            case .horizontal:
                return origin + self.scrollView.contentOffset.x + self.frame.size.width/2.0
            case .vertical:
                return origin + self.scrollView.contentOffset.y + self.frame.size.height/2.0
            }
        }()
        
        // Get Cell Frames
        let frames: [CGRect] = {
            var frames: [CGRect] = []
            for index in itemIndexes {
                let frame: CGRect
                switch self.orientation {
                case .horizontal:
                    frame = CGRect(x: origin, y: 0.0, width: self.lengthOfItems[index], height: self.frame.size.height)
                case .vertical:
                    frame = CGRect(x: 0.0, y: origin, width: self.frame.size.width, height: self.lengthOfItems[index])
                }
                frames.append(frame)
                origin = origin + self.lengthOfItems[index]
            }
            return frames
        }()
        
        // Update Cell Frame
        for (_index, itemIndex) in itemIndexes.enumerated() {
                        
            let index: Int = indexes[_index]
            let frame: CGRect = frames[_index]
        
            // Create New Cells
            if newCellIndexSet.contains(index) {
                
                let cell: LoopedContentsViewCell = dataSource.loopedContentsView(self, cellAtIndex: itemIndex)
                self.activeCells[index] = cell
                cell.frame = frame
                cell.index = index
                cell.itemIndex = itemIndex
                
                let selected: Bool = self.selectedItemIndexSet.contains(cell.itemIndex)
                cell.setSelected(selected, animated: false)
                
                let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onCellTapped(_:)))
                cell.addGestureRecognizer(tapGestureRecognizer)
                
                // Cell Will Display
                if let delegate: LoopedContentsViewDelegate = self.delegate {
                    delegate.loopedContentsView(self, willDisplayCell: cell, forItemAtIndex: itemIndex)
                }
                
                self.scrollView.addSubview(cell)
            }
        }
        
        // Remove Disabled Cells
        for index in disableCellIndexSet {
            if let cell = self.activeCells[index] {
                
                cell.removeFromSuperview()
                self.activeCells[index] = nil
                
                // Cell Did End Displaying
                if let delegate: LoopedContentsViewDelegate = self.delegate {
                    delegate.loopedContentsView(self, didEndDisplaying: cell, forItemAtIndex: cell.itemIndex)
                }
                
                // Cell is Not Cached if Any Reusable Cell Class is Not Registered.
                if self.reusedClassStore.keys.count == 0 {
                    continue
                }

                // Store Reusable Cell
                let name: String = NSStringFromClass(type(of: cell)) as String
                
                var cells: [LoopedContentsViewCell] = []
                if let storedCells: [LoopedContentsViewCell] = self.reusedCellStore[name] {
                    cells = cells + storedCells
                }
                if cells.count < Constants.MaxStoredCellCount {
                    cells.append(cell)
                    self.reusedCellStore[name] = cells
                }
            }
        }
        
        // Update Cell Transform, Alpha
        if self.cellTransform != nil || self.cellAlpha != nil {
            
            for (_, cell) in self.activeCells {
                
                let range: CGFloat = {
                    switch self.orientation {
                    case .horizontal:
                        return cell.frame.midX - self.scrollView.contentOffset.x - self.scrollView.frame.size.width/2.0
                    case .vertical:
                        return cell.frame.midY - self.scrollView.contentOffset.y - self.scrollView.frame.size.height/2.0
                    }
                }()
                
                if let cellTransform: ((_ range: CGFloat) -> CGAffineTransform) = self.cellTransform {
                    cell.contentView.transform = cellTransform(range)
                }
                if let cellAlpha: ((_ range: CGFloat) -> CGFloat) = self.cellAlpha {
                    cell.contentView.alpha = cellAlpha(range)
                }
                
            }
        }
    }
    
    // MARK: Gesture
    
    func onCellTapped(_ sender: UITapGestureRecognizer) {
        
        guard let cell: LoopedContentsViewCell = sender.view as? LoopedContentsViewCell else {
            return
        }
        
        let itemIndex: Int = cell.itemIndex
        let willSelect: Bool = !self.selectedItemIndexSet.contains(itemIndex)
        if willSelect {
            self.selectItem(atIndex: itemIndex, animated: true)
        } else {
            self.deselectItem(atIndex: itemIndex, animated: true)
        }
    }
    
    // MARK: Scroll View Delegate
    
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        self.adjustScrollIndicator()
        self.updateVisibleCells()
    }
    
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        self.adjustScrollIndicator()
        self.controlledScrollIndicator.alpha = 1.0
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        // Cell Did Focus
        if let delegate: LoopedContentsViewDelegate = self.delegate, let cell: LoopedContentsViewCell = self.activeCells[self.centerItem.index] {
            delegate.loopedContentsView(self, didFocusCell: cell, forItemAtIndex: centerItem.itemIndex)
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.controlledScrollIndicator.alpha = 0.0
        })
    }
    
    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if !self.pagingEnabled {
            return
        }
        
        switch self.orientation {
        case .horizontal:
            
            let middle: CGFloat = self.scrollView.contentOffset.x + self.frame.size.width/2.0
            let target: CGFloat = middle + self.centerItem.origin + self.scrollEndDraggingFactor*velocity.x
            var current: (index: Int, x: CGFloat) = (index: self.centerItem.itemIndex, x: middle + self.centerItem.origin)
            
            if velocity.x >= 0.0 {
                while true {
                    let nextLength: CGFloat = self.lengthOfItems[self.next(itemIndex: current.index)]
                    if current.x + nextLength >= target {
                        targetContentOffset.pointee.x = current.x + nextLength/2.0 - self.frame.size.width/2.0
                        return
                    }
                    current.index = self.next(itemIndex: current.index)
                    current.x = current.x + nextLength
                }
            } else {
                while true {
                    let previousLength: CGFloat = self.lengthOfItems[self.previous(itemIndex: current.index)]
                    if current.x - previousLength <= target {
                        targetContentOffset.pointee.x = current.x + previousLength/2.0 - self.frame.size.width/2.0
                        return
                    }
                    current.index = self.previous(itemIndex: current.index)
                    current.x = current.x - previousLength
                }
            }
        case .vertical:
            
            let middle: CGFloat = self.scrollView.contentOffset.y + self.frame.size.height/2.0
            let target: CGFloat = middle + self.centerItem.origin + self.scrollEndDraggingFactor*velocity.y
            var current: (index: Int, y: CGFloat) = (index: self.centerItem.itemIndex, y: middle + self.centerItem.origin)
            
            if velocity.y >= 0.0 {
                while true {
                    let nextLength: CGFloat = self.lengthOfItems[self.next(itemIndex: current.index)]
                    if current.y + nextLength >= target {
                        targetContentOffset.pointee.y = current.y + nextLength/2.0 - self.frame.size.height/2.0
                        return
                    }
                    current.index = self.next(itemIndex: current.index)
                    current.y = current.y + nextLength
                }
            } else {
                while true {
                    let previousLength: CGFloat = self.lengthOfItems[self.previous(itemIndex: current.index)]
                    if current.y - previousLength <= target {
                        targetContentOffset.pointee.y = current.y + previousLength/2.0 - self.frame.size.height/2.0
                        return
                    }
                    current.index = self.previous(itemIndex: current.index)
                    current.y = current.y - previousLength
                }
            }
        }
    }
}
