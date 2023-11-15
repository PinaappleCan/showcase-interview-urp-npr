Shader "Hidden/Universal Render Pipeline/PostOutline"
{
    HLSLINCLUDE
        #pragma exclude_renderers gles
        #pragma multi_compile_local_fragment _ _USE_FAST_SRGB_LINEAR_CONVERSION

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Shaders/PostProcessing/Common.hlsl"

        #define SAMPLE_COUNT            42

        // a small cost to the pre-filtering pass
        #define COC_LUMA_WEIGHTING      0

        #define SCALE 0.71f


        TEXTURE2D_X(SceneColorTexture);
        TEXTURE2D_X(NewDepthTexture);

        half4 _SourceSize;
        half4 _HalfSourceSize;

        //Texture2D SceneColorTexture;
        //SamplerState SceneColorSampler;
        //Texture2D NewDepthTexture;
        //SamplerState NewDepthSampler;

        float ColorTorresContrast;
        float ColorTorresAlpha;
        float OutlineIntensity;
        float OutlineFarIntensity;
        float OutlineShadowIntensity;
        float OutlineFarShadowIntensity;
        float OutlineIntensityDistance;
        float OutlineWidth;
        float DepthOutlineScale;
        float DepthOutlineThreshold;
        float ColorOutlineScale;
        float NormalOutlineScale;
        float4 OutlineColor;



        float4 Frag(Varyings input) : SV_Target
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

            return 1;
        }


        

    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            Name "Bokeh Depth Of Field CoC"

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment Frag
                //#pragma target 4.5
            ENDHLSL
        }




    }


}
