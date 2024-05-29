//
//  AudioRecorder.swift
//  Microphone Detector
//
//  Created by Mazen Chami on 4/2/24.
//

import Foundation
import AVFoundation

class AudioRecorder: ObservableObject {
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    
    func checkPermissionAndSetupRecorder() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            setupRecorder()
        case .denied:
            // Handle denied permissions
            print("Permission denied")
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupRecorder()
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
    
    func setupRecorder() {
        let recordingSettings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ] as [String : Any]
        
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentPath.appendingPathComponent("audioRecording.pcm")
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordingSettings)
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to set up the recorder: \(error)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            audioRecorder?.stop()
            if audioRecorder?.url != nil {
                analyzeAudioFile(url: audioRecorder!.url)
            }
        } else {
            audioRecorder?.record()
        }
        isRecording = !isRecording
    }
    
    func analyzeAudioFile(url: URL) {
        let file = try? AVAudioFile(forReading: url)
        guard let audioFile = file else { return }
        
        NSLog("%@", audioFile)
        
        let leftChannelAverageVolume: Float = 0.5 // Example values
        let rightChannelAverageVolume: Float = 0.7 // Example values

        // Determine direction based on which channel is louder
        if leftChannelAverageVolume > rightChannelAverageVolume {
            print("Sound is biased to the left")
        } else if rightChannelAverageVolume > leftChannelAverageVolume {
            print("Sound is biased to the right")
        } else {
            print("Sound is centered or undetermined")
        }
    }
}

