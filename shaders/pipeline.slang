#language slang 2026
// Copyright (C) 2026 Kovid Goyal <kovid at kovidgoyal.net>
// Distributed under terms of the GPLv3 license.

import kitty_custom_shader_types;

// IMPORTS

public struct BlitOutput {
    float2 texcoord;
    float2 position;
};

#define left 0
#define top 1
#define right 2
#define bottom 3

// Static constant array mapping vertex IDs
static const int2 vertex_pos_map[4] = { { right, top }, { right, bottom }, { left, bottom }, { left, top } };

BlitOutput
get_coords_for_blit(uint vertex_id, float4 src_rect, float4 dest_rect) {
    int2 pos = vertex_pos_map[vertex_id];
    BlitOutput output;
    output.texcoord = float2(src_rect[pos.x], src_rect[pos.y]);
    output.position = float2(dest_rect[pos.x], dest_rect[pos.y]);
    return output;
}


public ConstantBuffer<KittyCustomShaderData> csd;


public float4
pipeline_vertex_main(uint vertex_id) {
    BlitOutput ans = get_coords_for_blit(vertex_id, csd.src_rect, csd.dest_rect);
    return float4(ans.texcoord[0], ans.texcoord[1], ans.position[0], ans.position[1]);
}

float4
vec4_premul(float3 rgb, float a) {
    return float4(rgb * a, a);
}

float
linear2srgb(float x) { // scalar
    float lower = 12.92 * x;
    float upper = 1.055 * pow(x, 1.0f / 2.4f) - 0.055f;

    return lerp(lower, upper, step(0.0031308f, x));
}

float3
linear2srgb(float3 x) { // vector
    float3 lower = 12.92 * x;
    float3 upper = 1.055 * pow(x, float3(1.0f / 2.4f)) - 0.055f;

    return lerp(lower, upper, step(float3(0.0031308f), x));
}

uniform Sampler2D backbuffer, a, b, persist;

public float4
pipeline_fragment_main(float2 backbuffer_pos, int group, float4 viewport, float animation_progress, bool convert_to_srgb) {
    float4 color = backbuffer.Sample(backbuffer_pos); // pre multiplied linear RGB
    color = float4(color.rgb / color.a, color.a);     // un pre multiplied color passed through pipeline
    // src_rect encodes (0, sy, sx, 0) — the fraction of the shared texture occupied by the current
    // viewport. The shared texture is grown to fit the largest OS Window viewport and never
    // shrunk, so sx/sy are less than one whenever this window is smaller than that. Normalize
    // backbuffer_pos so that t.pos is always in [0,1] viewport UV and wrap the samplers so that
    // shaders can address them in that same space, regardless of the size of the shared texture.
    float2 src_scale = float2(max(1e-6, csd.src_rect[right]), max(1e-6, csd.src_rect[top]));
    float2 viewport_pos = backbuffer_pos / src_scale;
    // Half a texel inset, in viewport UV, so that clamped samples do not bilinearly blend in the
    // stale texels that lie just outside the viewport region of the shared texture.
    float2 max_pos = 1.f - 0.5f / max(float2(csd.viewport_size_pixels), float2(1.f));
    KittyTextures t = {
        { backbuffer, src_scale, max_pos },
        { a, src_scale, max_pos },
        { b, src_scale, max_pos },
        { persist, src_scale, max_pos },
        viewport_pos,
        viewport,
        animation_progress,
        group
    };
    // PIPELINE
    return vec4_premul(color.rgb, color.a);
}
