#ifndef CHARACTER_LIGHTING_INCLUDE
    #define CHARACTER_LIGHTING_INCLUDE

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 color :  COLOR;
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
    float4 color            : TEXCOORD8;
    float4 positionCS       : SV_POSITION;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings character_vert_forward(Attributes input)
{
    Varyings output = (Varyings)0;

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionVS = TransformWorldToView(output.positionWS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.positionSS = ComputeScreenPos(output.positionCS);
    float4 ndc = output.positionCS * 0.5f;
    output.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    output.positionNDC.zw = output.positionCS.zw;
    
    output.uv = input.uv1;
    
    output.color = input.color;

    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(output.positionWS);
    output.viewDirWS = viewDirWS;

    return output;
}

float4 character_frag_forward(Varyings input) : SV_Target
{
    Light light = GetMainLight();
    
    float3 normalWS = input.normalWS;
    float3 lightWS = light.direction;
    float3 viewWS = input.viewDirWS;

    float3 H = normalize(lightWS + viewWS);
    float NdotL = step(-0.2, dot(normalWS, light.direction));
    float NdotH = max(0, dot(H, normalWS));


    float4 mainMap = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv) * _MainColor;
    float4 diMap = SAMPLE_TEXTURE2D(_DI_Tex, sampler_DI_Tex, input.uv);
    float4 spMap = SAMPLE_TEXTURE2D(_SP_Tex, sampler_SP_Tex, input.uv);
    //return mainMap;
    float4 col = mainMap;
    float4 shadowColor = float4( ShadowColorShift_RGB_Monster(col.rgb), 1);

    float shadowArea = NdotL * diMap.r;

    col = lerp(lerp(shadowColor, _ShadowColor * col, _SwitchShadowMode) , col, shadowArea);
    float2 positionSS = input.positionSS.xy / input.positionSS.w;
 
    float4 specularColor = NdotH * _SpecularColor * spMap.g;

    float4 emissiveColor = spMap.b * _Emissive1Color + spMap.a * _Emissive2Color;

    col = lerp(_InlineColor, col, diMap.a);

    float rimRange = Character_Rim(positionSS, _RimWidth, _RimLightThreshold) * shadowArea * diMap.g;
    col += rimRange * _RimColor;// lerp(col, _RimColor, rimRange);
    col += emissiveColor + specularColor;

    return col;
}





#endif