import SwiftUI
import MetalKit

// MARK: - Shader Overlay Window

class ShaderOverlayWindow: NSWindow {
    private var metalView: MTKView?
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var screenTexture: MTLTexture?
    private var startTime: CFTimeInterval = 0
    private var originPoint: CGPoint = .zero

    init(origin: CGPoint) {
        self.originPoint = origin

        guard let screen = NSScreen.main else {
            super.init(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
            return
        }

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        setupMetal()
        captureScreen()
        startAnimation()
    }

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        let view = MTKView(frame: self.frame, device: device)
        view.delegate = self
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.layer?.isOpaque = false
        self.contentView = view
        self.metalView = view

        commandQueue = device.makeCommandQueue()

        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
            float2 positions[4] = {
                float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1)
            };
            float2 texCoords[4] = {
                float2(0, 1), float2(1, 1), float2(0, 0), float2(1, 0)
            };
            VertexOut out;
            out.position = float4(positions[vertexID], 0, 1);
            out.texCoord = texCoords[vertexID];
            return out;
        }

        fragment float4 fragmentShader(
            VertexOut in [[stage_in]],
            texture2d<float> screenTex [[texture(0)]],
            constant float2 &origin [[buffer(0)]],
            constant float &time [[buffer(1)]],
            constant float2 &resolution [[buffer(2)]]
        ) {
            constexpr sampler s(address::clamp_to_edge, filter::linear);

            float2 uv = in.texCoord;
            float2 center = origin;
            float dist = distance(uv, center);
            float2 dir = normalize(uv - center + 0.0001);

            // Multiple expanding rings
            float t = time * 1.2;
            float ring1 = smoothstep(t - 0.02, t, dist) - smoothstep(t, t + 0.02, dist);
            float ring2 = smoothstep(t * 0.7 - 0.015, t * 0.7, dist) - smoothstep(t * 0.7, t * 0.7 + 0.015, dist);
            float ring3 = smoothstep(t * 0.4 - 0.01, t * 0.4, dist) - smoothstep(t * 0.4, t * 0.4 + 0.01, dist);

            // Glitch displacement
            float glitch = sin(uv.y * 200.0 + time * 50.0) * 0.5 + 0.5;
            float glitchMask = step(0.97, sin(time * 30.0 + dist * 10.0) * 0.5 + 0.5);
            float2 glitchOffset = float2(glitchMask * glitch * 0.02, 0.0);

            // Heavy chromatic aberration
            float aberration = (ring1 + ring2 * 0.7 + ring3 * 0.5) * 0.025;

            float4 color;
            color.r = screenTex.sample(s, uv - dir * aberration + glitchOffset).r;
            color.g = screenTex.sample(s, uv + glitchOffset * 0.5).g;
            color.b = screenTex.sample(s, uv + dir * aberration - glitchOffset).b;
            color.a = 1.0;

            // Digital grid overlay
            float grid = step(0.95, fract(uv.x * 150.0)) + step(0.95, fract(uv.y * 150.0));
            grid *= (ring1 + ring2) * 0.3;

            // Neon glow on rings
            float3 neon1 = float3(0.0, 1.0, 0.9) * ring1 * 0.6;
            float3 neon2 = float3(1.0, 0.0, 0.8) * ring2 * 0.5;
            float3 neon3 = float3(0.2, 0.5, 1.0) * ring3 * 0.4;

            color.rgb += neon1 + neon2 + neon3;
            color.rgb += float3(0.0, 1.0, 1.0) * grid;

            // Scanline flicker
            float scanline = sin(uv.y * 400.0) * 0.03 * (ring1 + ring2);
            color.rgb += scanline;

            // Pixelate inside the wave
            float inside = smoothstep(t + 0.1, t - 0.05, dist);
            float2 pixelUV = floor(uv * 80.0) / 80.0;
            float4 pixelColor = screenTex.sample(s, pixelUV);
            color.rgb = mix(color.rgb, pixelColor.rgb + float3(0.0, 0.15, 0.2), inside * 0.4);

            float fadeOut = 1.0 - smoothstep(0.9, 1.3, time);
            color.a *= fadeOut;

            return color;
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let vertexFunc = library.makeFunction(name: "vertexShader")
            let fragmentFunc = library.makeFunction(name: "fragmentShader")

            let pipelineDesc = MTLRenderPipelineDescriptor()
            pipelineDesc.vertexFunction = vertexFunc
            pipelineDesc.fragmentFunction = fragmentFunc
            pipelineDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            pipelineDesc.colorAttachments[0].isBlendingEnabled = true
            pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
            pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha

            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDesc)
        } catch {
            print("Shader compile error: \(error)")
        }
    }

    private func captureScreen() {
        guard NSScreen.main != nil,
              let device = metalView?.device else { return }

        let displayID = CGMainDisplayID()
        guard let cgImage = CGDisplayCreateImage(displayID) else { return }

        let textureLoader = MTKTextureLoader(device: device)
        screenTexture = try? textureLoader.newTexture(cgImage: cgImage, options: [
            .SRGB: false,
            .textureUsage: MTLTextureUsage.shaderRead.rawValue
        ])
    }

    private func startAnimation() {
        startTime = CACurrentMediaTime()
        metalView?.isPaused = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.dismiss()
        }
    }

    func dismiss() {
        metalView?.isPaused = true
        metalView?.delegate = nil
        orderOut(nil)
        metalView?.removeFromSuperview()
        metalView = nil
        screenTexture = nil
        pipelineState = nil
        commandQueue = nil
    }
}

extension ShaderOverlayWindow: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let pipelineState = pipelineState,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let screenTexture = screenTexture,
              let renderPassDesc = view.currentRenderPassDescriptor else { return }

        renderPassDesc.colorAttachments[0].loadAction = .clear
        renderPassDesc.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }

        encoder.setRenderPipelineState(pipelineState)
        encoder.setFragmentTexture(screenTexture, index: 0)

        var origin = SIMD2<Float>(Float(originPoint.x), Float(originPoint.y))
        var time = Float(CACurrentMediaTime() - startTime)
        var resolution = SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height))

        encoder.setFragmentBytes(&origin, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
        encoder.setFragmentBytes(&time, length: MemoryLayout<Float>.size, index: 1)
        encoder.setFragmentBytes(&resolution, length: MemoryLayout<SIMD2<Float>>.size, index: 2)

        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
