Shader "Hidden/Universal Render Pipeline/Diffusion"
{
    HLSLINCLUDE

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

    struct a2v
    {
        float4 positionOS : POSITION;
        float2 uv         : TEXCOORD0;
    };

    struct v2f
    {
        float4 positionCS : SV_POSITION;
        float2 uv         : TEXCOORD0;
    };

    TEXTURE2D(_DiffusionY2);
    //SamplerState sampler_LinearClamp;
    //SamplerState sampler_PointClamp;

    half LinearToSrgbBranchingChannel(half lin)
    {
        if (lin < 0.00313067) return lin * 12.92;
        return pow(lin, (1.0 / 2.4)) * 1.055 - 0.055;
    }

    half3 LinearToSrgbBranching(half3 lin)
    {
        return half3(
            LinearToSrgbBranchingChannel(lin.r),
            LinearToSrgbBranchingChannel(lin.g),
            LinearToSrgbBranchingChannel(lin.b));
    }

    half3 LinearToSrgb(half3 lin)
    {
        return LinearToSrgbBranching(lin);
    }

    half3 sRGBToLinear(half3 Color)
    {
        Color = max(6.10352e-5, Color); // minimum positive non-denormal (fixes black problem on DX11 AMD and NV)
        return Color > 0.04045 ? pow(Color * (1.0 / 1.055) + 0.0521327, 2.4) : Color * (1.0 / 12.92);
    }



    half4 frag_diffusion_power2(v2f input) : SV_Target
    {
        float4 col = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.uv);

        float3 finalColor = col.xyz * col.xyz;
        return float4(finalColor, 1);
    }

#define MAX_FILTER_SAMPLES 32
#define PACKED_STATIC_SAMPLE_COUNT ((_SampleCount + 1) / 2)

    uniform float4 _DiffusionViewSize0;

    uniform int _SampleCount;
    uniform float4 _SampleOffsets[(MAX_FILTER_SAMPLES + 1) / 2];
    uniform float4 _SampleWeights[MAX_FILTER_SAMPLES];

    float4 SampleFilterTexture(float2 uv)
    {
        float4 Sample = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv);
        return Sample;
    }


    float4 frag_diffusion_blur(v2f input) : SV_Target
    {
        float4 Color = 0;
        float4 InOffsetUVs[20];
        //return SampleFilterTexture(input.uv);
        //uv
        UNITY_UNROLL
        for (int OffsetIndex = 0; OffsetIndex < ((_SampleCount + 1) / 2); ++OffsetIndex)
        {
            InOffsetUVs[OffsetIndex] = input.uv.xyxy + _SampleOffsets[OffsetIndex];
        }

        // cal
        UNITY_UNROLL
        for (int SampleIndex = 0; SampleIndex < _SampleCount - 1; SampleIndex += 2)
        {
            float4 UVUV = InOffsetUVs[SampleIndex / 2];
            Color += SampleFilterTexture(UVUV.xy) * _SampleWeights[SampleIndex + 0];
            Color += SampleFilterTexture(UVUV.zw) * _SampleWeights[SampleIndex + 1];
        }

        if (_SampleCount & 1)
        {
            float2 UV = InOffsetUVs[((_SampleCount + 1) / 2) - 1].xy;
            Color += SampleFilterTexture(UV) * _SampleWeights[_SampleCount - 1];
        }

        return Color;
    }

        void frag_diffusion_composite(v2f input, out half4 out_color : SV_TARGET, out float out_depth : SV_DEPTH)
    {
        float4 baseColor = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, input.uv);
        float4 pow2Color = baseColor * baseColor;

        float4 blurColor = SAMPLE_TEXTURE2D(_DiffusionY2, sampler_LinearClamp, input.uv);
        float4 finalColor = (1.0f - ((1.0f - pow2Color) * (1.0f - blurColor)));

        finalColor.xyz = max(baseColor.xyz, finalColor.xyz);
        finalColor.w = baseColor.w;

#ifdef _ENABLE_COLOR_GRADING
        finalColor.rgb = ColorLookupTable_Scene(finalColor.rgb, input.uv);
#endif

        finalColor.rgb = sRGBToLinear(finalColor.rgb);

#ifdef _ENABLE_COLOR_GRADING
#if defined(_ENABLE_OVERRIDE_LUT) || defined(_ENABLE_CUT_SCENE_COLOR_GRADING)
        finalColor.rgb = ColorLookupTable_Override(finalColor.rgb);
#endif
#endif

        out_color = finalColor;
        out_depth = SampleSceneDepth(input.uv);
    }

    float4 DownsampleCommon(float2 UV)
    {
        float4 OutColor;
        float2 UVs[4];

        UVs[0] = UV + _DiffusionViewSize0.zw * float2(-1, -1);
        UVs[1] = UV + _DiffusionViewSize0.zw * float2(1, -1);
        UVs[2] = UV + _DiffusionViewSize0.zw * float2(-1, 1);
        UVs[3] = UV + _DiffusionViewSize0.zw * float2(1, 1);

        float4 Sample[4];

        UNITY_UNROLL
            for (uint i = 0; i < 4; ++i)
            {
                Sample[i] = SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, UVs[i]);
            }

        OutColor = (Sample[0] + Sample[1] + Sample[2] + Sample[3]) * 0.25f;
        OutColor.rgb = max(float3(0, 0, 0), OutColor.rgb);
        return OutColor;
    }

    half4 frag_down_sample(v2f input) : SV_Target
    {
        return DownsampleCommon(input.uv);
    }


        ENDHLSL

        SubShader
    {
        ZTest Always Cull Off
            ZWrite Off
            Pass
        {
            Name "Diffusion Power2"

            HLSLPROGRAM
                #pragma vertex   Vert
                #pragma fragment frag_diffusion_power2
            ENDHLSL
        }

            Pass
        {
            Name "Diffusion BlurX"

            HLSLPROGRAM
                #define BlurX
                #pragma vertex   Vert
                #pragma fragment frag_diffusion_blur
            ENDHLSL
        }

            Pass
        {
            Name "Diffusion BlurY"

            HLSLPROGRAM
                #define BlurY
                #pragma vertex   Vert
                #pragma fragment frag_diffusion_blur
            ENDHLSL
        }

            Pass
        {
            Name "Diffusion Composite"

            HLSLPROGRAM
                #pragma vertex   Vert
                #pragma fragment frag_diffusion_composite

                #pragma multi_compile_fragment _ _ENABLE_INDOOR_LUT
                #pragma multi_compile_fragment _ _ENABLE_OVERRIDE_LUT _ENABLE_CUT_SCENE_COLOR_GRADING
                #pragma multi_compile_fragment _ _ENABLE_COLOR_GRADING
            ENDHLSL
        }

            Pass
        {
            Name "Down Sample"

            HLSLPROGRAM
                #pragma vertex   Vert
                #pragma fragment frag_down_sample
            ENDHLSL
        }
    }
}
