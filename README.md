# JunkPunkTacticsHC

JunkPunkTacticsHC is a prototype tactical RPG built with Swift and SpriteKit.

## Structure
- **AppDelegate.swift**, **SceneDelegate.swift**, **GameViewController.swift**: iOS application entry points.
- **Game.swift**: central singleton that loads content, tracks runs, and manages services.
- **Scenes**: `MainMenuScene`, `MapScene`, `InventoryScene`, `CombatScene`, `SlotScene`, `MetaScene`, `GameOverScene`, and `OnboardingScene` drive the game flow.
- **Models.swift**: data definitions for player, enemies, items, and run state.
- **Services.swift** and **ContentDefaults.swift**: supporting services and default content tables.

## Building
This project targets iOS using SpriteKit. Open the folder in Xcode and build for iOS 15 or later. Command line builds require Apple's SpriteKit frameworks, which are unavailable on Linux.

## Notes for Newcomers
Each of the core files now contains line-by-line comments to explain what the code does, making it easier to get familiar with the project structure.
