// 通过 iPad 内置扬声器生成基于独立系统音效服务的极短低频触觉脉冲
import AudioToolbox
import AVFAudio
import Foundation

// 管理完全脱离媒体总线、不干扰外部音频输出的低频脉冲
@MainActor
final class SpeakerPulse {
    private var cachedSounds: [Int: SystemSoundID] = [:]

    // 在允许的音频路由上播放单次脉冲
    func play(enabled: Bool, fullAccess: Bool, intensity: Double = 0.6) {
        guard enabled, fullAccess else { return }
        let session = AVAudioSession.sharedInstance()
        guard isBuiltIn(session.currentRoute) else { return }

        // 将强度量化为 1~10 档（对应 10% ~ 100%），方便系统音效精准复用与缓存
        let step = max(1, min(10, Int(round(intensity * 10))))
        let soundID = getOrCreateSoundID(forStep: step)
        guard soundID != 0 else { return }

        AudioServicesPlaySystemSound(soundID)
    }

    // 确认当前仅使用设备内置扬声器
    private func isBuiltIn(_ route: AVAudioSessionRouteDescription) -> Bool {
        !route.outputs.isEmpty && route.outputs.allSatisfy { $0.portType == .builtInSpeaker }
    }

    // 获取或创建对应强度的独立系统音效 ID
    private func getOrCreateSoundID(forStep step: Int) -> SystemSoundID {
        if let existing = cachedSounds[step] {
            return existing
        }

        let intensityDouble = Double(step) / 10.0
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("haptic_pulse_\(step).wav")

        if !FileManager.default.fileExists(atPath: tempURL.path) {
            let wavData = makeWavData(intensity: intensityDouble)
            do {
                try wavData.write(to: tempURL, options: .atomic)
            } catch {
                return 0
            }
        }

        var soundID: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(tempURL as CFURL, &soundID)
        guard status == kAudioServicesNoError else { return 0 }

        // 设置 isUISound = 0：即使系统设置中关闭了键盘打字声/UI音效，触感脉冲也依然发声生效
        var isUI: UInt32 = 0
        AudioServicesSetProperty(
            kAudioServicesPropertyIsUISound,
            UInt32(MemoryLayout.size(ofValue: soundID)),
            &soundID,
            UInt32(MemoryLayout.size(ofValue: isUI)),
            &isUI
        )

        // 设置 completePlaybackIfAppDies = 1：确保 14ms 的短波形即使在瞬态下也能平稳播放完毕
        var completeIfDies: UInt32 = 1
        AudioServicesSetProperty(
            kAudioServicesPropertyCompletePlaybackIfAppDies,
            UInt32(MemoryLayout.size(ofValue: soundID)),
            &soundID,
            UInt32(MemoryLayout.size(ofValue: completeIfDies)),
            &completeIfDies
        )

        cachedSounds[step] = soundID
        return soundID
    }

    // 动态合成 14ms 72Hz 低频正弦波并生成标准 16-bit PCM WAV 数据
    private func makeWavData(intensity: Double) -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 0.014
        let frequency: Double = 72.0
        let numSamples = Int(sampleRate * duration)
        let dataSize = numSamples * 2
        let chunkSize = 36 + dataSize

        var data = Data()
        data.reserveCapacity(44 + dataSize)

        // RIFF 标头
        data.append(contentsOf: [UInt8]("RIFF".utf8))
        var v32 = UInt32(chunkSize).littleEndian
        data.append(Data(bytes: &v32, count: 4))
        data.append(contentsOf: [UInt8]("WAVE".utf8))

        // fmt 子块
        data.append(contentsOf: [UInt8]("fmt ".utf8))
        var subchunk1Size = UInt32(16).littleEndian
        data.append(Data(bytes: &subchunk1Size, count: 4))
        var audioFormat = UInt16(1).littleEndian
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels = UInt16(1).littleEndian
        data.append(Data(bytes: &numChannels, count: 2))
        var sRate = UInt32(sampleRate).littleEndian
        data.append(Data(bytes: &sRate, count: 4))
        var byteRate = UInt32(sampleRate * 2).littleEndian
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(2).littleEndian
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample = UInt16(16).littleEndian
        data.append(Data(bytes: &bitsPerSample, count: 2))

        // data 子块
        data.append(contentsOf: [UInt8]("data".utf8))
        var dSize = UInt32(dataSize).littleEndian
        data.append(Data(bytes: &dSize, count: 4))

        // 72Hz 正弦脉冲配合半正弦平滑窗：
        // 消除高频杂音，将声学能量集中于扬声器纸盆冲程机械冲击
        let maxAmp = max(0.1, min(1.0, intensity)) * 32767.0
        for i in 0 ..< numSamples {
            let t = Double(i) / sampleRate
            let progress = Double(i) / Double(numSamples)
            let env = sin(.pi * progress)
            let sampleVal = Int16(sin(2.0 * .pi * frequency * t) * env * maxAmp)
            var s = sampleVal.littleEndian
            data.append(Data(bytes: &s, count: 2))
        }
        return data
    }
}
