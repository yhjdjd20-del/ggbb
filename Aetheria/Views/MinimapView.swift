import SwiftUI

/// Live minimap rendered with Canvas from the scene snapshot (5 Hz).
struct MinimapView: View {
    @ObservedObject var vm: GameViewModel

    var body: some View {
        Canvas { context, size in
            guard let mm = vm.minimap, mm.levelW > 0, mm.levelH > 0 else { return }
            let sx = size.width / mm.levelW
            let sy = size.height / mm.levelH
            func map(_ p: CGPoint) -> CGPoint {
                CGPoint(x: p.x * sx, y: size.height - p.y * sy)
            }
            // Terrain.
            for rect in mm.solids {
                let r = CGRect(x: rect.minX * sx, y: size.height - rect.maxY * sy,
                               width: max(1.5, rect.width * sx), height: max(1.5, rect.height * sy))
                context.fill(Path(r), with: .color(Color(hex: "#3A4158")))
            }
            // Checkpoints.
            for cp in mm.checkpoints {
                let p = map(cp)
                context.fill(Path(CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)),
                             with: .color(Color(hex: "#3FD97C")))
            }
            // NPCs.
            for npc in mm.npcs {
                let p = map(npc)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)),
                             with: .color(Color(hex: "#FFD95E")))
            }
            // Portal.
            let pp = map(mm.portal)
            context.fill(Path(ellipseIn: CGRect(x: pp.x - 4, y: pp.y - 4, width: 8, height: 8)),
                         with: .color(mm.portalLocked ? .red : Color(hex: "#B45CFF")))
            // Boss.
            if let boss = mm.boss {
                let p = map(boss)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)),
                             with: .color(.red))
            }
            // Player.
            let pl = map(mm.player)
            context.fill(Path(ellipseIn: CGRect(x: pl.x - 3, y: pl.y - 3, width: 6, height: 6)),
                         with: .color(.white))
            context.stroke(Path(ellipseIn: CGRect(x: pl.x - 3, y: pl.y - 3, width: 6, height: 6)),
                           with: .color(.black), lineWidth: 1)
        }
        .frame(width: 185, height: 55)
        .background(Color.black.opacity(0.5))
        .cornerRadius(7)
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.panelBorder, lineWidth: 1))
    }
}
