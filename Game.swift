import Foundation
import SpriteKit

final class Game {
    static let shared = Game()

    let motion = MotionService()
    let audio = AudioService()
    let save = SaveService()
    let content = ContentService()
    let performance = PerformanceService()
    var config = RemoteConfig()

    var meta = MetaProgress()
    var ux = UX()
    var safeInsets = UIEdgeInsets.zero

    var player = Player.from(hero: ContentDefaults.heroes[0], weapons: ContentDefaults.weapons, items: ContentDefaults.items)
    var selectedHeroIndex: Int = 0

    var run = RunState()
    var scrap: Int = 0

    func boot() {
        content.load()
        audio.preload()
        meta = save.loadMeta()
        ux = save.loadUX()
        performance.updateThermalState()
        TextureService.shared.preload(names: [
            "reel_wrench","reel_med","reel_target","reel_bolt","reel_chem","reel_magnet","reel_shield","reel_boom"
        ])
    }

    func startNewRun() {
        let hero = content.heroes.indices.contains(selectedHeroIndex) ? content.heroes[selectedHeroIndex] : content.heroes[0]
        player = Player.from(hero: hero, weapons: content.weapons, items: content.items)
        player.maxHP += meta.hpBonus
        player.hp = player.maxHP
        player.baseAP += meta.apTurnOne
        player.currentAP = player.baseAP
        player.inventory.maxSlots += meta.extraSlots
        player.baseAcc += meta.accBonus
        player.baseCrit += meta.critBonus
        scrap = 0
        run = RunState()
        nextMap(isStart: true)
    }

    func nextMap(isStart: Bool = false) {
        let length = isStart ? 4 : 3
        var nodes: [MapNode] = []
        for i in 0..<length {
            let t: NodeType
            if i == length - 1 { t = run.depth >= 2 ? .boss : .combat }
            else { t = randomNode() }
            nodes.append(MapNode(type: t))
        }
        run.nodes = nodes
        run.cursor = 0
        run.toast = ""
        run.flavor = ""
    }

    private func randomNode() -> NodeType {
        let r = Int.random(in: 0..<10)
        if r < 6 { return .combat }
        if r < 7 { return .shop }
        if r < 9 { return .mystery }
        return .repair
    }

    func beginCombat(boss: Bool) {
        let bp: EnemyBlueprint
        if boss { bp = content.enemies.first(where: {$0.tier == .boss}) ?? content.enemies.last! }
        else { bp = content.enemies.filter{$0.tier == .normal}.randomElement() ?? content.enemies.first! }
        var e = Enemy(from: bp)
        let scale = 1.0 + Double(run.depth) * 0.15
        e.maxHP = Int(Double(e.maxHP) * scale)
        e.hp = e.maxHP
        e.attack = Int(Double(e.attack) * scale)
        run.enemy = e
        run.enemyIsBoss = boss
        run.state = .playerTurn
        player.currentAP = player.baseAP
        player.block = 0
        run.flavor = bp.flavor
    }

    func endCombat(victory: Bool) {
        if victory {
            let reward = Int(Double(Int.random(in: config.scrapRewardMin...config.scrapRewardMax)) * (1.0 + meta.scrapMult))
            scrap += reward
            run.toast = "You scoop up \(reward) scrap"
        }
    }

    func afterBoss() {
        meta.gears += 1
        save.save(meta)
        run.depth += 1
    }
}
