//
//  AudioManager.swift
//  Agar
//
//  Created by Stephannie M. Linggo on 18/11/26.
//

import Foundation
import AVFoundation

class AudioManager {

    private var audioPlayer: AVAudioPlayer?

    func playSound(_ filename: String) async {
        guard let audioURL = Bundle.main.url(
            forResource: filename,
            withExtension: "mp3"
        ) else {
            print("Audio file not found: \(filename)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Audio playback error: \(error.localizedDescription)")
        }
    }

    func stopSound() {
        audioPlayer?.stop()
    }
}
