import Foundation
import Capacitor
import Photos
import UIKit
import Speech
import AVFoundation

/**
 * OukekSpeech for handling speech-related operations
 */
class SpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?
    private var recordingSession: String?
    private var tempURL: URL?
    private var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    
    override init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        super.init()
        self.speechRecognizer?.delegate = self
    }
    
    func startRecording() throws -> String {
        // 清理之前的任务
        if isRecording {
            try stopRecording()
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 创建新的录音会话ID
        recordingSession = UUID().uuidString
        
        // 创建临时文件URL
        let tempDirectory = FileManager.default.temporaryDirectory
        tempURL = tempDirectory.appendingPathComponent("\(recordingSession!).wav")
        
        // 设置录音格式
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        // 创建录音机
        audioRecorder = try AVAudioRecorder(url: tempURL!, settings: settings)
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        isRecording = true
        
        return recordingSession!
    }
    
    func stopRecording() throws -> String {
        guard isRecording else {
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not recording"])
        }
        
        // 停止录音
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        guard let url = tempURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else {
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio data available"])
        }
        
        // 将音频数据转换为 base64
        let base64String = data.base64EncodedString()
        
        // 清理数据
        try? FileManager.default.removeItem(at: url)
        tempURL = nil
        
        return base64String
    }
    
    func recognize(audioBase64: String, locale: String) async throws -> String {
        guard let audioData = Data(base64Encoded: audioBase64) else {
            throw NSError(domain: "SpeechRecognizer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 audio data"])
        }
        
        // 创建临时文件来存储音频数据
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFile = tempDirectory.appendingPathComponent(UUID().uuidString + ".wav")
        try audioData.write(to: tempFile)
        
        return try await withCheckedThrowingContinuation { continuation in
            let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) ?? speechRecognizer
            guard let recognizer = recognizer, recognizer.isAvailable else {
                try? FileManager.default.removeItem(at: tempFile)
                continuation.resume(throwing: NSError(domain: "SpeechRecognizer", code: -1, 
                    userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
                return
            }
            
            let request = SFSpeechURLRecognitionRequest(url: tempFile)
            request.shouldReportPartialResults = false
            request.taskHint = .dictation
            
            recognizer.recognitionTask(with: request) { result, error in
                // 识别完成后删除临时文件
                try? FileManager.default.removeItem(at: tempFile)
                
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let result = result {
                    if result.bestTranscription.formattedString.isEmpty {
                        continuation.resume(throwing: NSError(domain: "SpeechRecognizer", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "No speech detected in the audio"]))
                    } else {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    }
                } else {
                    continuation.resume(throwing: NSError(domain: "SpeechRecognizer", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "No recognition result available"]))
                }
            }
        }
    }
}

@objc(OukekSpeech)
public class OukekSpeech: CAPPlugin {
    private var speechRecognizer: SpeechRecognizer?
    
    override public func load() {
        speechRecognizer = SpeechRecognizer()
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppLaunch),
                                            name: UIApplication.didFinishLaunchingNotification,
                                            object: nil)
        
        // 请求麦克风权限
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                }
            }
        }
        
        // 请求语音识别权限
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied:
                    print("Speech recognition authorization denied")
                case .restricted:
                    print("Speech recognition not available on this device")
                case .notDetermined:
                    print("Speech recognition not determined")
                @unknown default:
                    print("Speech recognition unknown status")
                }
            }
        }
    }
    
    @objc func startRecording(_ call: CAPPluginCall) {
        do {
            try speechRecognizer?.startRecording()
        } catch {
            call.reject("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    @objc func stopRecording(_ call: CAPPluginCall) {
        do {
            let audioBase64 = try speechRecognizer?.stopRecording()
            call.resolve(["audioBase64": audioBase64 ?? ""])
        } catch {
            call.reject("Failed to stop recording: \(error.localizedDescription)")
        }
    }
    
    @objc func recognize(_ call: CAPPluginCall) {
        guard let audioBase64 = call.getString("audioBase64") else {
            call.reject("Audio data is required")
            return
        }
        
        let locale = call.getString("locale") ?? "zh-CN"
        
        Task {
            do {
                let result = try await speechRecognizer?.recognize(audioBase64: audioBase64, locale: locale)
                DispatchQueue.main.async {
                    call.resolve(["text": result ?? ""])
                }
            } catch {
                DispatchQueue.main.async {
                    call.reject("Recognition failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func handleAppLaunch(_ notification: Notification) {
        print("OukekSpeech: App launched")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
