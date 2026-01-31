import SpriteKit
import AVFoundation

/// Generates and plays sound effects programmatically using AVAudioEngine (no audio files needed).
/// All sounds are synthesized at init time as PCM buffers matching NES Battle City style.
class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private let playerCount = 4
    private var currentPlayerIndex = 0

    // Dedicated music player (separate from SFX pool)
    private let musicPlayer = AVAudioPlayerNode()
    private var musicBuffer: AVAudioPCMBuffer?
    private var isMusicPlaying = false

    private let sampleRate: Double = 44100.0
    private let format: AVAudioFormat

    private var buffers: [String: AVAudioPCMBuffer] = [:]

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        for _ in 0..<playerCount {
            let player = AVAudioPlayerNode()
            players.append(player)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }

        // Music player
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        musicPlayer.volume = 0.4

        engine.prepare()
        do {
            try engine.start()
        } catch {
            print("SoundManager: Failed to start AVAudioEngine: \(error)")
        }

        generateAllBuffers()
        musicBuffer = generateBackgroundMusic()
    }

    // MARK: - Public API

    func playShoot(on node: SKNode) {
        play("shoot")
    }

    func playExplosionSmall(on node: SKNode) {
        play("explosionSmall")
    }

    func playExplosionLarge(on node: SKNode) {
        play("explosionLarge")
    }

    func playHitBrick(on node: SKNode) {
        play("hitBrick")
    }

    func playHitSteel(on node: SKNode) {
        play("hitSteel")
    }

    func playPowerUp(on node: SKNode) {
        play("powerUp")
    }

    func playGameOver(on node: SKNode) {
        play("gameOver")
        stopMusic()
    }

    func playLevelStart(on node: SKNode) {
        play("levelStart")
    }

    func playBonusLife(on node: SKNode) {
        play("bonusLife")
    }

    func startMusic() {
        guard let buffer = musicBuffer else { return }
        if isMusicPlaying {
            musicPlayer.stop()
        }
        isMusicPlaying = true
        musicPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicPlayer.play()
    }

    func stopMusic() {
        guard isMusicPlaying else { return }
        isMusicPlaying = false
        musicPlayer.stop()
    }

    // MARK: - Playback

    private func play(_ name: String) {
        guard let buffer = buffers[name] else { return }
        let player = players[currentPlayerIndex]
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount

        if player.isPlaying {
            player.stop()
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    // MARK: - Buffer Generation

    private func generateAllBuffers() {
        buffers["shoot"] = makeSquareWave(frequency: 880, duration: 0.05, volume: 0.3)
        buffers["explosionSmall"] = makeNoiseBurst(duration: 0.1, volume: 0.4, fadeOut: true)
        buffers["explosionLarge"] = makeLargeExplosion()
        buffers["hitBrick"] = makeNoiseBurst(duration: 0.03, volume: 0.25, fadeOut: true)
        buffers["hitSteel"] = makeSineWave(frequency: 1200, duration: 0.05, volume: 0.3)
        buffers["powerUp"] = makeSweep(startFreq: 400, endFreq: 800, duration: 0.15, volume: 0.35, waveform: .square)
        buffers["gameOver"] = makeSweep(startFreq: 600, endFreq: 200, duration: 0.5, volume: 0.4, waveform: .square)
        buffers["levelStart"] = makeFanfare()
        buffers["bonusLife"] = makeSweep(startFreq: 500, endFreq: 1000, duration: 0.15, volume: 0.35, waveform: .sine)
    }

    // MARK: - Background Music Generator

    private func generateBackgroundMusic() -> AVAudioPCMBuffer {
        // Funny bouncy chiptune march — square wave melody
        let bpm: Double = 150
        let beat = 60.0 / bpm
        let s16 = beat / 4  // sixteenth note duration

        // (frequency, duration in sixteenths). freq=0 is rest.
        let melody: [(Double, Int)] = [
            // Bar 1: Bouncy C major arpeggio
            (523.25, 2), (0, 1), (659.25, 2), (0, 1), (783.99, 2), (0, 1),
            (659.25, 2), (0, 1), (523.25, 2), (0, 2),
            // Bar 2: D minor response
            (587.33, 2), (0, 1), (698.46, 2), (0, 1), (880.00, 2), (0, 1),
            (698.46, 2), (0, 1), (587.33, 2), (0, 2),
            // Bar 3: Descending run
            (783.99, 2), (698.46, 2), (659.25, 2), (587.33, 2),
            (523.25, 4), (0, 4),
            // Bar 4: Funny high staccato
            (1046.50, 1), (0, 1), (1046.50, 1), (0, 1),
            (880.00, 1), (0, 1), (783.99, 1), (0, 1),
            (659.25, 3), (0, 1), (523.25, 2), (0, 2),
            // Bar 5: Low march
            (261.63, 2), (0, 1), (329.63, 2), (0, 1),
            (392.00, 2), (0, 1), (523.25, 4), (0, 3),
            // Bar 6: Chromatic wobble
            (440.00, 2), (466.16, 2), (440.00, 2), (392.00, 2),
            (349.23, 2), (329.63, 2), (293.66, 2), (0, 2),
            // Bar 7: Ascending fanfare
            (523.25, 2), (587.33, 2), (659.25, 2), (698.46, 2),
            (783.99, 2), (880.00, 2), (987.77, 2), (1046.50, 2),
            // Bar 8: Ending bounce
            (1046.50, 3), (0, 1), (783.99, 2), (0, 1),
            (523.25, 3), (0, 2), (261.63, 2), (0, 2),
        ]

        // Total samples
        var totalS16 = 0
        for (_, dur) in melody { totalS16 += dur }
        let totalDuration = Double(totalS16) * s16

        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let vol: Float = 0.6
        var offset = 0
        var phase: Double = 0

        for (freq, dur) in melody {
            let samples = Int(Double(dur) * s16 * sampleRate)
            let end = min(offset + samples, Int(frameCount))
            let noteDur = Double(dur) * s16

            if freq > 0 {
                let period = sampleRate / freq
                for i in offset..<end {
                    let lt = Double(i - offset) / sampleRate

                    // Envelope: attack 3ms, release last 8ms
                    let env: Float
                    if lt < 0.003 {
                        env = Float(lt / 0.003)
                    } else if lt > noteDur - 0.008 {
                        env = max(0, Float((noteDur - lt) / 0.008))
                    } else {
                        env = 1.0
                    }

                    // 25% duty cycle square wave (classic NES pulse channel)
                    let p = phase.truncatingRemainder(dividingBy: period) / period
                    let sample: Float = p < 0.25 ? vol : -vol
                    data[i] = sample * env

                    phase += 1.0
                }
            } else {
                // Rest
                for i in offset..<end { data[i] = 0 }
                phase = 0
            }
            offset = end
        }

        return buffer
    }

    // MARK: - Waveform Generators

    private enum Waveform {
        case sine
        case square
    }

    private func makeSquareWave(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let period = sampleRate / frequency
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - t / duration) // linear fade
            let phase = Double(i).truncatingRemainder(dividingBy: period) / period
            let sample: Float = phase < 0.5 ? volume : -volume
            data[i] = sample * envelope
        }
        return buffer
    }

    private func makeSineWave(frequency: Double, duration: Double, volume: Float) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = Float(1.0 - t / duration)
            let sample = Float(sin(2.0 * .pi * frequency * t)) * volume
            data[i] = sample * envelope
        }
        return buffer
    }

    private func makeNoiseBurst(duration: Double, volume: Float, fadeOut: Bool) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope: Float = fadeOut ? Float(1.0 - t / duration) : 1.0
            let noise = Float.random(in: -1.0...1.0) * volume
            data[i] = noise * envelope
        }
        return buffer
    }

    private func makeSweep(startFreq: Double, endFreq: Double, duration: Double, volume: Float, waveform: Waveform) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        var phase: Double = 0
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress
            let envelope = Float(1.0 - progress * 0.5) // gentle fade

            let sample: Float
            switch waveform {
            case .sine:
                sample = Float(sin(phase)) * volume
            case .square:
                sample = (sin(phase) >= 0 ? volume : -volume)
            }
            data[i] = sample * envelope

            phase += 2.0 * .pi * freq / sampleRate
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
        return buffer
    }

    private func makeLargeExplosion() -> AVAudioPCMBuffer {
        let duration = 0.2
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let volume: Float = 0.45
        var phase: Double = 0
        let startFreq: Double = 300
        let endFreq: Double = 80

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let freq = startFreq + (endFreq - startFreq) * progress
            let envelope = Float(1.0 - progress)

            // Mix noise + low tone
            let noise = Float.random(in: -1.0...1.0) * volume * 0.6
            let tone = Float(sin(phase)) * volume * 0.4
            data[i] = (noise + tone) * envelope

            phase += 2.0 * .pi * freq / sampleRate
            if phase > 2.0 * .pi { phase -= 2.0 * .pi }
        }
        return buffer
    }

    private func makeFanfare() -> AVAudioPCMBuffer {
        // Three ascending notes: ~100ms each
        let noteDuration = 0.1
        let totalDuration = noteDuration * 3
        let frameCount = AVAudioFrameCount(sampleRate * totalDuration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let frequencies: [Double] = [400, 600, 800]
        let volume: Float = 0.35
        let noteFrames = Int(sampleRate * noteDuration)

        for i in 0..<Int(frameCount) {
            let noteIndex = min(i / noteFrames, 2)
            let freq = frequencies[noteIndex]
            let localT = Double(i - noteIndex * noteFrames) / sampleRate
            let localProgress = localT / noteDuration
            let envelope = Float(1.0 - localProgress * 0.3)

            let period = sampleRate / freq
            let phase = Double(i).truncatingRemainder(dividingBy: period) / period
            let sample: Float = phase < 0.5 ? volume : -volume
            data[i] = sample * envelope
        }
        return buffer
    }
}
