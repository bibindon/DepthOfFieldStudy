// simple2.fx:
// 1 パス目で作ったカラーと距離テクスチャを使い、
// 中心画素がピント外のときだけポストエフェクトでぼかす。

float2 g_texelSize = float2(1.0 / 1600.0, 1.0 / 900.0);

// 入力カラー。
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

// 入力距離テクスチャ。
// simple.fx が COLOR1 の R 成分へ書いた距離を読む。
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

// ピント中心距離。単位はメートル扱い。
float focalDistanceMeters = 6.5;

// ピントが合っているとみなす距離帯の半幅。単位はメートル。
float focusBandHalfWidthMeters = 2.0;

// ぼかし半径。これは距離ではなく画面上のピクセル半径。
float blurRadiusPixels = 1.0;

// C++ 側で制御する DOF の適用率。
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

// 奇数前提のサンプルサイズ。
#define GaussSampleSize 11

float4 PS(in float4 pos : POSITION, in float2 uv : TEXCOORD0) : COLOR
{
    float2 texel = g_texelSize;
    float2 sampleUv = uv + texel * 0.5;
    float4 baseColor = tex2D(colorSampler, sampleUv);
    float centerDistanceMeters = tex2D(depthSampler, sampleUv).r;

    // 中心画素がピント内なら、その画素はぼかさない。
    if (abs(centerDistanceMeters - focalDistanceMeters) <= focusBandHalfWidthMeters)
    {
        return baseColor;
    }

    // 中心画素がピント外のときだけ周囲を平均する。
    float4 sumC = baseColor;
    float wSum = 1.0;

    const int GaussSampleSizeHalf = GaussSampleSize / 2;
    [unroll]
    for (int j = -GaussSampleSizeHalf; j <= GaussSampleSizeHalf; ++j)
    {
        [unroll]
        for (int i = -GaussSampleSizeHalf; i <= GaussSampleSizeHalf; ++i)
        {
            if (i == 0 && j == 0)
                continue;

            float2 o = float2((float) i, (float) j) * texel * blurRadiusPixels;
            float sampleDistanceMeters = tex2D(depthSampler, sampleUv + o).r;

            // 本来くっきり表示されるサンプルは混ぜない。
            if (abs(sampleDistanceMeters - focalDistanceMeters) <= focusBandHalfWidthMeters)
            {
                continue;
            }

            float4 cs = tex2D(colorSampler, sampleUv + o);
            sumC += cs;
            wSum += 1.0;
        }
    }

    float4 outColor = sumC / wSum;

    // デバッグ用。
    // true にすると 5 ピクセルおきの緑グリッドを表示する。
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

    // 最終的な DOF 強度を C++ 側のブレンド値で制御する。
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
