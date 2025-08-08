import Foundation

enum ContentDefaults {
    static let weapons: [Weapon] = [
        Weapon(name: "Nail Pistol",   minDmg: 6,  maxDmg: 10, ap: 1, acc: 0.10, crit: 0.05, special: "jam:0.15"),
        Weapon(name: "Pipe",          minDmg: 10, maxDmg: 16, ap: 2, acc: -0.05, crit: 0.00, special: "bleed:2"),
        Weapon(name: "Staple SMG",    minDmg: 4,  maxDmg: 7,  ap: 1, acc: 0.05, crit: 0.02, special: "jam:0.10"),
        Weapon(name: "Rebar Cutter",  minDmg: 14, maxDmg: 22, ap: 3, acc: -0.10, crit: 0.10, special: nil),
        Weapon(name: "Arc Welder",    minDmg: 8,  maxDmg: 14, ap: 2, acc: 0.00, crit: 0.12, special: "jam:0.20"),
        Weapon(name: "Saw Fist",      minDmg: 12, maxDmg: 18, ap: 2, acc: -0.05, crit: 0.05, special: "bleed:3"),
        Weapon(name: "Bolt Thrower",  minDmg: 9,  maxDmg: 20, ap: 3, acc: -0.08, crit: 0.15, special: "jam:0.10"),
        Weapon(name: "Chem Sprayer",  minDmg: 5,  maxDmg: 9,  ap: 1, acc: 0.12, crit: 0.00, special: "bleed:2")
    ]
    static let items: [Item] = [
        Item(name: "Med Patch",       kind: .consumable, desc: "Heal 15", tags: ["heal:15"]),
        Item(name: "Heavy Patch",     kind: .consumable, desc: "Heal 25", tags: ["heal:25"]),
        Item(name: "Shock Spray",     kind: .consumable, desc: "Jam",     tags: ["jam:0.30"]),
        Item(name: "Rusty Scope",     kind: .passive,    desc: "Acc up",  tags: ["acc:+0.07"]),
        Item(name: "Oil Rag",         kind: .passive,    desc: "Dmg up",  tags: ["dmg:+0.10"]),
        Item(name: "Spare Fuses",     kind: .passive,    desc: "Crit up", tags: ["crit:+0.08"]),
        Item(name: "Aux Battery",     kind: .passive,    desc: "AP +1",   tags: ["startAP:+1"]),
        Item(name: "Hard Hat",        kind: .passive,    desc: "HP +10",  tags: ["hp:+10"])
    ]
    static let enemies: [EnemyBlueprint] = [
        EnemyBlueprint(name: "Tin Poet",      tier: .normal, maxHP: 35,  attack: 7,  flavor: "Haiku on scrap. Swings wide."),
        EnemyBlueprint(name: "Hull Butcher",  tier: .normal, maxHP: 45,  attack: 9,  flavor: "Cuts ships and arguments."),
        EnemyBlueprint(name: "Corrugator",    tier: .normal, maxHP: 55,  attack: 8,  flavor: "Keeps a spare arm named Patience."),
        EnemyBlueprint(name: "Grease Jockey", tier: .normal, maxHP: 40,  attack: 8,  flavor: "Sleeps under engines."),
        EnemyBlueprint(name: "King Clank",    tier: .boss,   maxHP: 120, attack: 14, flavor: "Crown of gears. Hates silence.")
    ]
    static let heroes: [HeroTemplate] = [
        HeroTemplate(id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
                     name: "Rivet", quote: "Keeps three screws for luck.",
                     baseHP: 60, baseAP: 3, baseAcc: 0.78, baseCrit: 0.10,
                     startingWeaponIds: [weapons[0].id, weapons[1].id],
                     traits: []),
        HeroTemplate(id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
                     name: "Spark", quote: "Sleeps with a live wire.",
                     baseHP: 55, baseAP: 4, baseAcc: 0.80, baseCrit: 0.08,
                     startingWeaponIds: [weapons[4].id, weapons[2].id],
                     traits: ["startAP:+1","acc:+0.03","jamOnHit:+0.10"]),
        HeroTemplate(id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
                     name: "Slug", quote: "Heavier metal.",
                     baseHP: 85, baseAP: 3, baseAcc: 0.70, baseCrit: 0.05,
                     startingWeaponIds: [weapons[3].id, weapons[6].id],
                     traits: ["dmg:+0.12","acc:-0.03"])
    ]
}
