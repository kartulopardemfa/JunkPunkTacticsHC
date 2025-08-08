import Foundation // Core Swift utilities
import SpriteKit // 2D rendering framework

final class Game { // Central game singleton
    static let shared = Game() // Global shared instance

    let motion = MotionService() // Handles device motion
    let audio = AudioService() // Plays sound effects
    let save = SaveService() // Persists data
    let content = ContentService() // Loads game content
    let performance = PerformanceService() // Adjusts graphics/performance
    var config = RemoteConfig() // Tunable parameters

    var meta = MetaProgress() // Player's permanent progress
    var ux = UX() // User preferences
    var safeInsets = UIEdgeInsets.zero // Safe area insets

    var player = Player.from(hero: ContentDefaults.heroes[0], weapons: ContentDefaults.weapons, items: ContentDefaults.items) // Active player data
    var selectedHeroIndex: Int = 0 // Currently chosen hero

    var run = RunState() // Current run state
    var scrap: Int = 0 // Currency gained during run

    func boot() { // Initialize services at app launch
        content.load() // Load default content
        audio.preload() // Preload audio assets
        meta = save.loadMeta() // Load meta progression
        ux = save.loadUX() // Load user settings
        performance.updateThermalState() // Adjust based on device thermal state
        TextureService.shared.preload(names: [ // Preload commonly used textures
            "reel_wrench","reel_med","reel_target","reel_bolt","reel_chem","reel_magnet","reel_shield","reel_boom"
        ]) // End texture list
    } // End boot

    func startNewRun() { // Begin a new game run
        let hero = content.heroes.indices.contains(selectedHeroIndex) ? content.heroes[selectedHeroIndex] : content.heroes[0] // Choose hero
        player = Player.from(hero: hero, weapons: content.weapons, items: content.items) // Create player from hero and items
        player.maxHP += meta.hpBonus // Apply meta HP bonus
        player.hp = player.maxHP // Heal to full
        player.baseAP += meta.apTurnOne // Apply AP bonus for first turn
        player.currentAP = player.baseAP // Reset current AP
        player.inventory.maxSlots += meta.extraSlots // Add inventory slots
        player.baseAcc += meta.accBonus // Apply accuracy bonus
        player.baseCrit += meta.critBonus // Apply crit chance bonus
        scrap = 0 // Reset scrap currency
        run = RunState() // Reset run state
        nextMap(isStart: true) // Generate first map
    } // End startNewRun

    func nextMap(isStart: Bool = false) { // Generate next map nodes
        let length = isStart ? 4 : 3 // Number of nodes depends on start
        var nodes: [MapNode] = [] // Container for nodes
        for i in 0..<length { // Iterate through node slots
            let t: NodeType // Determine node type
            if i == length - 1 { t = run.depth >= 2 ? .boss : .combat } // Last node is boss/combat
            else { t = randomNode() } // Otherwise random node
            nodes.append(MapNode(type: t)) // Append node to list
        }
        run.nodes = nodes // Save nodes to run
        run.cursor = 0 // Reset cursor
        run.toast = "" // Clear toast messages
        run.flavor = "" // Clear flavor text
    } // End nextMap

    private func randomNode() -> NodeType { // Choose random node type
        let r = Int.random(in: 0..<10) // Random number 0-9
        if r < 6 { return .combat } // 60% chance combat
        if r < 7 { return .shop } // 10% shop
        if r < 9 { return .mystery } // 20% mystery
        return .repair // Otherwise repair
    } // End randomNode

    func beginCombat(boss: Bool) { // Start a combat encounter
        let bp: EnemyBlueprint // Blueprint for enemy
        if boss { bp = content.enemies.first(where: {$0.tier == .boss}) ?? content.enemies.last! } // Select boss enemy
        else { bp = content.enemies.filter{$0.tier == .normal}.randomElement() ?? content.enemies.first! } // Select random normal enemy
        var e = Enemy(from: bp) // Create enemy instance
        let scale = 1.0 + Double(run.depth) * 0.15 // Scale difficulty by depth
        e.maxHP = Int(Double(e.maxHP) * scale) // Scale enemy HP
        e.hp = e.maxHP // Reset current HP
        e.attack = Int(Double(e.attack) * scale) // Scale enemy attack
        run.enemy = e // Store enemy in run
        run.enemyIsBoss = boss // Mark boss flag
        run.state = .playerTurn // Player starts turn
        player.currentAP = player.baseAP // Reset player AP
        player.block = 0 // Reset block
        run.flavor = bp.flavor // Show enemy flavor text
    } // End beginCombat

    func endCombat(victory: Bool) { // Handle combat conclusion
        if victory { // Only reward on victory
            let reward = Int(Double(Int.random(in: config.scrapRewardMin...config.scrapRewardMax)) * (1.0 + meta.scrapMult)) // Calculate reward
            scrap += reward // Add scrap
            run.toast = "You scoop up \(reward) scrap" // Set toast message
        } // End if
    } // End endCombat

    func afterBoss() { // Called after defeating a boss
        meta.gears += 1 // Grant a gear
        save.save(meta) // Persist meta progress
        run.depth += 1 // Increase run depth
    } // End afterBoss
} // End of Game
