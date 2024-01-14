#ifndef CUSTOM_AUTOSHADOWCOLOR_INCLUDED
#define CUSTOM_AUTOSHADOWCOLOR_INCLUDED

real3 applyLut2D_up(TEXTURE2D_PARAM(tex, samplerTex), float3 uvw, float3 scaleOffset)
{
    // Strip format where `height = sqrt(width)`
    uvw.z *= scaleOffset.z;
    float shift = floor(uvw.z);
    uvw.xy = uvw.xy * scaleOffset.z * scaleOffset.xy + scaleOffset.xy * 0.5;
    uvw.x += shift * scaleOffset.y;
    uvw.y = clamp(uvw.y, 0, 1) * 0.5 + 0.5;
    uvw.xyz = lerp(
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy, 0.0).rgb,
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy + float2(scaleOffset.y, 0.0), 0.0).rgb,
        uvw.z - shift
    );
    return uvw;
}

real3 applyLut2D_down(TEXTURE2D_PARAM(tex, samplerTex), float3 uvw, float3 scaleOffset)
{
    // Strip format where `height = sqrt(width)`
    uvw.z *= scaleOffset.z;
    float shift = floor(uvw.z);
    uvw.xy = uvw.xy * scaleOffset.z * scaleOffset.xy + scaleOffset.xy * 0.5;
    uvw.x += shift * scaleOffset.y;
    uvw.y = clamp(uvw.y, 0, 1) * 0.5;
    uvw.xyz = lerp(
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy, 0.0).rgb,
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy + float2(scaleOffset.y, 0.0), 0.0).rgb,
        uvw.z - shift
    );
    return uvw;
}


float3 ShadowColorShift_HSV(
    float3 HSVColor,
    float _HueShifts[21],
    float _SatShifts[8],
    float _ValShifts[8],
    float3 BaseColor
)
{
    //ɫ��
    {
        const float HueKeys[21] =
        {
            0.0f, 17.0f, 27.0f, 37.0f, 48.5f,
                60.0f, 86.5f, 113.0f, 139.0f, 165.0f,
                173.0f, 181.0f, 191.5f, 202.0f, 230.5f,
                259.0f, 284.5f, 310.0f, 325.5f, 341.0f,
                360.0f
        };

        float Hue = HSVColor.x * 360.0f;

        int KeyMax = 0;
        for (int i = 1; i < 21; i++)
        {
            if (Hue <= HueKeys[i])
            {
                KeyMax = i;
                break;
            }
        }
        int KeyMin = KeyMax - 1;
        float Weight = (Hue - HueKeys[KeyMin]) / (HueKeys[KeyMax] - HueKeys[KeyMin]);

        float MinHue = _HueShifts[KeyMin];
        float MaxHue = _HueShifts[KeyMax];

        Hue += lerp(MinHue, MaxHue, Weight);
        HSVColor.x = RotateHue(Hue / 360.0f, 0.0, 1.0);
    }

    //���Ͷȡ�����
    {
        float Saturation = HSVColor.y;
        float Value = HSVColor.z;
        float Lum = Luminance(BaseColor);

        int KeyMin = min(max((Lum - 0.2f) / 0.1f, 0.0f), 6.0f);
        int KeyMax = KeyMin + 1;
        float Weight = saturate((Lum - (0.2f + 0.1f * KeyMin)) / 0.1f);

        float MinSaturation = _SatShifts[KeyMin];
        float MaxSaturation = _SatShifts[KeyMax];
        float MinValue = _ValShifts[KeyMin];
        float MaxValue = _ValShifts[KeyMax];

        float AddS = lerp(MinSaturation, MaxSaturation, Weight);
        float AddV = lerp(MinValue, MaxValue, Weight);

        HSVColor.y = clamp(HSVColor.y + AddS * 0.01, 0.0, 1.0);

        HSVColor.z = clamp(HSVColor.z + AddV * 0.01, 0.0, 1.0);
    }
    return HSVColor;
}

Texture2D _OutfitAndSkinLut;
float4 LUTScaleOffset;
SamplerState sampler_linear_clamp;

//********Outfit********//
float _HueShifts_Outfit[21];
float _SatShifts_Outfit[8];
float _ValShifts_Outfit[8];
//Texture2D _OutfitLUT;

float3 ShadowColorShift_RGB_Outfit(float3 RGBColor)
{
#ifdef _AUTOSHADOW_USE_DEBUG
    float3 HSVColor = RgbToHsv(RGBColor);
    float3 ShadowHSVColor = ShadowColorShift_HSV(
        HSVColor,
        _HueShifts_Outfit,
        _SatShifts_Outfit,
        _ValShifts_Outfit, RGBColor);
    float3 ShadowRGBColor = HsvToRgb(ShadowHSVColor);

    return ShadowRGBColor;
#else
    float3 color = applyLut2D_up(
        TEXTURE2D_ARGS(_OutfitAndSkinLut, sampler_linear_clamp),
        RGBColor,
        LUTScaleOffset.xyz
    );
    return color;
#endif
}


//********Skin********//
float _HueShifts_Skin[21];
float _SatShifts_Skin[8];
float _ValShifts_Skin[8];
//Texture2D _SkinLUT;
float3 ShadowColorShift_RGB_Skin(float3 RGBColor)
{
#ifdef _AUTOSHADOW_USE_DEBUG
    float3 HSVColor = RgbToHsv(RGBColor);
    float3 ShadowHSVColor = ShadowColorShift_HSV(
        HSVColor,
        _HueShifts_Skin,
        _SatShifts_Skin,
        _ValShifts_Skin, RGBColor);
    float3 ShadowRGBColor = HsvToRgb(ShadowHSVColor);

    return ShadowRGBColor;
#else
    float3 color = applyLut2D_down(
        TEXTURE2D_ARGS(_OutfitAndSkinLut, sampler_linear_clamp),
        RGBColor,
        LUTScaleOffset.xyz
    );
    return color;
#endif
}

//********Hair********//
float _HueShifts_Hair[21];
float _SatShifts_Hair[8];
float _ValShifts_Hair[8];
Texture2D _HairLUT;
float3 ShadowColorShift_RGB_Hair(float3 RGBColor)
{
#ifdef _AUTOSHADOW_USE_DEBUG
    float3 HSVColor = RgbToHsv(RGBColor);
    float3 ShadowHSVColor = ShadowColorShift_HSV(
        HSVColor,
        _HueShifts_Hair,
        _SatShifts_Hair,
        _ValShifts_Hair, RGBColor);
    float3 ShadowRGBColor = HsvToRgb(ShadowHSVColor);
    return ShadowRGBColor;
#else
    float3 color = ApplyLut2D(
        TEXTURE2D_ARGS(_HairLUT, sampler_linear_clamp),
        RGBColor,
        LUTScaleOffset.xyz
    );
    return color;
#endif
}

//********Monster********//
float _HueShifts_Monster[21];
float _SatShifts_Monster[8];
float _ValShifts_Monster[8];
Texture2D _MonsterLUT;
float3 ShadowColorShift_RGB_Monster(float3 RGBColor)
{
#ifdef _AUTOSHADOW_USE_DEBUG
    float3 HSVColor = RgbToHsv(RGBColor);
    float3 ShadowHSVColor = ShadowColorShift_HSV(
        HSVColor,
        _HueShifts_Monster,
        _SatShifts_Monster,
        _ValShifts_Monster, RGBColor);
    float3 ShadowRGBColor = HsvToRgb(ShadowHSVColor);
    return ShadowRGBColor;
#else
    float3 color = ApplyLut2D(
        TEXTURE2D_ARGS(_MonsterLUT, sampler_linear_clamp),
        RGBColor,
        LUTScaleOffset.xyz
    );
    return color;
#endif
}



float _HueShifts_Baker[21];
float _SatShifts_Baker[8];
float _ValShifts_Baker[8];
float3 ShadowColorShift_RGB_BakeLut(float3 RGBColor)
{
    float3 HSVColor = RgbToHsv(RGBColor);
    float3 ShadowHSVColor = ShadowColorShift_HSV(
        HSVColor,
        _HueShifts_Baker,
        _SatShifts_Baker,
        _ValShifts_Baker, RGBColor);
    float3 ShadowRGBColor = HsvToRgb(ShadowHSVColor);
    return ShadowRGBColor;
}

#endif