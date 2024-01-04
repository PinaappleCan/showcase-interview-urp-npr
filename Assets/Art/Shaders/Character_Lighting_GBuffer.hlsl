#ifndef CHARACTER_LIGHTING_INCLUDE
    #define CHARACTER_LIGHTING_INCLUDE

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
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
    float3 viewDirTS        : TEXCOORD7;
    float4 positionCS       : SV_POSITION;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct FragmentOutput
{
    half4 GBuffer0 : SV_Target0;
    half4 GBuffer1 : SV_Target1;
    half4 GBuffer2 : SV_Target2;
    half4 GBuffer3 : SV_Target3; // Camera color attachment
#if OUTPUT_SHADOWMASK
    half4 GBuffer4 : SV_Target4;
#endif
    half4 GBuffer5 : SV_Target5;
};



Varyings character_vert_gbuffer(Attributes input)
{
    Varyings output = (Varyings) 0;

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionVS = TransformWorldToView(output.positionWS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.positionSS = ComputeScreenPos(output.positionCS);
    float4 ndc = output.positionCS * 0.5f;
    output.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    output.positionNDC.zw = output.positionCS.zw;
    
    output.uv = input.uv;
    
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);

    real sign = input.tangentOS.w * GetOddNegativeScale();
    half4 tangentWS = half4(TransformObjectToWorldDir(input.tangentOS.xyz), sign);
    output.tangentWS = tangentWS;

    half3 viewDirWS = GetWorldSpaceNormalizeViewDir(output.positionWS);
    half3 viewDirTS = GetViewDirectionTangentSpace(tangentWS, output.normalWS, viewDirWS);
    output.viewDirTS = viewDirTS;
    return output;
}


FragmentOutput character_frag_gbuffer(Varyings input)
{
    float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    FragmentOutput output;
    output.GBuffer0 = col;                                      // diffuse           diffuse         diffuse         materialFlags   (sRGB rendertarget)
    output.GBuffer1 = half4(0.0, 0, 0, 0.0);                    // metallic/specular specular        specular        occlusion
    output.GBuffer2 = half4(PackNormal(input.normalWS), 0.8);   // encoded-normal    encoded-normal  encoded-normal  smoothness
    //output.GBuffer2 = half4(0.5,0.5,0.5, 1);                  // encoded-normal    encoded-normal  encoded-normal  smoothness
    output.GBuffer3 = half4(col.rgb, CHARACTER_MONSTER_ID_PERCENT); // GI                GI              GI              unused          (lighting buffer)
#if OUTPUT_SHADOWMASK
    output.GBuffer4 = half4(1.0, 1.0, 1.0, 1.0);             // will have unity_ProbesOcclusion value if subtractive lighting is used (baked)
#endif
    output.GBuffer5 = half4(1.0, 1.0, 1.0, 1.0);
    return output;
}










#endif