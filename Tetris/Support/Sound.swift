//
//  Sound.swift
//  Tetris
//
//  Created by John Lee on 2021/11/16.
//

import Foundation

enum Sound: String {
    case drop = "drop.mp3"
    case levelup = "levelup.mp3"
    case gameover = "gameover.mp3"
    case theme = "theme.mp3"
    case bomb = "bomb.mp3"
    
    var fileName: String {
        return rawValue
    }
}
