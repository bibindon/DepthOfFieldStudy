// simple2.fx : single-pass 5x5 Gaussian blur
// depth-driven skip (0..31) where step = (skip+1) * texel

float2 g_texelSize = float2(1.0 / 640.0, 1.0 / 480.0);

// 入力カラー（RT0）
texture texture1;
sampler colorSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// 深度（RT1: 近=0, 遠=1）
texture textureDepth;
sampler depthSampler = sampler_state
{
    Texture = (textureDepth);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// DOF パラメータ
float focalDepth = 0.96; // ピント位置（0..1）
float cocRange = 0.15; // |d - focalDepth| がこの値で最大ぼけ（skip=31）

void VS(
    in float4 inPos : POSITION,
    in float2 inUV : TEXCOORD0,
    out float4 outPos : POSITION,
    out float2 outUV : TEXCOORD0)
{
    outPos = inPos;
    outUV = inUV;
}

// 5x5 Gaussian kernel = [1 4 6 4 1] ⊗ [1 4 6 4 1] / 256
float4 PS(
    in float4 pos : POSITION,
    in float2 uv : TEXCOORD0) : COLOR
{
    // ---- 深度→skip(0..31) ----
    float d = tex2D(depthSampler, uv).r; // 近=0, 遠=1
    float coc = abs(d - focalDepth); // blur 指標
    float t = saturate(coc / max(cocRange, 1e-6)); // 0..1
    // 32 段階に量子化（0..31）
    float skipIdx = floor(t * 31.0 + 0.5); // 近いほど 0、遠いほど 31
    float2 step = g_texelSize * (skipIdx + 1.0);

    float4 sum = 0.0;
    // y = -2
    sum += tex2D(colorSampler, uv + float2(-2, -2) * step) * 1.0;
    sum += tex2D(colorSampler, uv + float2(-1, -2) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(0, -2) * step) * 6.0;
    sum += tex2D(colorSampler, uv + float2(1, -2) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(2, -2) * step) * 1.0;

    // y = -1
    sum += tex2D(colorSampler, uv + float2(-2, -1) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(-1, -1) * step) * 16.0;
    sum += tex2D(colorSampler, uv + float2(0, -1) * step) * 24.0;
    sum += tex2D(colorSampler, uv + float2(1, -1) * step) * 16.0;
    sum += tex2D(colorSampler, uv + float2(2, -1) * step) * 4.0;

    // y = 0
    sum += tex2D(colorSampler, uv + float2(-2, 0) * step) * 6.0;
    sum += tex2D(colorSampler, uv + float2(-1, 0) * step) * 24.0;
    sum += tex2D(colorSampler, uv + float2(0, 0) * step) * 36.0;
    sum += tex2D(colorSampler, uv + float2(1, 0) * step) * 24.0;
    sum += tex2D(colorSampler, uv + float2(2, 0) * step) * 6.0;

    // y = +1
    sum += tex2D(colorSampler, uv + float2(-2, 1) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(-1, 1) * step) * 16.0;
    sum += tex2D(colorSampler, uv + float2(0, 1) * step) * 24.0;
    sum += tex2D(colorSampler, uv + float2(1, 1) * step) * 16.0;
    sum += tex2D(colorSampler, uv + float2(2, 1) * step) * 4.0;

    // y = +2
    sum += tex2D(colorSampler, uv + float2(-2, 2) * step) * 1.0;
    sum += tex2D(colorSampler, uv + float2(-1, 2) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(0, 2) * step) * 6.0;
    sum += tex2D(colorSampler, uv + float2(1, 2) * step) * 4.0;
    sum += tex2D(colorSampler, uv + float2(2, 2) * step) * 1.0;

    return saturate(sum / 256.0);
}

technique Technique1
{
    pass P0
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
