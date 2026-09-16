import Foundation
import AVFoundation

/// Procedural audio: all SFX and music loops are synthesized in code with
/// AVAudioEngine — no audio assets required.
final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private let sampleRate = 22050.0
    private var pool: [AVAudioPlayerNode] = []
    private let musicPlayer = AVAudioPlayerNode()
    private var sfxCache: [String: AVAudioPCMBuffer] = [:]
    private var musicCache: [String: AVAudioPCMBuffer] = [:]
    private var currentTheme: String?
    private var isSetUp = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    // MARK: - Setup

    func setup() {
        guard !isSetUp else { return }
        isSetUp = true
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session failed: \(error)")
        }
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        for _ in 0..<10 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            pool.append(node)
        }
        do {
            try engine.start()
        } catch {
            print("Audio engine failed: \(error)")
        }
        applyVolumes()
        pregenerate()
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let self else { return }
            if let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
               type == AVAudioSession.InterruptionType.ended.rawValue {
                try? self.engine.start()
                if self.musicPlayer.isPlaying == false, let theme = self.currentTheme {
                    self.currentTheme = nil
                    self.playMusic(theme: theme)
                }
            }
        }
    }

    func applyVolumes() {
        guard isSetUp else { return }
        let s = AppSettings.shared
        musicPlayer.volume = Float(s.masterVolume * s.musicVolume) * 0.55
        for node in pool {
            node.volume = Float(s.masterVolume * s.sfxVolume)
        }
    }

    // MARK: - SFX

    func play(_ name: String, volume: Float = 1.0) {
        setup()
        guard AppSettings.shared.sfxVolume > 0.01, AppSettings.shared.masterVolume > 0.01 else { return }
        let buffer: AVAudioPCMBuffer
        if let cached = sfxCache[name] {
            buffer = cached
        } else {
            guard let built = buildSFX(name) else { return }
            sfxCache[name] = built
            buffer = built
        }
        guard let node = pool.first(where: { !$0.isPlaying }) else { return }
        node.volume = Float(AppSettings.shared.masterVolume * AppSettings.shared.sfxVolume) * volume
        node.scheduleBuffer(buffer, at: nil, options: [])
        node.play()
    }

    // MARK: - Music

    func playMusic(theme: String) {
        setup()
        if currentTheme == theme, musicPlayer.isPlaying { return }
        currentTheme = theme
        musicPlayer.stop()
        let buffer: AVAudioPCMBuffer
        if let cached = musicCache[theme] {
            buffer = cached
        } else {
            buffer = buildMusic(theme: theme)
            musicCache[theme] = buffer
        }
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        musicPlayer.play()
    }

    func stopMusic() {
        currentTheme = nil
        musicPlayer.stop()
    }

    // MARK: - Synthesis primitives

    private enum Wave { case sine, square, saw, noise }

    private func makeBuffer(duration: Double, _ fn: (Double) -> Double) -> AVAudioPCMBuffer {
        let frames = AVAudioFrameCount(max(1, duration * sampleRate))
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        guard let ptr = buffer.floatChannelData?[0] else { return buffer }
        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            ptr[i] = Float(max(-1.0, min(1.0, fn(t))))
        }
        return buffer
    }

    private func tone(f0: Double, f1: Double, duration: Double, type: Wave,
                      volume: Double, attack: Double = 0.005, decayPow: Double = 1.5) -> AVAudioPCMBuffer {
        var phase = 0.0
        return makeBuffer(duration: duration) { t in
            let k = min(1.0, t / duration)
            let f = f0 + (f1 - f0) * k
            phase += 2.0 * .pi * f / self.sampleRate
            let s: Double
            switch type {
            case .sine: s = sin(phase)
            case .square: s = sin(phase) > 0 ? 0.8 : -0.8
            case .saw: s = 2.0 * (phase / (2.0 * .pi)).truncatingRemainder(dividingBy: 1.0) - 1.0
            case .noise: s = Double.random(in: -1.0...1.0)
            }
            let env = min(1.0, t / attack) * pow(1.0 - k, decayPow)
            return s * volume * env
        }
    }

    private func mix(_ buffers: [AVAudioPCMBuffer]) -> AVAudioPCMBuffer {
        let frames = buffers.map { Int($0.frameLength) }.max() ?? 1
        let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        out.frameLength = AVAudioFrameCount(frames)
        guard let dst = out.floatChannelData?[0] else { return out }
        for i in 0..<frames { dst[i] = 0 }
        for buf in buffers {
            guard let src = buf.floatChannelData?[0] else { continue }
            for i in 0..<min(frames, Int(buf.frameLength)) {
                dst[i] += src[i] / Float(buffers.count).squareRoot()
            }
        }
        return out
    }

    private func pregenerate() {
        for name in ["jump", "dash", "swing", "hit", "hurt", "coin", "click", "shoot"] {
            sfxCache[name] = buildSFX(name)
        }
    }

    // MARK: - SFX library

    private func buildSFX(_ name: String) -> AVAudioPCMBuffer? {
        switch name {
        case "jump": return tone(f0: 300, f1: 620, duration: 0.16, type: .square, volume: 0.35)
        case "doubleJump": return tone(f0: 420, f1: 840, duration: 0.16, type: .square, volume: 0.35)
        case "dash": return tone(f0: 900, f1: 200, duration: 0.18, type: .saw, volume: 0.3)
        case "swing": return tone(f0: 1400, f1: 500, duration: 0.09, type: .noise, volume: 0.25)
        case "hit": return tone(f0: 220, f1: 90, duration: 0.14, type: .square, volume: 0.5)
        case "crit": return mix([
            tone(f0: 700, f1: 1400, duration: 0.12, type: .square, volume: 0.4),
            tone(f0: 200, f1: 80, duration: 0.16, type: .square, volume: 0.5),
        ])
        case "hurt": return tone(f0: 400, f1: 120, duration: 0.22, type: .saw, volume: 0.45)
        case "enemyDie": return tone(f0: 500, f1: 60, duration: 0.3, type: .square, volume: 0.4)
        case "coin": return mix([
            tone(f0: 990, f1: 990, duration: 0.08, type: .sine, volume: 0.4),
            tone(f0: 1320, f1: 1320, duration: 0.2, type: .sine, volume: 0.4),
        ])
        case "pickup": return tone(f0: 520, f1: 1040, duration: 0.14, type: .sine, volume: 0.45)
        case "potion": return tone(f0: 300, f1: 700, duration: 0.3, type: .sine, volume: 0.45, decayPow: 0.8)
        case "levelup": return mix([
            tone(f0: 523, f1: 523, duration: 0.35, type: .square, volume: 0.3),
            tone(f0: 659, f1: 659, duration: 0.35, type: .square, volume: 0.3),
            tone(f0: 784, f1: 1046, duration: 0.4, type: .square, volume: 0.3),
        ])
        case "quest": return tone(f0: 660, f1: 990, duration: 0.25, type: .sine, volume: 0.4)
        case "questDone": return mix([
            tone(f0: 784, f1: 784, duration: 0.3, type: .sine, volume: 0.4),
            tone(f0: 1046, f1: 1318, duration: 0.4, type: .sine, volume: 0.4),
        ])
        case "chest": return mix([
            tone(f0: 150, f1: 90, duration: 0.25, type: .square, volume: 0.4),
            tone(f0: 880, f1: 1320, duration: 0.25, type: .sine, volume: 0.35),
        ])
        case "portal": return tone(f0: 200, f1: 1200, duration: 0.6, type: .saw, volume: 0.3, decayPow: 0.6)
        case "checkpoint": return tone(f0: 440, f1: 880, duration: 0.3, type: .sine, volume: 0.4)
        case "click", "uiClick": return tone(f0: 800, f1: 700, duration: 0.05, type: .square, volume: 0.25)
        case "error": return tone(f0: 220, f1: 160, duration: 0.2, type: .square, volume: 0.35)
        case "shoot": return tone(f0: 1200, f1: 300, duration: 0.12, type: .saw, volume: 0.3)
        case "explosion": return mix([
            tone(f0: 120, f1: 30, duration: 0.5, type: .noise, volume: 0.6, decayPow: 1.0),
            tone(f0: 90, f1: 25, duration: 0.6, type: .sine, volume: 0.6, decayPow: 1.0),
        ])
        case "bossRoar": return mix([
            tone(f0: 80, f1: 45, duration: 0.9, type: .saw, volume: 0.55, decayPow: 0.7),
            tone(f0: 160, f1: 90, duration: 0.8, type: .square, volume: 0.35, decayPow: 0.7),
        ])
        case "heal": return tone(f0: 500, f1: 1000, duration: 0.4, type: .sine, volume: 0.4, decayPow: 0.7)
        case "skill": return tone(f0: 600, f1: 1500, duration: 0.3, type: .square, volume: 0.3)
        case "victory": return mix([
            tone(f0: 523, f1: 523, duration: 0.6, type: .square, volume: 0.3, decayPow: 0.5),
            tone(f0: 659, f1: 659, duration: 0.6, type: .square, volume: 0.3, decayPow: 0.5),
            tone(f0: 784, f1: 1046, duration: 0.8, type: .square, volume: 0.35, decayPow: 0.5),
        ])
        case "defeat": return tone(f0: 300, f1: 60, duration: 1.0, type: .saw, volume: 0.4, decayPow: 0.6)
        case "select": return tone(f0: 700, f1: 900, duration: 0.07, type: .sine, volume: 0.3)
        case "land": return tone(f0: 180, f1: 120, duration: 0.07, type: .sine, volume: 0.25)
        case "splash": return tone(f0: 600, f1: 200, duration: 0.2, type: .noise, volume: 0.3)
        default: return nil
        }
    }

    // MARK: - Music sequencer

    private struct Note {
        var start: Double
        var length: Double
        var midi: Int
        var volume: Double
        var bright: Bool
    }

    private func midiHz(_ m: Int) -> Double {
        440.0 * pow(2.0, Double(m - 69) / 12.0)
    }

    private func buildMusic(theme: String) -> AVAudioPCMBuffer {
        // (bpm, roots as midi, mode: minor/major, energy)
        let presets: [String: (bpm: Double, roots: [Int], minor: Bool, energy: Double)] = [
            "menu": (72, [45, 41, 48, 43], true, 0.3),
            "forest": (92, [45, 41, 43, 40], true, 0.55),
            "caves": (64, [38, 38, 41, 36], true, 0.4),
            "castle": (104, [43, 43, 45, 41], true, 0.7),
            "sky": (100, [48, 45, 41, 43], false, 0.65),
            "boss": (132, [40, 40, 43, 38], true, 0.95),
        ]
        let p = presets[theme] ?? presets["forest"]!
        let beat = 60.0 / p.bpm
        let bar = beat * 4
        var notes: [Note] = []
        for (i, root) in p.roots.enumerated() {
            let t0 = Double(i) * bar
            // Bass on beats 1 and 3.
            notes.append(Note(start: t0, length: beat * 1.8, midi: root - 12, volume: 0.5, bright: false))
            notes.append(Note(start: t0 + beat * 2, length: beat * 1.5, midi: root - 12, volume: 0.4, bright: false))
            // Arpeggio.
            let third = root + (p.minor ? 3 : 4)
            let fifth = root + 7
            let arp = [root + 12, third + 12, fifth + 12, third + 24]
            let steps = p.energy > 0.8 ? 8 : 4
            for s in 0..<steps {
                let m = arp[s % arp.count]
                notes.append(Note(start: t0 + Double(s) * bar / Double(steps),
                                  length: bar / Double(steps) * 0.9,
                                  midi: m, volume: 0.22 + p.energy * 0.12, bright: true))
            }
            // Pad chord.
            for m in [root, third, fifth] {
                notes.append(Note(start: t0, length: bar, midi: m, volume: 0.1, bright: false))
            }
        }
        let total = bar * Double(p.roots.count)
        return makeBuffer(duration: total) { t in
            var s = 0.0
            for n in notes {
                let dt = t - n.start
                if dt < 0 || dt > n.length { continue }
                let f = self.midiHz(n.midi)
                let env = min(1.0, dt / 0.02) * (1.0 - dt / n.length)
                let v = sin(2.0 * .pi * f * t)
                    + (n.bright ? 0.3 * sin(4.0 * .pi * f * t) : 0.0)
                    + 0.15 * sin(2.0 * .pi * f * t * 0.5)
                s += v * n.volume * env
            }
            // Soft drum on beats for energetic themes.
            if p.energy > 0.6 {
                let beatPhase = (t / beat).truncatingRemainder(dividingBy: 1.0)
                if beatPhase < 0.12 {
                    s += sin(2.0 * .pi * 70.0 * t) * 0.5 * (1.0 - beatPhase / 0.12)
                }
            }
            return s * 0.5
        }
    }
}
