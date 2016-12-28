//
//  FlexiCollectionViewLayout.swift
//  FlexiCollectionViewLayout
//
//  Created by Deepak Kumar on 11/13/16.
//  Copyright © 2016 Deepak Kumar. All rights reserved.
//

import UIKit
import Foundation
/**
 Conform to the protocol and implement the required method for the layout to work.
 */
@objc public protocol FlexiCollectionViewLayoutDelegate: UICollectionViewDelegateFlowLayout {
    /**
        Return the cell size attributes
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: FlexiCollectionViewLayout, sizeForFlexiItemAt indexPath: IndexPath) -> ItemSizeAttributes
    
    @objc optional func collectionView (_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                                        heightForHeaderInSection section: Int) -> CGFloat
    
    @objc optional func collectionView (_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                                        heightForFooterInSection section: Int) -> CGFloat
}

/**
    - Parameter regular: Regular sqaure cells.
    - Parameter large: Cells which have width or height more than regular cells.
 */
@objc public enum FlexiCellSize: Int {
    case regular
    case large
}

///A class used for return type object in FlexiCollectionViewLayoutDelegate.
@objc open class ItemSizeAttributes: NSObject {
    let itemSize: CGSize
    let layoutSize: FlexiCellSize
    let widthFactor: Int
    let heightFactor: Int
    /**
        Pass in the collection view cell layout information
        - Parameter itemSize: The size of the base cell, actual cell size may vary to fit the collection view width properly. Size of bigger cells will be calculated based on this.
        - Parameter layoutSize: If the cell size is bigger than the base cell size then return .large else return .regular
        - Parameter widthFactor: The multipling factor of the current cell compared to base cell. If the cell width has to be 3 times the base cell width then return 3
        - Parameter heightFactor: The multipling factor of the current cell compared to base cell. If the cell height has to be 3 times the base cell height then return 3
     */
    public init(itemSize: CGSize, layoutSize: FlexiCellSize, widthFactor: Int, heightFactor: Int) {
        self.itemSize = itemSize
        self.layoutSize = layoutSize
        self.widthFactor = widthFactor
        self.heightFactor = heightFactor
    }
}

/**
 A UICollectionViewLayout subclass which can render dynamic collection view layouts with items of irregular heights and widths. Conform to FlexiCollectionViewLayoutDelegate delegate for layout to work.
 */
@objc open class FlexiCollectionViewLayout: UICollectionViewLayout {
    
    weak var delegate: FlexiCollectionViewLayoutDelegate? {
        get {
            return self.collectionView!.delegate as? FlexiCollectionViewLayoutDelegate
        }
    }
    
    fileprivate var columnHeightsPerSection: [[CGFloat]] = []
    private var layoutInfo: [[UICollectionViewLayoutAttributes]] = []
    private var supplementaryAttributes: [IndexPath : UICollectionViewLayoutAttributes] = [:]
    private var numRegularCells = 1
    private var wasMovedDown = false
    private var addedToBufferHolder = false
    private var bufferArray = [(CGRect, Int)]()
    
    //MARK: UICollectionViewLayout Lifecycle methods
    override open func prepare() {
        super.prepare()
        resetLayout()
        
        let sectionCount = collectionView?.numberOfSections ?? 0
        if sectionCount == 0 {
            return
        }
        
        for sectionIndex in 0 ..< sectionCount {
            let interitemSpacing = interitemSpacingForSectionAtIndex(sectionIndex)
            let sectionInset = insetForSectionAtIndex(sectionIndex)
            let width = collectionViewContentWidth()
            numRegularCells = numberOfRegularCellsInSection(sectionIndex, width: width, interItemSpacing: interitemSpacing, insets: sectionInset)
            columnHeightsPerSection.append([CGFloat] (repeating: 0, count: numRegularCells))
            
            let headerLayoutAttribute = getLayoutAttributesForSupplementaryViewOfKind(kind: UICollectionElementKindSectionHeader, indexPath: IndexPath(item: 0, section: sectionIndex), insets: sectionInset, width: width)
            increaseAllColumnHeightsBy(headerLayoutAttribute.frame.height + interitemSpacing, section: sectionIndex)
            
            let numberOfItems = collectionView!.numberOfItems(inSection: sectionIndex)
            var itemAttributes: [UICollectionViewLayoutAttributes] = []
            
            for item in 0 ..< numberOfItems {
                
                let cellIndexPath = IndexPath(item: item, section: sectionIndex)
                let itemSize = sizeForItemAtIndexPath(cellIndexPath)
                let indexOfShortestColumn = indexOfShortestColumnInSection(sectionIndex)
                
                if itemSize.layoutSize == .large {
                    let attributes = flexiLayoutAttributesForIndexPath(cellIndexPath, cellSize: itemSize, column: indexOfShortestColumn, width: width, insets: sectionInset, interItemSpacing: interitemSpacing)
                    let columnHeight = columnHeightsPerSection[sectionIndex][indexOfShortestColumn]
                    let regularSize = regularCellSize(cellIndexPath, interItemSpacing: interitemSpacing, insets: sectionInset)
                    
                    if wasMovedDown {
                        wasMovedDown = false
                    } else if attributes.frame.origin.x + attributes.frame.size.width + regularSize.width > width {
                        for index in indexOfShortestColumn..<columnHeightsPerSection[sectionIndex].count {
                            columnHeightsPerSection[sectionIndex][index] = columnHeight + attributes.frame.size.height + interitemSpacing
                        }
                    } else {
                        for index in 0 ..< itemSize.widthFactor {
                            columnHeightsPerSection[sectionIndex][index + indexOfShortestColumn] = columnHeight + attributes.frame.size.height + interitemSpacing
                        }
                    }
                    itemAttributes.append(attributes)
                } else {
                    let attributes = flexiLayoutAttributesForIndexPath(cellIndexPath, cellSize: itemSize, column: indexOfShortestColumn, width: width, insets: sectionInset, interItemSpacing: interitemSpacing)
                    let columnHeight = columnHeightsPerSection[sectionIndex][indexOfShortestColumn]
                    
                    // No need to increase the column height if the cell was added to buffer placeholder as its height is already increased by large cell.
                    if !addedToBufferHolder {
                        columnHeightsPerSection[sectionIndex][indexOfShortestColumn] = columnHeight + attributes.frame.size.height + interitemSpacing
                    } else if (addedToBufferHolder && indexOfShortestColumn >= sizeForItemAtIndexPath(cellIndexPath).widthFactor) {
                        columnHeightsPerSection[sectionIndex][indexOfShortestColumn] = columnHeight + attributes.frame.size.height + interitemSpacing
                    }
                    itemAttributes.append(attributes)
                }
            }
            
            layoutInfo.append(itemAttributes)
            
            let footerLayoutAttribute = getLayoutAttributesForSupplementaryViewOfKind(kind: UICollectionElementKindSectionFooter, indexPath: IndexPath(item: 1, section: sectionIndex), insets: sectionInset, width: width)
            increaseAllColumnHeightsBy(footerLayoutAttribute.frame.height + sectionInset.bottom, section: sectionIndex)
        }
    }
    
    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributesInRect: [UICollectionViewLayoutAttributes] = []
        
        for sectionAttributes in layoutInfo {
            for attributes in sectionAttributes {
                if rect.intersects(attributes.frame) {
                    layoutAttributesInRect.append(attributes)
                }
            }
        }
        
        for (_, attributes) in supplementaryAttributes {
            if rect.intersects(attributes.frame) {
                layoutAttributesInRect.append(attributes)
            }
        }
        return layoutAttributesInRect
    }
    
    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let list = layoutInfo[indexPath.section]
        return list[indexPath.item]
    }
    
    override open func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return supplementaryAttributes[indexPath]
    }
    
    override open var collectionViewContentSize : CGSize {
        let width = collectionViewContentWidth()
        var height: CGFloat = 0.0
        
        for i in 0 ..< columnHeightsPerSection.count {
            let columnHeights = columnHeightsPerSection[i]
            let indexOfTallestColumn = indexOfTallestColumnInSection(i)
            let heightOfTallestColumn = columnHeights[indexOfTallestColumn]
            height += heightOfTallestColumn
        }
        return CGSize(width: width, height: height)
    }
    
    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        let oldBounds = self.collectionView!.bounds
        if newBounds.width != oldBounds.width {
            return true
        }
        return false
    }
    
    //MARK: Layout Attributes generators
    fileprivate func flexiLayoutAttributesForIndexPath(_ indexPath: IndexPath, cellSize: ItemSizeAttributes, column: NSInteger, width: CGFloat, insets: UIEdgeInsets, interItemSpacing: CGFloat) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        layoutAttributes.frame = flexiCellRectForIndexPath(indexPath, size: cellSize, column: column, width: width, insets: insets, interItemSpacing: interItemSpacing)
        return layoutAttributes
    }
    
    fileprivate func flexiCellRectForIndexPath(_ indexPath:IndexPath, size: ItemSizeAttributes ,column: NSInteger, width: CGFloat, insets: UIEdgeInsets, interItemSpacing: CGFloat) -> CGRect {
        let sectionIndex = indexPath.section
        let cellSize = cellSizeForIndexPath(indexPath, itemSize: size, interItemSpacing: interItemSpacing, insets: insets)
        var cellHeight = cellSize.height
        let cellWidth = cellSize.width
        
        var columnHeight = columnHeightsPerSection[sectionIndex][column]
        var originX: CGFloat = 0.0
        var originY = verticalOffsetForSection(section: sectionIndex) + columnHeight
        let regularSize = regularCellSize(indexPath, interItemSpacing: interItemSpacing, insets: insets)
        
        if size.layoutSize == .large {
            originX = CGFloat(column) * (regularSize.width + interItemSpacing)
            cellHeight += interItemSpacing * (CGFloat(sizeForItemAtIndexPath(indexPath).heightFactor-1))
        } else {
            originX = CGFloat(column) * (cellWidth + interItemSpacing)
        }
        originX += insets.left
        
        if size.layoutSize == .large {
            if originX + cellWidth > width {
                //Cell does not fit in the column, move it down and add the remaining space to buffer so that it can be filled with smaller once later.
                for bufferIndex in 1...numRegularCells - column {
                    addToBufferArray(bufferIndex: bufferIndex, calulatedOriginX: originX, regularSize: regularSize, interItemSpacing: interItemSpacing, column: column, originY: originY, cellSize: cellSize)
                }
                //update the big cell Origins
                let shortestNextIndex = indexOfShortestColumnBeforeColumn(column, section: sectionIndex)
                originY = columnHeightsPerSection[sectionIndex][shortestNextIndex]
                originX = CGFloat(shortestNextIndex) * (regularSize.width + interItemSpacing) + insets.left
                wasMovedDown = true
                
                // Increase the column height of all columns which the large cell spans
                columnHeight = columnHeightsPerSection[sectionIndex][shortestNextIndex]
                for index in 0 ..< size.widthFactor {
                    columnHeightsPerSection[sectionIndex][index + shortestNextIndex] = columnHeight + cellHeight + interItemSpacing
                }
            } else if !canFitInShortestColumn(column, section: sectionIndex, widthFactor: size.widthFactor) {
                //Cell does not fit in the column, move it further and add the remaining space to buffer so that it can be filled with smaller once later.
                addToBufferArray(bufferIndex: 1, calulatedOriginX: originX, regularSize: regularSize, interItemSpacing: interItemSpacing, column: column, originY: originY, cellSize: cellSize)
                
                //update the big cell Origins
                let shortestNextIndex = indexOfShortestColumnAfterColumn(column, section: sectionIndex)
                originY = columnHeightsPerSection[sectionIndex][shortestNextIndex]
                originX = CGFloat(shortestNextIndex) * (regularSize.width + interItemSpacing)
                wasMovedDown = true
                
                // Increase the column height of all columns which the large cell spans
                var localColumnHeightsPerSection = columnHeightsPerSection[sectionIndex]
                columnHeight = columnHeightsPerSection[sectionIndex][shortestNextIndex]
                for index in 0 ..< size.widthFactor {
                    localColumnHeightsPerSection[index + shortestNextIndex] = columnHeight + cellHeight + interItemSpacing
                }
                columnHeightsPerSection[sectionIndex] = localColumnHeightsPerSection
            }
        } else {
            // Place the cell in buffer placeholders if there are any buffer plaholders left.
            if bufferArray.count > 0 && (column >= bufferArray[0].1){
                originX = bufferArray[0].0.origin.x
                originY = bufferArray[0].0.origin.y
                bufferArray.remove(at: 0)
                addedToBufferHolder = true
            } else {
                addedToBufferHolder = false
            }
        }
        originY += insets.top + interItemSpacing
        return CGRect(x: originX, y: originY, width: cellWidth, height: cellHeight)
    }
    
    private func addToBufferArray(bufferIndex: Int, calulatedOriginX: CGFloat, regularSize: CGSize, interItemSpacing: CGFloat, column: Int, originY: CGFloat, cellSize: CGSize) {
        let originX = calulatedOriginX + (CGFloat(bufferIndex-1) * regularSize.width) + (interItemSpacing * CGFloat(bufferIndex-1))
        var bufferObjectOrigin = CGRect(x: originX, y: originY, width: cellSize.width, height: cellSize.height)
        
        for bufferObject in bufferArray {
            if bufferObject.0.equalTo(bufferObjectOrigin) {
                bufferObjectOrigin.origin.y += regularSize.height
            }
        }
        let bufferObject = (bufferObjectOrigin, (column + bufferIndex - 1))
        bufferArray.append(bufferObject)
    }
    
    private func getLayoutAttributesForSupplementaryViewOfKind(kind: String, indexPath: IndexPath, insets: UIEdgeInsets, width: CGFloat) -> UICollectionViewLayoutAttributes {
        let layoutAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: kind, with: indexPath)
        let yOrigin = verticalOffsetForSection(section: indexPath.section)
        let sectionWidth = width - insets.left - insets.right
        var height: CGFloat = 0
        
        if kind == UICollectionElementKindSectionHeader {
            height += heightForHeaderInSection(section: indexPath.section)
        } else if kind == UICollectionElementKindSectionFooter {
            height += heightForFooterInSection(section: indexPath.section)
        }
        
        let tallestColumn = indexOfTallestColumnInSection(indexPath.section)
        let columnHeight = columnHeightsPerSection[indexPath.section][tallestColumn]
        layoutAttributes.frame = CGRect(x: insets.left, y: yOrigin + columnHeight, width: sectionWidth, height: height)
        layoutAttributes.zIndex = 1
        
        supplementaryAttributes[indexPath] = layoutAttributes
        return layoutAttributes
    }
    
    //MARK: Cell Size calucators
    fileprivate func cellSizeForIndexPath(_ indexPath: IndexPath, itemSize: ItemSizeAttributes, interItemSpacing: CGFloat, insets: UIEdgeInsets) -> CGSize {
        var cellHeight = itemSize.itemSize.height
        var cellWidth = itemSize.itemSize.width
        let cellSize = regularCellSize(indexPath, interItemSpacing: interItemSpacing, insets: insets)
        
        if itemSize.layoutSize == .large {
            cellWidth = cellSize.width * CGFloat(itemSize.widthFactor)
            cellWidth += interItemSpacing * CGFloat(itemSize.widthFactor - 1)
            cellHeight = cellHeight * CGFloat(itemSize.heightFactor)
        } else {
            cellWidth = cellSize.width
        }
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    fileprivate func regularCellSize(_ indexPath: IndexPath, interItemSpacing: CGFloat, insets: UIEdgeInsets) -> CGSize {
        let regularCellWidth = (collectionViewContentWidth() - insets.right - insets.left - (interItemSpacing * CGFloat(numRegularCells)))/CGFloat(numRegularCells)
        
        return CGSize(width: regularCellWidth, height: sizeForItemAtIndexPath(indexPath).itemSize.height)
    }
    
    private func collectionViewContentWidth() -> CGFloat {
        return self.collectionView!.frame.size.width
    }
    
    // MARK: Helpers
    private func indexOfShortestColumnInSection(_ section: NSInteger) -> NSInteger {
        var indexOfShortestColumn: NSInteger = 0
        var shortestHeight = CGFloat.greatestFiniteMagnitude
        
        for (idx, height) in columnHeightsPerSection[section].enumerated() {
            if height < shortestHeight {
                shortestHeight = height
                indexOfShortestColumn = idx
            }
        }
        return indexOfShortestColumn
    }
    
    private func indexOfShortestColumnBeforeColumn(_ index: Int, section: Int) -> Int {
        let columnHeights = columnHeightsPerSection[section]
        var indexOfShortestColumn: NSInteger = 0
        
        for i in 1 ..< index {
            if (Float(columnHeights[i] as NSNumber) < Float(columnHeights[indexOfShortestColumn] as NSNumber)){
                indexOfShortestColumn = i
            }
        }
        return indexOfShortestColumn
    }
    
    private func indexOfShortestColumnAfterColumn(_ index: Int, section: Int) -> Int {
        let columnHeights = columnHeightsPerSection[section]
        var indexOfShortestColumn: NSInteger = index + 1
        
        for i in index+1 ..< columnHeights.count {
            if (Float(columnHeights[i] as NSNumber) < Float(columnHeights[indexOfShortestColumn] as NSNumber)){
                indexOfShortestColumn = i
            }
        }
        return indexOfShortestColumn
    }
    
    private func indexOfTallestColumnInSection(_ section: NSInteger) -> NSInteger {
        var indexOfTallestColumn: NSInteger = 0
        var longestHeight: CGFloat = 0.0
        
        for (idx, height) in columnHeightsPerSection[section].enumerated() {
            if height > longestHeight {
                longestHeight = height
                indexOfTallestColumn = idx
            }
        }
        
        return indexOfTallestColumn
    }
    
    private func canFitInShortestColumn(_ index: Int, section: Int, widthFactor: Int) -> Bool {
        let columnHeight = columnHeightsPerSection[section][index]
        var canFit = true
        for i in 1 ..< widthFactor {
            if columnHeight != columnHeightsPerSection[section][index + i] {
               canFit = false
            }
        }
        return canFit
    }
    
    private func verticalOffsetForSection(section: Int) -> CGFloat {
        var yOffset: CGFloat = 0
        
        for i in 0 ..< section {
            yOffset += columnHeightsPerSection[i][indexOfTallestColumnInSection(i)]
        }
        return yOffset
    }
    
    fileprivate func numberOfRegularCellsInSection(_ section: Int, width: CGFloat, interItemSpacing: CGFloat, insets: UIEdgeInsets) -> Int {
        let cellWidth = sizeForItemAtIndexPath(IndexPath(item: 0, section: section)).itemSize.width
        return Int(((width - insets.right - insets.left - interItemSpacing ) / cellWidth))
    }
    
    private func increaseAllColumnHeightsBy(_ height: CGFloat, section: Int) {
        var columnHeights = columnHeightsPerSection[section]
        for idx in 0 ..< columnHeights.count {
            columnHeights[idx] += height
        }
        columnHeightsPerSection[section] = columnHeights
    }
    
    //MARK: Custom UICollectionViewDelegate data fetching functions.
    fileprivate func sizeForItemAtIndexPath(_ indexPath:IndexPath) -> ItemSizeAttributes {
        if delegate != nil {
            return delegate!.collectionView(collectionView!, layout: FlexiCollectionViewLayout(), sizeForFlexiItemAt: indexPath)
        }
        return ItemSizeAttributes(itemSize: CGSize(width: 50, height: 50), layoutSize: FlexiCellSize.regular, widthFactor: 1, heightFactor: 1)
    }
    
    fileprivate func interitemSpacingForSectionAtIndex(_ index: Int) -> CGFloat {
        if delegate != nil {
            return delegate!.collectionView!(collectionView!, layout: self, minimumInteritemSpacingForSectionAt: index)
        }
        return 2
    }
    
    fileprivate func insetForSectionAtIndex(_ index: Int) -> UIEdgeInsets {
        if delegate != nil {
            return delegate!.collectionView!(collectionView!, layout: self, insetForSectionAt: index)
        }
        return UIEdgeInsets.zero
    }
    
    private func heightForHeaderInSection(section: Int) -> CGFloat {
        if let flexiDelegate = delegate, let height = flexiDelegate.collectionView?(self.collectionView!, layout: self, heightForHeaderInSection: section) {
            return height
        }
        return 0
    }
    
    private func heightForFooterInSection(section: Int) -> CGFloat {
        if let flexiDelegate = delegate, let height = flexiDelegate.collectionView?(self.collectionView!, layout: self, heightForFooterInSection: section) {
            return height
        }
        return 0
    }
    
    //MARK: Reset
    private func resetLayout() {
        columnHeightsPerSection.removeAll()
        layoutInfo.removeAll()
        supplementaryAttributes.removeAll()
        bufferArray.removeAll(keepingCapacity: false)
    }
}
