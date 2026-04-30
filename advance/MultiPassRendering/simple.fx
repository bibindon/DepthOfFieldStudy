float4x4 g_matWorldViewProj;
float4x4 g_matWorldView;
float4 g_lightNormal = { 0.3f, 1.0f, 0.5f, 0.0f };
float3 g_ambient = { 0.3f, 0.3f, 0.3f };

bool g_bUseTexture = true;

texture texture1;
sampler textureSampler = sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = NONE;
    MagFilter = NONE;
};

// 1 パス目の頂点シェーダー。
// COLOR0 用の UV をそのまま渡しつつ、
// COLOR1 用にカメラからの距離をメートル扱いで計算して次段へ渡す。
void VertexShader1(
    in float4 inPosition : POSITION,
    in float3 inNormal : NORMAL,
    in float2 inTexCoord0 : TEXCOORD0,
    out float4 outPosition : POSITION0,
    out float2 outTexCoord0 : TEXCOORD0,
    out float outDistanceMeters : TEXCOORD1)
{
    float4 clipPosition = mul(inPosition, g_matWorldViewProj);
    float4 viewPosition = mul(inPosition, g_matWorldView);
    outPosition = clipPosition;
    outTexCoord0 = inTexCoord0;

    // ビュー空間の原点はカメラ位置なので、その長さを距離として使う。
    outDistanceMeters = length(viewPosition.xyz);
}

// 1 パス目のピクセルシェーダー。
// COLOR0 にはカラーを、COLOR1 の R 成分には距離を書き出す。
// 距離テクスチャの実体は R32F だが、COLOR1 自体は float4 で返す必要がある。
void PixelShaderMRT(
    in float2 inTexCoord0 : TEXCOORD0,
    in float inDistanceMeters : TEXCOORD1,
    out float4 outColor0 : COLOR0,
    out float4 outColor1 : COLOR1)
{
    float4 baseColor = float4(0.5, 0.5, 0.5, 1.0);

    if (g_bUseTexture)
    {
        baseColor = tex2D(textureSampler, inTexCoord0);
    }

    outColor0 = baseColor;
    outColor1 = float4(inDistanceMeters, 0.0, 0.0, 0.0);
}

// 1 パス目:
// カラーと距離を MRT へ同時に書き出す。
technique TechniqueMRT
{
    pass P0
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VertexShader1();
        PixelShader = compile ps_3_0 PixelShaderMRT();
    }
}
