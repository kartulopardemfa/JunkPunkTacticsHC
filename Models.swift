import Foundation

enum Handedness: String, Codable { case right, left }
struct UX: Codable { var handedness: Handedness = .right; var reduceMotion: Bool = false }

extension Double { func clamped(_ lo: Double, _ hi: Double) -> Double { max(lo, min(hi, self)) } }

struct Weapon: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var minDmg: Int
    var maxDmg: Int
    var ap: Int
    var acc: Double
    var crit: Double
    var special: String?
    init(id: UUID = UUID(), name: String, minDmg: Int, maxDmg: Int, ap: Int, acc: Double, crit: Double, special: String? = nil) {
        self.id = id; self.name = name; self.minDmg = minDmg; self.maxDmg = maxDmg; self.ap = ap; self.acc = acc; self.crit = crit; self.special = special
    }
    func rollDamage(crit: Bool) -> Int {
        let base = Int.random(in: minDmg...maxDmg)
        return crit ? Int(Double(base) * 1.75) : base
    }
}

enum ItemKind: String, Codable { case consumable, passive }

struct Item: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var kind: ItemKind
    var desc: String
    var tags: [String]
    init(id: UUID = UUID(), name: String, kind: ItemKind, desc: String, tags: [String]) {
        self.id = id; self.name = name; self.kind = kind; self.desc = desc; self.tags = tags
    }
}

struct Inventory: Codable, Equatable {
    var active: [Weapon]
    var slotted: [Item]
    var bag: [Item]
    var maxSlots: Int
    mutating func toggle(_ item: Item) {
        if let i = slotted.firstIndex(of: item) { slotted.remove(at: i) }
        else if slotted.count < maxSlots { slotted.append(item) }
    }
}

struct HeroTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var quote: String
    var baseHP: Int
    var baseAP: Int
    var baseAcc: Double
    var baseCrit: Double
    var startingWeaponIds: [UUID]
    var traits: [String]
}

struct Player: Codable, Equatable {
    var name: String
    var maxHP: Int
    var hp: Int
    var baseAP: Int
    var currentAP: Int
    var baseAcc: Double
    var baseCrit: Double
    var block: Int
    var inventory: Inventory
    static func from(hero: HeroTemplate, weapons: [Weapon], items: [Item]) -> Player {
        let actives = weapons.filter { hero.startingWeaponIds.contains($0.id) }
        var p = Player(
            name: hero.name, maxHP: hero.baseHP, hp: hero.baseHP,
            baseAP: hero.baseAP, currentAP: hero.baseAP,
            baseAcc: hero.baseAcc, baseCrit: hero.baseCrit, block: 0,
            inventory: Inventory(active: Array(actives.prefix(2)), slotted: [], bag: Array(items.prefix(8)), maxSlots: 6)
        )
        for t in hero.traits {
            if t.hasPrefix("startAP:"), let v = Double(String(t.split(separator: ":")[1])) {
                p.baseAP += Int(v)
            }
            if t.hasPrefix("startBlock:"), let v = Double(String(t.split(separator: ":")[1])) {
                p.block += Int(v)
            }
            if t.hasPrefix("acc:"), let v = Double(String(t.split(separator: ":")[1])) {
                p.baseAcc += v
            }
            if t.hasPrefix("crit:"), let v = Double(String(t.split(separator: ":")[1])) {
                p.baseCrit += v
            }
        }
        p.currentAP = p.baseAP
        return p
    }
}

struct EnemyBlueprint: Codable {
    enum Tier: String, Codable { case normal, boss }
    var name: String
    var tier: Tier
    var maxHP: Int
    var attack: Int
    var flavor: String
}
struct Enemy: Codable, Equatable {
    var name: String
    var maxHP: Int
    var hp: Int
    var attack: Int
    var block: Int
    var isCharging: Bool
    var bleedTurns: Int
    var jamNext: Double
    init(from bp: EnemyBlueprint) {
        name = bp.name; maxHP = bp.maxHP; hp = bp.maxHP; attack = bp.attack
        block = 0; isCharging = false; bleedTurns = 0; jamNext = 0
    }
}

enum NodeType: String, Codable { case combat, shop, mystery, repair, boss }

struct MapNode: Codable, Equatable { var type: NodeType }

struct MetaProgress: Codable {
    var gears: Int = 0
    var apTurnOne: Int = 0
    var hpBonus: Int = 0
    var dmgBonus: Double = 0
    var accBonus: Double = 0
    var critBonus: Double = 0
    var extraSlots: Int = 0
    var scrapMult: Double = 0
    var reviveUnlocked: Bool = false
    var adsRemoved: Bool = false
}

struct RunState: Codable {
    enum TurnState: String, Codable { case playerTurn, enemyTurn, victory, defeat }
    var nodes: [MapNode] = []
    var cursor: Int = 0
    var enemy: Enemy?
    var enemyIsBoss: Bool = false
    var state: TurnState = .playerTurn
    var toast: String = ""
    var flavor: String = ""
    var log: [String] = []
    var depth: Int = 0
}
