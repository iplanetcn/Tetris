//
//  Tetris.swift
//  Tetris
//
//  Created by John Lee on 2021/11/16.
//

import Foundation
import SpriteKit

// 游戏区域行列数
let NumColumns = Int(UIScreen.main.bounds.width / 32)
let NumRows = Int(UIScreen.main.bounds.height / 28.4)

// 开始行列位置
let StartingColumn = 4
let StartingRow = 2

// 预览区行列位置
let PreviewColumn = NumColumns + 3
let PreviewRow = 2

/// 消除一行的分数
let PointsPerLine = 10
/// 关卡升级阈值
let LevelThreshold = 100

/// Tetris代理
protocol TetrisDelegate {
    /// 游戏开始
    func gameDidBegin(tetris: Tetris)
    /// 游戏结束
    func gameDidEnd(tetris: Tetris)
    func gameShapeDidLand(tetris: Tetris)
    func gameShapeDidMove(tetris: Tetris)
    func gameShapeDidDrop(tetris: Tetris)
    func gameDidLevelUp(tetris: Tetris)
}

class Tetris {
    /// 形状块数据
    var blockArray: Array2D<Block>
    /// 下一个形状
    var nextShape: Shape?
    /// 正在下落的形状
    var fallingShape: Shape?
    /// 代理
    var delegate: TetrisDelegate?
    /// 分数
    var score = 0
    /// 等级(等级越高,下落速度越快)
    var level = 1
    
    init() {
        fallingShape = nil
        nextShape = nil
        blockArray = Array2D<Block>(columns: NumColumns, rows: NumRows)
        print("columns: \(NumColumns), rows: \(NumRows)")
    }
    
    func beginGame() {
        // 初始化下一个形状
        if nextShape == nil {
            nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
        }
        delegate?.gameDidBegin(tetris: self)
    }
    
    func newShape() -> (fallingShape: Shape?, nextShape: Shape?) {
        fallingShape = nextShape
        
        nextShape = Shape.random(startingColumn: PreviewColumn, startingRow: PreviewRow)
        
        fallingShape?.moveTo(column: StartingColumn, row: StartingRow)
        
        guard detectIllegalPlacement() == false else {
            nextShape = fallingShape
            nextShape!.moveTo(column: PreviewColumn, row: PreviewRow)
            endGame()
            return (nil, nil)
        }
        
        return (fallingShape, nextShape)
    }
    
    func detectIllegalPlacement() -> Bool {
        guard let shape = fallingShape else {
            return false
        }
        
        for block in shape.blocks {
            if block.column < 0 || block.column >= NumColumns || block.row < 0 || block.row >= NumRows {
                return true
            } else if blockArray[block.column, block.row] != nil {
                return true
            }
        }
        return false
    }
    
    func dropShape() {
        guard let shape = fallingShape else {
            return
        }
        
        while detectIllegalPlacement() == false {
            shape.lowerShapeByOneRow()
        }
        
        shape.raiseShapeByOneRow()
        delegate?.gameShapeDidDrop(tetris: self)
    }
    
    func letShapeFall() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.lowerShapeByOneRow()
        if detectIllegalPlacement() {
            shape.raiseShapeByOneRow()
            if detectIllegalPlacement() {
                endGame()
            } else {
                settleShape()
            }
        } else {
            delegate?.gameShapeDidMove(tetris: self)
            
            if detectTouch() {
                settleShape()
            }
        }
    }
    
    func rotateShape() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.rotateClockwise()
        
        guard detectIllegalPlacement() == false else {
            shape.rotateClockwise()
            return
        }
        
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    func moveShapeLeft() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftLeftByOneColumn()
        guard detectIllegalPlacement() == false else {
            shape.shiftRightByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    func moveShapeRight() {
        guard let shape = fallingShape else {
            return
        }
        
        shape.shiftRightByOneColumn()
        
        guard detectIllegalPlacement() == false else {
            shape.shiftLeftByOneColumn()
            return
        }
        delegate?.gameShapeDidMove(tetris: self)
    }
    
    func settleShape() {
        guard let shape = fallingShape else {
            return
        }
        
        for block in shape.blocks {
            blockArray[block.column, block.row] = block
        }
        
        fallingShape = nil
        delegate?.gameShapeDidLand(tetris: self)
    }
    
    func detectTouch() -> Bool {
        guard let shape = fallingShape else {
            return false
        }
        
        for bottomBlock in shape.bottomBlocks {
            if bottomBlock.row == NumRows - 1 || blockArray[bottomBlock.column, bottomBlock.row + 1] != nil {
                return true
            }
        }
        
        return false
    }
    
    func endGame() {
        score = 0
        level = 1
        delegate?.gameDidEnd(tetris: self)
    }
    
    func removeCompleteLines() -> (linesRemoved: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>) {
        var removedLines = Array<Array<Block>>()
        
        for row in (1..<NumRows).reversed() {
            var rowOfBlocks = Array<Block>()
            
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    continue
                }
                rowOfBlocks.append(block)
            }
            
            if rowOfBlocks.count == NumColumns {
                removedLines.append(rowOfBlocks)
                for block in rowOfBlocks {
                    blockArray[block.column, block.row] = nil
                }
            }
        }
        
        if removedLines.count == 0 {
            return ([], [])
        }
        
        let pointsEarned = removedLines.count * PointsPerLine * level
        
        score += pointsEarned
        
        if score >= level * LevelThreshold {
            level += 1
            delegate?.gameDidLevelUp(tetris: self)
        }
        
        var fallenBlocks = Array<Array<Block>>()
        
        for column in 0..<NumColumns {
            var fallenBlocksArray = Array<Block>()
            
            for row in (1..<removedLines[0][0].row).reversed() {
                guard let block = blockArray[column, row] else {
                    continue
                }
                
                var newRow = row
                while (newRow < NumRows - 1 && blockArray[column, newRow + 1] == nil) {
                    newRow += 1
                }
                
                block.row = newRow
                blockArray[column, row] = nil
                blockArray[column, newRow] = block
                fallenBlocksArray.append(block)
            }
            if fallenBlocksArray.count > 0 {
                fallenBlocks.append(fallenBlocksArray)
            }
        }
        
        return (removedLines, fallenBlocks)
    }
    
    func removeAllBlocks() -> Array<Array<Block>> {
        var allBlocks = Array<Array<Block>>()
        for row in 0..<NumRows {
            var rowOfBlocks = Array<Block>()
            for column in 0..<NumColumns {
                guard let block = blockArray[column, row] else {
                    continue
                }
                rowOfBlocks.append(block)
                blockArray[column, row] = nil
            }
            allBlocks.append(rowOfBlocks)
        }
        return allBlocks
    }
    
    func pauseGame() {
        print("Game is paused")
    }
}
