// simple2.fx : single-pass 5x5 Gaussian blur with "skip" spacing

float4x4 g_matWorldViewProj;

// ��f�T�C�Y�i���� 640x480�j
// ���s�𑜓x�ɍ��킹�ăA�v�������� SetFloatArray("g_texelSize", ...) �ŏ㏑����
float2 g_texelSize = float2(1.0 / 640.0, 1.0 / 480.0);

// �T���v�����O�Ԋu�̔{��
// 0=5x5(1px�Ԋu), 1=10x10����(2px�Ԋu), 2=15x15����(3px�Ԋu)
int skip = 3;

texture texture1;
sampler textureSampler =
sampler_state
{
    Texture = (texture1);
    MipFilter = NONE;
    MinFilter = POINT;
    MagFilter = POINT;
    AddressU = CLAMP;
    AddressV = CLAMP;
};

void VertexShader1
(
    in float4 inPosition : POSITION,
    in float2 inTexCood : TEXCOORD0,
    out float4 outPosition : POSITION,
    out float2 outTexCood : TEXCOORD0
)
{
    outPosition = inPosition;
    outTexCood = inTexCood;
}

// 5x5 Gaussian kernel (outer product of [1 4 6 4 1], normalized by 256)
void PixelShader1
(
    in float4 inPosition : POSITION,
    in float2 inTexCood : TEXCOORD0,
    out float4 outColor : COLOR
)
{
    float2 baseStep = g_texelSize * (float) (skip + 1);

    float4 sumColor = 0.0;

    // row y = -2
    sumColor += tex2D(textureSampler, inTexCood + float2(-2, -2) * baseStep) * 1.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(-1, -2) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(0, -2) * baseStep) * 6.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(1, -2) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(2, -2) * baseStep) * 1.0;

    // row y = -1
    sumColor += tex2D(textureSampler, inTexCood + float2(-2, -1) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(-1, -1) * baseStep) * 16.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(0, -1) * baseStep) * 24.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(1, -1) * baseStep) * 16.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(2, -1) * baseStep) * 4.0;

    // row y = 0
    sumColor += tex2D(textureSampler, inTexCood + float2(-2, 0) * baseStep) * 6.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(-1, 0) * baseStep) * 24.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(0, 0) * baseStep) * 36.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(1, 0) * baseStep) * 24.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(2, 0) * baseStep) * 6.0;

    // row y = +1
    sumColor += tex2D(textureSampler, inTexCood + float2(-2, 1) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(-1, 1) * baseStep) * 16.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(0, 1) * baseStep) * 24.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(1, 1) * baseStep) * 16.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(2, 1) * baseStep) * 4.0;

    // row y = +2
    sumColor += tex2D(textureSampler, inTexCood + float2(-2, 2) * baseStep) * 1.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(-1, 2) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(0, 2) * baseStep) * 6.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(1, 2) * baseStep) * 4.0;
    sumColor += tex2D(textureSampler, inTexCood + float2(2, 2) * baseStep) * 1.0;

    outColor = saturate(sumColor / 256.0);
}

technique Technique1
{
    pass P0
    {
        CullMode = NONE;
        VertexShader = compile vs_3_0 VertexShader1();
        PixelShader = compile ps_3_0 PixelShader1();
    }
}
