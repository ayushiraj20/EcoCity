import SceneKit
import SwiftUI
import Observation
import UIKit

@MainActor
@Observable
class SceneManager {
    var scene: SCNScene
    var cameraNode: SCNNode
    var sunLightNode: SCNNode
    var ambientLightNode: SCNNode

    var currentLevel: Level?
    var gameState: GameStateManager?
    var levelItemsRemaining: Int = 0
    var cameraTarget: SCNVector3 = SCNVector3Zero
    
    init() {
        scene = SCNScene()
        
        cameraNode = SCNNode()
        ambientLightNode = SCNNode()
        sunLightNode = SCNNode()

        scene.background.contents = UIColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1.0)
        
        let camera = SCNCamera()
        camera.zFar = 600
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 10, y: 55, z: 75)
        cameraNode.eulerAngles = SCNVector3(x: -.pi / 5.5, y: 0, z: 0)
        scene.rootNode.addChildNode(cameraNode)
        
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor(white: 0.35, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        sunLightNode.light = SCNLight()
        sunLightNode.light?.type = .directional
        sunLightNode.light?.castsShadow = false
        sunLightNode.light?.color = UIColor(white: 1.0, alpha: 1.0)
        sunLightNode.light?.intensity = 1000
        sunLightNode.position = SCNVector3(x: 15, y: 30, z: 15)
        sunLightNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
        scene.rootNode.addChildNode(sunLightNode)
    }
    
    func setupForLevel(_ level: Level) {
        self.currentLevel = level
        self.levelItemsRemaining = 0
        gameState?.isLevelActionComplete = false
        gameState?.levelItemsDone = 0
        gameState?.levelItemsTotal = 0
        
        let completed = gameState?.completedLevels ?? []
        setupCityScene(completedLevels: completed)
        
        let isAlreadyCompleted = completed.contains(level.id)
        
        let parkZone = SCNVector3(-22, 0, 4)
        let riverCenter = SCNVector3(-4, 0, 5)
        let solarZone = SCNVector3(10, 0, 5)
        let windZone = SCNVector3(4, 0, 26)
        let hydroZone = SCNVector3(-4, 0, -20)
        let roadZone = SCNVector3(18, 0, 2)
        let factoryZone = SCNVector3(8, 0, -2)
        let treatmentZone = SCNVector3(3, 0, -2)
        
        switch level.id {
        case 1:
            gameState?.levelItemsTotal = 5
            if !isAlreadyCompleted { addLevelOverlay_PlantTrees(at: parkZone) }
            cameraTarget = parkZone
            cameraNode.position = SCNVector3(x: parkZone.x, y: 24, z: parkZone.z + 26)
            cameraNode.look(at: parkZone)
        case 2:
            gameState?.levelItemsTotal = 7
            if !isAlreadyCompleted { addLevelOverlay_CleanRiver(at: riverCenter) }
            cameraTarget = riverCenter
            cameraNode.position = SCNVector3(x: riverCenter.x, y: 22, z: riverCenter.z + 22)
            cameraNode.look(at: riverCenter)
        case 3:
            gameState?.levelItemsTotal = 3
            if !isAlreadyCompleted { addLevelOverlay_Solar(at: solarZone) }
            cameraTarget = solarZone
            cameraNode.position = SCNVector3(x: solarZone.x, y: 28, z: solarZone.z + 26)
            cameraNode.look(at: solarZone)
        case 4:
            gameState?.levelItemsTotal = 3
            if !isAlreadyCompleted { addLevelOverlay_Wind(at: windZone) }
            cameraTarget = windZone
            cameraNode.position = SCNVector3(x: windZone.x, y: 22, z: windZone.z + 22)
            cameraNode.look(at: windZone)
        case 5:
            gameState?.levelItemsTotal = 1
            if !isAlreadyCompleted { addLevelOverlay_Hydro(at: hydroZone) }
            cameraTarget = hydroZone
            cameraNode.position = SCNVector3(x: hydroZone.x, y: 18, z: hydroZone.z + 22)
            cameraNode.look(at: hydroZone)
        case 6:
            gameState?.levelItemsTotal = 8
            cameraTarget = roadZone
            cameraNode.position = SCNVector3(x: roadZone.x, y: 22, z: roadZone.z + 26)
            cameraNode.look(at: roadZone)
        case 7:
            gameState?.levelItemsTotal = 2
            cameraTarget = factoryZone
            cameraNode.position = SCNVector3(x: factoryZone.x, y: 22, z: factoryZone.z + 22)
            cameraNode.look(at: factoryZone)
        case 8:
            gameState?.levelItemsTotal = 2
            cameraTarget = treatmentZone
            cameraNode.position = SCNVector3(x: treatmentZone.x, y: 18, z: treatmentZone.z + 22)
            cameraNode.look(at: treatmentZone)
        case 9:
            setupLevel9_ThrivingCity()
            cameraTarget = SCNVector3(3, 0, 5)
            cameraNode.position = SCNVector3(x: 3, y: 50, z: 60)
            cameraNode.look(at: SCNVector3(3, 0, 5))
        default: break
        }
        
        if isAlreadyCompleted {
            gameState?.levelItemsDone = gameState?.levelItemsTotal ?? 0
            gameState?.isLevelActionComplete = true
        }
        
        cameraNode.eulerAngles.z = 0
        updateAtmosphere()
    }
    
    
    func setupCityScene(completedLevels: Set<Int>) {
        scene.rootNode.childNodes.forEach { node in
            if node != cameraNode && node.light == nil {
                node.removeFromParentNode()
            }
        }
        
        buildBaseEnvironment()
        
       
        let completionRatio = Float(completedLevels.count) / 8.0
        addClouds(cleanliness: completionRatio)
        
        cameraNode.position = SCNVector3(x: 3, y: 50, z: 60)
        cameraNode.look(at: SCNVector3(3, 0, 5))
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.0
        
        let fogAlpha = max(0.0, 1.0 - completionRatio)
        if fogAlpha > 0.25 {
            scene.fogColor = UIColor(white: 0.6, alpha: CGFloat(fogAlpha * 0.25))
            scene.fogStartDistance = 40
            scene.fogEndDistance = 120
            scene.fogDensityExponent = 1.0
        } else {
            scene.fogColor = UIColor.clear
        }
        scene.background.contents = UIColor(red: 0.45, green: 0.72, blue: 0.92, alpha: 1.0)
        
        updateSunAndClouds(cleanliness: completionRatio)
        updateGroundColor(cleanliness: completionRatio)
        
        SCNTransaction.commit()
        
        
        let parkZone = SCNVector3(-22, 0, 4)
        if completedLevels.contains(1) {
           
            let grassGeo = SCNBox(width: 10, height: 0.05, length: 10, chamferRadius: 0)
            grassGeo.materials.first?.diffuse.contents = UIColor(red: 0.3, green: 0.6, blue: 0.25, alpha: 1.0)
            let grass = SCNNode(geometry: grassGeo)
            grass.position = SCNVector3(parkZone.x, 0.03, parkZone.z)
            scene.rootNode.addChildNode(grass)
            
            for i in 0..<5 {
                let tree = SCNNode()
                let trunk = SCNNode(geometry: SCNCylinder(radius: CGFloat.random(in: 0.15...0.25), height: 1.5))
                trunk.geometry?.materials.first?.diffuse.contents = UIColor.brown
                trunk.position = SCNVector3(0, 0.75, 0)
                tree.addChildNode(trunk)
                let leaves = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.8...1.2)))
                leaves.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.1, green: CGFloat.random(in: 0.6...0.9), blue: 0.2, alpha: 1.0)
                leaves.position = SCNVector3(0, 1.8, 0)
                tree.addChildNode(leaves)
                let angle = Float(i) * (Float.pi * 2 / 5)
                tree.position = SCNVector3(parkZone.x + cos(angle) * Float.random(in: 3.5...4.5), 0.75, parkZone.z + sin(angle) * Float.random(in: 3.5...4.5))
                scene.rootNode.addChildNode(tree)
            }
            addFence(from: SCNVector3(parkZone.x - 5, 0, parkZone.z - 5), to: SCNVector3(parkZone.x + 5, 0, parkZone.z - 5), posts: 6)
            addFence(from: SCNVector3(parkZone.x - 5, 0, parkZone.z + 5), to: SCNVector3(parkZone.x + 5, 0, parkZone.z + 5), posts: 6)
            addBench(at: SCNVector3(parkZone.x - 4, 0, parkZone.z), rotation: .pi / 2)
            addBench(at: SCNVector3(parkZone.x + 4, 0, parkZone.z), rotation: -.pi / 2)
            
            for i in 0..<8 {
                let stoneGeo = SCNCylinder(radius: 0.3, height: 0.04)
                stoneGeo.materials.first?.diffuse.contents = UIColor(white: 0.7, alpha: 1.0)
                let stone = SCNNode(geometry: stoneGeo)
                let t = Float(i) / 7.0
                stone.position = SCNVector3(-26 + t * 8, 0.08, 6 + sin(t * .pi) * 2)
                scene.rootNode.addChildNode(stone)
            }
            
            let swingFrame = SCNNode()
            let topBar = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 3))
            topBar.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.4, alpha: 1.0)
            topBar.eulerAngles.z = .pi / 2
            topBar.position = SCNVector3(0, 2.5, 0)
            swingFrame.addChildNode(topBar)
            for x: Float in [-1.5, 1.5] {
                let legA = SCNNode(geometry: SCNCylinder(radius: 0.04, height: 2.6))
                legA.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.4, alpha: 1.0)
                legA.position = SCNVector3(x, 1.25, 0.3)
                legA.eulerAngles.x = 0.15
                swingFrame.addChildNode(legA)
                let legB = SCNNode(geometry: SCNCylinder(radius: 0.04, height: 2.6))
                legB.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.4, alpha: 1.0)
                legB.position = SCNVector3(x, 1.25, -0.3)
                legB.eulerAngles.x = -0.15
                swingFrame.addChildNode(legB)
            }
            for x: Float in [-0.5, 0.5] {
                let chain = SCNNode(geometry: SCNCylinder(radius: 0.01, height: 1.5))
                chain.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.35, alpha: 1.0)
                chain.position = SCNVector3(x, 1.75, 0)
                swingFrame.addChildNode(chain)
                let seat = SCNNode(geometry: SCNBox(width: 0.5, height: 0.04, length: 0.2, chamferRadius: 0.02))
                seat.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.6, green: 0.3, blue: 0.15, alpha: 1.0)
                seat.position = SCNVector3(x, 1.0, 0)
                let swingAction = SCNAction.sequence([
                    SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.0),
                    SCNAction.rotateBy(x: -0.6, y: 0, z: 0, duration: 2.0),
                    SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.0)
                ])
                seat.runAction(SCNAction.repeatForever(swingAction))
                swingFrame.addChildNode(seat)
            }
            swingFrame.position = SCNVector3(-24, 0, 4)
            scene.rootNode.addChildNode(swingFrame)
            
            let slideBase = SCNNode()
            let slideLadder = SCNNode(geometry: SCNBox(width: 0.6, height: 2, length: 0.1, chamferRadius: 0))
            slideLadder.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.4, alpha: 1.0)
            slideLadder.position = SCNVector3(0, 1, 0)
            slideBase.addChildNode(slideLadder)
            let slideChute = SCNNode(geometry: SCNBox(width: 0.6, height: 0.05, length: 2.5, chamferRadius: 0.05))
            slideChute.geometry?.materials.first?.diffuse.contents = UIColor.systemYellow
            slideChute.position = SCNVector3(0, 1.2, -1.2)
            slideChute.eulerAngles.x = 0.4
            slideBase.addChildNode(slideChute)
            slideBase.position = SCNVector3(-20, 0, 4)
            scene.rootNode.addChildNode(slideBase)
            
            let merryBase = SCNNode(geometry: SCNCylinder(radius: 1.2, height: 0.1))
            merryBase.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 0.8, alpha: 1.0)
            merryBase.position = SCNVector3(-22, 0.15, 8)
            merryBase.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 4.0)))
            for angle in stride(from: 0, to: Float.pi * 2, by: Float.pi / 2) {
                let handleGeo = SCNCylinder(radius: 0.03, height: 0.6)
                handleGeo.materials.first?.diffuse.contents = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
                let handle = SCNNode(geometry: handleGeo)
                handle.position = SCNVector3(cos(angle) * 0.9, 0.35, sin(angle) * 0.9)
                merryBase.addChildNode(handle)
            }
            scene.rootNode.addChildNode(merryBase)
            
            let parkFountainBase = SCNNode(geometry: SCNCylinder(radius: 1, height: 0.4))
            parkFountainBase.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.65, alpha: 1.0)
            parkFountainBase.position = SCNVector3(-26, 0.2, 7)
            scene.rootNode.addChildNode(parkFountainBase)
            let parkFountainPillar = SCNNode(geometry: SCNCylinder(radius: 0.12, height: 0.9))
            parkFountainPillar.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.6, alpha: 1.0)
            parkFountainPillar.position = SCNVector3(-26, 0.65, 7)
            scene.rootNode.addChildNode(parkFountainPillar)
            if completedLevels.count >= 2 {
                let fWater = SCNParticleSystem()
                fWater.particleColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.7)
                fWater.birthRate = 60
                fWater.emissionDuration = 1
                fWater.loops = true
                fWater.particleLifeSpan = 0.8
                fWater.particleVelocity = 1.5
                fWater.particleSize = 0.06
                fWater.spreadingAngle = 40
                fWater.acceleration = SCNVector3(0, -2, 0)
                parkFountainPillar.addParticleSystem(fWater)
            }
            
            addMovingPerson(from: SCNVector3(-26, 0, 6), to: SCNVector3(-18, 0, 6), duration: 8)
            addMovingPerson(from: SCNVector3(-22, 0, 3), to: SCNVector3(-22, 0, 9), duration: 6)
            addStreetLamp(at: SCNVector3(-25, 0, 3))
            addStreetLamp(at: SCNVector3(-19, 0, 9))
        } else {
            let barrenGeo = SCNBox(width: 10, height: 0.05, length: 10, chamferRadius: 0)
            barrenGeo.materials.first?.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
            let barren = SCNNode(geometry: barrenGeo)
            barren.position = SCNVector3(parkZone.x, 0.03, parkZone.z)
            scene.rootNode.addChildNode(barren)
        }
      
        let riverCenterX: Float = -4
        let riverbedGeo = SCNBox(width: 7, height: 0.15, length: 48, chamferRadius: 0)
        riverbedGeo.materials.first?.diffuse.contents = UIColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
        let riverbed = SCNNode(geometry: riverbedGeo)
        riverbed.position = SCNVector3(riverCenterX, -0.02, -1)
        scene.rootNode.addChildNode(riverbed)
        
        if completedLevels.contains(2) {
            let riverGeo = SCNPlane(width: 5, height: 45)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.9)
            mat.emission.contents = UIColor(red: 0.05, green: 0.2, blue: 0.4, alpha: 0.3)
            riverGeo.materials = [mat]
            let river = SCNNode(geometry: riverGeo)
            river.eulerAngles.x = -.pi / 2
            river.position = SCNVector3(riverCenterX, 0.1, -1)
            scene.rootNode.addChildNode(river)
        } else {
            let riverGeo = SCNPlane(width: 5, height: 45)
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor(red: 0.15, green: 0.4, blue: 0.6, alpha: 0.9) // Murky water
            mat.emission.contents = UIColor(red: 0.0, green: 0.1, blue: 0.2, alpha: 0.3)
            riverGeo.materials = [mat]
            let river = SCNNode(geometry: riverGeo)
            river.eulerAngles.x = -.pi / 2
            river.position = SCNVector3(riverCenterX, 0.1, -1)
            river.name = "River"
            scene.rootNode.addChildNode(river)
            for _ in 0..<8 {
                let garb = SCNNode()
                let type = Int.random(in: 0...3)
                switch type {
                case 0:
                    let geo = SCNCapsule(capRadius: 0.1, height: 0.5)
                    geo.materials.first?.diffuse.contents = UIColor(white: 0.9, alpha: 0.6)
                    garb.geometry = geo
                    garb.eulerAngles.x = .pi / 2
                case 1:
                    let geo = SCNBox(width: 0.6, height: 0.35, length: 0.4, chamferRadius: 0.02)
                    geo.materials.first?.diffuse.contents = UIColor(red: 0.65, green: 0.5, blue: 0.3, alpha: 1.0)
                    garb.geometry = geo
                    garb.eulerAngles = SCNVector3(Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1))
                case 2:
                    let geo = SCNSphere(radius: 0.3)
                    geo.materials.first?.diffuse.contents = UIColor(white: 0.15, alpha: 0.9)
                    let main = SCNNode(geometry: geo)
                    main.scale = SCNVector3(1.2, 0.8, 1.2)
                    
                    let tieGeo = SCNCone(topRadius: 0, bottomRadius: 0.14, height: 0.25)
                    tieGeo.materials.first?.diffuse.contents = UIColor(white: 0.15, alpha: 0.9)
                    let tie = SCNNode(geometry: tieGeo)
                    tie.position = SCNVector3(0, 0.2, 0)
                    
                    garb.addChildNode(main)
                    garb.addChildNode(tie)
                    garb.eulerAngles.x = Float.random(in: -0.3...0.3)
                default:
                    let geo = SCNCylinder(radius: 0.1, height: 0.3)
                    geo.materials.first?.diffuse.contents = [UIColor.systemRed, UIColor.systemBlue, UIColor.lightGray].randomElement()!
                    
                    let topGeo = SCNCylinder(radius: 0.08, height: 0.31)
                    topGeo.materials.first?.diffuse.contents = UIColor(white: 0.8, alpha: 1.0)
                    let top = SCNNode(geometry: topGeo)
                    
                    let canNode = SCNNode(geometry: geo)
                    canNode.addChildNode(top)
                    
                    garb.addChildNode(canNode)
                    garb.eulerAngles = SCNVector3(Float.random(in: 0...3), Float.random(in: 0...3), Float.random(in: 0...3))
                }
                
                garb.position = SCNVector3(riverCenterX + Float.random(in: -1.8...1.8), 0.1, Float.random(in: -6...15))
                garb.name = "Garbage"
                
                let dur = TimeInterval.random(in: 1.2...1.8)
                let bobUp = SCNAction.moveBy(x: 0, y: 0.1, z: 0, duration: dur)
                bobUp.timingMode = .easeInEaseOut
                let bobDown = SCNAction.moveBy(x: 0, y: -0.1, z: 0, duration: dur)
                bobDown.timingMode = .easeInEaseOut
                let bobSeq = SCNAction.sequence([bobUp, bobDown])
                
                let spin = SCNAction.rotateBy(x: CGFloat.random(in: -0.2...0.2), y: CGFloat.random(in: -0.4...0.4), z: CGFloat.random(in: -0.2...0.2), duration: dur * 2)
                
                let driftDur = TimeInterval.random(in: 2.0...3.5)
                let drift = SCNAction.moveBy(x: CGFloat.random(in: -0.6...0.6), y: 0, z: CGFloat.random(in: -1.0...1.0), duration: driftDur)
                drift.timingMode = .easeInEaseOut
                let driftSeq = SCNAction.sequence([drift, drift.reversed()])
                
                let group = SCNAction.group([
                    SCNAction.repeatForever(bobSeq),
                    SCNAction.repeatForever(spin),
                    SCNAction.repeatForever(driftSeq)
                ])
                garb.runAction(group)
                
                scene.rootNode.addChildNode(garb)
            }
        }
        
        for side: Float in [-1, 1] {
            let bankGeo = SCNBox(width: 0.8, height: 0.25, length: 48, chamferRadius: 0.05)
            bankGeo.materials.first?.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.25, alpha: 1.0)
            let bank = SCNNode(geometry: bankGeo)
            bank.position = SCNVector3(riverCenterX + side * 3.2, 0.12, -1)
            scene.rootNode.addChildNode(bank)
        }
        
        let bridgeDeck = SCNNode(geometry: SCNBox(width: 10, height: 0.35, length: 2.5, chamferRadius: 0.1))
        bridgeDeck.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        bridgeDeck.position = SCNVector3(riverCenterX, 0.6, 0)
        scene.rootNode.addChildNode(bridgeDeck)
        for side: Float in [-1.1, 1.1] {
            let railGeo = SCNBox(width: 10, height: 0.35, length: 0.08, chamferRadius: 0)
            railGeo.materials.first?.diffuse.contents = UIColor(white: 0.35, alpha: 1.0)
            let rail = SCNNode(geometry: railGeo)
            rail.position = SCNVector3(riverCenterX, 0.95, side)
            scene.rootNode.addChildNode(rail)
        }
        
        let fBase = SCNNode(geometry: SCNCylinder(radius: 0.6, height: 0.2))
        fBase.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 1.0)
        fBase.position = SCNVector3(riverCenterX, 0.15, 8)
        scene.rootNode.addChildNode(fBase)
        
        let fPillar = SCNNode(geometry: SCNCylinder(radius: 0.08, height: 0.6))
        fPillar.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.55, green: 0.53, blue: 0.5, alpha: 1.0)
        fPillar.position = SCNVector3(riverCenterX, 0.5, 8)
        scene.rootNode.addChildNode(fPillar)
        
        let fSpray = SCNParticleSystem()
        fSpray.birthRate = 180
        fSpray.emissionDuration = 1
        fSpray.loops = true
        fSpray.particleLifeSpan = 1.0
        fSpray.particleLifeSpanVariation = 0.3
        fSpray.particleVelocity = 3.5
        fSpray.particleVelocityVariation = 0.8
        fSpray.emittingDirection = SCNVector3(0, 1, 0)
        fSpray.spreadingAngle = 15
        fSpray.particleColor = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.8)
        fSpray.particleColorVariation = SCNVector4(0.05, 0.05, 0.0, 0.15)
        fSpray.particleSize = 0.06
        fSpray.particleSizeVariation = 0.02
        fSpray.acceleration = SCNVector3(0, -6, 0)
        fSpray.blendMode = .alpha
        
        let fOpacity = CAKeyframeAnimation()
        fOpacity.values = [0.0, 0.9, 0.7, 0.0]
        fOpacity.keyTimes = [0.0, 0.1, 0.6, 1.0]
        fSpray.propertyControllers = [.opacity: SCNParticlePropertyController(animation: fOpacity)]
        
        let fSprayNode = SCNNode()
        fSprayNode.position = SCNVector3(riverCenterX, 0.85, 8)
        fSprayNode.addParticleSystem(fSpray)
        scene.rootNode.addChildNode(fSprayNode)
        
        
        let solarZone = SCNVector3(10, 0, 5)
        let solarHeights: [CGFloat] = [5, 7, 4]
        let solarXOffsets: [Float] = [-3, 0, 3]
        for i in 0..<3 {
            let h = solarHeights[i]
            let bldgGeo = SCNBox(width: 3, height: h, length: 3, chamferRadius: 0.1)
            bldgGeo.materials.first?.diffuse.contents = UIColor(white: CGFloat.random(in: 0.4...0.55), alpha: 1.0)
            let bldg = SCNNode(geometry: bldgGeo)
            bldg.position = SCNVector3(solarZone.x + solarXOffsets[i], Float(h / 2), solarZone.z)
            scene.rootNode.addChildNode(bldg)
            addWindowsToBuilding(bldg, rows: max(2, Int(h / 2)), cols: 1, buildingWidth: 3, buildingHeight: h)
            
            if completedLevels.contains(3) {
                let panelGeo = SCNBox(width: 2.5, height: 0.15, length: 2.5, chamferRadius: 0)
                panelGeo.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
                let panel = SCNNode(geometry: panelGeo)
                panel.position = SCNVector3(solarZone.x + solarXOffsets[i], Float(h) + 0.1, solarZone.z)
                scene.rootNode.addChildNode(panel)
            }
        }
        
  
        let windZone = SCNVector3(4, 0, 26)
        if completedLevels.contains(4) {
            let padOffsets: [SCNVector3] = [SCNVector3(-3.5, 0, -2.5), SCNVector3(0, 0, 0), SCNVector3(3.5, 0, -1.0)]
            for i in 0..<3 {
                let turbine = SCNNode()
                let pole = SCNNode(geometry: SCNCylinder(radius: 0.1, height: 5))
                pole.geometry?.materials.first?.diffuse.contents = UIColor.white
                pole.position = SCNVector3(0, 2.5, 0)
                turbine.addChildNode(pole)
                
                let hub = SCNNode()
                hub.position = SCNVector3(0, 4.8, 0.2)
                for angle in [0, 120, 240] {
                    let blade = SCNNode(geometry: SCNBox(width: 0.3, height: 2.0, length: 0.1, chamferRadius: 0))
                    blade.geometry?.materials.first?.diffuse.contents = UIColor.white
                    blade.pivot = SCNMatrix4MakeTranslation(0, -1.0, 0)
                    blade.eulerAngles.z = Float(angle) * .pi / 180
                    hub.addChildNode(blade)
                }
                turbine.addChildNode(hub)
                
                hub.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 2.0)))
                
                turbine.position = SCNVector3(windZone.x + padOffsets[i].x, 0, windZone.z + padOffsets[i].z)
                scene.rootNode.addChildNode(turbine)
            }
        }
        let hydroZone = SCNVector3(-4, 0, -20)
        
        let hydroRiverGeo = SCNBox(width: 8, height: 0.12, length: 8, chamferRadius: 0.5)
        hydroRiverGeo.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.9)
        let hydroRiver = SCNNode(geometry: hydroRiverGeo)
        hydroRiver.position = SCNVector3(hydroZone.x, 0.08, hydroZone.z - 3)
        scene.rootNode.addChildNode(hydroRiver)
        for side: Float in [-1, 1] {
            let bankGeo = SCNBox(width: 0.6, height: 0.2, length: 8, chamferRadius: 0.05)
            bankGeo.materials.first?.diffuse.contents = UIColor(red: 0.4, green: 0.35, blue: 0.25, alpha: 1.0)
            let bank = SCNNode(geometry: bankGeo)
            bank.position = SCNVector3(hydroZone.x + side * 4.5, 0.1, hydroZone.z - 3)
            scene.rootNode.addChildNode(bank)
        }
        if completedLevels.contains(5) {
            let damWallGeo = SCNBox(width: 9, height: 4, length: 1.8, chamferRadius: 0.05)
            let concreteMat = SCNMaterial()
            concreteMat.diffuse.contents = UIColor(red: 0.7, green: 0.68, blue: 0.65, alpha: 1.0)
            damWallGeo.materials = [concreteMat]
            let damWall = SCNNode(geometry: damWallGeo)
            damWall.position = SCNVector3(hydroZone.x, 2, hydroZone.z)
            scene.rootNode.addChildNode(damWall)
            
            for (yOff, wScale) in [(Float(0.6), Float(1.0)), (Float(1.8), Float(0.85))] {
                let ledgeGeo = SCNBox(width: CGFloat(9.2 * wScale), height: 0.15, length: 0.4, chamferRadius: 0)
                ledgeGeo.materials.first?.diffuse.contents = UIColor(red: 0.65, green: 0.63, blue: 0.6, alpha: 1.0)
                let ledge = SCNNode(geometry: ledgeGeo)
                ledge.position = SCNVector3(hydroZone.x, yOff, hydroZone.z + 1.0)
                scene.rootNode.addChildNode(ledge)
            }
            
            for xOff: Float in [-3, -1, 1, 3] {
                let buttGeo = SCNBox(width: 0.4, height: 3.5, length: 1.2, chamferRadius: 0)
                buttGeo.materials.first?.diffuse.contents = UIColor(red: 0.62, green: 0.6, blue: 0.57, alpha: 1.0)
                let butt = SCNNode(geometry: buttGeo)
                butt.position = SCNVector3(hydroZone.x + xOff, 1.75, hydroZone.z + 1.2)
                scene.rootNode.addChildNode(butt)
            }
            
            for side: Float in [-0.6, 0.6] {
                let railGeo = SCNBox(width: 9, height: 0.2, length: 0.06, chamferRadius: 0)
                railGeo.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
                let rail = SCNNode(geometry: railGeo)
                rail.position = SCNVector3(hydroZone.x, 4.1, hydroZone.z + side)
                scene.rootNode.addChildNode(rail)
            }
            
            for xCenter: Float in [-2, 0, 2] {
                let sheetGeo = SCNBox(width: 1.5, height: 3.8, length: 0.1, chamferRadius: 0)
                sheetGeo.materials.first?.diffuse.contents = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85) // Frothy white-blue
                let waterSheet = SCNNode(geometry: sheetGeo)
                waterSheet.position = SCNVector3(hydroZone.x + xCenter, 1.9, hydroZone.z + 1.2)
                waterSheet.eulerAngles.x = 0.1
                scene.rootNode.addChildNode(waterSheet)
                
                let mistParticles = SCNParticleSystem()
                mistParticles.particleColor = UIColor(white: 1.0, alpha: 0.45)
                mistParticles.birthRate = 80
                mistParticles.emissionDuration = 1
                mistParticles.loops = true
                mistParticles.particleLifeSpan = 0.8
                mistParticles.particleVelocity = 1.2
                mistParticles.spreadingAngle = 60
                mistParticles.particleSize = 0.6
                mistParticles.blendMode = .alpha
                let mistNode = SCNNode()
                mistNode.position = SCNVector3(hydroZone.x + xCenter, 0.2, hydroZone.z + 1.5)
                mistNode.addParticleSystem(mistParticles)
                scene.rootNode.addChildNode(mistNode)
            }
        }
        

        
        let roadX: Float = 18 // for bus stop reference
        
        let isEV = completedLevels.contains(6)
        let colors: [UIColor] = isEV ? 
            [.systemGreen, UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0), UIColor(red: 0.1, green: 0.6, blue: 0.4, alpha: 1.0), .systemGreen, UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)] :
            [UIColor(red: 0.75, green: 0.12, blue: 0.12, alpha: 1.0), UIColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1.0), UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0), UIColor(red: 0.7, green: 0.15, blue: 0.15, alpha: 1.0), UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0)]
            
        let roadConfigs: [(pos: Float, isVert: Bool, count: [Int])] = [
            (-12, true, [-2, 0, 2]),        // 3 cars
            (18, true, [0, 1, 2]),          // 3 cars
            (32, true, [-1, 1])             // 2 cars
        ]
        
        for config in roadConfigs {
            for i in config.count {
                let laneOffset = (i % 2 == 0 ? Float(-1) : Float(1))
                let car = buildRealisticCar(color: colors[(i + 2 + colors.count) % colors.count], isEV: isEV)
                let isForward = (laneOffset > 0)
                let speed: Float = 2.5
                let halfRoad: Float = 22.0
                
                if config.isVert {
                    let startZ = Float(i) * 6
                    car.position = SCNVector3(config.pos + laneOffset, 0.0, startZ)
                    car.eulerAngles.y = isForward ? 0 : .pi
                    
                    let distToEdge = isForward ? (halfRoad - startZ) : (startZ - (-halfRoad))
                    let timeToEdge = TimeInterval(abs(distToEdge) / speed)
                    let zMoveOut = isForward ? CGFloat(distToEdge) : CGFloat(-distToEdge)
                    let driveOut = SCNAction.moveBy(x: 0, y: 0, z: zMoveOut, duration: timeToEdge)
                    
                    let zTeleport = isForward ? CGFloat(-halfRoad * 2) : CGFloat(halfRoad * 2)
                    let teleportBack = SCNAction.moveBy(x: 0, y: 0, z: zTeleport, duration: 0.01)
                    
                    let zFull = isForward ? CGFloat(halfRoad * 2) : CGFloat(-halfRoad * 2)
                    let driveFull = SCNAction.moveBy(x: 0, y: 0, z: zFull, duration: TimeInterval(halfRoad * 2 / speed))
                    
                    let loop = SCNAction.repeatForever(SCNAction.sequence([driveFull, teleportBack]))
                    car.runAction(SCNAction.sequence([driveOut, teleportBack, loop]))
                } else {
                    car.position = SCNVector3(Float(i) * 6, 0.0, config.pos + laneOffset)
                    car.eulerAngles.y = (laneOffset < 0) ? .pi / 2 : -.pi / 2
                }
                scene.rootNode.addChildNode(car)
            }
        }
        addTrafficLight(at: SCNVector3(roadX - 3, 0, -8))
        addBusStopShelter(at: SCNVector3(roadX + 3.5, 0, 3))
        
        let factoryZone = SCNVector3(8, 0, -2)
        let factoryGeo = SCNBox(width: 5, height: 4, length: 5, chamferRadius: 0)
        factoryGeo.materials.first?.diffuse.contents = UIColor.darkGray
        let factoryNode = SCNNode(geometry: factoryGeo)
        factoryNode.position = SCNVector3(factoryZone.x, 2, factoryZone.z)
        scene.rootNode.addChildNode(factoryNode)
        
        for xOff: Float in [-1.5, 1.5] {
            let chimney = SCNNode(geometry: SCNCylinder(radius: 0.5, height: 3))
            chimney.geometry?.materials.first?.diffuse.contents = UIColor.gray
            chimney.position = SCNVector3(factoryZone.x + xOff, 3.5, factoryZone.z)
            chimney.name = "Chimney"
            scene.rootNode.addChildNode(chimney)
            if completedLevels.contains(7) {
                let filterGeo = SCNCylinder(radius: 0.6, height: 1)
                filterGeo.materials.first?.diffuse.contents = UIColor.systemBlue
                let filter = SCNNode(geometry: filterGeo)
                filter.position = SCNVector3(0, 1.5, 0)
                chimney.addChildNode(filter)
            } else {
                let smoke = SCNParticleSystem()
                smoke.particleColor = UIColor(white: 0.2, alpha: 0.6)
                smoke.particleColorVariation = SCNVector4(0.05, 0.05, 0.05, 0.15)
                smoke.birthRate = 40
                smoke.emissionDuration = 1
                smoke.loops = true
                smoke.particleLifeSpan = 3.0
                smoke.particleLifeSpanVariation = 1.0
                smoke.particleVelocity = 1.5
                smoke.particleVelocityVariation = 0.5
                smoke.emittingDirection = SCNVector3(0, 1, 0)
                smoke.spreadingAngle = 15
                smoke.particleSize = 0.4
                smoke.particleSizeVariation = 0.2
                smoke.blendMode = .alpha
                smoke.acceleration = SCNVector3(0.3, 0.5, 0) // Slight wind drift
                
                let smokeNode = SCNNode()
                smokeNode.position = SCNVector3(0, 1.8, 0)
                smokeNode.addParticleSystem(smoke)
                chimney.addChildNode(smokeNode)
            }
        }
        let containerColors: [UIColor] = [
            UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0)
        ]
        for (idx, zOff) in [Float(-3), Float(3)].enumerated() {
            let cGeo = SCNBox(width: 2.5, height: 1.2, length: 1.2, chamferRadius: 0.05)
            cGeo.materials.first?.diffuse.contents = containerColors[idx]
            let c = SCNNode(geometry: cGeo)
            c.position = SCNVector3(factoryZone.x + 4, 0.6, factoryZone.z + zOff)
            scene.rootNode.addChildNode(c)
        }
        
        let treatmentZone = SCNVector3(3, 0, -3.5)
        let treatmentFactory = SCNNode(geometry: SCNBox(width: 3, height: 2.5, length: 3, chamferRadius: 0))
        treatmentFactory.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.35, alpha: 1.0)
        treatmentFactory.position = SCNVector3(treatmentZone.x, 1.25, treatmentZone.z)
        scene.rootNode.addChildNode(treatmentFactory)
        
        let corridorGeo = SCNBox(width: 1.0, height: 1.5, length: 1.5, chamferRadius: 0)
        corridorGeo.materials.first?.diffuse.contents = UIColor(white: 0.35, alpha: 1.0)
        let corridor = SCNNode(geometry: corridorGeo)
        corridor.position = SCNVector3(5.0, 0.75, treatmentZone.z) // bridges x=4.5 to x=5.5
        scene.rootNode.addChildNode(corridor)
        for zOff: Float in [-0.5, 0.5] {
            let pipeZ = treatmentZone.z + zOff * 2
            let pipe = SCNNode(geometry: SCNCylinder(radius: 0.3, height: 7))
            pipe.eulerAngles.z = .pi / 2
            pipe.position = SCNVector3(-0.5, 0.8, pipeZ)
            pipe.name = completedLevels.contains(8) ? "CleanPipe" : "ToxicPipe"
            scene.rootNode.addChildNode(pipe)
            
            let spoutPos = SCNVector3(-4.0, pipe.position.y - 0.2, pipeZ)
            
            if completedLevels.contains(8) {
                pipe.geometry?.materials.first?.diffuse.contents = UIColor.systemBlue
                
                let cleanDripNode = SCNNode()
                cleanDripNode.position = spoutPos
                scene.rootNode.addChildNode(cleanDripNode)
                
                let cleanP = SCNParticleSystem()
                cleanP.particleColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.9)
                cleanP.birthRate = 100
                cleanP.emissionDuration = 1
                cleanP.loops = true
                cleanP.particleLifeSpan = 0.6
                cleanP.particleSize = 0.15
                cleanP.emittingDirection = SCNVector3(0, -1, 0)
                cleanP.particleVelocity = 2.5
                cleanP.spreadingAngle = 10
                cleanDripNode.addParticleSystem(cleanP)
            } else {
                pipe.geometry?.materials.first?.diffuse.contents = UIColor.gray
                
                let dripNode = SCNNode()
                dripNode.name = "ToxicDrip"
                dripNode.position = spoutPos
                scene.rootNode.addChildNode(dripNode)
                
                let toxicP = SCNParticleSystem()
                toxicP.particleColor = UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 0.9)
                toxicP.birthRate = 120
                toxicP.emissionDuration = 1
                toxicP.loops = true
                toxicP.particleLifeSpan = 0.4
                toxicP.particleSize = 0.15
                toxicP.emittingDirection = SCNVector3(0, -1, 0)
                toxicP.particleVelocity = 2.5
                toxicP.spreadingAngle = 10
                dripNode.addParticleSystem(toxicP)
                
                let patchGeo = SCNPlane(width: 1.5, height: 1.5)
                patchGeo.materials.first?.diffuse.contents = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.6)
                patchGeo.materials.first?.emission.contents = UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 0.3)
                let patchNode = SCNNode(geometry: patchGeo)
                patchNode.name = "ToxicPatch"
                patchNode.eulerAngles.x = -.pi / 2
                patchNode.position = SCNVector3(spoutPos.x, 0.081, spoutPos.z)
                patchNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: .pi*2, duration: 4.0)))
                
                let splat = SCNParticleSystem()
                splat.particleColor = UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.8)
                splat.birthRate = 40
                splat.particleLifeSpan = 1.0
                splat.particleSize = 0.2
                splat.particleVelocity = 0.5
                splat.emittingDirection = SCNVector3(0, 1, 0)
                splat.spreadingAngle = 80
                splat.emitterShape = SCNSphere(radius: 0.5)
                patchNode.addParticleSystem(splat)
                scene.rootNode.addChildNode(patchNode)
            }
        }
        
        addMovingPerson(from: SCNVector3(roadX - 3.5, 0, -10), to: SCNVector3(roadX - 3.5, 0, 12), duration: 10)
        addMovingPerson(from: SCNVector3(roadX + 3.5, 0, 10), to: SCNVector3(roadX + 3.5, 0, -8), duration: 12)
        addMovingPerson(from: SCNVector3(4, 0, -3), to: SCNVector3(4, 0, 12), duration: 14)
        addMovingPerson(from: SCNVector3(6, 0, 12), to: SCNVector3(6, 0, -3), duration: 11)
        addMovingPerson(from: SCNVector3(-14, 0, -5), to: SCNVector3(-14, 0, 12), duration: 13)
        addMovingPerson(from: SCNVector3(-10, 0, 10), to: SCNVector3(-10, 0, -3), duration: 8)
                if completedLevels.count >= 4 {
            addStickFigure(at: SCNVector3(roadX + 3.5, 0, 3.5)) // at bus stop
            addStickFigure(at: SCNVector3(-10, 0, parkZone.z)) // west sidewalk near park
            addMovingPerson(from: SCNVector3(8, 0, -3), to: SCNVector3(8, 0, 10), duration: 9)
        }
        if completedLevels.count >= 6 {
            addStickFigure(at: SCNVector3(-12, 0, -3))
            addMovingPerson(from: SCNVector3(-14, 0, -3), to: SCNVector3(-14, 0, 8), duration: 10)
            addBench(at: SCNVector3(1, 0, parkZone.z + 6))
        }
        
        for z in stride(from: -12, through: 12, by: 6) {
            addStreetLamp(at: SCNVector3(roadX - 3, 0, Float(z)))
        }
      
        let homeColors: [(wall: UIColor, roof: UIColor)] = [
            (UIColor(red: 0.9, green: 0.85, blue: 0.75, alpha: 1.0), UIColor(red: 0.7, green: 0.25, blue: 0.2, alpha: 1.0)),
            (UIColor(red: 0.85, green: 0.9, blue: 0.8, alpha: 1.0), UIColor(red: 0.35, green: 0.5, blue: 0.3, alpha: 1.0)),
            (UIColor(red: 0.8, green: 0.85, blue: 0.92, alpha: 1.0), UIColor(red: 0.3, green: 0.35, blue: 0.55, alpha: 1.0)),
            (UIColor(red: 0.92, green: 0.88, blue: 0.8, alpha: 1.0), UIColor(red: 0.55, green: 0.3, blue: 0.2, alpha: 1.0)),
            (UIColor(red: 0.88, green: 0.82, blue: 0.78, alpha: 1.0), UIColor(red: 0.4, green: 0.25, blue: 0.2, alpha: 1.0))
        ]
        
        for (idx, xPos) in ([-16] as [Float]).enumerated() {
            let colors = homeColors[idx % homeColors.count]
            addHouse(at: SCNVector3(xPos, 0, 17), wallColor: colors.wall, roofColor: colors.roof)
        }
      
        for (idx, xPos) in ([22, 28, 38, 42] as [Float]).enumerated() {
            let colors = homeColors[(idx + 2) % homeColors.count]
            addHouse(at: SCNVector3(xPos, 0, 17), wallColor: colors.wall, roofColor: colors.roof)
        }
        addHouse(at: SCNVector3(-16, 0, 24), wallColor: homeColors[2].wall, roofColor: homeColors[2].roof)
        addHouse(at: SCNVector3(25, 0, 24), wallColor: homeColors[3].wall, roofColor: homeColors[3].roof)
        addHouse(at: SCNVector3(38, 0, 24), wallColor: homeColors[1].wall, roofColor: homeColors[1].roof)
        addHouse(at: SCNVector3(42, 0, 24), wallColor: homeColors[0].wall, roofColor: homeColors[0].roof)
        addHouse(at: SCNVector3(-16, 0, 30), wallColor: homeColors[3].wall, roofColor: homeColors[3].roof)
        addHouse(at: SCNVector3(4, 0, 30), wallColor: homeColors[2].wall, roofColor: homeColors[2].roof)
        addHouse(at: SCNVector3(22, 0, 30), wallColor: homeColors[0].wall, roofColor: homeColors[0].roof)
        addHouse(at: SCNVector3(28, 0, 30), wallColor: homeColors[4].wall, roofColor: homeColors[4].roof)
        addHouse(at: SCNVector3(38, 0, 30), wallColor: homeColors[3].wall, roofColor: homeColors[3].roof)
        addHouse(at: SCNVector3(42, 0, 30), wallColor: homeColors[2].wall, roofColor: homeColors[2].roof)
        addHouse(at: SCNVector3(-16, 0, 36), wallColor: homeColors[4].wall, roofColor: homeColors[4].roof)
        addHouse(at: SCNVector3(4, 0, 36), wallColor: homeColors[1].wall, roofColor: homeColors[1].roof)
        addHouse(at: SCNVector3(22, 0, 36), wallColor: homeColors[3].wall, roofColor: homeColors[3].roof)
        addHouse(at: SCNVector3(38, 0, 36), wallColor: homeColors[0].wall, roofColor: homeColors[0].roof)
        
        addFence(from: SCNVector3(-18, 0, 15), to: SCNVector3(-14, 0, 15), posts: 4)
        addFence(from: SCNVector3(20, 0, 15), to: SCNVector3(44, 0, 15), posts: 12)
        addFence(from: SCNVector3(-18, 0, 28), to: SCNVector3(-14, 0, 28), posts: 4)
        addFence(from: SCNVector3(2, 0, 28), to: SCNVector3(44, 0, 28), posts: 22)
        addFence(from: SCNVector3(-18, 0, 34), to: SCNVector3(-14, 0, 34), posts: 4)
        addFence(from: SCNVector3(2, 0, 34), to: SCNVector3(44, 0, 34), posts: 22)
        
       
        

        if completedLevels.count >= 4 {
            addFlyingBird(at: SCNVector3(0, 0, 5), radius: 8, height: 12, duration: 15)
            addFlyingBird(at: SCNVector3(-4, 0, 2), radius: 6, height: 16, duration: 11)
            addFlyingBird(at: SCNVector3(4, 0, 8), radius: 10, height: 14, duration: 19)
            addFlyingBird(at: SCNVector3(8, 0, -2), radius: 5, height: 10, duration: 13)
        }
    }
    
    private func updateAtmosphere() {
        if let gameState = gameState {
            let fogAlpha = max(0.0, min(1.0, gameState.globalAQI / 400.0))
            if fogAlpha > 0.15 && gameState.globalAQI > 80 {
                scene.fogColor = UIColor(white: 0.6, alpha: CGFloat(fogAlpha * 0.3))
                scene.fogStartDistance = 30
                scene.fogEndDistance = 80
                scene.fogDensityExponent = 1.0
            } else {
                scene.fogColor = UIColor.clear
            }
            scene.background.contents = UIColor(red: 0.45, green: 0.72, blue: 0.92, alpha: 1.0)
            
            let cleanliness = max(0.0, min(1.0, 1.0 - Float(gameState.globalAQI / 400.0)))
            updateSunAndClouds(cleanliness: cleanliness)
            updateGroundColor(cleanliness: cleanliness)
        }
    }
    private func updateGroundColor(cleanliness: Float) {
        guard let floor = scene.rootNode.childNode(withName: "GroundFloor", recursively: false) else { return }
        let r = CGFloat(0.35 - 0.10 * cleanliness)
        let g = CGFloat(0.30 + 0.25 * cleanliness)
        let b = CGFloat(0.20)
        floor.geometry?.materials.first?.diffuse.contents = UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    private func updateSunAndClouds(cleanliness: Float) {
        let sunWhiteness = 0.55 + cleanliness * 0.45  // 0.55 (smoggy amber) → 1.0 (pure white)
        let sunIntensity = 500 + cleanliness * 500     // 500 (dim) → 1000 (full brightness)
        let ambientWhiteness = 0.15 + cleanliness * 0.2 // 0.15 (dark) → 0.35 (normal)
        
        sunLightNode.light?.color = UIColor(
            red: CGFloat(sunWhiteness),
            green: CGFloat(sunWhiteness * (0.85 + cleanliness * 0.15)),  // slightly less green when polluted
            blue: CGFloat(sunWhiteness * (0.6 + cleanliness * 0.4)),    // much less blue when polluted (warm tint)
            alpha: 1.0
        )
        sunLightNode.light?.intensity = CGFloat(sunIntensity)
        ambientLightNode.light?.color = UIColor(white: CGFloat(ambientWhiteness), alpha: 1.0)
        
        if let existingSun = scene.rootNode.childNode(withName: "PhysicalSun", recursively: false) {
            existingSun.removeFromParentNode()
        }
        
        if cleanliness > 0.5 {
            let sunGeo = SCNSphere(radius: 2.5)
            sunGeo.materials.first?.diffuse.contents = UIColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            sunGeo.materials.first?.emission.contents = UIColor(red: 1.0, green: 0.95, blue: 0.6, alpha: 1.0)
            sunGeo.materials.first?.lightingModel = .constant
            sunGeo.materials.first?.isDoubleSided = true
            let physicalSun = SCNNode(geometry: sunGeo)
            physicalSun.position = SCNVector3(15, 30, -35)
            physicalSun.name = "PhysicalSun"
            let opacity = CGFloat((cleanliness - 0.5) * 2.0)
            physicalSun.opacity = opacity
            scene.rootNode.addChildNode(physicalSun)
            
            let haloGeo = SCNPlane(width: 14, height: 14)
            let size = CGSize(width: 64, height: 64)
            UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
            let ctx = UIGraphicsGetCurrentContext()!
            let colors = [
                UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 0.9).cgColor,
                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.4).cgColor,
                UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 0.4, 1.0])!
            let center = CGPoint(x: 32, y: 32)
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 32, options: [])
            let haloImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let haloMaterial = SCNMaterial()
            haloMaterial.diffuse.contents = haloImage
            haloMaterial.emission.contents = haloImage // Emit its own light
            haloMaterial.isDoubleSided = true
            haloMaterial.blendMode = .add // Make it glow against the sky instead of painting over it
            haloGeo.materials = [haloMaterial]
            let haloNode = SCNNode(geometry: haloGeo)
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = .all
            haloNode.constraints = [constraint]
            physicalSun.addChildNode(haloNode)
        }
        
        let cloudBrightness: CGFloat = CGFloat(0.35 + cleanliness * 0.65) // 0.35 (dark gray) → 1.0 (white)
        let cloudAlpha: CGFloat = CGFloat(0.6 + cleanliness * 0.32)       // 0.6 (more opaque/heavy) → 0.92 (light/airy)
        
        scene.rootNode.childNodes.filter { $0.name == "Cloud" }.forEach { cloudNode in
            cloudNode.childNodes.forEach { puffNode in
                if let material = puffNode.geometry?.materials.first {
                    material.diffuse.contents = UIColor(white: cloudBrightness, alpha: cloudAlpha)
                    let emissionR = CGFloat(0.4 * (1.0 - cleanliness)) // brownish when polluted
                    let emissionG = CGFloat(0.3 * (1.0 - cleanliness))
                    let emissionB = CGFloat(0.15 * (1.0 - cleanliness))
                    material.emission.contents = UIColor(red: emissionR, green: emissionG, blue: emissionB, alpha: 0.4)
                    material.transparency = cloudAlpha
                }
            }
        }
    }
    
    
    enum ActionType {
        case plantTree
        case cleanGarbage
        case placeSolar
        case placeWindmill
        case placeDam
        case deployEV
        case installFilter
        case treatWater
    }
    
    @MainActor func handleTap(at point: CGPoint, in scnView: SCNView) {
        let hitResults = scnView.hitTest(point, options: [:])
        
        guard let firstHit = hitResults.first else { return }
        
        if currentLevel?.id == 1, firstHit.node.name == "PlantPad" || firstHit.node.name == "PlantPadHighlight" || firstHit.node.parent?.name == "PlantPad" {
            guard !(gameState?.isLevelActionComplete ?? false) else { return }
            if let pad = scene.rootNode.childNode(withName: "PlantPad", recursively: true) {
                var localPos = pad.convertPosition(firstHit.worldCoordinates, from: nil)
                localPos.y = 0.05
                plantTree(at: localPos, parent: pad)
                gameState?.soundManager?.playTreePlant()
            }
            return
        }
        
        guard let lev = currentLevel else { return }
        let nodeName = firstHit.node.name ?? ""
        
        switch lev.id {
        case 2:
            var tappedNode: SCNNode? = firstHit.node
            while let n = tappedNode {
                if n.name == "Garbage" {
                    cleanGarbage(node: n)
                    gameState?.soundManager?.playGarbageClean()
                    break
                }
                tappedNode = n.parent
            }
        case 3:
            if nodeName == "SolarPad" {
                placeSolarPanel(node: firstHit.node)
                gameState?.soundManager?.playSolarInstall()
            }
        case 4:
            if nodeName == "WindPad" {
                placeWindmill(node: firstHit.node)
                gameState?.soundManager?.playWindmillPlace()
            }
        case 5:
            if nodeName == "HydroPad" {
                placeDam(node: firstHit.node)
                gameState?.soundManager?.playHydroRush()
            }
        case 6:
            var tappedNode: SCNNode? = firstHit.node
            while let n = tappedNode {
                if n.name == "GasCar" || n.name == "EV" {
                    if n.name == "GasCar" {
                        replaceWithEV(node: n)
                        gameState?.soundManager?.playEVWhirr()
                    }
                    break
                }
                tappedNode = n.parent
            }
        case 7:
            if nodeName == "Chimney" {
                addFilter(node: firstHit.node)
                gameState?.soundManager?.playFilterSnap()
            }
        case 8:
            if nodeName == "ToxicPipe" {
                addWaterTreatment(node: firstHit.node)
                gameState?.soundManager?.playWaterBubble()
            }
        default:
            break
        }
    }
    
    @MainActor func performAction(actionType: ActionType) {
        switch actionType {
        case .plantTree:
            if let pad = scene.rootNode.childNode(withName: "PlantPad", recursively: true) {
                let offsetX = Float.random(in: -4...4)
                let offsetZ = Float.random(in: -4...4)
                let pos = SCNVector3(offsetX, 0.05, offsetZ)
                plantTree(at: pos, parent: pad)
                gameState?.soundManager?.playTreePlant()
            }
        case .cleanGarbage:
            if let garbage = scene.rootNode.childNode(withName: "Garbage", recursively: true) {
                cleanGarbage(node: garbage)
                gameState?.soundManager?.playGarbageClean()
            }
        case .placeSolar:
            if let pad = scene.rootNode.childNode(withName: "SolarPad", recursively: true) {
                placeSolarPanel(node: pad)
                gameState?.soundManager?.playSolarInstall()
            }
        case .placeWindmill:
            if let pad = scene.rootNode.childNode(withName: "WindPad", recursively: true) {
                placeWindmill(node: pad)
                gameState?.soundManager?.playWindmillPlace()
            }
        case .placeDam:
            if let pad = scene.rootNode.childNode(withName: "HydroPad", recursively: true) {
                placeDam(node: pad)
                gameState?.soundManager?.playHydroRush()
            }
        case .deployEV:
            if let car = scene.rootNode.childNode(withName: "GasCar", recursively: true) {
                replaceWithEV(node: car)
                gameState?.soundManager?.playEVWhirr()
            }
        case .installFilter:
            if let chimney = scene.rootNode.childNode(withName: "Chimney", recursively: true) {
                addFilter(node: chimney)
                gameState?.soundManager?.playFilterSnap()
            }
        case .treatWater:
            if let pipe = scene.rootNode.childNode(withName: "ToxicPipe", recursively: true) {
                addWaterTreatment(node: pipe)
                gameState?.soundManager?.playWaterBubble()
            }
        }
    }
    
    private func buildBaseEnvironment() {
        let floorGeometry = SCNFloor()
        floorGeometry.reflectivity = 0
        let grassMaterial = SCNMaterial()
        grassMaterial.diffuse.contents = UIColor(red: 0.35, green: 0.35, blue: 0.25, alpha: 1.0)
        floorGeometry.materials = [grassMaterial]
        let floorNode = SCNNode(geometry: floorGeometry)
        floorNode.name = "GroundFloor"
        floorNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(floorNode)
        
        addRoad(at: SCNVector3(-12, 0.02, 0), width: 5, length: 60, axis: .z)
        addRoad(at: SCNVector3(18, 0.02, 0), width: 5, length: 60, axis: .z)
        
        addRoad(at: SCNVector3(-20.5, 0.02, -8), width: 23, length: 4, axis: .x) // left: x=-32 to x=-9
        addRoad(at: SCNVector3(25.5, 0.02, -8), width: 35, length: 4, axis: .x) // right: x=8 to x=43
        addRoad(at: SCNVector3(-20.5, 0.02, 12), width: 23, length: 4, axis: .x) // left: x=-32 to x=-9
        addRoad(at: SCNVector3(25.5, 0.02, 12), width: 35, length: 4, axis: .x) // right: x=8 to x=43
        
        addRoad(at: SCNVector3(34, 0.02, 0), width: 5, length: 60, axis: .z)
        
        for roadX: Float in [-12, 18, 34] {
            for i in stride(from: -25, through: 25, by: 3) {
                let z = Float(i)
                if z > -10 && z < -6 { continue }
                if z > 10 && z < 14 { continue }
                let dashGeo = SCNPlane(width: 0.15, height: 1.5)
                dashGeo.materials.first?.diffuse.contents = UIColor.white
                let dash = SCNNode(geometry: dashGeo)
                dash.eulerAngles.x = -.pi / 2
                dash.position = SCNVector3(roadX, 0.025, z)
                scene.rootNode.addChildNode(dash)
            }
        }
        
        for roadZ: Float in [-8, 12] {
            for i in stride(from: -28, through: 40, by: 3) {
                let x = Float(i)
                if x > -12 && x < 9 { continue } // wide skip for all river zones
                let dashGeo = SCNPlane(width: 1.5, height: 0.15)
                dashGeo.materials.first?.diffuse.contents = UIColor.white
                let dash = SCNNode(geometry: dashGeo)
                dash.eulerAngles.x = -.pi / 2
                dash.position = SCNVector3(x, 0.025, roadZ)
                scene.rootNode.addChildNode(dash)
            }
        }
        
        for roadX: Float in [-12, 18, 34] {
            for side in [-1, 1] {
                let sidewalkGeo = SCNPlane(width: 1.5, height: 60)
                sidewalkGeo.materials.first?.diffuse.contents = UIColor(white: 0.7, alpha: 1.0)
                let sidewalk = SCNNode(geometry: sidewalkGeo)
                sidewalk.eulerAngles.x = -.pi / 2
                sidewalk.position = SCNVector3(roadX + Float(side) * 3.2, 0.04, 0)
                scene.rootNode.addChildNode(sidewalk)
            }
        }
        
        let buildingConfigs: [(pos: SCNVector3, scale: SCNVector3, color: UIColor)] = [
            (SCNVector3(-20, 0, -5), SCNVector3(3, 8, 3), UIColor(white: 0.42, alpha: 1.0)),
            (SCNVector3(-26, 0, -16), SCNVector3(3, 9, 3), UIColor(white: 0.47, alpha: 1.0)),
            (SCNVector3(-26, 0, -6), SCNVector3(3, 6, 3), UIColor(red: 0.52, green: 0.47, blue: 0.42, alpha: 1.0)),
            
            (SCNVector3(12, 0, -3), SCNVector3(4, 11, 3), UIColor(red: 0.52, green: 0.48, blue: 0.4, alpha: 1.0)),
            
            (SCNVector3(24, 0, -18), SCNVector3(4, 16, 4), UIColor(white: 0.42, alpha: 1.0)),
            (SCNVector3(24, 0, -10), SCNVector3(3, 10, 3), UIColor(red: 0.5, green: 0.48, blue: 0.4, alpha: 1.0)),
            (SCNVector3(24, 0, -3), SCNVector3(3, 8, 3), UIColor(white: 0.48, alpha: 1.0)),
            (SCNVector3(24, 0, 5), SCNVector3(4, 12, 4), UIColor(red: 0.45, green: 0.42, blue: 0.38, alpha: 1.0)),
            
            (SCNVector3(40, 0, -18), SCNVector3(3, 11, 3), UIColor(white: 0.43, alpha: 1.0)),
            (SCNVector3(40, 0, -10), SCNVector3(4, 14, 4), UIColor(red: 0.47, green: 0.43, blue: 0.4, alpha: 1.0)),
            (SCNVector3(40, 0, -3), SCNVector3(3, 9, 3), UIColor(white: 0.45, alpha: 1.0)),
            (SCNVector3(40, 0, 5), SCNVector3(3, 7, 3), UIColor(red: 0.53, green: 0.48, blue: 0.44, alpha: 1.0)),
            (SCNVector3(46, 0, -14), SCNVector3(4, 13, 3), UIColor(white: 0.4, alpha: 1.0)),
            (SCNVector3(46, 0, -4), SCNVector3(3, 8, 3), UIColor(red: 0.5, green: 0.46, blue: 0.42, alpha: 1.0)),
            
            (SCNVector3(-18, 0, -25), SCNVector3(5, 22, 4), UIColor(white: 0.36, alpha: 1.0)),
            (SCNVector3(5, 0, -25), SCNVector3(4, 17, 3), UIColor(white: 0.4, alpha: 1.0)),
            (SCNVector3(14, 0, -25), SCNVector3(3, 13, 3), UIColor(red: 0.48, green: 0.44, blue: 0.38, alpha: 1.0)),
            (SCNVector3(28, 0, -25), SCNVector3(4, 15, 4), UIColor(white: 0.38, alpha: 1.0)),
            (SCNVector3(40, 0, -25), SCNVector3(3, 19, 3), UIColor(red: 0.44, green: 0.4, blue: 0.36, alpha: 1.0)),
        ]
        for cfg in buildingConfigs {
            addBuilding(at: cfg.pos, scale: cfg.scale, color: cfg.color)
        }
        
        for z in stride(from: -20, through: 20, by: 7) {
            addStreetLamp(at: SCNVector3(-9, 0, Float(z)))
            addStreetLamp(at: SCNVector3(15, 0, Float(z)))
            addStreetLamp(at: SCNVector3(31, 0, Float(z)))
        }
        for x in stride(from: -20, through: 44, by: 8) {
            if Float(x) > -9 && Float(x) < 1 { continue } // skip river zone
            addStreetLamp(at: SCNVector3(Float(x), 0, -11))
            addStreetLamp(at: SCNVector3(Float(x), 0, 15))
        }
        
        let initialCleanliness: Float
        if let gs = gameState {
            initialCleanliness = max(0.0, min(1.0, 1.0 - Float(gs.globalAQI / 400.0)))
        } else {
            initialCleanliness = 0.0 // Defaultpolluted
        }
        addClouds(cleanliness: initialCleanliness)
    }
    private func addClouds(cleanliness: Float = 0.0) {
        scene.rootNode.childNodes.filter { $0.name == "Cloud" }.forEach { $0.removeFromParentNode() }
        
        let cloudConfigs: [(pos: SCNVector3, scale: Float, speed: TimeInterval)] = [
            (SCNVector3(-20, 28, 15), 1.3, 35),
            (SCNVector3(15, 30, 20), 1.0, 40),
            (SCNVector3(-5, 32, -5), 1.5, 45),
            (SCNVector3(25, 35, 0), 0.9, 50),
            (SCNVector3(-30, 33, -15), 1.1, 42),
            (SCNVector3(10, 36, -20), 0.8, 55),
            (SCNVector3(-15, 40, -30), 0.7, 60),
            (SCNVector3(30, 42, -25), 0.6, 65),
            (SCNVector3(0, 38, 30), 1.0, 48),
            (SCNVector3(-35, 34, 10), 0.85, 52),
            (SCNVector3(20, 37, 25), 0.75, 58),
        ]
        
        let cloudBrightness: CGFloat = CGFloat(0.35 + cleanliness * 0.65)
        let cloudAlpha: CGFloat = CGFloat(0.6 + cleanliness * 0.32)
        
        for config in cloudConfigs {
            let cloud = createCloudCluster(scale: config.scale, brightness: cloudBrightness, alpha: cloudAlpha, cleanliness: cleanliness)
            cloud.name = "Cloud"
            cloud.position = config.pos
            cloud.eulerAngles.y = Float.random(in: 0...Float.pi * 2)
            scene.rootNode.addChildNode(cloud)
            
            let driftDistance: Float = 60
            let drift = SCNAction.sequence([
                SCNAction.moveBy(x: CGFloat(driftDistance), y: 0, z: CGFloat(Float.random(in: -5...5)), duration: config.speed),
                SCNAction.moveBy(x: CGFloat(-driftDistance), y: 0, z: CGFloat(Float.random(in: -5...5)), duration: config.speed)
            ])
            cloud.runAction(SCNAction.repeatForever(drift))
        }
    }
    
    private func createCloudCluster(scale: Float, brightness: CGFloat, alpha: CGFloat, cleanliness: Float) -> SCNNode {
        let cloud = SCNNode()
        
        let puffConfigs: [(offset: SCNVector3, radius: CGFloat)] = [
            (SCNVector3(0, 0, 0), 2.0),
            (SCNVector3(1.5, 0.3, 0), 1.8),
            (SCNVector3(-1.5, 0.2, 0), 1.7),
            (SCNVector3(0.8, 0.6, 0.5), 1.5),
            (SCNVector3(-0.8, 0.5, -0.5), 1.4),
            (SCNVector3(3.0, -0.2, 0.3), 1.2),
            (SCNVector3(-2.8, -0.1, -0.2), 1.1),
            (SCNVector3(0, 0.8, 0), 1.3),
            (SCNVector3(2.0, 0.1, -0.8), 1.0),
            (SCNVector3(-1.8, 0.3, 0.7), 1.0),
        ]
        
        for puff in puffConfigs {
            let sphere = SCNSphere(radius: puff.radius * CGFloat(scale))
            
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(white: brightness, alpha: alpha)
            let emR = CGFloat(0.4 * (1.0 - cleanliness))
            let emG = CGFloat(0.3 * (1.0 - cleanliness))
            let emB = CGFloat(0.15 * (1.0 - cleanliness))
            material.emission.contents = UIColor(red: emR, green: emG, blue: emB, alpha: 0.4)
            material.transparency = alpha * CGFloat(Float.random(in: 0.85...1.0))
            material.lightingModel = .constant
            material.isDoubleSided = true
            material.writesToDepthBuffer = false
            sphere.materials = [material]
            
            let puffNode = SCNNode(geometry: sphere)
            puffNode.position = SCNVector3(
                puff.offset.x * scale,
                puff.offset.y * scale,
                puff.offset.z * scale
            )
            cloud.addChildNode(puffNode)
        }
        
        return cloud
    }
    
    enum RoadAxis { case x, z }
    
    private func addRoad(at position: SCNVector3, width: CGFloat, length: CGFloat, axis: RoadAxis) {
        let roadGeo: SCNPlane
        switch axis {
        case .z:
            roadGeo = SCNPlane(width: width, height: length)
        case .x:
            roadGeo = SCNPlane(width: width, height: length)
        }
        roadGeo.materials.first?.diffuse.contents = UIColor(white: 0.25, alpha: 1.0)
        let road = SCNNode(geometry: roadGeo)
        road.eulerAngles.x = -.pi / 2
        road.position = position
        scene.rootNode.addChildNode(road)
    }
    
    private func addBuilding(at position: SCNVector3, scale: SCNVector3, color: UIColor = UIColor(white: 0.4, alpha: 1.0)) {
        let geometry = SCNBox(width: CGFloat(scale.x), height: CGFloat(scale.y), length: CGFloat(scale.z), chamferRadius: 0.2)
        geometry.materials.first?.diffuse.contents = color
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(x: position.x, y: position.y + Float(scale.y / 2), z: position.z)
        scene.rootNode.addChildNode(node)
        
        let rows = max(2, Int(scale.y / 2))
        let cols = max(1, Int(scale.x / 1.5))
        addWindowsToBuilding(node, rows: rows, cols: cols, buildingWidth: CGFloat(scale.x), buildingHeight: CGFloat(scale.y))
    }
    
    
    private func addWindowsToBuilding(_ building: SCNNode, rows: Int, cols: Int, buildingWidth: CGFloat, buildingHeight: CGFloat) {
        let winWidth: CGFloat = 0.4
        let winHeight: CGFloat = 0.6
        let spacingX = buildingWidth / CGFloat(cols + 1)
        let spacingY = buildingHeight / CGFloat(rows + 1)
        
        for r in 1...rows {
            for c in 1...cols {
                let winGeo = SCNPlane(width: winWidth, height: winHeight)
                let warmth = CGFloat.random(in: 0.7...1.0)
                winGeo.materials.first?.diffuse.contents = UIColor(red: 1.0, green: warmth, blue: 0.4, alpha: 0.9)
                winGeo.materials.first?.emission.contents = UIColor(red: 1.0, green: warmth, blue: 0.4, alpha: 0.3)
                let win = SCNNode(geometry: winGeo)
                let xOff = Float(-buildingWidth / 2 + spacingX * CGFloat(c))
                let yOff = Float(-buildingHeight / 2 + spacingY * CGFloat(r))
                win.position = SCNVector3(xOff, yOff, Float(building.geometry!.boundingBox.max.z) + 0.01)
                building.addChildNode(win)
            }
        }
    }
    
    private func addStreetLamp(at position: SCNVector3) {
        let poleGeo = SCNCylinder(radius: 0.06, height: 4)
        poleGeo.materials.first?.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
        let pole = SCNNode(geometry: poleGeo)
        pole.position = SCNVector3(position.x, 2, position.z)
        scene.rootNode.addChildNode(pole)
        
        let lampGeo = SCNSphere(radius: 0.25)
        lampGeo.materials.first?.diffuse.contents = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        lampGeo.materials.first?.emission.contents = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.8)
        let lamp = SCNNode(geometry: lampGeo)
        lamp.position = SCNVector3(position.x, 4.1, position.z)
        
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        light.intensity = 150
        light.attenuationStartDistance = 2
        light.attenuationEndDistance = 8
        lamp.light = light
        scene.rootNode.addChildNode(lamp)
    }
    
    private func addBench(at position: SCNVector3, rotation: Float = 0) {
        let bench = SCNNode()
        let seatGeo = SCNBox(width: 1.2, height: 0.08, length: 0.4, chamferRadius: 0.02)
        seatGeo.materials.first?.diffuse.contents = UIColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)
        let seat = SCNNode(geometry: seatGeo)
        seat.position = SCNVector3(0, 0.45, 0)
        bench.addChildNode(seat)
        let backGeo = SCNBox(width: 1.2, height: 0.5, length: 0.06, chamferRadius: 0.02)
        backGeo.materials.first?.diffuse.contents = UIColor(red: 0.45, green: 0.3, blue: 0.15, alpha: 1.0)
        let back = SCNNode(geometry: backGeo)
        back.position = SCNVector3(0, 0.7, -0.17)
        bench.addChildNode(back)
        for x: Float in [-0.5, 0.5] {
            let legGeo = SCNBox(width: 0.06, height: 0.45, length: 0.06, chamferRadius: 0)
            legGeo.materials.first?.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
            let leg = SCNNode(geometry: legGeo)
            leg.position = SCNVector3(x, 0.225, 0)
            bench.addChildNode(leg)
        }
        bench.position = position
        bench.eulerAngles.y = rotation
        scene.rootNode.addChildNode(bench)
    }
    
    private func addFence(from start: SCNVector3, to end: SCNVector3, posts: Int = 5) {
        let dx = (end.x - start.x) / Float(posts - 1)
        let dz = (end.z - start.z) / Float(posts - 1)
        
        for i in 0..<posts {
            let postGeo = SCNCylinder(radius: 0.04, height: 0.8)
            postGeo.materials.first?.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
            let post = SCNNode(geometry: postGeo)
            post.position = SCNVector3(start.x + dx * Float(i), 0.4, start.z + dz * Float(i))
            scene.rootNode.addChildNode(post)
        }
        
        let length = sqrt(pow(end.x - start.x, 2) + pow(end.z - start.z, 2))
        let angle = atan2(end.x - start.x, end.z - start.z)
        for h: Float in [0.3, 0.6] {
            let railGeo = SCNBox(width: 0.03, height: 0.03, length: CGFloat(length), chamferRadius: 0)
            railGeo.materials.first?.diffuse.contents = UIColor(white: 0.35, alpha: 1.0)
            let rail = SCNNode(geometry: railGeo)
            rail.position = SCNVector3((start.x + end.x) / 2, h, (start.z + end.z) / 2)
            rail.eulerAngles.y = angle
            scene.rootNode.addChildNode(rail)
        }
    }
    
    private func addStickFigure(at position: SCNVector3) {
        let person = SCNNode()
        let bodyGeo = SCNCapsule(capRadius: 0.15, height: 0.8)
        let shirtColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.8, green: 0.3, blue: 0.3, alpha: 1.0),
            UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0),
            UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 1.0)
        ]
        bodyGeo.materials.first?.diffuse.contents = shirtColors.randomElement()!
        let body = SCNNode(geometry: bodyGeo)
        body.position = SCNVector3(0, 0.6, 0)
        person.addChildNode(body)
        let headGeo = SCNSphere(radius: 0.15)
        headGeo.materials.first?.diffuse.contents = UIColor(red: 0.9, green: 0.75, blue: 0.6, alpha: 1.0)
        let head = SCNNode(geometry: headGeo)
        head.position = SCNVector3(0, 1.15, 0)
        person.addChildNode(head)
        person.position = position
        scene.rootNode.addChildNode(person)
    }
    
    private func addMovingPerson(from start: SCNVector3, to end: SCNVector3, duration: Double) {
        let person = SCNNode()
        let bodyGeo = SCNCapsule(capRadius: 0.15, height: 0.8)
        let shirtColors: [UIColor] = [
            UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.85, green: 0.3, blue: 0.25, alpha: 1.0),
            UIColor(red: 0.25, green: 0.7, blue: 0.45, alpha: 1.0),
            UIColor(red: 0.65, green: 0.35, blue: 0.7, alpha: 1.0),
            UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0),
            UIColor(red: 0.4, green: 0.6, blue: 0.7, alpha: 1.0)
        ]
        bodyGeo.materials.first?.diffuse.contents = shirtColors.randomElement()!
        let body = SCNNode(geometry: bodyGeo)
        body.position = SCNVector3(0, 0.6, 0)
        person.addChildNode(body)
        
        let headGeo = SCNSphere(radius: 0.15)
        headGeo.materials.first?.diffuse.contents = UIColor(red: 0.9, green: 0.75, blue: 0.6, alpha: 1.0)
        let head = SCNNode(geometry: headGeo)
        head.position = SCNVector3(0, 1.15, 0)
        person.addChildNode(head)
        for x: Float in [-0.08, 0.08] {
            let legGeo = SCNCylinder(radius: 0.05, height: 0.4)
            legGeo.materials.first?.diffuse.contents = UIColor(white: 0.3, alpha: 1.0)
            let leg = SCNNode(geometry: legGeo)
            leg.position = SCNVector3(x, 0.2, 0)
            person.addChildNode(leg)
        }
        
        person.position = start
        
        let dx = end.x - start.x
        let dz = end.z - start.z
        person.eulerAngles.y = atan2(dx, dz)
        
        let walk = SCNAction.sequence([
            SCNAction.move(to: end, duration: duration),
            SCNAction.run { node in node.eulerAngles.y += .pi },
            SCNAction.move(to: start, duration: duration),
            SCNAction.run { node in node.eulerAngles.y += .pi }
        ])
        person.runAction(SCNAction.repeatForever(walk))
        
        let bob = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 0.06, z: 0, duration: 0.35),
            SCNAction.moveBy(x: 0, y: -0.06, z: 0, duration: 0.35)
        ])
        body.runAction(SCNAction.repeatForever(bob))
        
        scene.rootNode.addChildNode(person)
    }
    
    
    private func addFlyingBird(at center: SCNVector3, radius: Float, height: Float, duration: Double) {
        let birdNode = SCNNode()
        let color = UIColor.white
        
        let bodyGeo = SCNCapsule(capRadius: 0.06, height: 0.3)
        bodyGeo.materials.first?.diffuse.contents = color
        let body = SCNNode(geometry: bodyGeo)
        body.eulerAngles.x = .pi / 2
        birdNode.addChildNode(body)
        
        let headGeo = SCNSphere(radius: 0.08)
        headGeo.materials.first?.diffuse.contents = color
        let head = SCNNode(geometry: headGeo)
        head.position = SCNVector3(0, 0.02, -0.15)
        birdNode.addChildNode(head)
        
        let beakGeo = SCNCone(topRadius: 0, bottomRadius: 0.03, height: 0.1)
        beakGeo.materials.first?.diffuse.contents = UIColor.systemOrange
        let beak = SCNNode(geometry: beakGeo)
        beak.eulerAngles.x = -.pi / 2
        beak.position = SCNVector3(0, 0.02, -0.22)
        birdNode.addChildNode(beak)
        
        let tailGeo = SCNBox(width: 0.1, height: 0.01, length: 0.15, chamferRadius: 0.01)
        tailGeo.materials.first?.diffuse.contents = color
        let tail = SCNNode(geometry: tailGeo)
        tail.position = SCNVector3(0, 0, 0.15)
        birdNode.addChildNode(tail)
        
        let wingGeo = SCNBox(width: 0.4, height: 0.02, length: 0.15, chamferRadius: 0.01)
        wingGeo.materials.first?.diffuse.contents = color
        
        let wing1 = SCNNode(geometry: wingGeo)
        wing1.position = SCNVector3(0.2, 0, 0)
        wing1.pivot = SCNMatrix4MakeTranslation(-0.2, 0, 0)
        
        let wing2 = SCNNode(geometry: wingGeo)
        wing2.position = SCNVector3(-0.2, 0, 0)
        wing2.pivot = SCNMatrix4MakeTranslation(0.2, 0, 0)
        
        birdNode.addChildNode(wing1)
        birdNode.addChildNode(wing2)
        
        let flapUp1 = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 4, duration: 0.2)
        let flapDown1 = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 4, duration: 0.2)
        let flapUp2 = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 4, duration: 0.2)
        let flapDown2 = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 4, duration: 0.2)
        
        flapUp1.timingMode = .easeInEaseOut
        flapDown1.timingMode = .easeInEaseOut
        flapUp2.timingMode = .easeInEaseOut
        flapDown2.timingMode = .easeInEaseOut
        
        wing1.runAction(SCNAction.repeatForever(SCNAction.sequence([flapUp1, flapDown1])))
        wing2.runAction(SCNAction.repeatForever(SCNAction.sequence([flapUp2, flapDown2])))
        
        let bobUp = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.2)
        let bobDown = SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 0.2)
        bobUp.timingMode = .easeInEaseOut
        bobDown.timingMode = .easeInEaseOut
        birdNode.runAction(SCNAction.repeatForever(SCNAction.sequence([bobUp, bobDown])))
        
        let pathNode = SCNNode()
        pathNode.position = center
        
        birdNode.position = SCNVector3(radius, height, 0)
        birdNode.eulerAngles.y = 0 
        pathNode.addChildNode(birdNode)
        
        let spin = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)
        pathNode.runAction(SCNAction.repeatForever(spin))
        
        scene.rootNode.addChildNode(pathNode)
    }
    
    private func addHouse(at position: SCNVector3, wallColor: UIColor, roofColor: UIColor) {
        let house = SCNNode()
        
        let wallGeo = SCNBox(width: 3, height: 2.2, length: 3, chamferRadius: 0.05)
        wallGeo.materials.first?.diffuse.contents = wallColor
        let walls = SCNNode(geometry: wallGeo)
        walls.position = SCNVector3(0, 1.1, 0)
        house.addChildNode(walls)
        
        let roofGeo = SCNPyramid(width: 3.4, height: 1.2, length: 3.4)
        roofGeo.materials.first?.diffuse.contents = roofColor
        let roof = SCNNode(geometry: roofGeo)
        roof.position = SCNVector3(0, 2.2, 0)
        house.addChildNode(roof)
        
        let doorGeo = SCNBox(width: 0.5, height: 0.9, length: 0.05, chamferRadius: 0.03)
        doorGeo.materials.first?.diffuse.contents = UIColor(red: 0.45, green: 0.3, blue: 0.18, alpha: 1.0)
        let door = SCNNode(geometry: doorGeo)
        door.position = SCNVector3(0, 0.5, 1.52)
        house.addChildNode(door)
        
        let knobGeo = SCNSphere(radius: 0.03)
        knobGeo.materials.first?.diffuse.contents = UIColor(red: 0.85, green: 0.75, blue: 0.3, alpha: 1.0)
        let knob = SCNNode(geometry: knobGeo)
        knob.position = SCNVector3(0.15, 0.5, 1.55)
        house.addChildNode(knob)
        
        for x: Float in [-0.7, 0.7] {
            let windowGeo = SCNBox(width: 0.5, height: 0.5, length: 0.05, chamferRadius: 0.02)
            windowGeo.materials.first?.diffuse.contents = UIColor(red: 0.6, green: 0.8, blue: 0.95, alpha: 0.85)
            windowGeo.materials.first?.emission.contents = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 0.3)
            let window = SCNNode(geometry: windowGeo)
            window.position = SCNVector3(x, 1.2, 1.52)
            house.addChildNode(window)
            let crossH = SCNNode(geometry: SCNBox(width: 0.48, height: 0.03, length: 0.01, chamferRadius: 0))
            crossH.geometry?.materials.first?.diffuse.contents = wallColor
            crossH.position = SCNVector3(x, 1.2, 1.55)
            house.addChildNode(crossH)
            let crossV = SCNNode(geometry: SCNBox(width: 0.03, height: 0.48, length: 0.01, chamferRadius: 0))
            crossV.geometry?.materials.first?.diffuse.contents = wallColor
            crossV.position = SCNVector3(x, 1.2, 1.55)
            house.addChildNode(crossV)
        }
        
        let chimneyGeo = SCNBox(width: 0.4, height: 0.8, length: 0.4, chamferRadius: 0)
        chimneyGeo.materials.first?.diffuse.contents = UIColor(red: 0.6, green: 0.35, blue: 0.25, alpha: 1.0)
        let chimney = SCNNode(geometry: chimneyGeo)
        chimney.position = SCNVector3(0.8, 3.0, -0.5)
        house.addChildNode(chimney)
        
        house.position = position
        scene.rootNode.addChildNode(house)
    }
    
    private func addTrafficLight(at position: SCNVector3) {
        let poleGeo = SCNCylinder(radius: 0.06, height: 3.5)
        poleGeo.materials.first?.diffuse.contents = UIColor(white: 0.25, alpha: 1.0)
        let pole = SCNNode(geometry: poleGeo)
        pole.position = SCNVector3(position.x, 1.75, position.z)
        scene.rootNode.addChildNode(pole)
        
        let boxGeo = SCNBox(width: 0.35, height: 0.9, length: 0.2, chamferRadius: 0.05)
        boxGeo.materials.first?.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
        let box = SCNNode(geometry: boxGeo)
        box.position = SCNVector3(position.x, 3.7, position.z)
        scene.rootNode.addChildNode(box)
        
        let lightColors: [(UIColor, Float)] = [
            (.red, 3.9), (.yellow, 3.7), (UIColor(red: 0.1, green: 0.8, blue: 0.1, alpha: 1.0), 3.5)
        ]
        for (color, y) in lightColors {
            let lightGeo = SCNSphere(radius: 0.08)
            lightGeo.materials.first?.diffuse.contents = color
            lightGeo.materials.first?.emission.contents = color.withAlphaComponent(0.5)
            let lightNode = SCNNode(geometry: lightGeo)
            lightNode.position = SCNVector3(position.x, y, position.z + 0.11)
            scene.rootNode.addChildNode(lightNode)
        }
    }
    
    private func addBusStopShelter(at position: SCNVector3) {
        let shelter = SCNNode()
        let roofGeo = SCNBox(width: 2.0, height: 0.08, length: 1.0, chamferRadius: 0.02)
        roofGeo.materials.first?.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.7, alpha: 0.8)
        let roof = SCNNode(geometry: roofGeo)
        roof.position = SCNVector3(0, 2.2, 0)
        shelter.addChildNode(roof)
        for x: Float in [-0.9, 0.9] {
            let poleGeo = SCNCylinder(radius: 0.04, height: 2.2)
            poleGeo.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
            let pole = SCNNode(geometry: poleGeo)
            pole.position = SCNVector3(x, 1.1, -0.4)
            shelter.addChildNode(pole)
        }
        let wallGeo = SCNPlane(width: 2.0, height: 2.2)
        wallGeo.materials.first?.diffuse.contents = UIColor(white: 0.8, alpha: 0.4)
        let wall = SCNNode(geometry: wallGeo)
        wall.position = SCNVector3(0, 1.1, -0.46)
        shelter.addChildNode(wall)
        let benchGeo = SCNBox(width: 1.6, height: 0.06, length: 0.35, chamferRadius: 0.02)
        benchGeo.materials.first?.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        let benchNode = SCNNode(geometry: benchGeo)
        benchNode.position = SCNVector3(0, 0.5, -0.2)
        shelter.addChildNode(benchNode)
        
        shelter.position = position
        scene.rootNode.addChildNode(shelter)
    }
    
    private func createSmokeParticleSystem() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor(white: 1.0, alpha: 1.0).cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
        let center = CGPoint(x: 32, y: 32)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 32, options: [])
        let smokeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        particles.particleImage = smokeImage
        particles.loops = true
        particles.birthRate = 40
        particles.emissionDuration = 1
        particles.emitterShape = SCNCylinder(radius: 0.4, height: 0.2)
        particles.particleLifeSpan = 4.0
        particles.particleVelocity = 2.5
        particles.particleVelocityVariation = 0.8
        particles.particleColor = UIColor(white: 0.2, alpha: 0.8) // Dark grey
        particles.particleSize = 1.0 // Start size
        particles.particleSizeVariation = 0.5
        
        let sizeAnim = CAKeyframeAnimation()
        sizeAnim.values = [1.0, 3.0, 6.0]
        sizeAnim.keyTimes = [0.0, 0.5, 1.0]
        particles.propertyControllers = [.size: SCNParticlePropertyController(animation: sizeAnim)]
        
        let opacityAnim = CAKeyframeAnimation()
        opacityAnim.values = [0.0, 0.8, 0.0]
        opacityAnim.keyTimes = [0.0, 0.2, 1.0]
        particles.propertyControllers?[.opacity] = SCNParticlePropertyController(animation: opacityAnim)
        
        particles.spreadingAngle = 20
        particles.blendMode = .alpha
        particles.emittingDirection = SCNVector3(0, 1, 0)
        
        return particles
    }
    private func buildRealisticCar(color: UIColor, isEV: Bool) -> SCNNode {
        let car = SCNNode()
        car.name = isEV ? "EV" : "GasCar"
        
        let bodyColor = isEV ? color : color
        let cabinColor: UIColor = isEV
            ? UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 0.7)
            : UIColor(red: 0.7, green: 0.8, blue: 0.9, alpha: 0.7)
        
        let bodyGeo = SCNBox(width: 1.5, height: 0.5, length: 3.2, chamferRadius: 0.12)
        bodyGeo.materials.first?.diffuse.contents = bodyColor
        let bodyNode = SCNNode(geometry: bodyGeo)
        bodyNode.name = "CarBody"
        bodyNode.position = SCNVector3(0, 0.45, 0)
        car.addChildNode(bodyNode)
        
        let hoodGeo = SCNBox(width: 1.4, height: 0.15, length: 0.9, chamferRadius: 0.06)
        hoodGeo.materials.first?.diffuse.contents = bodyColor
        let hood = SCNNode(geometry: hoodGeo)
        hood.name = "CarBody"
        hood.position = SCNVector3(0, 0.72, 1.05)
        car.addChildNode(hood)
        
        let trunkGeo = SCNBox(width: 1.4, height: 0.15, length: 0.7, chamferRadius: 0.06)
        trunkGeo.materials.first?.diffuse.contents = bodyColor
        let trunk = SCNNode(geometry: trunkGeo)
        trunk.name = "CarBody"
        trunk.position = SCNVector3(0, 0.72, -1.15)
        car.addChildNode(trunk)
        
        let cabinGeo = SCNBox(width: 1.3, height: 0.5, length: 1.3, chamferRadius: 0.12)
        let glassMat = SCNMaterial()
        glassMat.diffuse.contents = cabinColor
        glassMat.transparency = 0.7
        cabinGeo.materials = [glassMat]
        let cabinNode = SCNNode(geometry: cabinGeo)
        cabinNode.name = "CarCabin"
        cabinNode.position = SCNVector3(0, 0.96, -0.1)
        car.addChildNode(cabinNode)
        
        let wsMat = SCNMaterial()
        wsMat.diffuse.contents = UIColor(red: 0.6, green: 0.75, blue: 0.9, alpha: 0.5)
        wsMat.transparency = 0.5
        let wsGeo = SCNBox(width: 1.25, height: 0.45, length: 0.05, chamferRadius: 0.02)
        wsGeo.materials = [wsMat]
        let ws = SCNNode(geometry: wsGeo)
        ws.name = "CarCabin"
        ws.position = SCNVector3(0, 0.97, 0.6)
        ws.eulerAngles.x = -0.35
        car.addChildNode(ws)
        
        let rwGeo = SCNBox(width: 1.2, height: 0.4, length: 0.05, chamferRadius: 0.02)
        rwGeo.materials = [wsMat]
        let rw = SCNNode(geometry: rwGeo)
        rw.name = "CarCabin"
        rw.position = SCNVector3(0, 0.95, -0.8)
        rw.eulerAngles.x = 0.3
        car.addChildNode(rw)
        
        for side: Float in [-0.55, 0.55] {
            let hlGeo = SCNBox(width: 0.25, height: 0.12, length: 0.05, chamferRadius: 0.02)
            hlGeo.materials.first?.diffuse.contents = UIColor(red: 1.0, green: 1.0, blue: 0.85, alpha: 1.0)
            hlGeo.materials.first?.emission.contents = UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 0.6)
            let hl = SCNNode(geometry: hlGeo)
            hl.position = SCNVector3(side, 0.5, 1.61)
            car.addChildNode(hl)
        }
        
        for side: Float in [-0.55, 0.55] {
            let tlGeo = SCNBox(width: 0.2, height: 0.1, length: 0.05, chamferRadius: 0.02)
            tlGeo.materials.first?.diffuse.contents = UIColor(red: 0.9, green: 0.1, blue: 0.1, alpha: 1.0)
            tlGeo.materials.first?.emission.contents = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.5)
            let tl = SCNNode(geometry: tlGeo)
            tl.position = SCNVector3(side, 0.5, -1.61)
            car.addChildNode(tl)
        }
        
        for side: Float in [-0.8, 0.8] {
            let mGeo = SCNBox(width: 0.06, height: 0.08, length: 0.12, chamferRadius: 0.02)
            mGeo.materials.first?.diffuse.contents = bodyColor
            let m = SCNNode(geometry: mGeo)
            m.position = SCNVector3(side, 0.82, 0.45)
            car.addChildNode(m)
        }
        
        let wPositions = [
            SCNVector3( 0.75, 0.2, 1.0), SCNVector3(-0.75, 0.2, 1.0),
            SCNVector3( 0.75, 0.2, -1.0), SCNVector3(-0.75, 0.2, -1.0)
        ]
        for wPos in wPositions {
            let tireGeo = SCNCylinder(radius: 0.22, height: 0.18)
            tireGeo.materials.first?.diffuse.contents = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
            let tire = SCNNode(geometry: tireGeo)
            tire.eulerAngles.z = .pi / 2
            tire.position = wPos
            car.addChildNode(tire)
            
            let rimGeo = SCNCylinder(radius: 0.13, height: 0.19)
            rimGeo.materials.first?.diffuse.contents = UIColor(white: 0.7, alpha: 1.0)
            let rim = SCNNode(geometry: rimGeo)
            rim.eulerAngles.z = .pi / 2
            rim.position = wPos
            car.addChildNode(rim)
        }
        
        if !isEV {
            let exhaustNode = SCNNode()
            exhaustNode.name = "Exhaust"
            exhaustNode.position = SCNVector3(0, 0.3, -1.7)
            exhaustNode.addParticleSystem(createCarExhaustSystem())
            car.addChildNode(exhaustNode)
        }
        
        return car
    }
    
    private func createCarExhaustSystem() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        particles.loops = true
        particles.birthRate = 15
        particles.emissionDuration = 1
        particles.emitterShape = SCNSphere(radius: 0.1)
        particles.particleLifeSpan = 1.5
        particles.particleVelocity = 1.5
        particles.particleVelocityVariation = 0.5
        particles.particleColor = UIColor(white: 0.3, alpha: 0.6)
        particles.particleSize = 0.15
        particles.particleSizeVariation = 0.1
        particles.spreadingAngle = 25
        particles.blendMode = .alpha
        particles.emittingDirection = SCNVector3(0, 0.3, -1)
        particles.acceleration = SCNVector3(0, 0.8, 0) // drift upward gently
        return particles
    }
    
    private func addLevelOverlay_PlantTrees(at zone: SCNVector3) {
        let padGeo = SCNBox(width: 10, height: 0.1, length: 10, chamferRadius: 0)
        padGeo.materials.first?.diffuse.contents = UIColor(red: 0.25, green: 0.5, blue: 0.25, alpha: 1.0)
        let padNode = SCNNode(geometry: padGeo)
        padNode.name = "PlantPad"
        padNode.position = SCNVector3(zone.x, 0.05, zone.z)
        
        let highlightGeo = SCNPlane(width: 10, height: 10)
        highlightGeo.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.4)
        highlightGeo.materials.first?.emission.contents = UIColor.yellow.withAlphaComponent(0.2)
        let highlightNode = SCNNode(geometry: highlightGeo)
        highlightNode.name = "PlantPadHighlight"
        highlightNode.eulerAngles.x = -.pi/2
        highlightNode.position = SCNVector3(0, 0.055, 0)
        
        let fadeOut = SCNAction.fadeOpacity(to: 0.1, duration: 1.0)
        let fadeIn = SCNAction.fadeOpacity(to: 0.6, duration: 1.0)
        highlightNode.runAction(SCNAction.repeatForever(SCNAction.sequence([fadeOut, fadeIn])))
        
        padNode.addChildNode(highlightNode)
        scene.rootNode.addChildNode(padNode)
    }
    
    private func plantTree(at pos: SCNVector3, parent: SCNNode) {
        let treeNode = SCNNode()
        let trunkRadius = CGFloat.random(in: 0.15...0.25)
        let trunk = SCNNode(geometry: SCNCylinder(radius: trunkRadius, height: 1.5))
        trunk.geometry?.materials.first?.diffuse.contents = UIColor.brown
        trunk.position = SCNVector3(0, 0.75, 0)
        treeNode.addChildNode(trunk)
        
        let leafScale = Float.random(in: 0.8...1.2)
        let leaves = SCNNode(geometry: SCNSphere(radius: 1.0))
        let greenShade = CGFloat.random(in: 0.5...0.9)
        leaves.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.1, green: greenShade, blue: 0.2, alpha: 1.0)
        leaves.position = SCNVector3(0, 1.8, 0)
        leaves.scale = SCNVector3(leafScale, leafScale, leafScale)
        treeNode.addChildNode(leaves)
        
        treeNode.position = SCNVector3(pos.x, pos.y + 0.5, pos.z)
        treeNode.scale = SCNVector3(0, 0, 0)
        parent.addChildNode(treeNode)
        
        let grow = SCNAction.scale(to: 1.0, duration: 0.6)
        grow.timingMode = .easeOut
        treeNode.runAction(grow)
        
        gameState?.completeLevelAction(aqiReduction: 10, lifeExpectancyIncrease: 0.5)
        
        if (gameState?.levelItemsDone ?? 0) >= (gameState?.levelItemsTotal ?? 5) {
            gameState?.markLevelComplete(1)
            if let highlight = parent.childNode(withName: "PlantPadHighlight", recursively: false) {
                let fadeOut = SCNAction.fadeOut(duration: 0.5)
                let remove = SCNAction.removeFromParentNode()
                highlight.runAction(SCNAction.sequence([fadeOut, remove]))
            }
        }
        updateAtmosphere()
    }
    
    private func addLevelOverlay_CleanRiver(at zone: SCNVector3) {
    }
    
    private func cleanGarbage(node: SCNNode) {
        let splashParams = SCNParticleSystem()
        splashParams.loops = false
        splashParams.birthRate = 120
        splashParams.emissionDuration = 0.15
        splashParams.particleLifeSpan = 0.4
        splashParams.particleVelocity = 1.5
        splashParams.particleColor = UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
        splashParams.particleSize = 0.08
        splashParams.spreadingAngle = 180
        splashParams.particleImage = nil
        
        let splashNode = SCNNode()
        splashNode.position = node.position
        splashNode.addParticleSystem(splashParams)
        scene.rootNode.addChildNode(splashNode)
        splashNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 1.0), SCNAction.removeFromParentNode()]))
        
        node.removeAllActions()
        node.removeFromParentNode()
        
        gameState?.completeLevelAction(aqiReduction: 5, lifeExpectancyIncrease: 0.3)
        let itemsDone = gameState?.levelItemsDone ?? 0
        let itemsTotal = gameState?.levelItemsTotal ?? 7
        var ratio = Float(itemsDone) / Float(itemsTotal)
        if ratio > 1.0 { ratio = 1.0 }
        
        if let riverNode = scene.rootNode.childNode(withName: "River", recursively: false) {
            let red = CGFloat(0.15 - (0.05 * ratio))  // 0.15 -> 0.1
            let green = CGFloat(0.4 + (0.1 * ratio))  // 0.4 -> 0.5
            let blue = CGFloat(0.6 + (0.3 * ratio))   // 0.6 -> 0.9
            
            let eRed = CGFloat(0.05 * ratio)
            let eGreen = CGFloat(0.1 + (0.1 * ratio))
            let eBlue = CGFloat(0.2 + (0.2 * ratio))
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.4
            riverNode.geometry?.materials.first?.diffuse.contents = UIColor(red: red, green: green, blue: blue, alpha: 0.9)
            riverNode.geometry?.materials.first?.emission.contents = UIColor(red: eRed, green: eGreen, blue: eBlue, alpha: 0.3)
            SCNTransaction.commit()
        }
        
        if itemsDone >= itemsTotal {
            gameState?.markLevelComplete(2)
            updateAtmosphere()
        }
    }
    
    private func addLevelOverlay_Solar(at zone: SCNVector3) {
        let heights: [CGFloat] = [5, 7, 4]
        let xOffsets: [Float] = [-3, 0, 3]
        
        for i in 0..<3 {
            let h = heights[i]
            let pPos = SCNVector3(zone.x + xOffsets[i], Float(h) + 0.01, zone.z)
            
            let padGeo = SCNPlane(width: 2.5, height: 2.5) // Slightly smaller to fit the 3x3 buildings
            padGeo.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
            padGeo.materials.first?.emission.contents = UIColor.yellow
            let pad = SCNNode(geometry: padGeo)
            pad.eulerAngles.x = -.pi/2
            pad.position = pPos
            pad.name = "SolarPad"
            scene.rootNode.addChildNode(pad)
        }
    }
    
    private func placeSolarPanel(node: SCNNode) {
        node.geometry?.materials.first?.diffuse.contents = UIColor.black
        node.geometry?.materials.first?.emission.contents = UIColor.black
        
        let panelGeo = SCNBox(width: 3.3, height: 0.2, length: 3.3, chamferRadius: 0)
        panelGeo.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
        let panel = SCNNode(geometry: panelGeo)
        panel.position = SCNVector3(0, 0.1, 0)
        node.addChildNode(panel)
        node.name = "SolarInstalled"
        
        gameState?.completeLevelAction(aqiReduction: 15, lifeExpectancyIncrease: 1.0)
        
        if (gameState?.levelItemsDone ?? 0) >= (gameState?.levelItemsTotal ?? 3) {
            gameState?.markLevelComplete(3)
        }
        updateAtmosphere()
    }
    
    private func addLevelOverlay_Wind(at zone: SCNVector3) {
        let padOffsets: [SCNVector3] = [
            SCNVector3(-3.5, 0.05, -2.5),
            SCNVector3(0, 0.05, 0),
            SCNVector3(3.5, 0.05, -1.0)
        ]
        for offset in padOffsets {
            let padGeo = SCNCylinder(radius: 1.2, height: 0.1)
            padGeo.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
            let pad = SCNNode(geometry: padGeo)
            pad.position = SCNVector3(zone.x + offset.x, zone.y + offset.y, zone.z + offset.z)
            pad.name = "WindPad"
            scene.rootNode.addChildNode(pad)
        }
    }
    
    private func placeWindmill(node: SCNNode) {
        node.geometry?.materials.first?.diffuse.contents = UIColor.clear
        node.name = "WindInstalled"
        
        let pole = SCNNode(geometry: SCNCylinder(radius: 0.1, height: 5))
        pole.geometry?.materials.first?.diffuse.contents = UIColor.white
        pole.position = SCNVector3(0, 2.5, 0)
        node.addChildNode(pole)
        
        let hub = SCNNode()
        hub.position = SCNVector3(0, 4.8, 0.2)
        for angle in [0, 120, 240] {
            let blade = SCNNode(geometry: SCNBox(width: 0.3, height: 2.0, length: 0.1, chamferRadius: 0))
            blade.geometry?.materials.first?.diffuse.contents = UIColor.white
            blade.pivot = SCNMatrix4MakeTranslation(0, -1.0, 0)
            blade.eulerAngles.z = Float(angle) * .pi / 180
            hub.addChildNode(blade)
        }
        node.addChildNode(hub)
        
        let spin = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: .pi*2, duration: 2.0))
        hub.runAction(spin)
        
        gameState?.completeLevelAction(aqiReduction: 15, lifeExpectancyIncrease: 1.0)
        
        if (gameState?.levelItemsDone ?? 0) >= (gameState?.levelItemsTotal ?? 3) {
            gameState?.markLevelComplete(4)
        }
        updateAtmosphere()
    }
    
    private func addLevelOverlay_Hydro(at zone: SCNVector3) {
        let padGeo = SCNBox(width: 3, height: 0.1, length: 2, chamferRadius: 0)
        padGeo.materials.first?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.5)
        let pad = SCNNode(geometry: padGeo)
        pad.position = SCNVector3(zone.x, 0.1, zone.z) // Place it at the dam site position
        pad.name = "HydroPad"
        scene.rootNode.addChildNode(pad)
    }
    
    private func placeDam(node: SCNNode) {
        node.geometry?.materials.first?.diffuse.contents = UIColor.clear
        node.name = "DamInstalled"
        
        let damWallGeo = SCNBox(width: 10, height: 4, length: 1.8, chamferRadius: 0.05)
        let concreteMat = SCNMaterial()
        concreteMat.diffuse.contents = UIColor(red: 0.7, green: 0.68, blue: 0.65, alpha: 1.0)
        damWallGeo.materials = [concreteMat]
        let damWall = SCNNode(geometry: damWallGeo)
        damWall.position = SCNVector3(0, 2, 0)
        node.addChildNode(damWall)
        
        for (yOff, wScale) in [(Float(0.6), Float(1.0)), (Float(1.8), Float(0.85))] {
            let ledgeGeo = SCNBox(width: CGFloat(10.2 * wScale), height: 0.15, length: 0.4, chamferRadius: 0)
            ledgeGeo.materials.first?.diffuse.contents = UIColor(red: 0.65, green: 0.63, blue: 0.6, alpha: 1.0)
            let ledge = SCNNode(geometry: ledgeGeo)
            ledge.position = SCNVector3(0, yOff, 1.0)
            node.addChildNode(ledge)
        }
        
        for xOff: Float in [-3.5, -1.5, 0.5, 2.5] {
            let buttGeo = SCNBox(width: 0.4, height: 3.5, length: 1.2, chamferRadius: 0)
            buttGeo.materials.first?.diffuse.contents = UIColor(red: 0.62, green: 0.6, blue: 0.57, alpha: 1.0)
            let butt = SCNNode(geometry: buttGeo)
            butt.position = SCNVector3(xOff, 1.75, 1.2)
            node.addChildNode(butt)
        }
        
        for side: Float in [-0.6, 0.6] {
            let railGeo = SCNBox(width: 10, height: 0.2, length: 0.06, chamferRadius: 0)
            railGeo.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
            let rail = SCNNode(geometry: railGeo)
            rail.position = SCNVector3(0, 4.1, side)
            node.addChildNode(rail)
        }
        for xCenter: Float in [-2.5, -0.5, 1.5] {
            let sheetGeo = SCNBox(width: 1.5, height: 3.8, length: 0.1, chamferRadius: 0)
            sheetGeo.materials.first?.diffuse.contents = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85) // Frothy white-blue
            let waterSheet = SCNNode(geometry: sheetGeo)
            waterSheet.position = SCNVector3(xCenter, 1.9, 1.25)
            waterSheet.eulerAngles.x = 0.1 // Slight angle downwards
            node.addChildNode(waterSheet)
            
            let mistParticles = SCNParticleSystem()
            mistParticles.particleColor = UIColor(white: 1.0, alpha: 0.45)
            mistParticles.birthRate = 80
            mistParticles.emissionDuration = 1
            mistParticles.loops = true
            mistParticles.particleLifeSpan = 0.8
            mistParticles.particleVelocity = 1.2
            mistParticles.emittingDirection = SCNVector3(0, 1, 1)
            mistParticles.spreadingAngle = 60
            mistParticles.particleSize = 0.6 // Larger, softer particles
            mistParticles.blendMode = .alpha
            let mistNode = SCNNode()
            mistNode.position = SCNVector3(xCenter, 0.2, 1.6)
            mistNode.addParticleSystem(mistParticles)
            node.addChildNode(mistNode)
        }
        
        gameState?.completeLevelAction(aqiReduction: 25, lifeExpectancyIncrease: 1.0)
        gameState?.markLevelComplete(5)
        updateAtmosphere()
    }
    

    private func replaceWithEV(node: SCNNode) {
        let carNode = node.parent?.name == "GasCar" ? node.parent! : node
        
        carNode.enumerateChildNodes { child, _ in
            if child.name == "Exhaust" {
                child.removeAllParticleSystems()
            } else if child.name == "CarBody" {
                child.geometry?.materials.first?.diffuse.contents = UIColor.systemGreen
            } else if child.name == "CarCabin" {
                child.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.6, green: 1.0, blue: 0.6, alpha: 0.9) // slight green tint to windows
            }
        }
        
        carNode.name = "EV"
        
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 0.2),
            SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 0.2)
        ])
        carNode.runAction(bounce)
        
        gameState?.completeLevelAction(aqiReduction: 10, lifeExpectancyIncrease: 0.5)
        
        if (gameState?.levelItemsDone ?? 0) >= (gameState?.levelItemsTotal ?? 8) {
            gameState?.markLevelComplete(6)
        }
        updateAtmosphere()
    }
    

    private func addFactoryChimney(parent: SCNNode, x: Float, z: Float) {
        let chimneyGeo = SCNCylinder(radius: 0.35, height: 3.5)
        chimneyGeo.materials.first?.diffuse.contents = UIColor(red: 0.55, green: 0.3, blue: 0.25, alpha: 1.0)
        let chimney = SCNNode(geometry: chimneyGeo)
        chimney.position = SCNVector3(x, 5.5, z)
        chimney.name = "Chimney"
        parent.addChildNode(chimney)
        let band = SCNNode(geometry: SCNCylinder(radius: 0.38, height: 0.2))
        band.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0)
        band.position = SCNVector3(0, 1.2, 0)
        chimney.addChildNode(band)
        
        let cap = SCNNode(geometry: SCNCylinder(radius: 0.42, height: 0.15))
        cap.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.35, green: 0.2, blue: 0.15, alpha: 1.0)
        cap.position = SCNVector3(0, 1.7, 0)
        chimney.addChildNode(cap)

    }
    private func createChimneySmoke() -> SCNParticleSystem {
        let particles = SCNParticleSystem()
        
        let size = CGSize(width: 64, height: 64)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor(white: 1.0, alpha: 1.0).cgColor, UIColor(white: 1.0, alpha: 0.0).cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!
        let center = CGPoint(x: 32, y: 32)
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: 32, options: [])
        let smokeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        particles.particleImage = smokeImage
        particles.loops = true
        particles.birthRate = 15               // Much lower than the original 40
        particles.emissionDuration = 1
        particles.emitterShape = SCNCylinder(radius: 0.3, height: 0.1)
        particles.particleLifeSpan = 5.0
        particles.particleVelocity = 1.8
        particles.particleVelocityVariation = 0.4
        particles.particleColor = UIColor(white: 0.25, alpha: 0.5)  // More transparent
        particles.particleSize = 0.6           // Smaller starting size
        particles.particleSizeVariation = 0.2
        
        let sizeAnim = CAKeyframeAnimation()
        sizeAnim.values = [0.8, 2.0, 3.5]
        sizeAnim.keyTimes = [0.0, 0.5, 1.0]
        particles.propertyControllers = [.size: SCNParticlePropertyController(animation: sizeAnim)]
        
        let opacityAnim = CAKeyframeAnimation()
        opacityAnim.values = [0.0, 0.5, 0.0]
        opacityAnim.keyTimes = [0.0, 0.15, 1.0]
        particles.propertyControllers?[.opacity] = SCNParticlePropertyController(animation: opacityAnim)
        
        particles.spreadingAngle = 12
        particles.blendMode = .alpha
        particles.emittingDirection = SCNVector3(0, 1, 0)
        
        return particles
    }
    
    private func addFilter(node: SCNNode) {
        node.removeAllParticleSystems()
        node.enumerateChildNodes { child, _ in
            child.removeAllParticleSystems()
        }
        node.name = "FilteredChimney"
        
        let filterGeo = SCNCylinder(radius: 0.6, height: 1)
        filterGeo.materials.first?.diffuse.contents = UIColor.systemBlue
        let filterNode = SCNNode(geometry: filterGeo)
        filterNode.position = SCNVector3(0, 1.5, 0)
        node.addChildNode(filterNode)
        
        gameState?.completeLevelAction(aqiReduction: 12, lifeExpectancyIncrease: 1.0)
        
        let requiredFilters = gameState?.levelItemsTotal ?? 2
        if (gameState?.levelItemsDone ?? 0) >= requiredFilters {
            gameState?.markLevelComplete(7)
        }
        updateAtmosphere()
    }
    

    private func addWaterTreatment(node: SCNNode) {
        guard node.name == "ToxicPipe" else { return }
        
        node.removeAllParticleSystems()
        node.name = "CleanPipe"
        node.geometry?.materials.first?.diffuse.contents = UIColor.systemBlue
        
        let zPos = node.position.z
        
        if let dripNode = scene.rootNode.childNodes.first(where: { $0.name == "ToxicDrip" && abs($0.position.z - zPos) < 1.0 }) {
            dripNode.removeAllParticleSystems()
            dripNode.removeFromParentNode()
        }
        
        if let patchNode = scene.rootNode.childNodes.first(where: { $0.name == "ToxicPatch" && abs($0.position.z - zPos) < 1.0 }) {
            patchNode.removeAllParticleSystems()
            patchNode.removeFromParentNode()
        }
        
        let cleanLiquid = SCNParticleSystem()
        cleanLiquid.particleColor = UIColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.9)
        cleanLiquid.birthRate = 100
        cleanLiquid.emissionDuration = 1
        cleanLiquid.loops = true
        cleanLiquid.particleLifeSpan = 0.6
        cleanLiquid.particleSize = 0.15
        cleanLiquid.emittingDirection = SCNVector3(0, -1, 0)
        cleanLiquid.particleVelocity = 2.5
        cleanLiquid.spreadingAngle = 10
        
        let spoutEmitter = SCNNode()
        spoutEmitter.position = SCNVector3(-4.0, node.position.y - 0.2, zPos)
        scene.rootNode.addChildNode(spoutEmitter)
        spoutEmitter.addParticleSystem(cleanLiquid)
        
        gameState?.completeLevelAction(aqiReduction: 20, lifeExpectancyIncrease: 1.5)
        
        if (gameState?.levelItemsDone ?? 0) >= (gameState?.levelItemsTotal ?? 2) {
            let patches = scene.rootNode.childNodes { node, _ in node.name == "ToxicPatch" }
            for patch in patches {
                if let system = patch.particleSystems?.first {
                    system.birthRate = 0
                }
                let wait = SCNAction.wait(duration: 2.0)
                let flexRemove = SCNAction.removeFromParentNode()
                patch.runAction(SCNAction.sequence([wait, flexRemove]))
            }
            if let river = scene.rootNode.childNode(withName: "ToxicRiver", recursively: false) ?? scene.rootNode.childNode(withName: "River", recursively: false) {
                river.name = "CleanRiver"
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 2.0
                river.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.9)
                river.geometry?.materials.first?.emission.contents = UIColor.clear
                SCNTransaction.commit()
            }
            gameState?.markLevelComplete(8)
        }
        updateAtmosphere()
    }
    
    private func setupLevel9_ThrivingCity() {
        gameState?.globalAQI = 10
        gameState?.happinessScore = 5
        gameState?.lifeExpectancy = 90
        gameState?.markLevelComplete(9)
        updateAtmosphere()
        
        for i in -3...3 {
            for j in -2...2 {
                if (abs(i) + abs(j)) % 2 == 0 && abs(i) > 1 {
                    let tree = SCNNode()
                    let trunk = SCNNode(geometry: SCNCylinder(radius: 0.2, height: 1.5))
                    trunk.geometry?.materials.first?.diffuse.contents = UIColor.brown
                    trunk.position = SCNVector3(0, 0.75, 0)
                    tree.addChildNode(trunk)
                    
                    let leaves = SCNNode(geometry: SCNSphere(radius: CGFloat.random(in: 0.8...1.2)))
                    leaves.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.1, green: CGFloat.random(in: 0.6...0.9), blue: 0.2, alpha: 1.0)
                    leaves.position = SCNVector3(0, 1.8, 0)
                    tree.addChildNode(leaves)
                    
                    tree.position = SCNVector3(Float(i)*3.5, 0.75, Float(j)*3 + 5)
                    scene.rootNode.addChildNode(tree)
                }
            }
        }
        
        let solarBldg = SCNNode(geometry: SCNBox(width: 4, height: 5, length: 4, chamferRadius: 0.1))
        solarBldg.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
        solarBldg.position = SCNVector3(0, 2.5, 5)
        scene.rootNode.addChildNode(solarBldg)
        
        let solarPanel = SCNNode(geometry: SCNBox(width: 3.5, height: 0.2, length: 3.5, chamferRadius: 0))
        solarPanel.geometry?.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
        solarPanel.position = SCNVector3(0, 5.1, 5)
        scene.rootNode.addChildNode(solarPanel)
        let windmill = SCNNode()
        let pole = SCNNode(geometry: SCNCylinder(radius: 0.1, height: 5))
        pole.geometry?.materials.first?.diffuse.contents = UIColor.white
        pole.position = SCNVector3(0, 2.5, 0)
        windmill.addChildNode(pole)
       
        let hub = SCNNode()
        hub.position = SCNVector3(0, 4.8, 0.2)
        for angle in [0, 120, 240] {
            let blade = SCNNode(geometry: SCNBox(width: 0.3, height: 2.0, length: 0.1, chamferRadius: 0))
            blade.geometry?.materials.first?.diffuse.contents = UIColor.white
            blade.pivot = SCNMatrix4MakeTranslation(0, -1.0, 0)
            blade.eulerAngles.z = Float(angle) * .pi / 180
            hub.addChildNode(blade)
        }
        windmill.addChildNode(hub)
        hub.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0, z: .pi*2, duration: 2.0)))
        windmill.position = SCNVector3(-8, 0, 8)
        scene.rootNode.addChildNode(windmill)
        
        let roadGeo = SCNPlane(width: 4, height: 25)
        roadGeo.materials.first?.diffuse.contents = UIColor.darkGray
        let road = SCNNode(geometry: roadGeo)
        road.eulerAngles.x = -.pi/2
        road.position = SCNVector3(8, 0.05, 5)
        scene.rootNode.addChildNode(road)
        
        let speed: Float = 2.5
        let halfRoad: Float = 12.5
        for i in -1...1 {
            let evGeo = SCNBox(width: 1.2, height: 0.8, length: 2, chamferRadius: 0.2)
            evGeo.materials.first?.diffuse.contents = UIColor.systemGreen
            let ev = SCNNode(geometry: evGeo)
            
            let isForward = (i % 2 != 0)
            ev.eulerAngles.y = isForward ? 0 : .pi
            let laneOffset: Float = isForward ? 1.0 : -1.0
            
            let startZ = Float(i) * 5
            ev.position = SCNVector3(8 + laneOffset, 0.4, startZ)
            
            let distToEdge = isForward ? (halfRoad - startZ) : (startZ - (-halfRoad))
            let timeToEdge = TimeInterval(abs(distToEdge) / speed)
            
            let zMoveOut = isForward ? CGFloat(distToEdge) : CGFloat(-distToEdge)
            let driveOut = SCNAction.moveBy(x: 0, y: 0, z: zMoveOut, duration: timeToEdge)
            
            let zTeleport = isForward ? CGFloat(-halfRoad * 2) : CGFloat(halfRoad * 2)
            let teleportBack = SCNAction.moveBy(x: 0, y: 0, z: zTeleport, duration: 0.01)
            
            let zFull = isForward ? CGFloat(halfRoad * 2) : CGFloat(-halfRoad * 2)
            let driveFull = SCNAction.moveBy(x: 0, y: 0, z: zFull, duration: TimeInterval(halfRoad * 2 / speed))
            
            let loop = SCNAction.repeatForever(SCNAction.sequence([driveFull, teleportBack]))
            ev.runAction(SCNAction.sequence([driveOut, teleportBack, loop]))
            
            scene.rootNode.addChildNode(ev)
        }
        
        let riverGeo = SCNPlane(width: 5, height: 45)
        riverGeo.materials.first?.diffuse.contents = UIColor(red: 0.1, green: 0.5, blue: 0.9, alpha: 0.9)
        let river = SCNNode(geometry: riverGeo)
        river.eulerAngles.x = -.pi/2
        river.position = SCNVector3(-4, 0.08, -1)
        scene.rootNode.addChildNode(river)
       
        let hydroZone = SCNVector3(-4, 0, -20)
        
        let damWallGeo = SCNBox(width: 9, height: 4, length: 1.8, chamferRadius: 0.05)
        let concreteMat = SCNMaterial()
        concreteMat.diffuse.contents = UIColor(red: 0.7, green: 0.68, blue: 0.65, alpha: 1.0)
        damWallGeo.materials = [concreteMat]
        let damWall = SCNNode(geometry: damWallGeo)
        damWall.position = SCNVector3(hydroZone.x, 2, hydroZone.z)
        scene.rootNode.addChildNode(damWall)
        
        for xOff: Float in [-3, -1, 1, 3] {
            let buttGeo = SCNBox(width: 0.4, height: 3.5, length: 1.2, chamferRadius: 0)
            buttGeo.materials.first?.diffuse.contents = UIColor(red: 0.62, green: 0.6, blue: 0.57, alpha: 1.0)
            let butt = SCNNode(geometry: buttGeo)
            butt.position = SCNVector3(hydroZone.x + xOff, 1.75, hydroZone.z + 1.2)
            scene.rootNode.addChildNode(butt)
        }
        
        for side: Float in [-0.6, 0.6] {
            let railGeo = SCNBox(width: 9, height: 0.2, length: 0.06, chamferRadius: 0)
            railGeo.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
            let rail = SCNNode(geometry: railGeo)
            rail.position = SCNVector3(hydroZone.x, 4.1, hydroZone.z + side)
            scene.rootNode.addChildNode(rail)
        }
        
        for xCenter: Float in [-2, 0, 2] {
            let sheetGeo = SCNBox(width: 1.5, height: 3.8, length: 0.1, chamferRadius: 0)
            sheetGeo.materials.first?.diffuse.contents = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85)
            let waterSheet = SCNNode(geometry: sheetGeo)
            waterSheet.position = SCNVector3(hydroZone.x + xCenter, 1.9, hydroZone.z + 1.2)
            waterSheet.eulerAngles.x = 0.1
            scene.rootNode.addChildNode(waterSheet)
            
            let mistParticles = SCNParticleSystem()
            mistParticles.particleColor = UIColor(white: 1.0, alpha: 0.45)
            mistParticles.birthRate = 80
            mistParticles.emissionDuration = 1
            mistParticles.loops = true
            mistParticles.particleLifeSpan = 0.8
            mistParticles.particleVelocity = 1.2
            mistParticles.spreadingAngle = 60
            mistParticles.particleSize = 0.6
            mistParticles.blendMode = .alpha
            let mistNode = SCNNode()
            mistNode.position = SCNVector3(hydroZone.x + xCenter, 0.2, hydroZone.z + 1.5)
            mistNode.addParticleSystem(mistParticles)
            scene.rootNode.addChildNode(mistNode)
        }
        addWindowsToBuilding(solarBldg, rows: 3, cols: 2, buildingWidth: 4, buildingHeight: 5)
        
        let fountainBase = SCNNode(geometry: SCNCylinder(radius: 1.2, height: 0.5))
        fountainBase.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.65, alpha: 1.0)
        fountainBase.position = SCNVector3(-4, 0.25, 14)
        scene.rootNode.addChildNode(fountainBase)
        let fountainPillar = SCNNode(geometry: SCNCylinder(radius: 0.15, height: 1.2))
        fountainPillar.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.6, alpha: 1.0)
        fountainPillar.position = SCNVector3(-4, 0.85, 14)
        scene.rootNode.addChildNode(fountainPillar)
        let waterParticles = SCNParticleSystem()
        waterParticles.particleColor = UIColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 0.8)
        waterParticles.birthRate = 80
        waterParticles.emissionDuration = 1
        waterParticles.loops = true
        waterParticles.particleLifeSpan = 1.0
        waterParticles.particleVelocity = 2
        waterParticles.particleSize = 0.08
        waterParticles.spreadingAngle = 45
        waterParticles.acceleration = SCNVector3(0, -3, 0)
        fountainPillar.addParticleSystem(waterParticles)
        
        let flowerColors: [UIColor] = [.red, .systemPink, .yellow, .purple, .orange]
        for i in stride(from: -8, through: 8, by: 4) {
            for _ in 0..<3 {
                let flowerGeo = SCNSphere(radius: 0.15)
                flowerGeo.materials.first?.diffuse.contents = flowerColors.randomElement()!
                let flower = SCNNode(geometry: flowerGeo)
                flower.position = SCNVector3(Float(i) + Float.random(in: -1...1), 0.15, Float.random(in: 0...3))
                scene.rootNode.addChildNode(flower)
                let stemGeo = SCNCylinder(radius: 0.02, height: 0.2)
                stemGeo.materials.first?.diffuse.contents = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
                let stem = SCNNode(geometry: stemGeo)
                stem.position = SCNVector3(flower.position.x, 0.05, flower.position.z)
                scene.rootNode.addChildNode(stem)
            }
        }
        
        let bikeRack = SCNNode(geometry: SCNBox(width: 2, height: 0.06, length: 0.5, chamferRadius: 0.02))
        bikeRack.geometry?.materials.first?.diffuse.contents = UIColor(white: 0.5, alpha: 1.0)
        bikeRack.position = SCNVector3(5, 0.5, 0)
        scene.rootNode.addChildNode(bikeRack)
        for x: Float in [-0.6, 0, 0.6] {
            let hookGeo = SCNTorus(ringRadius: 0.2, pipeRadius: 0.02)
            hookGeo.materials.first?.diffuse.contents = UIColor(white: 0.4, alpha: 1.0)
            let hook = SCNNode(geometry: hookGeo)
            hook.position = SCNVector3(5 + x, 0.55, 0)
            hook.eulerAngles.x = .pi / 2
            scene.rootNode.addChildNode(hook)
        }
        addMovingPerson(from: SCNVector3(6, 0, 3), to: SCNVector3(4, 0, 10), duration: 8) // Stay east of river
        addMovingPerson(from: SCNVector3(-10, 0, 10), to: SCNVector3(-10, 0, 0), duration: 11) // Stay west of river
        addMovingPerson(from: SCNVector3(3, 0, -2), to: SCNVector3(3, 0, 12), duration: 12)
        addMovingPerson(from: SCNVector3(-12, 0, 14), to: SCNVector3(-8, 0, 2), duration: 14) // Adjusted away from river
        
        addFlyingBird(at: SCNVector3(0, 0, 5), radius: 8, height: 12, duration: 15)
        addFlyingBird(at: SCNVector3(-4, 0, 2), radius: 6, height: 16, duration: 11)
        addFlyingBird(at: SCNVector3(4, 0, 8), radius: 10, height: 14, duration: 19)
        addFlyingBird(at: SCNVector3(8, 0, -2), radius: 5, height: 10, duration: 13)
        
        addBench(at: SCNVector3(-6, 0, 0))
        addBench(at: SCNVector3(5, 0, 12), rotation: .pi)
    }
}

extension SCNVector3 {
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.init(x: x, y: y, z: z)
    }
}
 