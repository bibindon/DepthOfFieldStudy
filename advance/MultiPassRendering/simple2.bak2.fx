// simple2.fx : single-pass 5x5 Gaussian blur
// depth-driven skip (3 steps: 0 -> 5x5, 1 -> 10x10相当, 2 -> 15x15相当)

float2 g_texelSize = float2(1.0 / 640.0, 1.0 / 480.0);

// 入力カラー（RT0）
texture texture1;
sampler colorSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = POINT; // 5x5ガウスの重みを正確に反映したいので POINT 推奨
    MagFilter = POINT;
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
float focalDepth = 0.95; // ピント（0..1）
float2 cocThreshold = float2( // 2段しきい値で 0/1/2 を決定
    0.05, // |d - focalDepth| < x -> skip=0（ぼかし最小、実質5x5）
    0.08 // x〜y -> skip=1、それ以上 -> skip=2
);

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
    // ---- 深度→skip(0/1/2) ----
    float d = tex2D(depthSampler, uv).r; // 近=0, 遠=1（必要なら d = 1.0 - d;）
    float coc = abs(d - focalDepth);
    float skipIdx =
        (coc < cocThreshold.x) ? 0.0 :
        (coc < cocThreshold.y) ? 2.0 : 8.0;

    // ステップ = (skip+1) * texel
    float2 step = g_texelSize * (skipIdx);

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
