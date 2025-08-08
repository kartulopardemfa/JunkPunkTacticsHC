import Foundation
import CoreMotion
import AVFoundation
import UIKit
import SpriteKit

final class MotionService {
    private let mgr = CMMotionManager()
    private let queue = OperationQueue()
    var roll: Double = 0
    var pitch: Double = 0
    var yaw: Double = 0
    var enabled: Bool = true

    func start() {
        enabled = !(UIAccessibility.isReduceMotionEnabled || ProcessInfo.processInfo.isLowPowerModeEnabled)
        guard enabled, mgr.isDeviceMotionAvailable, !mgr.isDeviceMotionActive else { return }
        mgr.deviceMotionUpdateInterval = 1.0 / 60.0
        mgr.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: queue) { [weak self] m, _ in
            guard let m else { return }
            let damp = 0.65
            self?.roll = m.attitude.roll * damp
            self?.pitch = m.attitude.pitch * damp
            self?.yaw = m.attitude.yaw * damp
        }
    }
    func stop() { mgr.stopDeviceMotionUpdates() }
}

final class SaveService {
    private let metaKey = "JP_Meta_v1"
    private let uxKey   = "JP_UX_v1"
    private let firstKey = "JP_FirstRunShown"

    func save(_ meta: MetaProgress) {
        if let data = try? JSONEncoder().encode(meta) {
            UserDefaults.standard.set(data, forKey: metaKey)
        }
    }
    func loadMeta() -> MetaProgress {
        guard let data = UserDefaults.standard.data(forKey: metaKey),
              let decoded = try? JSONDecoder().decode(MetaProgress.self, from: data) else { return MetaProgress() }
        return decoded
    }

    func saveUX(_ ux: UX) {
        if let data = try? JSONEncoder().encode(ux) {
            UserDefaults.standard.set(data, forKey: uxKey)
        }
    }
    func loadUX() -> UX {
        guard let data = UserDefaults.standard.data(forKey: uxKey),
              let decoded = try? JSONDecoder().decode(UX.self, from: data) else { return UX() }
        return decoded
    }

    func firstRunShown() -> Bool { UserDefaults.standard.bool(forKey: firstKey) }
    func setFirstRunShown() { UserDefaults.standard.set(true, forKey: firstKey) }
}

final class AudioService {
    private var hitPlayer: AVAudioPlayer?
    private var critPlayer: AVAudioPlayer?

    func preload() {
        if let url = Bundle.main.url(forResource: "hit", ofType: "wav") {
            hitPlayer = try? AVAudioPlayer(contentsOf: url)
            hitPlayer?.prepareToPlay()
        }
        if let url = Bundle.main.url(forResource: "crit", ofType: "wav") {
            critPlayer = try? AVAudioPlayer(contentsOf: url)
            critPlayer?.prepareToPlay()
        }
    }
    func hit() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        hitPlayer?.currentTime = 0
        hitPlayer?.play()
    }
    func crit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        critPlayer?.currentTime = 0
        critPlayer?.play()
    }
}

struct RemoteConfig: Codable {
    var interstitialEvery: Int = 2
    var slotRareChance: Double = 0.25
    var scrapRewardMin: Int = 20
    var scrapRewardMax: Int = 45
    var dailyGiftAmount: Int = 50
    var heatDecayOnEnemyTurn: Double = 0.35
}

final class ContentService {
    var weapons: [Weapon] = []
    var items: [Item] = []
    var enemies: [EnemyBlueprint] = []
    var heroes: [HeroTemplate] = []
    func load() {
        weapons = ContentDefaults.weapons
        items   = ContentDefaults.items
        enemies = ContentDefaults.enemies
        heroes  = ContentDefaults.heroes
    }
}

final class PerformanceService {
    private(set) var lowEffects = false
    func updateThermalState() {
        let t = ProcessInfo.processInfo.thermalState
        lowEffects = (t == .serious || t == .critical) || ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}

final class TextureService {
    static let shared = TextureService()
    private var cache: [String: SKTexture] = [:]

    func preload(names: [String]) {
        for n in names {
            if cache[n] == nil {
                let tex = SKTexture(imageNamed: n)
                tex.filteringMode = .nearest
                cache[n] = tex
            }
        }
        SKTexture.preload(Array(cache.values), withCompletionHandler: {})
    }

    func texture(named name: String) -> SKTexture? {
        if let t = cache[name] { return t }
        let tex = SKTexture(imageNamed: name)
        if tex.size() != .zero {
            tex.filteringMode = .nearest
            cache[name] = tex
            return tex
        }
        return nil
    }
}
