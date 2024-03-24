Shader "BP/Character_Toon"
{
    Properties
    {
        _MainColor("Main Color", Color) = (1,1,1,1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _DI_Tex("DI Texture", 2D) = "white"{}
        _SP_Tex("SP Texture", 2D) = "white"{}

        _RimWidth("Rim Width", Float) = 1
        _RimLightThreshold("Rim Light Threshold", Range(0, 1)) = 1
        [HDR]_RimColor("Rim Color", Color) = (1,1,1,1)

        _InlineColor("Inline Color", Color) = (1,1,1,1)

        [HDR]_SpecularColor("Specular Color", Color) = (1,1,1,1)
        [HDR]_Emissive1Color("Emissive1 Color", Color) = (1,1,1,1)
        [HDR]_Emissive2Color("Emissive2 Color", Color) = (1,1,1,1)
        [Toggle] _SwitchShadowMode("Switch Shadow Mode", Float) = 0

        _GradingHeight("Grading Height", Range(0, 30)) = 1
        _GradingOffset("Grading Offset", Range(-10, 10)) = 0
        [HDR]_GradingColor("Grading Color", Color) = (.5, .5, .5, .5)
        [HDR]_ShadowColor("Shadow Color", Color) = (.5, .5, .5, .5)

        _OutlineWidth("Outline Width", Float) = 0.01
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 0)
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

        #pragma multi_compile_fragment _ _AUTOSHADOW_USE_DEBUG

        TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
        TEXTURE2D(_DI_Tex);         SAMPLER(sampler_DI_Tex);
        TEXTURE2D(_SP_Tex);         SAMPLER(sampler_SP_Tex);

        float4 _GradingColor;
        float _GradingHeight, _GradingOffset ;

        float _SwitchShadowMode;

        float4 _MainTex_ST;
        float4 _ShadowColor;
        float _RimWidth;
        float _RimLightThreshold;

        float4 _MainColor;
        float4 _RimColor;

        float4 _SpecularColor;
        float4 _Emissive1Color, _Emissive2Color;
        float4 _InlineColor;

        float _OutlineWidth;
        float4 _OutlineColor;
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

            #include "../PPS/AutoShadowColor.hlsl"
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

            #include "./GBuffer_ShadingModel_ID.hlsl"
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

        Pass
        {
            Name "Outline"
            Tags
            {
                "LightMode" = "Outline"
            }

            Cull Front

            HLSLPROGRAM
            #pragma vertex character_vert_outline
            #pragma fragment character_frag_outline

            #include "./Character_Outline.hlsl"

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
