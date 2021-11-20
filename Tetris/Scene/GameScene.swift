//
//  GameScene.swift
//  Tetris
//
//  Created by John Lee on 2021/11/16.
//

import SpriteKit
import GameplayKit

let TickLengthLevelOne = TimeInterval(600)
let BlockSize: CGFloat = 20

/// 游戏场景
class GameScene: SKScene {
    /// 时钟回调
    var tick:(()-> Void)?
    /// 时钟长度
    var tickLengthMillis = TickLengthLevelOne
    /// 最后时钟的时间
    var lastTick: NSDate?
    /// 游戏层
    let gameLayer = SKNode()
    /// 形状层
    let shapeLayer = SKNode()
    /// 形状层位置
    let LayerPosition = CGPoint(x: 6, y: -6)
    /// 材质图片缓存
    var textureCache = Dictionary<String, SKTexture>()
    
    /// 必要初始化(用以实现反序列化) Called when a node is initialized from an .sks file.
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        // 锚点位置为frame左上角
        anchorPoint = CGPoint(x: 0, y: 1)
        // 设置背景
        let backgroundTexture = SKTexture(imageNamed: "background" )
        let background = SKSpriteNode(texture: backgroundTexture, size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        background.position = CGPoint(x: 0, y: 0)
        background.anchorPoint = CGPoint(x: 0, y: 1.0)
        
        addChild(background)
        addChild(gameLayer)
        
        // 游戏画板
        let gameBoardTexture = SKTexture(imageNamed: "gameboard")
        let gameBoard = SKSpriteNode(texture: gameBoardTexture, size: CGSize(width: BlockSize * CGFloat(NumColumns), height: BlockSize * CGFloat(NumRows - 2)))
        gameBoard.anchorPoint = CGPoint(x: 0, y: 1.0)
        gameBoard.position = CGPoint(x: 6, y: -48)
        
        shapeLayer.position = LayerPosition
        shapeLayer.addChild(gameBoard)
        
        gameLayer.addChild(shapeLayer)
        
        // 播放背景音乐
        Audio.sharedInstance.playSound(soundFileName: Sound.theme.fileName)
        Audio.sharedInstance.player(with: Sound.theme.fileName)?.volume = 0.3
        Audio.sharedInstance.player(with: Sound.theme.fileName)?.numberOfLoops = -1
    }
    
    /// 播放声音
    /// - Parameter sound: 声音文件名称
    func playSound(sound: String) {
        run(SKAction.playSoundFileNamed(sound, waitForCompletion: false))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        // 确保lastTick存在
        guard let lastTick = lastTick else {
            return
        }
        
        // 计算已过时间
        let timePassed = lastTick.timeIntervalSinceNow * -1000.0
        
        // 如果已过时间大于时钟时长, 则回调时钟
        if timePassed > tickLengthMillis {
            self.lastTick = NSDate()
            tick?()
        }
    }
    
    /// 开始时钟 ( 将时钟时间设置当前时间 )
    func startTicking() {
        lastTick = NSDate()
    }
    
    /// 停止时钟 ( 将时钟时间设置为空 )
    func stopTicking() {
        lastTick = nil
    }
    
    /// 根据行列位置计算计算游戏画板上对应的位置
    func pointForColumn(column: Int, row: Int) -> CGPoint {
        let x = LayerPosition.x + (CGFloat(column) * BlockSize) + (BlockSize / 2)
        let y = LayerPosition.y - ((CGFloat(row) * BlockSize) + (BlockSize / 2))
    
        return CGPoint(x: x, y: y)
    }
    
    /// 添加预览形状到场景中
    /// - Parameters:
    ///   - shape: 形状
    ///   - completion: 完成回调
    func addPreviewShapeToScene(shape: Shape, completion: @escaping () -> Void) {
        for block in shape.blocks {
            // 创建形状
            var texture = textureCache[block.spriteName]
            
            if texture == nil {
                texture = SKTexture(imageNamed: block.spriteName)
                textureCache[block.spriteName] = texture
            }
            
            let sprite = SKSpriteNode(texture: texture)
            
            // 初始位置
            sprite.position = pointForColumn(column: block.column, row: block.row - 2)
            shapeLayer.addChild(sprite)
            block.sprite = sprite
            
            // 出现动画
            sprite.alpha = 0
            let moveAction = SKAction.move(to: pointForColumn(column: block.column, row: block.row), duration: TimeInterval(0.2))
            moveAction.timingMode = .easeOut
            
            let fadeInAction = SKAction.fadeAlpha(to: 0.7, duration: 0.4)
            fadeInAction.timingMode = .easeOut
            
            sprite.run(SKAction.group([moveAction, fadeInAction]))
        }
        
        run(SKAction.wait(forDuration: 0.4), completion: completion)
    }
    
    /// 移动预览形状
    /// - Parameters:
    ///   - shape: 形状
    ///   - completion: 完成回调
    func movePreviewShape(shape: Shape, completion: @escaping () -> Void) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(column: block.column, row: block.row)
            let moveToAction: SKAction = SKAction.move(to: moveTo, duration: 0.2)
            
            moveToAction.timingMode = .easeOut
            sprite.run(SKAction.group([moveToAction, SKAction.fadeAlpha(to: 1.0, duration: 0.2)]), completion: {})
        }
        
        run(SKAction.wait(forDuration: 0.2), completion: completion)
    }
    
    /// 重绘制形状
    /// - Parameters:
    ///   - shape: 形状
    ///   - completion: 完成回调
    func redrawShape(shape: Shape, completion: @escaping () -> Void) {
        for block in shape.blocks {
            let sprite = block.sprite!
            let moveTo = pointForColumn(column: block.column, row: block.row)
            let moveToAction: SKAction = SKAction.move(to: moveTo, duration: 0.05)
            
            moveToAction.timingMode = .easeOut
            
            if block == shape.blocks.last {
                sprite.run(moveToAction, completion: completion)
            } else {
                sprite.run(moveToAction)
            }
        }
    }
    
    /// 消除行动画
    /// - Parameters:
    ///   - linesToRemove: 待移除的行
    ///   - fallenBlocks: 下落行
    ///   - completion: 完成回调
    func animateCollapsingLines(linesToRemove: Array<Array<Block>>, fallenBlocks: Array<Array<Block>>, completion:@escaping () -> Void) {
        var longestDuration: TimeInterval = 0
        // #2
        for (columnIdx, column) in fallenBlocks.enumerated() {
            for (blockIdx, block) in column.enumerated() {
                let newPosition = pointForColumn(column: block.column, row: block.row)
                let sprite = block.sprite!
                // #3
                let delay = (TimeInterval(columnIdx) * 0.05) + (TimeInterval(blockIdx) * 0.05)
                let duration = TimeInterval(((sprite.position.y - newPosition.y) / BlockSize) * 0.1)
                let moveAction = SKAction.move(to: newPosition, duration: duration)
                moveAction.timingMode = .easeOut
                sprite.run(
                    SKAction.sequence([
                                        SKAction.wait(forDuration: delay),
                                        moveAction]))
                longestDuration = max(longestDuration, duration + delay)
            }
        }
        
        for rowToRemove in linesToRemove {
            for block in rowToRemove {
                // #4
                let randomRadius = CGFloat(UInt(arc4random_uniform(400) + 100))
                let goLeft = arc4random_uniform(100) % 2 == 0
                
                var point = pointForColumn(column: block.column, row: block.row)
                point = CGPoint(x: point.x + (goLeft ? -randomRadius : randomRadius), y: point.y)
                
                let randomDuration = TimeInterval(arc4random_uniform(2)) + 0.5
                // #5
                var startAngle = CGFloat(Double.pi)
                var endAngle = startAngle * 2
                if goLeft {
                    endAngle = startAngle
                    startAngle = 0
                }
                let archPath = UIBezierPath(arcCenter: point, radius: randomRadius, startAngle: startAngle, endAngle: endAngle, clockwise: goLeft)
                let archAction = SKAction.follow(archPath.cgPath, asOffset: false, orientToPath: true, duration: randomDuration)
                archAction.timingMode = .easeIn
                let sprite = block.sprite!
                // #6
                sprite.zPosition = 100
                sprite.run(
                    SKAction.sequence(
                        [SKAction.group([archAction, SKAction.fadeOut(withDuration: TimeInterval(randomDuration))]),
                         SKAction.removeFromParent()]))
            }
        }
        // #7
        run(SKAction.wait(forDuration: longestDuration), completion: completion)
    }
}
