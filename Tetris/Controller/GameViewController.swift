//
//  GameViewController.swift
//  Tetris
//
//  Created by John Lee on 2021/11/16.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController, TetrisDelegate, UIGestureRecognizerDelegate {
    var scene: GameScene!
    var tetris: Tetris!
    var panPointReference: CGPoint?

    override func viewDidLoad() {
        super.viewDidLoad()

        let skview = view as! SKView
        scene = GameScene(size: skview.bounds.size)
        scene.scaleMode = .aspectFill
        scene.tick = didTick

        skview.ignoresSiblingOrder = false
        skview.showsFPS = true
        skview.showsNodeCount = true
        skview.isMultipleTouchEnabled = true

        tetris = Tetris()
        tetris.delegate = self
        tetris.beginGame()

        // Present the scene
        skview.presentScene(scene)

        // Gesture observer
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tap)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(swipe)
    }

    func didTick() {
        tetris.letShapeFall()
    }

    func nextShape() {
        let newShapes = tetris.newShape()
        guard let fallingShape = newShapes.fallingShape else {
            return
        }

        scene.addPreviewShapeToScene(shape: newShapes.nextShape!) {}
        scene.movePreviewShape(shape: fallingShape) {
            self.view.isUserInteractionEnabled = true
            self.scene.startTicking()
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tetris.endGame()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - gestures

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UISwipeGestureRecognizer {
            if otherGestureRecognizer is UIPanGestureRecognizer {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            if otherGestureRecognizer is UITapGestureRecognizer {
                return true
            }
        }
        return false
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        let currentPoint = sender.translation(in: view)
        if let originalPoint = panPointReference {
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                if sender.velocity(in: view).x > CGFloat(0) {
                    tetris.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    tetris.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .began {
            panPointReference = currentPoint
        }
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        tetris.rotateShape()
    }

    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        tetris.dropShape()
    }

    // MARK: - Tetris delegate methods

    func gameDidBegin(tetris: Tetris) {
        scene.tickLengthMillis = TickLengthLevelOne

        // The following is false when restarting a new game
        if tetris.nextShape != nil && tetris.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(shape: tetris.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }

    func gameDidEnd(tetris: Tetris) {
        view.isUserInteractionEnabled = false
        scene.stopTicking()
        scene.playSound(sound: Sound.gameover.fileName)
        scene.animateCollapsingLines(linesToRemove: tetris.removeAllBlocks(), fallenBlocks: tetris.removeAllBlocks()) {
            tetris.beginGame()
        }
    }

    func gameShapeDidLand(tetris: Tetris) {
        scene.stopTicking()
        view.isUserInteractionEnabled = false
        let removedLines = tetris.removeCompleteLines()
        if removedLines.linesRemoved.count > 0 {
            scene.animateCollapsingLines(linesToRemove: removedLines.linesRemoved, fallenBlocks: removedLines.fallenBlocks) {
                // #11
                self.gameShapeDidLand(tetris: tetris)
            }
            scene.playSound(sound: Sound.bomb.fileName)
        } else {
            nextShape()
        }
    }

    func gameShapeDidMove(tetris: Tetris) {
        scene.redrawShape(shape: tetris.fallingShape!) {}
    }

    func gameShapeDidDrop(tetris: Tetris) {
        scene.stopTicking()
        scene.redrawShape(shape: tetris.fallingShape!) {
            tetris.letShapeFall()
        }
        scene.playSound(sound: Sound.drop.fileName)
    }

    func gameDidLevelUp(tetris: Tetris) {
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound(sound: Sound.levelup.fileName)
    }
}
