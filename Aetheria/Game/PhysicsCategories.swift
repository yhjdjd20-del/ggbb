import Foundation

/// Physics categories. Combat uses manual distance checks; physics bodies
/// exist only for world collision (player + grounded enemies).
enum PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0x1 << 0
    static let ground: UInt32 = 0x1 << 1   // solid, always collides
    static let platform: UInt32 = 0x1 << 2 // one-way (player passes when moving up)
    static let moving: UInt32 = 0x1 << 3   // one-way moving platforms
    static let enemy: UInt32 = 0x1 << 4
}
