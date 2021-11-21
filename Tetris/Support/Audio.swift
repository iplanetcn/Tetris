//
//  Audio.swift
//  Tetris
//
//  Created by John Lee on 2021/11/16.
//

import Foundation
import AVFoundation

class Audio: NSObject, AVAudioPlayerDelegate {
    static let sharedInstance = Audio()

    var players: [URL: AVAudioPlayer] = [:]
    var duplicatePlayers: [AVAudioPlayer] = []

    private override init() {
    }


    func player(with soundFileName: String) -> AVAudioPlayer? {
        guard let bundle = Bundle.main.path(forResource: soundFileName, ofType: nil) else {
            return nil
        }

        let soundFileNameURL = URL(fileURLWithPath: bundle)

        return players[soundFileNameURL]
    }

    func playSound(soundFileName: String) {
        guard let bundle = Bundle.main.path(forResource: soundFileName, ofType: nil) else {
            return
        }
        let soundFileNameURL = URL(fileURLWithPath: bundle)

        if let player = players[soundFileNameURL] {
            // player for sound has been found
            if !player.isPlaying {
                // player is not in use, so use the one
                player.prepareToPlay()
                player.play()
            } else {
                // player is in use, create a new, duplicate, player and use that instead
                do {
                    let duplicatePlayer = try AVAudioPlayer(contentsOf: soundFileNameURL)

                    // assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing
                    duplicatePlayer.delegate = self

                    // add duplicate to array so it doesn't get removed from memory before finishing
                    duplicatePlayers.append(duplicatePlayer)

                    duplicatePlayer.prepareToPlay()
                    duplicatePlayer.play()

                } catch let error {
                    print(error.localizedDescription)
                }
            }
        } else {
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileNameURL)
                players[soundFileNameURL] = player
                player.prepareToPlay()
                player.play()
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    func playSounds(soundFileNames: [String]) {
        for soundFileName in soundFileNames {
            playSound(soundFileName: soundFileName)
        }
    }

    /// Play sounds with a delay
    /// - Parameters:
    ///   - soundFileNames: Array of sound file names
    ///   - withDelay: Delay in seconds
    func playSounds(soundFileNames: [String], withDelay: Double) {
        for (index, soundFileName) in soundFileNames.enumerated() {
            let delay = withDelay * Double(index)
            let _ = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(playSoundNotification(_:)), userInfo: ["fileName": soundFileName], repeats: false)

        }
    }

    @objc func playSoundNotification(_ notification: NSNotification) {
        if let soundFileName = notification.userInfo?["fileName"] as? String {
            playSound(soundFileName: soundFileName)
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let index = duplicatePlayers.firstIndex(of: player) {
            duplicatePlayers.remove(at: index)
        }
    }

}
