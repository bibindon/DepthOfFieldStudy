// simple2.fx : single-pass 5x5 BOX blur (all weights = 1)
// 深度を見て「ぼけが発生しない深度（焦点付近）」のサンプルは捨てる
// COLOR0: color, COLOR1: depth (near=0, far=1)

float2 g_texelSize = float2(1.0 / 1600.0, 1.0 / 900.0);

// 入力カラー
texture texture1;
sampler colorSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

// 入力深度（0..1, 近=0 / 遠=1）
texture textureDepth;
sampler depthSampler = sampler_state
{
    Texture = (textureDepth);
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

float focalDistanceMeters = 6.5;
float focusBandHalfWidthMeters = 2.0;

// 「焦点付近」とみなす幅（半幅）。必要なら微調整用の新パラメータ
// 例: 0.004〜0.010 あたりで調整。既定は 0.006。
float blurRadiusPixels = 1.0;
float g_dofBlend = 1.0;

void VS(
    in float4 inPos : POSITION,
    in float2 inUV : TEXCOORD0,
    out float4 outPos : POSITION,
    out float2 outUV : TEXCOORD0)
{
    outPos = inPos;
    outUV = inUV;
}

#define GaussSampleSize 11

float4 PS(in float4 pos : POSITION, in float2 uv : TEXCOORD0) : COLOR
{
    float2 texel = g_texelSize;
    float2 sampleUv = uv + texel * 0.5;
    float4 baseColor = tex2D(colorSampler, sampleUv);
    float centerDistanceMeters = tex2D(depthSampler, sampleUv).r;

    if (abs(centerDistanceMeters - focalDistanceMeters) <= focusBandHalfWidthMeters)
    {
        return baseColor;
    }

    // 中心は必ず採用（ぼけなし領域でもそのまま表示できるように）
    float4 sumC = baseColor;
    float wSum = 1.0;

    // 各タップで「焦点付近なら捨てる」

    // 奇数

    const int GaussSampleSizeHalf = GaussSampleSize / 2;
    [unroll]
    for (int j = -GaussSampleSizeHalf; j <= GaussSampleSizeHalf; ++j)
    {
        [unroll]
        for (int i = -GaussSampleSizeHalf; i <= GaussSampleSizeHalf; ++i)
        {
            if (i == 0 && j == 0)
                continue; // 中心は上で加算済み

            float2 o = float2((float) i, (float) j) * texel * blurRadiusPixels;
            float sampleDistanceMeters = tex2D(depthSampler, sampleUv + o).r;

            if (abs(sampleDistanceMeters - focalDistanceMeters) <= focusBandHalfWidthMeters)
            {
                continue;
            }

            // サンプル側の深度が「焦点付近」なら 0（捨てる）、そうでなければ 1（採用）

            float4 cs = tex2D(colorSampler, sampleUv + o);
            sumC += cs;
            wSum += 1.0;
        }
    }

    // 採用タップ数で正規化（最低でも中心の1タップは残る）
    float4 outColor = sumC / wSum;

    // デバッグ用。
    if (false)
    {
        float2 pixelPos = sampleUv / texel;
        float lineX = (frac(pixelPos.x / 5.0) < 0.2) ? 1.0 : 0.0;
        float lineY = (frac(pixelPos.y / 5.0) < 0.2) ? 1.0 : 0.0;
        float lineMask = max(lineX, lineY);

        if (lineMask > 0.0)
        {
            outColor = float4(0.0, 1.0, 0.0, 1.0);
        }
    }

    return lerp(baseColor, outColor, saturate(g_dofBlend));
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
