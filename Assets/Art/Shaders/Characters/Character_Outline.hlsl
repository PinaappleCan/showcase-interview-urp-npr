#ifndef CHARACTER_OUTLINE_INCLUDE
	#define CHARACTER_OUTLINE_INCLUDE

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv1 : TEXCOORD0;
    float2 uv2 : TEXCOORD1;
    float2 staticLightmapUV : TEXCOORD1;
    float2 dynamicLightmapUV : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv               : TEXCOORD0;
    float3 positionWS       : TEXCOORD1;
    float3 positionVS       : TEXCOORD2;
    float4 positionNDC      : TEXCOORD3;
    float3 normalWS         : TEXCOORD4;
    float4 positionSS       : TEXCOORD5;

    float4 tangentWS        : TEXCOORD6; // xyz: tangent, w: sign
    float3 viewDirWS        : TEXCOORD7;
    float4 positionCS       : SV_POSITION;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};


Varyings character_vert_outline(Attributes input)
{
    Varyings output = (Varyings)0;
    
    input.positionOS.xyz += input.normalOS * _OutlineWidth * 0.01;

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionVS = TransformWorldToView(output.positionWS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.positionSS = ComputeScreenPos(output.positionCS);
    float4 ndc = output.positionCS * 0.5f;
    output.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    output.positionNDC.zw = output.positionCS.zw;

    output.uv = input.uv1;

    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(output.positionWS);
    output.viewDirWS = viewDirWS;

    return output;
}

float4 character_frag_outline(Varyings input) : SV_Target
{
    return _OutlineColor;
}

#endif