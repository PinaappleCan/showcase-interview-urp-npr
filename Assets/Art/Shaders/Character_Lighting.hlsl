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
    float4 positionCS       : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};



Varyings character_vert(Attributes input)
{
    Varyings output = (Varyings)0;

    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.positionVS = TransformWorldToView(output.positionWS);
    output.positionCS = TransformWorldToHClip(output.positionWS);
    output.positionSS = ComputeScreenPos(output.positionCS);
    float4 ndc = output.positionCS * 0.5f;
    output.positionNDC.xy = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
    output.positionNDC.zw = output.positionCS.zw;
    
    output.uv = input.uv;
    
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    return output;
}

float4 character_frag(Varyings input) : SV_Target
{
    Light light = GetMainLight();
    
    float3 normalWS = input.normalWS;
    float NdotL = step( 0, dot(normalWS, light.direction));
    
    float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
    
    col = lerp(_ShadowColor * col, col, NdotL);
    float2 positionSS = input.positionSS.xy / input.positionSS.w;
 
    float4 rimColor = Character_Rim(positionSS, _RimWidth, _RimLightThreshold) * _RimColor;

    col += rimColor;

    return col;
}


#endif