//
//  ContentView.swift
//  Microphone Detector
//
//  Created by Mazen Chami on 4/2/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var isStreaming: Bool = false
    @StateObject private var audioProcessor = AudioProcessor()
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isStreaming ? "Streaming..." : "Not Streaming")
                .foregroundColor(isStreaming ? .green : .red)
                .font(.title)
            
            Button(action: {
                if self.isStreaming {
                    self.audioProcessor.stopAudioEngine()
                } else {
                    self.audioProcessor.startAudioEngine()
                }
                self.isStreaming.toggle()
            }) {
                Text(isStreaming ? "Stop Streaming" : "Start Streaming")
                    .foregroundColor(.white)
                    .padding()
                    .background(isStreaming ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            self.audioProcessor.requestMicrophoneAccess()
        }
    }
//    @StateObject private var audioRecorder = AudioRecorder()
//        
//        var body: some View {
//            VStack {
//                Image(systemName: "mic.fill")
//                    .imageScale(.large)
//                    .foregroundColor(audioRecorder.isRecording ? .red : .blue)
//                Text(audioRecorder.isRecording ? "Recording..." : "Tap to Record")
//                Button(action: {
//                    if audioRecorder.isRecording {
//                        audioRecorder.toggleRecording()
//                    } else {
//                        audioRecorder.checkPermissionAndSetupRecorder()
//                        audioRecorder.toggleRecording()
//                    }
//                }) {
//                    Text(audioRecorder.isRecording ? "Stop" : "Start Recording")
//                        .foregroundColor(.white)
//                        .padding()
//                        .background(audioRecorder.isRecording ? Color.red : Color.blue)
//                        .cornerRadius(8)
//                }
//            }
//            .padding()
//        }
}

#Preview {
    ContentView()
}
