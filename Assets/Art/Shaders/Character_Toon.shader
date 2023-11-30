Shader "BP/Character_Toon"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _DI_Tex("DI Texture", 2D) = "white"{}
        _SP_Tex("SP Texture", 2D) = "white"{}

        _RimWidth ("Rim Width", Float) = 1
        _RimLightThreshold ("Rim Light Threshold", Range(0, 1)) = 1
        _RimColor("Rim Color", Color) = (1,1,1,1)
        [HDR]_ShadowColor("Shadow Color", color) = (.5, .5, .5, .5)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        ZWrite On
        Cull Back
        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        //#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ParallaxMapping.hlsl"

        TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
        TEXTURE2D(_DI_Tex);         SAMPLER(sampler_DI_Tex);
        TEXTURE2D(_SP_Tex);         SAMPLER(sampler_SP_Tex);
        float4 _MainTex_ST;
        float4 _ShadowColor;
        float _RimWidth;
        float _RimLightThreshold;
        float4 _RimColor;

        ENDHLSL

        Pass
        { 
            Name "ForwardLit"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            HLSLPROGRAM
            #pragma vertex character_vert_forward
            #pragma fragment character_frag_forward

            #include "./Character_Include_Forward.hlsl"
            #include "./Character_Lighting_Forward.hlsl"

            ENDHLSL
        }

        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }
            HLSLPROGRAM
            #pragma vertex character_vert_gbuffer
            #pragma fragment character_frag_gbuffer

            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

            #include "./Character_Include_GBuffer.hlsl"
            #include "./Character_Lighting_GBuffer.hlsl"
            ENDHLSL
        
        }

        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            HLSLPROGRAM
            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            #include "./Character_DepthOnly.hlsl"
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
