//
//  Shaders.metal
//  YabaiPro
//
//  Created by Jake Shore
//  Copyright © 2024 Jake Shore. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Liquid Border Shaders

vertex float4 liquidBorderVertex(uint vertexID [[vertex_id]],
                                constant float2 *vertices [[buffer(0)]],
                                constant float &time [[buffer(1)]],
                                constant float4 &bounds [[buffer(2)]]) {
    float2 position = vertices[vertexID];

    // Convert to normalized device coordinates (-1 to 1)
    float2 normalizedPos = position / float2(bounds.z, bounds.w) * 2.0 - 1.0;

    return float4(normalizedPos, 0.0, 1.0);
}

fragment float4 liquidBorderFragment(float4 position [[position]],
                                    constant LiquidBorderUniforms &uniforms [[buffer(0)]]) {
    // Create flowing liquid effect with smooth gradients
    float wave1 = sin(position.x * 0.005 + uniforms.time * 2.0) * uniforms.amplitude;
    float wave2 = sin(position.x * 0.01 + uniforms.time * 1.5) * uniforms.amplitude * 0.5;
    float wave3 = sin(position.x * 0.02 + uniforms.time * 3.0) * uniforms.amplitude * 0.3;

    float totalWave = wave1 + wave2 + wave3;

    // Create organic edge falloff
    float edgeDistance = min(min(position.x, position.y),
                           min(1.0 - position.x, 1.0 - position.y));
    float edgeAlpha = smoothstep(0.0, 10.0, edgeDistance);

    // Combine waves with edge falloff
    float alpha = uniforms.color.a * edgeAlpha * (0.7 + totalWave * 0.1);

    return float4(uniforms.color.rgb, clamp(alpha, 0.0, 1.0));
}

// MARK: - Particle Shaders

struct ParticleVertexOut {
    float4 position [[position]];
    float4 color;
    float size;
    float pointSize [[point_size]];
};

vertex ParticleVertexOut particleVertex(uint vertexID [[vertex_id]],
                                       constant ParticleUniforms *particles [[buffer(0)]],
                                       constant float &time [[buffer(1)]],
                                       constant float2 &viewportSize [[buffer(2)]]) {
    ParticleUniforms particle = particles[vertexID];

    // Convert position to clip space
    float2 clipPos = (particle.position / viewportSize) * 2.0 - 1.0;

    ParticleVertexOut out;
    out.position = float4(clipPos, 0.0, 1.0);
    out.color = particle.color;
    out.size = particle.size;
    out.pointSize = particle.size * 2.0; // Double for better visibility

    return out;
}

fragment float4 particleFragment(ParticleVertexOut in [[stage_in]],
                                float2 pointCoord [[point_coord]]) {
    // Create circular particles with soft edges
    float distance = length(pointCoord - float2(0.5, 0.5));

    // Smooth circular falloff
    float alpha = 1.0 - smoothstep(0.0, 0.5, distance);
    alpha *= in.color.a;

    // Add subtle glow effect
    float glow = smoothstep(0.3, 0.0, distance) * 0.3;

    return float4(in.color.rgb, alpha + glow);
}

// MARK: - Ripple Shaders

vertex float4 rippleVertex(uint vertexID [[vertex_id]],
                          constant RippleUniforms &ripple [[buffer(0)]],
                          constant float &time [[buffer(1)]],
                          constant float2 &viewportSize [[buffer(2)]]) {
    // Generate quad vertices for ripple
    float2 vertices[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    float2 position = vertices[vertexID];

    // Scale by ripple radius
    position *= ripple.radius / max(viewportSize.x, viewportSize.y);

    // Offset to ripple center
    float2 center = ripple.center / viewportSize * 2.0 - 1.0;
    position += center;

    return float4(position, 0.0, 1.0);
}

fragment float4 rippleFragment(float4 position [[position]],
                              constant RippleUniforms &ripple [[buffer(0)]],
                              constant float &time [[buffer(1)]],
                              constant float2 &viewportSize [[buffer(2)]]) {
    // Calculate distance from ripple center
    float2 center = ripple.center / viewportSize * 2.0 - 1.0;
    float distance = length(position.xy - center);

    // Create expanding ring effect
    float ringWidth = 20.0;
    float ringProgress = fmod(time * 100.0 - distance * 10.0, ringWidth * 2.0);
    float ringAlpha = 1.0 - abs(ringProgress - ringWidth) / ringWidth;

    // Fade with distance and time
    float timeFade = max(0.0, 1.0 - time * 0.5);
    float distanceFade = max(0.0, 1.0 - distance * 2.0);

    float alpha = ringAlpha * timeFade * distanceFade * ripple.strength * ripple.color.a;

    return float4(ripple.color.rgb, clamp(alpha, 0.0, 1.0));
}

// MARK: - Morphing Shape Shaders

vertex float4 morphingShapeVertex(uint vertexID [[vertex_id]],
                                 constant float2 *vertices [[buffer(0)]],
                                 constant float &morphProgress [[buffer(1)]],
                                 constant float4 &bounds [[buffer(2)]],
                                 constant float &time [[buffer(3)]]) {
    float2 position = vertices[vertexID];

    // Apply morphing transformation
    float morphFactor = morphProgress;

    // Create organic deformation
    float deformation = sin(position.x * 0.01 + time * 2.0) * morphFactor * 20.0;
    position.y += deformation;

    // Convert to normalized device coordinates
    float2 normalizedPos = position / float2(bounds.z, bounds.w) * 2.0 - 1.0;

    return float4(normalizedPos, 0.0, 1.0);
}

fragment float4 morphingShapeFragment(float4 position [[position]],
                                     constant float &morphProgress [[buffer(0)]],
                                     constant float4 &color [[buffer(1)]]) {
    // Create gradient based on morph progress
    float gradient = morphProgress * 0.5 + 0.5;
    float alpha = color.a * gradient;

    // Add subtle animation
    float animation = sin(position.x * 0.1 + position.y * 0.1) * 0.1 + 0.9;

    return float4(color.rgb * animation, alpha);
}











