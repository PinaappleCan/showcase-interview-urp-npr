Shader "Hidden/Universal Render Pipeline/SSGI"

{
	HLSLINCLUDE

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

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

	v2f vert(a2v v)
	{
		v2f o;
		o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
		o.uv = v.uv;

		return o;
	}

	//-------------------------------------------------------- CONFIG
#ifdef OUTPUT_COUNT_2
#define OUTPUT_COUNT 2
#elif defined(OUTPUT_COUNT_3)
#define OUTPUT_COUNT 3
#else
#define OUTPUT_COUNT 1
#endif

#ifdef DOWN_SAMPLE_METHOD_1
#define DOWN_SAMPLE_METHOD 1
#elif defined(DOWN_SAMPLE_METHOD_2)
#define DOWN_SAMPLE_METHOD 2
#else
#define DOWN_SAMPLE_METHOD 0
#endif

//------------------------------------------------------- ENUM VALUES
/** Matches ESSGIDownSampleMethod. */
#define DOWN_SAMPLE_METHOD_DEPTH_SEPARATE 1
#define DOWN_SAMPLE_METHOD_BLEND 2

//------------------------------------------------------- PARAMETERS
	TEXTURE2D(_CameraNormalsTexture);

	TEXTURE2D(_SSGIDownSampleInput0); SAMPLER(sampler_SSGIDownSampleInput0);
	TEXTURE2D(_SSGIDownSampleInput1); SAMPLER(sampler_SSGIDownSampleInput1);
	TEXTURE2D(_SSGIDownSampleInput2); SAMPLER(sampler_SSGIDownSampleInput2);

	TEXTURE2D(_HZBTexture); SAMPLER(sampler_HZBTexture);

	SamplerState sampler_LinearClamp;
	SamplerState sampler_PointClamp;

	uniform float4 SSGIDownSampleInputParameter0;
	uniform float4 UVScale;
	uniform float4 UVClampParam;
	uniform float4 HZBRemappingParam;
	uniform real4 _DarkColor;


	//------------------------------------------------------- FUNCTIONS
	float4 Texture2DSample(Texture2D Tex, SamplerState Sampler, float2 UV)
	{
		return Tex.SampleLevel(Sampler, UV, 0);
	}

	float4 Texture2DSampleLevel(Texture2D Tex, SamplerState Sampler, float2 UV, float Mip)
	{
		return Tex.SampleLevel(Sampler, UV, Mip);
	}


	float2 ClampUVToViewSize(float2 InUV)
	{
		float2 ClampedUV;
		ClampedUV.x = min(UVClampParam.x, InUV.x);
		ClampedUV.y = min(UVClampParam.y, InUV.y);
		return ClampedUV;
	}

	float3 ClampOutputColor(float3 InputColor)
	{
		InputColor += 0.001f;
		InputColor = max(InputColor, 0.001f);
		InputColor = min(InputColor, 50.0f);
		return InputColor;
	}

	void DownSampleFilterColorPassFunc(Texture2D InputTexture, SamplerState Sampler, float2 TexCenter, out float4 OutColor)
	{
		float2 Offset = SSGIDownSampleInputParameter0.zw;

		float2 UV0 = TexCenter + Offset * float2(-1, -1);
		float3 ResultColor = Texture2DSample(InputTexture, Sampler, UV0).rgb;

		float2 UV1 = TexCenter + Offset * float2(1, -1);
		ResultColor += Texture2DSample(InputTexture, Sampler, UV1).rgb;

		float2 UV2 = TexCenter + Offset * float2(-1, 1);
		ResultColor += Texture2DSample(InputTexture, Sampler, UV2).rgb;

		float2 UV3 = TexCenter + Offset * float2(1, 1);
		ResultColor += Texture2DSample(InputTexture, Sampler, UV3).rgb;

		ResultColor *= 0.25f;

		OutColor = float4(ResultColor, 1.0f);
	}

	float2 ScreenPosToHZBUV(float2 In)
	{
		return In;// * HZBRemappingParam.zw;
	}

#define NEAR_SSGI_DEPTH_THREASHOLD 15.0f
#define NEAR_SSGI_DEPTH_FADE_INTERVAL 5.0f

#define MIDDLE_SSGI_DEPTH_THREASHOLD 80.0f
#define MIDDLE_SSGI_FADE_INTERVAL 10.0f

	float CalcSSGIMiddleDepthWeightCore(float Depth)
	{
		float NearDepthDiff = Depth - (NEAR_SSGI_DEPTH_THREASHOLD - NEAR_SSGI_DEPTH_FADE_INTERVAL);
		float NearWeight = saturate(NearDepthDiff / NEAR_SSGI_DEPTH_FADE_INTERVAL);

		return NearWeight;
	}

	float CalcSSGIFarDepthWeightCore(float Depth)
	{
		float MiddleDepthDiff = Depth - (MIDDLE_SSGI_DEPTH_THREASHOLD - MIDDLE_SSGI_FADE_INTERVAL);
		float MiddleWeight = saturate(MiddleDepthDiff / MIDDLE_SSGI_FADE_INTERVAL);

		return MiddleWeight;
	}

	float CalcSSGIMiddleDepthWeight(float4 Depth)
	{
		float MinDepth = min(min(min(Depth.r, Depth.g), Depth.b), Depth.a);
		MinDepth = LinearEyeDepth(MinDepth, _ZBufferParams);// ConvertFromDeviceZ(MinDepth);
		float NearWeight0 = CalcSSGIMiddleDepthWeightCore(MinDepth);

		return NearWeight0;
	}

	float CalcSSGIFarDepthWeight(float4 Depth)
	{
		float MinDepth = min(min(min(Depth.r, Depth.g), Depth.b), Depth.a);
		MinDepth = LinearEyeDepth(MinDepth, _ZBufferParams);// ConvertFromDeviceZ(MinDepth);

		float NearWeight0 = CalcSSGIFarDepthWeightCore(MinDepth);

		return NearWeight0;
	}

	void frag_down_sample33(v2f input,
		out float4 RWOutColorTexture0 : SV_TARGET0
		, out float4 RWOutColorTexture1 : SV_TARGET1
		, out float4 RWOutColorTexture2 : SV_TARGET2
	) {
		RWOutColorTexture0 = 0;
		RWOutColorTexture1 = 0.2;
		RWOutColorTexture2 = 1;
	}

	void frag_pre_sample(v2f input,
		out float4 RWOutColorTexture0 : SV_TARGET0) 
	{
		float4 OutColor;

		float2 TexCenter = input.uv;
		TexCenter = ClampUVToViewSize(TexCenter);


		OutColor = Texture2DSample(_SSGIDownSampleInput0, sampler_LinearClamp, TexCenter);
		OutColor.rgb = ClampOutputColor(OutColor.rgb);
		RWOutColorTexture0 = OutColor;// pow(OutColor, 1.0);
	}

	//struct DepthSeparate
	//{
	//	float4 RWOutColorTexture0 : SV_Target0;
	//	float4 RWOutColorTexture1 : SV_Target1;
	//	float4 RWOutColorTexture2 : SV_Target2;
	//	float Depth : SV_Depth;
	//};


	void frag_depth_separate(v2f input
		,out float4 RWOutColorTexture0 : SV_TARGET0
		, out float4 RWOutColorTexture1 : SV_TARGET1
		, out float4 RWOutColorTexture2 : SV_TARGET2

	)
	{
		float2 TexCenter = input.uv;
		TexCenter = ClampUVToViewSize(TexCenter);

		float4 OutColor;
	
		DownSampleFilterColorPassFunc(_SSGIDownSampleInput0, sampler_LinearClamp, TexCenter, OutColor);
		OutColor.rgb = ClampOutputColor(OutColor.rgb);

		float2 HZB_UV = ScreenPosToHZBUV(TexCenter);
		float4 Depth = GATHER_RED_TEXTURE2D(_HZBTexture, sampler_HZBTexture, HZB_UV);// _HZBTexture.GatherRed(sampler_HZBTexture, HZB_UV);
		float MiddleWeight = CalcSSGIMiddleDepthWeight(Depth);
		float FarWeight = CalcSSGIFarDepthWeight(Depth);

		//RWOutColorTexture0 = OutColor * saturate(1.0 - MiddleWeight - FarWeight);

		//DepthSeparate o;
		//o.RWOutColorTexture0 = OutColor * saturate(1.0 - MiddleWeight - FarWeight);
		//o.RWOutColorTexture1 = OutColor * saturate(MiddleWeight - FarWeight);
		//o.RWOutColorTexture2 = OutColor * FarWeight;
		//o.Depth = Depth.x;
		//return o;
		//RWOutColorTexture0 = OutColor * saturate(1.0 - MiddleWeight - FarWeight);
		//RWOutColorTexture1 = OutColor * saturate(MiddleWeight - FarWeight);
		//RWOutColorTexture2 = OutColor * FarWeight;

#ifdef DOWN_SAMPLE_FULL_SEPARATE
		RWOutColorTexture0 = OutColor * saturate(1.0 - MiddleWeight - FarWeight);
		RWOutColorTexture1 = OutColor * saturate(MiddleWeight - FarWeight);
		RWOutColorTexture2 = OutColor * FarWeight;
#else //DOWN_SAMPLE_FULL_SEPARATE
		RWOutColorTexture0 = OutColor;
		RWOutColorTexture1 = OutColor * MiddleWeight;
		RWOutColorTexture2 = OutColor * FarWeight;
#endif // DOWN_SAMPLE_FULL_SEPARATE
	}


	void frag_down_sample(v2f input,
		out float4 RWOutColorTexture0 : SV_TARGET0
#if OUTPUT_COUNT >= 2
		, out float4 RWOutColorTexture1 : SV_TARGET1
#endif
#if OUTPUT_COUNT >= 3
		, out float4 RWOutColorTexture2 : SV_TARGET2
#endif
		, out float RWDepth : SV_DEPTH
	)
	{
		float2 TexCenter = input.uv;
		TexCenter = ClampUVToViewSize(TexCenter);

		float4 OutColor;

#if OUTPUT_COUNT >= 1
		DownSampleFilterColorPassFunc(_SSGIDownSampleInput0, sampler_LinearClamp, TexCenter, OutColor);
		OutColor.rgb = ClampOutputColor(OutColor.rgb);
		RWOutColorTexture0 = OutColor;
#endif

#if OUTPUT_COUNT >= 2
		float4 OutColor2;
		DownSampleFilterColorPassFunc(_SSGIDownSampleInput1, sampler_LinearClamp, TexCenter, OutColor2);
		OutColor2.rgb = ClampOutputColor(OutColor2.rgb);
		RWOutColorTexture1 = OutColor2;
#endif

#if OUTPUT_COUNT >= 3
		float4 OutColor3;
		DownSampleFilterColorPassFunc(_SSGIDownSampleInput2, sampler_LinearClamp, TexCenter, OutColor3);
		OutColor3.rgb = ClampOutputColor(OutColor3.rgb);
		RWOutColorTexture2 = OutColor3;
#endif
		RWDepth = 1;

	}


	//---------------------------------------------------------- SSGI OUTPUT
#ifdef SSGI_QUALITY_HEIGH
#define SSGI_QUALITY 2
#else
#define SSGI_QUALITY 1
#endif


	TEXTURE2D(_GIEnvTextureMap); SAMPLER(sampler_GIEnvTextureMap);
	TEXTURE2D(_GIEnvMiddleTextureMap); SAMPLER(sampler_GIEnvMiddleTextureMap);
	TEXTURE2D(_GIEnvFarTextureMap); SAMPLER(sampler_GIEnvFarTextureMap);

	TEXTURE2D(_SceneColorTexture); SAMPLER(sampler_SceneColorTexture);
	TEXTURE2D(_SceneDepthTexture); SAMPLER(sampler_SceneDepthTexture);

	uniform float SSGIIntensity;
	uniform float SSGIThreshold;

	uniform float3 MainLightDirection;

	uniform float4x4 TranslatedWorldToView;

	float3 GetGIEnvTextureCore(Texture2D EnvTex, float2 CenterTex, float3 ViewNormal)
	{
		const float UVOffset0 = 0.1f;
		float2 GIEnvTexUV = float2(UVOffset0, UVOffset0) * ViewNormal.xy + CenterTex;
		//GIEnvTexUV = min(GIEnvTexUV, 0.8f);
		float3 GIColor = 0.4f * Texture2DSampleLevel(EnvTex, sampler_LinearClamp, GIEnvTexUV, 0).rgb;

		const float UVOffset1 = 0.2f;
		GIEnvTexUV = float2(UVOffset1, UVOffset1) * ViewNormal.xy + CenterTex;
		//GIEnvTexUV = min(GIEnvTexUV, 0.8f);
		GIColor += 0.3f * Texture2DSampleLevel(EnvTex, sampler_LinearClamp, GIEnvTexUV, 0).rgb;

		const float UVOffset2 = 0.3f;
		GIEnvTexUV = float2(UVOffset2, UVOffset2) * ViewNormal.xy + CenterTex;
		//GIEnvTexUV = min(GIEnvTexUV, 0.8f);
		GIColor += 0.3f * Texture2DSampleLevel(EnvTex, sampler_LinearClamp, GIEnvTexUV, 0).rgb;
		return GIColor;
	}

	float3 GetGIEnvTexture(float2 CenterTex, float3 ViewNormal, float SceneDepth)
	{
#if SSGI_QUALITY == 1
		return GetGIEnvTextureCore(_GIEnvTextureMap, CenterTex, ViewNormal);
#else

		float NearSSGIColorOnlyThreashold = NEAR_SSGI_DEPTH_THREASHOLD - NEAR_SSGI_DEPTH_FADE_INTERVAL;
		float MiddleSSGIColorOnlyThreashold = MIDDLE_SSGI_DEPTH_THREASHOLD - MIDDLE_SSGI_FADE_INTERVAL;

		float3 GIColor = 0.0f;
		[branch]
		if (SceneDepth <= NearSSGIColorOnlyThreashold) {
			GIColor = GetGIEnvTextureCore(_GIEnvTextureMap, CenterTex, ViewNormal);
		}
		else if (SceneDepth <= NEAR_SSGI_DEPTH_THREASHOLD) {
			float3 GIColorNear = GetGIEnvTextureCore(_GIEnvTextureMap, CenterTex, ViewNormal);
			float3 GIColorMiddle = GetGIEnvTextureCore(_GIEnvMiddleTextureMap, CenterTex, ViewNormal);

			float MiddleWeight = (SceneDepth - NearSSGIColorOnlyThreashold) / NEAR_SSGI_DEPTH_FADE_INTERVAL;
			MiddleWeight = saturate(MiddleWeight);

			GIColor = lerp(GIColorNear, GIColorMiddle, MiddleWeight);
		}
		else if (SceneDepth <= MiddleSSGIColorOnlyThreashold) {
			GIColor = GetGIEnvTextureCore(_GIEnvMiddleTextureMap, CenterTex, ViewNormal);
		}
		else if (SceneDepth <= MIDDLE_SSGI_DEPTH_THREASHOLD) {
			float3 GIColorMiddle = GetGIEnvTextureCore(_GIEnvMiddleTextureMap, CenterTex, ViewNormal);
			float3 GIColorFar = GetGIEnvTextureCore(_GIEnvFarTextureMap, CenterTex, ViewNormal);

			float FarWeight = (SceneDepth - MiddleSSGIColorOnlyThreashold) / MIDDLE_SSGI_FADE_INTERVAL;
			FarWeight = saturate(FarWeight);

			GIColor = lerp(GIColorMiddle, GIColorFar, FarWeight);
		}
		else {
			GIColor = GetGIEnvTextureCore(_GIEnvFarTextureMap, CenterTex, ViewNormal);
		}

		return GIColor;
#endif
	}

	struct FGBufferData
	{
		float3 BaseColor;
		float3 WorldNormal;
		float Depth;
	};

	float3 CalcGIColor(FGBufferData GBufferTexture, float2 TexCenter, float3 MainLightDirection)
	{
		float3 CenterGIColor = 0.001f;
		float NdotL = dot(GBufferTexture.WorldNormal, -MainLightDirection);
		NdotL = saturate(NdotL * 0.5f + 0.5f);

#if !SSGI_BOUNDARY_FADE
		[branch]
		if (NdotL < SSGIThreshold)
#endif // SSGI_BOUNDARY_FADE
		{
#if SSGI_QUALITY == 1
			CenterGIColor = Texture2DSampleLevel(_GIEnvTextureMap, sampler_LinearClamp, TexCenter, 0);
#else
			float NearSSGIColorOnlyThreashold = NEAR_SSGI_DEPTH_THREASHOLD - NEAR_SSGI_DEPTH_FADE_INTERVAL;
			float MiddleSSGIColorOnlyThreashold = MIDDLE_SSGI_DEPTH_THREASHOLD - MIDDLE_SSGI_FADE_INTERVAL;

			float SceneDepth = GBufferTexture.Depth;

			[branch]
			if (SceneDepth <= NearSSGIColorOnlyThreashold)
			{
				CenterGIColor = Texture2DSampleLevel(_GIEnvTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;
			}
			else if (SceneDepth <= NEAR_SSGI_DEPTH_THREASHOLD)
			{
				float3 GIColorNear = Texture2DSampleLevel(_GIEnvTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;
				float3 GIColorMiddle = Texture2DSampleLevel(_GIEnvMiddleTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;

				float MiddleWeight = (SceneDepth - NearSSGIColorOnlyThreashold) / NEAR_SSGI_DEPTH_FADE_INTERVAL;
				MiddleWeight = saturate(MiddleWeight);

				CenterGIColor = lerp(GIColorNear, GIColorMiddle, MiddleWeight);
			}
			else if (SceneDepth <= MiddleSSGIColorOnlyThreashold)
			{
				CenterGIColor = Texture2DSampleLevel(_GIEnvMiddleTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;
			}
			else if (SceneDepth <= MIDDLE_SSGI_DEPTH_THREASHOLD)
			{
				float3 GIColorMiddle = Texture2DSampleLevel(_GIEnvMiddleTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;
				float3 GIColorFar = Texture2DSampleLevel(_GIEnvFarTextureMap, sampler_LinearClamp, TexCenter, 0).rgb;

				float FarWeight = (SceneDepth - MiddleSSGIColorOnlyThreashold) / MIDDLE_SSGI_FADE_INTERVAL;
				FarWeight = saturate(FarWeight);

				CenterGIColor = lerp(GIColorMiddle, GIColorFar, FarWeight);
			}
			else {
				CenterGIColor = Texture2DSampleLevel(_GIEnvFarTextureMap, sampler_LinearClamp, TexCenter, 0).rgb.rgb;
			}
#endif
#if !SSGI_BOUNDARY_FADE
			return CenterGIColor;
#endif // !SSGI_BOUNDARY_FADE
		}


		float3 ViewNormal = mul((float3x3)TranslatedWorldToView, GBufferTexture.WorldNormal.xyz);

		float GIDepthFade = saturate((GBufferTexture.Depth - 50.0f) / 50.0f);
		ViewNormal.xy = lerp(1.0f, 0.1f, GIDepthFade) * ViewNormal.xy;
		float3 GIColor = GetGIEnvTexture(TexCenter, ViewNormal, GBufferTexture.Depth);

#if SSGI_BOUNDARY_FADE
		GIColor = lerp(CenterGIColor, GIColor, min(NdotL / SSGIThreshold, 1.0f));
#endif // SSGI_BOUNDARY_FADE

		return GIColor;
	}

	float4 frag_down_composition(v2f input) : SV_TARGET 
	{
		FGBufferData GBuffer = (FGBufferData)0;
		GBuffer.BaseColor = 0.0; //Texture2DSample(_SceneColorTexture, sampler_SceneColorTexture, input.uv).rgb;
		GBuffer.Depth = SAMPLE_TEXTURE2D(_SceneDepthTexture, sampler_SceneDepthTexture, input.uv).r;
		GBuffer.Depth = LinearEyeDepth(GBuffer.Depth, _ZBufferParams);
		GBuffer.WorldNormal = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_PointClamp, input.uv).rgb;

		float3 GIColor = CalcGIColor(GBuffer, input.uv, half3(_MainLightPosition.xyz));
		//GIColor = GIColor * min(GBuffer.GBufferAO, AmbientOcclusion);

	/*	OutColor = Texture2DSample(_SceneColorTexture, sampler_SceneColorTexture, input.uv) * saturate(dot(GBuffer.WorldNormal, -MainLightDirection) * 0.5 + 0.5);
		OutColor.rgb += GBuffer.BaseColor.rgb * SSGIIntensity * GIColor;*/

		//float3 ViewNormal = mul((float3x3)TranslatedWorldToView, GBuffer.WorldNormal.xyz);
		float4 finalColor = float4(SSGIIntensity * pow( GIColor , 2.2), 1);
		return finalColor;

	}
	ENDHLSL

		SubShader
	{
		ZTest Always ZWrite Off Cull Off


		Pass
		{
			Name "SSGI Presample" // 0

			HLSLPROGRAM

			#pragma vertex   vert
			#pragma fragment frag_pre_sample

			#pragma target 3.5

			ENDHLSL
		}

		Pass
		{
			Name "SSGI Depth Separate" // 1

			HLSLPROGRAM

			#pragma vertex   vert
			#pragma fragment frag_depth_separate

			#pragma target 5.0
			#pragma multi_compile _ DOWN_SAMPLE_FULL_SEPARATE

			ENDHLSL
		}

		
		Pass
		{
			Name "SSGI Downsample"

			HLSLPROGRAM

			#pragma vertex   vert
			#pragma fragment frag_down_sample

			#pragma target 3.5

			#pragma multi_compile _ OUTPUT_COUNT_2 OUTPUT_COUNT_3
			#pragma multi_compile _ DOWN_SAMPLE_METHOD_1 DOWN_SAMPLE_METHOD_2
			//#pragma multi_compile _ DOWN_SAMPLE_FULL_SEPARATE

			ENDHLSL
		}

		Pass
		{
			Name "SSGI Ouput"

			HLSLPROGRAM

			#pragma vertex   vert
			#pragma fragment frag_down_composition

			#pragma multi_compile _ SSGI_QUALITY_HEIGH
			#pragma multi_compile _ SSGI_BOUNDARY_FADE

			ENDHLSL
		}
	}
}
