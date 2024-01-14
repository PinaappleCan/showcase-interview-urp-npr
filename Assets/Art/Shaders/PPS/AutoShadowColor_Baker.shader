Shader "BP/PPS_AutoShadowColor"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }
        SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // Include the AutoShadowColorCalculation
            #include "./AutoShadowColor.HLSL"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            float4 _LUTParams;

            half4 frag(v2f i) : SV_Target
            {
                half3 col = half3(i.uv.xy,0);
                col = GetLutStripValue(i.uv, _LUTParams);
                col = ShadowColorShift_RGB_BakeLut(col);

                return half4(col,1.0);
            }
            ENDHLSL
        }
    }
}
