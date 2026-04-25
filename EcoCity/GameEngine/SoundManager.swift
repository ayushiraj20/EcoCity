import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
class SoundManager {
    
    private let engine = AVAudioEngine()
    private let ambientNode = AVAudioPlayerNode()
    private let ambientNode2 = AVAudioPlayerNode()  // second ambient for layering
    private let sfxNode    = AVAudioPlayerNode()
    private let sfxNode2   = AVAudioPlayerNode()
    
    private var currentAmbientName: String?
    private let sr: Double = 44100   // Higher sample rate for better quality
    
    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundManager: AVAudioSession error: \(error)")
        }
        
        let fmt = monoFormat
        engine.attach(ambientNode)
        engine.attach(ambientNode2)
        engine.attach(sfxNode)
        engine.attach(sfxNode2)
        engine.connect(ambientNode, to: engine.mainMixerNode, format: fmt)
        engine.connect(ambientNode2, to: engine.mainMixerNode, format: fmt)
        engine.connect(sfxNode,    to: engine.mainMixerNode, format: fmt)
        engine.connect(sfxNode2,   to: engine.mainMixerNode, format: fmt)
        
        do {
            try engine.start()
        } catch {
            print("SoundManager: Engine start error: \(error)")
        }
    }
    
    private var monoFormat: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
    }
    
    
    private func makeBuffer(seconds: Double, _ fill: (Int, Int) -> Float) -> AVAudioPCMBuffer? {
        let fmt = monoFormat
        let n = AVAudioFrameCount(sr * seconds)
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n) else { return nil }
        buf.frameLength = n
        let ptr = buf.floatChannelData![0]
        for i in 0..<Int(n) { ptr[i] = fill(i, Int(n)) }
        return buf
    }
    
    private func clamp(_ v: Float) -> Float { max(-1, min(1, v)) }
    private func applyFade(buf: AVAudioPCMBuffer, fadeFrames: Int = 2000) {
        guard let ptr = buf.floatChannelData?[0] else { return }
        let n = Int(buf.frameLength)
        let f = min(fadeFrames, n / 2)
        for i in 0..<f {
            let g = Float(i) / Float(f)
            ptr[i] *= g
            ptr[n - 1 - i] *= g
        }
    }
    
    
    func playAmbientSound(named name: String, volume: Float = 0.45) {
        guard currentAmbientName != name else { return }
        currentAmbientName = name
        ambientNode.stop()
        
        let buf: AVAudioPCMBuffer?
        var vol = volume
        switch name {
        case "wind":   buf = makeWind();  vol = 0.20    // subtle background
        case "birds":  buf = makeBirds(); vol = 0.45    // pleasant and clear
        case "water":  buf = makeWater(); vol = 0.15    // gentle, not overpowering
        default:       buf = makeWind();  vol = 0.20
        }
        guard let b = buf else { return }
        applyFade(buf: b, fadeFrames: 4000)
        ambientNode.volume = vol
        ambientNode.scheduleBuffer(b, at: nil, options: .loops)
        ambientNode.play()
    }
    
    func stopAmbient() {
        ambientNode.stop()
        ambientNode2.stop()
        currentAmbientName = nil
    }
    func playCityAmbient() {
        guard currentAmbientName != "city" else { return }
        currentAmbientName = "city"
        ambientNode.stop()
        ambientNode2.stop()
        
        if let birds = makeBirds() {
            applyFade(buf: birds, fadeFrames: 4000)
            ambientNode.volume = 0.40
            ambientNode.scheduleBuffer(birds, at: nil, options: .loops)
            ambientNode.play()
        }
        if let water = makeWater() {
            applyFade(buf: water, fadeFrames: 4000)
            ambientNode2.volume = 0.12
            ambientNode2.scheduleBuffer(water, at: nil, options: .loops)
            ambientNode2.play()
        }
    }
    
    
    func playTaskSuccess() { playSFX(makeTaskSuccess()) }
    func playLevelComplete() { playSFX(makeLevelComplete()) }

    func playTreePlant()      { playSFX(makeTreePlant()) }
    func playGarbageClean()   { playSFX(makeGarbageClean()) }
    func playSolarInstall()   { playSFX(makeSolarInstall()) }
    func playWindmillPlace()  { playSFX(makeWindmill()) }
    func playHydroRush()      { playSFX(makeHydroRush()) }
    func playEVWhirr()        { playSFX(makeEVWhirr()) }
    func playFilterSnap()     { playSFX(makeFilterSnap()) }
    func playWaterBubble()    { playSFX(makeWaterBubble()) }
    func playButtonTap()      { playSFX2(makeButtonTap()) }
    
    private func playSFX(_ buf: AVAudioPCMBuffer?) {
        guard let b = buf else { return }
        sfxNode.stop()
        sfxNode.volume = 0.85
        sfxNode.scheduleBuffer(b)
        sfxNode.play()
    }
    
    private func playSFX2(_ buf: AVAudioPCMBuffer?) {
        guard let b = buf else { return }
        sfxNode2.volume = 0.7
        sfxNode2.scheduleBuffer(b)
        sfxNode2.play()
    }
    private func makeWind() -> AVAudioPCMBuffer? {
        var b0: Float=0, b1: Float=0, b2: Float=0, b3: Float=0, b4: Float=0, b5: Float=0, b6: Float=0
        var rumble: Float = 0
        return makeBuffer(seconds: 10) { i, total in
            let white = Float.random(in: -1...1)
            b0 = 0.99886*b0 + white*0.0555179; b1 = 0.99332*b1 + white*0.0750759
            b2 = 0.96900*b2 + white*0.1538520; b3 = 0.86650*b3 + white*0.3104856
            b4 = 0.55000*b4 + white*0.5329522; b5 = -0.7616*b5 - white*0.0168980
            let pink = (b0+b1+b2+b3+b4+b5+b6+white*0.5362)*0.11; b6 = white*0.115926
            rumble = rumble*0.999 + Float.random(in: -1...1)*0.001
            let t = Float(i)/Float(total)
            let gust = 0.55 + 0.25*sin(t * .pi * 2.3) + 0.20*sin(t * .pi * 5.7)
            return self.clamp((pink * 0.85 + rumble * 0.15) * gust)
        }
    }
    private func makeWater() -> AVAudioPCMBuffer? {
        var lp1: Float=0, lp2: Float=0, hp: Float=0
        return makeBuffer(seconds: 10) { i, total in
            let w = Float.random(in: -1...1)
            lp1 = lp1*0.85 + w*0.15
            lp2 = lp2*0.70 + lp1*0.30
            hp  = w - lp2  // high-pass = remove the DC lump
            let t = Float(i) / Float(self.sr)
            let ripple = 0.80 + 0.20 * sin(t * 4.3) * sin(t * 1.7)
            return self.clamp(hp * 0.55 * ripple)
        }
    }
    private func makeBirds() -> AVAudioPCMBuffer? {
        let totalFrames = Int(sr * 12)
        let fmt = monoFormat
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(totalFrames)) else { return nil }
        buf.frameLength = AVAudioFrameCount(totalFrames)
        let ptr = buf.floatChannelData![0]
        for i in 0..<totalFrames { ptr[i] = 0 }
        
        for i in 0..<totalFrames {
            let t = Float(i) / Float(sr)
            let tex = sin(2 * Float.pi * 3800 * t) * 0.04 * max(0, sin(t * 12.0))
            ptr[i] += tex
        }
        
        let callsA: [(Double, Float, Float)] = [(0.4, 4200, 3400), (2.1, 4400, 3600), (5.3, 4100, 3300), (8.2, 4300, 3500), (10.1, 4000, 3200)]
        for (startSec, f1, f2) in callsA {
            addChirp(ptr: ptr, total: totalFrames, startSec: startSec, dur: 0.18, f1: f1, f2: f2, amp: 0.28)
        }

        let callsB: [(Double, Float, Float)] = [(1.2, 2800, 3600), (3.5, 2900, 3800), (6.0, 2700, 3500), (9.1, 3000, 3900)]
        for (startSec, f1, f2) in callsB {
            addChirp(ptr: ptr, total: totalFrames, startSec: startSec, dur: 0.12, f1: f1, f2: f2, amp: 0.22)
            addChirp(ptr: ptr, total: totalFrames, startSec: startSec+0.18, dur: 0.10, f1: f2, f2: f2*1.1, amp: 0.20)
        }
        
        let callsC: [(Double, Float)] = [(0.9, 1800), (4.4, 1950), (7.7, 1750), (11.0, 1900)]
        for (startSec, freq) in callsC {
            let start = Int(startSec * sr)
            let len = Int(0.30 * sr)
            for j in 0..<len {
                guard start+j < totalFrames else { break }
                let t = Float(j) / Float(sr)
                let env = sin(Float(j)/Float(len) * .pi)
                let trill = sin(2 * Float.pi * freq * t) * sin(2 * Float.pi * 22 * t) // 22Hz trill
                ptr[start+j] += trill * env * 0.18
            }
        }
        
        applyFade(buf: buf, fadeFrames: 6000)
        return buf
    }
    
    private func addChirp(ptr: UnsafeMutablePointer<Float>, total: Int,
                          startSec: Double, dur: Double, f1: Float, f2: Float, amp: Float) {
        let start = Int(startSec * sr)
        let len   = Int(dur * sr)
        for j in 0..<len {
            guard start+j < total else { break }
            let t = Float(j) / Float(sr)
            let progress = Float(j)/Float(len)
            let env = sin(progress * .pi)  // smooth bell envelope
            let freq = f1 + (f2-f1)*progress
            let harm = sin(2 * .pi * freq * t) + 0.3*sin(4 * .pi * freq * t) // add harmonic for realism
            ptr[start+j] += harm * env * amp
        }
    }
    private func makeTreePlant() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.7) { i, total in
            let t = Float(i) / Float(self.sr)
            let progress = Float(i)/Float(total)
            let whooshFreq: Float = 800 - 600*progress
            let whoosh = sin(2 * .pi * whooshFreq * t) * 0.3 * max(0, 1 - progress*2)
            let thudProgress = max(0, (progress - 0.4) / 0.3)
            let thud = sin(2 * .pi * 60 * t) * pow(max(0, 1-thudProgress), 3) * 0.7
            let rustleEnv = max(0, progress - 0.5) * 0.8
            let rustle = Float.random(in: -1...1) * rustleEnv * 0.15
            return self.clamp(whoosh + thud + rustle)
        }
    }
    private func makeGarbageClean() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.6) { i, total in
            let progress = Float(i)/Float(total)
            let t = Float(i) / Float(self.sr)
            let crinkleEnv = max(0, 1 - progress*2.5) * 0.5
            let crinkle = Float.random(in: -1...1) * crinkleEnv *
                          max(0, sin(Float(i) / Float(self.sr) * 80))
            let thudP = max(0, (progress-0.38)/0.25)
            let thud  = sin(2 * .pi * 80 * t) * pow(max(0, 1-thudP), 2.5) * 0.65
            return self.clamp(crinkle + thud)
        }
    }
    private func makeSolarInstall() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.55) { i, total in
            let t = Float(i) / Float(self.sr)
            let progress = Float(i)/Float(total)
            let snapEnv = pow(max(0, 1 - progress*10), 3)
            let snap = Float.random(in: -1...1) * snapEnv * 0.6
            let humFreq: Float = 200 + 600*progress
            let humEnv = progress * max(0, 1 - (progress-0.7)/0.3)
            let hum = sin(2 * .pi * humFreq * t) * humEnv * 0.25
            let shimmer = sin(2 * .pi * humFreq * 3 * t) * humEnv * 0.10
            return self.clamp(snap + hum + shimmer)
        }
    }
    private func makeWindmill() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.9) { i, total in
            let t = Float(i) / Float(self.sr)
            let progress = Float(i)/Float(total)
            let spinFreq: Float = 100 + 300*progress
            let whoosh = sin(2 * .pi * spinFreq * t) * 0.35
            let windEnv = progress * (1 - progress*0.5)
            let wind = Float.random(in: -1...1) * 0.12 * windEnv
            let env = sin(progress * .pi)
            return self.clamp((whoosh + wind) * env)
        }
    }
    private func makeHydroRush() -> AVAudioPCMBuffer? {
        var lp: Float = 0
        return makeBuffer(seconds: 1.0) { i, total in
            let progress = Float(i)/Float(total)
            let w = Float.random(in: -1...1)
            lp = lp*0.75 + w*0.25
            let env = progress < 0.2 ? progress/0.2 : pow(1 - (progress-0.2)/0.8, 0.7)
            let t = Float(i)/Float(self.sr)
            let rumble = sin(2 * .pi * 55 * t) * 0.2 * env
            return self.clamp(lp * 0.65 * env + rumble)
        }
    }
    private func makeEVWhirr() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.8) { i, total in
            let t = Float(i) / Float(self.sr)
            let progress = Float(i)/Float(total)
            let baseFreq: Float = 150 + 850*progress
            let motor  = sin(2 * .pi * baseFreq * t) * 0.35
            let harm2  = sin(2 * .pi * baseFreq * 2 * t) * 0.15
            let harm3  = sin(2 * .pi * baseFreq * 3 * t) * 0.07
            let env = sin(progress * .pi)
            return self.clamp((motor + harm2 + harm3) * env * 0.9)
        }
    }
    private func makeFilterSnap() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.5) { i, total in
            let progress = Float(i)/Float(total)
            let t = Float(i)/Float(self.sr)
            let clickEnv = pow(max(0, 1 - progress*15), 4)
            let click = sin(2 * .pi * 1200 * t) * clickEnv * 0.7
            let whooshEnv = max(0, progress-0.05) * max(0, 1-progress*2)
            let whoosh = Float.random(in: -1...1) * whooshEnv * 0.35
            return self.clamp(click + whoosh)
        }
    }
    private func makeWaterBubble() -> AVAudioPCMBuffer? {
        let totalFrames = Int(sr * 0.9)
        let fmt = monoFormat
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(totalFrames)) else { return nil }
        buf.frameLength = AVAudioFrameCount(totalFrames)
        let ptr = buf.floatChannelData![0]
        for i in 0..<totalFrames { ptr[i] = 0 }
        
        let bubbles: [(Double, Float)] = [(0.05, 420), (0.2, 380), (0.38, 460), (0.55, 350), (0.71, 500)]
        for (startSec, freq) in bubbles {
            let start = Int(startSec * sr)
            let len = Int(0.08 * sr)
            for j in 0..<len {
                guard start+j < totalFrames else { break }
                let t = Float(j)/Float(sr)
                let env = pow(1 - Float(j)/Float(len), 2)
                let bubble = sin(2 * .pi * freq * (1 + Float(j)/Float(len) * 0.5) * t) * env * 0.55
                ptr[start+j] += bubble
            }
        }
        for i in 0..<totalFrames {
            let t = Float(i)/Float(sr)
            ptr[i] += sin(2 * .pi * 200 * t) * 0.04
        }
        applyFade(buf: buf)
        return buf
    }
    private func makeButtonTap() -> AVAudioPCMBuffer? {
        return makeBuffer(seconds: 0.08) { i, total in
            let t = Float(i)/Float(self.sr)
            let env = pow(1 - Float(i)/Float(total), 3)
            return self.clamp(sin(2 * .pi * 900 * t) * env * 0.5 +
                              sin(2 * .pi * 1800 * t) * env * 0.15)
        }
    }
    private func makeTaskSuccess() -> AVAudioPCMBuffer? {
        let notes: [(Float, Double)] = [(1174.66, 0.12), (1567.98, 0.28)] // D6 → G6
        return makeNoteSequence(notes)
    }
    private func makeLevelComplete() -> AVAudioPCMBuffer? {
        let notes: [(Float, Double)] = [(523.25, 0.15), (659.25, 0.15), (783.99, 0.15), (1046.50, 0.55)]
        return makeNoteSequence(notes)
    }
    
    private func makeNoteSequence(_ notes: [(Float, Double)]) -> AVAudioPCMBuffer? {
        let total = notes.reduce(0.0) { $0 + $1.1 }
        let fmt = monoFormat
        let n = AVAudioFrameCount(sr * total)
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: n) else { return nil }
        buf.frameLength = n
        let ptr = buf.floatChannelData![0]
        var offset = 0
        for (freq, dur) in notes {
            let len = Int(sr * dur)
            for j in 0..<len {
                let t = Float(j)/Float(sr)
                let env = pow(1 - Float(j)/Float(len), 1.4)
                let s = (sin(2 * .pi * freq * t) * 0.6
                       + sin(2 * .pi * freq * 2 * t) * 0.25
                       + sin(2 * .pi * freq * 3 * t) * 0.10) * env * 0.55
                ptr[offset + j] = clamp(s)
            }
            offset += len
        }
        return buf
    }
}
