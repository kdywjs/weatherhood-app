import SwiftUI
import SpriteKit

/// Sky and precipitation effects only; rates and ground placement are visual demo values.
struct RainBackground: UIViewRepresentable {
    var active: Bool
    var rain: RainPreviewLevel = .moderate
    var wind: WindPreviewLevel = .light
    var effects: WeatherEffectConfiguration? = nil

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.backgroundColor = .clear
        view.allowsTransparency = true
        view.isUserInteractionEnabled = false
        view.preferredFramesPerSecond = 30
        let scene = RainParticleScene(size: CGSize(width: 390, height: 844))
        scene.scaleMode = .resizeFill
        if effects == nil { scene.configure(rain: rain, wind: wind) }
        scene.configureAtmosphere(effects)
        view.presentScene(scene)
        view.isPaused = !active
        return view
    }

    func updateUIView(_ view: SKView, context: Context) {
        if effects == nil { (view.scene as? RainParticleScene)?.configure(rain: rain, wind: wind) }
        (view.scene as? RainParticleScene)?.configureAtmosphere(effects)
        view.isPaused = !active
    }

    static func dismantleUIView(_ view: SKView, coordinator: ()) {
        view.isPaused = true
        view.presentScene(nil)
    }
}

private final class RainParticleScene: SKScene {
    private let distantRain = SKEmitterNode()
    private let nearbyRain = SKEmitterNode()
    private let ripples = SKEmitterNode()
    private let groundSpray = SKEmitterNode()
    private let foregroundRain = SKNode()
    private let snow = SKEmitterNode()
    private let windDust = SKEmitterNode()
    private let atmosphere = SKNode()
    private var effects: WeatherEffectConfiguration?
    private var baseDistantRate: CGFloat = 0
    private var baseNearbyRate: CGFloat = 0
    private var cloudTexture: SKTexture?
    private var rainFactor: CGFloat { effects?.rainFactor ?? 1 }
    private var streakTexture: SKTexture?
    private var lastFrameTime: TimeInterval?
    private var spawnCredit: Double = 0
    private var particlesConfigured = false
    private var rainLevel: RainPreviewLevel = .moderate
    private var windLevel: WindPreviewLevel = .light
    func configureAtmosphere(_ newValue: WeatherEffectConfiguration?) {
        guard effects != newValue else { return }
        effects = newValue
        if let newValue { rainLevel = newValue.rain; windLevel = newValue.wind }
        foregroundRain.removeAllChildren()
        spawnCredit = 0
        layoutParticles()
        layoutAtmosphere()
    }
    func configure(rain: RainPreviewLevel, wind: WindPreviewLevel) {
        guard rain != rainLevel || wind != windLevel else { return }
        rainLevel = rain
        windLevel = wind
        layoutParticles()
        if rain == .none {
            foregroundRain.removeAllChildren()
            spawnCredit = 0
            ripples.resetSimulation()
            groundSpray.resetSimulation()
        }
    }

    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        let streak = SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 8, height: 64)).image { _ in
            for (width, alpha) in [(CGFloat(7), CGFloat(0.07)), (4, 0.15), (1.5, 0.60)] {
                UIColor(red: 0.78, green: 0.87, blue: 0.96, alpha: alpha).setFill()
                UIBezierPath(roundedRect: CGRect(x: (8 - width) / 2, y: 2, width: width, height: 60), cornerRadius: width / 2).fill()
            }
        })
        streakTexture = streak
        configureRain(distantRain, texture: streak, speed: 330, scale: 0.20, alpha: 0.25)
        configureRain(nearbyRain, texture: streak, speed: 570, scale: 0.36, alpha: 0.40)
        foregroundRain.zPosition = 2
        addChild(foregroundRain)

        ripples.particleTexture = SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 32, height: 12)).image { _ in
            UIColor.white.setStroke()
            let ring = UIBezierPath(ovalIn: CGRect(x: 2, y: 2, width: 28, height: 8))
            ring.lineWidth = 1.5
            ring.stroke()
        })
        ripples.particleLifetime = 0.65
        ripples.particleScale = 0.2
        ripples.particleScaleSpeed = 1.0
        ripples.particleAlpha = 0.25
        ripples.particleAlphaSpeed = -0.38
        addChild(ripples)
        groundSpray.particleTexture = SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 4, height: 4)).fill()
        })
        groundSpray.emissionAngle = .pi / 2
        groundSpray.emissionAngleRange = .pi * 0.7
        groundSpray.particleSpeed = 42
        groundSpray.particleSpeedRange = 24
        groundSpray.yAcceleration = -220
        groundSpray.particleLifetime = 0.35
        groundSpray.particleScale = 0.45
        groundSpray.particleAlpha = 0.4
        groundSpray.particleAlphaSpeed = -1.1
        addChild(groundSpray)
        let flake = SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { _ in
            UIColor.white.withAlphaComponent(0.15).setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 12, height: 12)).fill()
            UIColor.white.withAlphaComponent(0.8).setFill()
            UIBezierPath(ovalIn: CGRect(x: 3, y: 3, width: 6, height: 6)).fill()
        })
        snow.particleTexture = flake
        snow.particleAlpha = 0.7
        snow.particleAlphaRange = 0.35
        snow.particleScale = 0.45
        snow.particleScaleRange = 0.6
        snow.particleRotationRange = .pi
        snow.particleAction = .repeatForever(.sequence([
            .moveBy(x: 12, y: 0, duration: 1.2), .moveBy(x: -12, y: 0, duration: 1.2)
        ]))
        snow.zPosition = 1
        addChild(snow)
        windDust.particleTexture = streak
        windDust.particleScale = 0.16
        windDust.particleScaleRange = 0.12
        windDust.particleAlpha = 0.18
        windDust.particleAlphaSpeed = -0.09
        windDust.particleRotation = .pi / 2
        windDust.particleLifetime = 2
        addChild(windDust)
        cloudTexture = SKTexture(image: UIGraphicsImageRenderer(size: CGSize(width: 256, height: 128)).image { _ in
            for layer in (1...16).reversed() {
                let inset = CGFloat(16 - layer) * 3
                UIColor.white.withAlphaComponent(0.025).setFill()
                UIBezierPath(ovalIn: CGRect(x: inset, y: inset / 2, width: 256 - inset * 2, height: 128 - inset)).fill()
            }
        })
        atmosphere.zPosition = -1
        addChild(atmosphere)
        particlesConfigured = true
        layoutParticles()
    }

    required init?(coder: NSCoder) { fatalError("Use init(size:)") }

    private func configureRain(_ emitter: SKEmitterNode, texture: SKTexture, speed: CGFloat, scale: CGFloat, alpha: CGFloat) {
        emitter.particleTexture = texture
        emitter.emissionAngle = -.pi / 2 - 0.12
        emitter.particleRotation = -0.12
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.1
        emitter.particleScale = scale
        emitter.particleScaleRange = scale * 0.2
        emitter.particleAlpha = alpha
        addChild(emitter)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutParticles()
        layoutAtmosphere()
        foregroundRain.removeAllChildren()
        spawnCredit = 0
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastFrameTime = currentTime }
        guard let previous = lastFrameTime else { return }
        // Do not catch up with a burst after returning from the background.
        let delta = min(1.0 / 15.0, max(0, currentTime - previous))
        distantRain.particleBirthRate = baseDistantRate
        nearbyRain.particleBirthRate = baseNearbyRate
        guard rainLevel != .none, rainFactor > 0 else { return }
        spawnCredit += delta * Double(6 * rainLevel.density * rainFactor * min(2, size.width / 390))
        while spawnCredit >= 1 {
            spawnCredit -= 1
            if foregroundRain.children.count < 40 { spawnPerspectiveStreak() }
        }
    }

    private func spawnPerspectiveStreak() {
        guard let texture = streakTexture, size.width > 0, size.height > 0 else { return }
        let drop = SKSpriteNode(texture: texture)
        let startX = CGFloat.random(in: -0.08...1.08) * size.width
        let start = CGPoint(x: startX, y: size.height * CGFloat.random(in: 0.72...1.08))
        // Outward spread is subtle; gravity remains the dominant direction.
        let end = CGPoint(x: startX + (startX - size.width / 2) * 0.48 - size.height * tan(windLevel.angle) * 0.55,
                          y: -100)
        let duration = Double.random(in: 1.05...1.65)
        let width = CGFloat.random(in: 3...5)
        let length = CGFloat.random(in: 50...90)
        drop.position = start
        drop.alpha = 0
        drop.zRotation = atan2(end.x - start.x, start.y - end.y)
        foregroundRain.addChild(drop)
        drop.run(.sequence([
            .customAction(withDuration: duration) { node, elapsed in
                guard let sprite = node as? SKSpriteNode else { return }
                let t = min(1, CGFloat(elapsed) / CGFloat(duration))
                let distance = 0.30 * t + 0.70 * t * t
                sprite.position = CGPoint(x: start.x + (end.x - start.x) * distance,
                                          y: start.y + (end.y - start.y) * distance)
                sprite.size = CGSize(width: width * (0.35 + 0.65 * t),
                                     height: length * (0.18 + 0.82 * t * t))
                sprite.alpha = min(1, t / 0.12) * min(1, (1 - t) / 0.16) * (0.25 + 0.40 * t)
            },
            .removeFromParent()
        ]))
    }

    private func layoutParticles() {
        // SKScene.init(size:) can invoke didChangeSize before emitter setup.
        guard particlesConfigured, size.width > 0, size.height > 0 else { return }
        for (emitter, rate) in [(distantRain, CGFloat(48)), (nearbyRain, CGFloat(32))] {
            let drift = size.height * tan(windLevel.angle)
            emitter.emissionAngle = -.pi / 2 - windLevel.angle
            emitter.particleRotation = -windLevel.angle
            emitter.position = CGPoint(x: size.width / 2 + drift / 2, y: size.height + 32)
            emitter.particlePositionRange = CGVector(dx: size.width + drift + 64, dy: 0)
            emitter.particleLifetime = (size.height + 80) / (emitter.particleSpeed * 0.95 * cos(windLevel.angle))
            emitter.particleBirthRate = rate * rainLevel.density * rainFactor * min(2, size.width / 390)
            if emitter === distantRain { baseDistantRate = emitter.particleBirthRate }
            else { baseNearbyRate = emitter.particleBirthRate }
            emitter.resetSimulation()
        }
        ripples.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        ripples.particlePositionRange = CGVector(dx: size.width, dy: size.height * 0.15)
        ripples.particleBirthRate = 8 * rainLevel.density * rainFactor * min(2, size.width / 390)
        groundSpray.position = ripples.position
        groundSpray.particlePositionRange = ripples.particlePositionRange
        groundSpray.particleBirthRate = 24 * rainLevel.density * rainFactor * min(2, size.width / 390)
        if rainFactor == 0 { ripples.resetSimulation(); groundSpray.resetSimulation() }
        snow.position = CGPoint(x: size.width / 2 + size.height * windLevel.angle / 2, y: size.height + 15)
        snow.particlePositionRange = CGVector(dx: size.width + size.height * windLevel.angle, dy: 25)
        snow.emissionAngle = -.pi / 2 - windLevel.angle
        snow.particleSpeed = 55 + windLevel.angle * 100
        snow.particleSpeedRange = 25
        snow.particleLifetime = min(22, (size.height + 50) / max(25, snow.particleSpeed - 13))
        snow.particleBirthRate = (effects?.snowRate ?? 0) * min(2, size.width / 390)
        snow.resetSimulation()
        windDust.position = CGPoint(x: size.width + 20, y: size.height * 0.45)
        windDust.particlePositionRange = CGVector(dx: 0, dy: size.height * 0.7)
        windDust.emissionAngle = .pi + 0.10
        windDust.particleSpeed = size.width / 1.5
        windDust.particleBirthRate = effects == nil ? 0 : windLevel.angle * 15
        windDust.resetSimulation()
    }

    private func layoutAtmosphere() {
        guard particlesConfigured, size.width > 0, size.height > 0 else { return }
        atmosphere.removeAllChildren()
        guard let effect = effects, let texture = cloudTexture else { return }
        let cloudCount = effect.sky == .overcast ? 5 : effect.sky == .partlyCloudy ? 3 : 0
        for index in 0..<cloudCount {
            let node = SKSpriteNode(texture: texture)
            node.color = effect.sky == .overcast ? .gray : .white
            node.colorBlendFactor = 0.65
            node.alpha = effect.sky == .overcast ? 0.65 : 0.45
            node.size = CGSize(width: size.width * 1.15, height: size.height * 0.22)
            let y = size.height * (0.73 + CGFloat(index % 3) * 0.09)
            let startX = size.width * CGFloat(index) / CGFloat(max(1, cloudCount))
            node.position = CGPoint(x: startX, y: y)
            let speed: CGFloat = 5 + windLevel.angle * 30
            let endX = -node.size.width / 2
            let resetX = size.width + node.size.width / 2
            node.run(.sequence([
                .moveTo(x: endX, duration: Double((startX - endX) / speed)),
                .repeatForever(.sequence([.moveTo(x: resetX, duration: 0), .moveTo(x: endX, duration: Double((resetX - endX) / speed))]))
            ]))
            atmosphere.addChild(node)
        }
        if effect.sky == .sunny {
            let glow = SKSpriteNode(texture: texture)
            glow.position = CGPoint(x: size.width * 0.78, y: size.height * 0.88)
            glow.size = CGSize(width: size.width * 0.8, height: size.width * 0.8)
            glow.color = .systemYellow
            glow.colorBlendFactor = 0.7
            glow.alpha = 0.28
            glow.run(.repeatForever(.sequence([.fadeAlpha(to: 0.15, duration: 3), .fadeAlpha(to: 0.28, duration: 3)])))
            atmosphere.addChild(glow)
        }
    }
}
