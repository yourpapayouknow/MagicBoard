// 通过 iPad 内置扬声器生成极短低频反馈
import AVFAudio

// 管理不干扰外部音频输出的低频脉冲
@MainActor
final class SpeakerPulse {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var prepared = false

    // 在允许的音频路由上播放单次脉冲
    func play(enabled: Bool, fullAccess: Bool) {
        guard enabled, fullAccess else { return }
        let session = AVAudioSession.sharedInstance()
        guard isBuiltIn(session.currentRoute) else { return }

        do {
            try prepare(session)
            player.volume = max(0.018, min(0.055, 0.065 - session.outputVolume * 0.035))
            if player.isPlaying { player.stop() }
            player.scheduleBuffer(makeBuffer(), at: nil, options: .interrupts)
            player.play()
        } catch {
            return
        }
    }

    // 确认当前仅使用设备内置扬声器
    private func isBuiltIn(_ route: AVAudioSessionRouteDescription) -> Bool {
        !route.outputs.isEmpty && route.outputs.allSatisfy { $0.portType == .builtInSpeaker }
    }

    // 准备混音音频会话与播放节点
    private func prepare(_ session: AVAudioSession) throws {
        guard !prepared else {
            if !engine.isRunning { try engine.start() }
            return
        }
        try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try engine.start()
        prepared = true
    }

    // 生成十二毫秒低频正弦脉冲并平滑收尾
    private func makeBuffer() -> AVAudioPCMBuffer {
        let sampleRate = 44_100.0
        let count = AVAudioFrameCount(sampleRate * 0.012)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        guard let channel = buffer.floatChannelData?[0] else { return buffer }

        for index in 0 ..< Int(count) {
            let progress = Double(index) / Double(count)
            let envelope = sin(.pi * progress)
            channel[index] = Float(sin(2 * .pi * 72 * Double(index) / sampleRate) * envelope)
        }
        return buffer
    }
}
