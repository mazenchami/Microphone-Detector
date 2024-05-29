//
//  AudioProcessor.swift
//  Microphone Detector
//
//  Created by Mazen Chami on 4/2/24.
//

import Foundation
import AVFoundation
import Combine

class AudioProcessor: ObservableObject {
    let audioEngine = AVAudioEngine()
    let inputNode: AVAudioInputNode
    var audioFormat: AVAudioFormat?
    var isRecording = false
    var isTapInstalled = false
    let threshold: Float = 0.01 // Define an appropriate threshold for your application.

    init() {
        inputNode = audioEngine.inputNode
        audioFormat = inputNode.inputFormat(forBus: 0) // Default format
    }

    func requestMicrophoneAccess() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            startAudioEngine()
        case .denied:
            // Handle denied permissions
            print("Permission denied")
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.startAudioEngine()
                    }
                } else {
                    // Handle denied permissions
                    print("Permission denied")
                }
            }
        @unknown default:
            fatalError("Unknown case of recording permission")
        }
    }

    func startAudioEngine() {
        guard !isTapInstalled else {
            print("Tap is already installed.")
            return
        }
        
        let format = inputNode.outputFormat(forBus: 0) // Use the input node's output format

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, time) in
            self.processAudioBuffer(buffer: buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
//            try AVAudioSession.sharedInstance().setPreferredInputNumberOfChannels(2)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            isTapInstalled = true
        } catch {
            print("Error starting audio engine: \(error)")
        }
    }

    func stopAudioEngine() {
        guard isTapInstalled else {
            print("No tap to remove.")
            return
        }

        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
        isTapInstalled = false
    }

    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        let volumeEstimate = estimateVolume(buffer: buffer)
        
        if volumeEstimate > threshold {
            // The volume is above the threshold, proceed with RMS calculation.
            if let rmsValues = calculateRMS(buffer: buffer) {
                // Use rmsValues for further processing.
                // For example, determining if left or right channel is louder, etc.
                print("Left RMS: \(rmsValues.leftRMS), Right RMS: \(rmsValues.rightRMS)")
                // TODO!: print based on dominatant side
            }
        } else {
            // Volume is too low, skip further processing.
//            print("Audio too quiet, skipping RMS calculation.")
        }
    }
    
    func estimateVolume(buffer: AVAudioPCMBuffer) -> Float {
        guard let floatChannelData = buffer.floatChannelData else { return 0.0 }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }

        let channelData = floatChannelData[0] // Assuming mono or checking just one channel for simplicity.
        var volumeEstimate: Float = 0.0

        for i in stride(from: 0, to: frameLength, by: 10) { // Check every 10th sample for efficiency.
            volumeEstimate += abs(channelData[i])
        }
        volumeEstimate /= Float(frameLength / 10)

        return volumeEstimate
    }
    
    func calculateRMS(buffer: AVAudioPCMBuffer) -> (leftRMS: Float, rightRMS: Float)? {
        guard let floatChannelData = buffer.floatChannelData else { return nil }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil } // Ensure there's data to process.

        print("HII")
        print(buffer.format.channelCount)
        
        // Direct access to the channel data.
        // Since floatChannelData points to an array of pointers, access the first (left) and second (right) channel if available.
        let leftChannelData = floatChannelData[0]
        var rightChannelData: UnsafeMutablePointer<Float>?
        if buffer.format.channelCount > 1 { // Check if the second channel exists.
            rightChannelData = floatChannelData[1]
        }

        var leftRms = 0.0
        var rightRms = 0.0

        // Sum the square of each sample.
        // Process the left channel.
        for i in 0..<frameLength {
            leftRms += Double(leftChannelData[i] * leftChannelData[i])
        }

        // Process the right channel if it exists.
        if let rightChannel = rightChannelData {
            for i in 0..<frameLength {
                rightRms += Double(rightChannel[i] * rightChannel[i])
            }
        } else {
            // Handle mono audio or populate with a default value as necessary.
            rightRms = leftRms // For mono audio, you might replicate the left RMS for the right.
        }

        // Calculate mean.
        leftRms /= Double(frameLength)
        rightRms /= Double(frameLength)

        // Calculate square root of mean to get RMS.
        leftRms = sqrt(leftRms)
        rightRms = sqrt(rightRms)

        return (Float(leftRms), Float(rightRms))
    }
}
