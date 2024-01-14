#ifndef CHARACTER_METHOD_INCLUDE
    #define CHARACTER_METHOD_INCLUDE

float SampleDepthCmp(float CenterDepth, float2 ScreenUV)
{
    float Depth = SampleSceneDepth(ScreenUV);

    if (Depth > CenterDepth)
    {
        return CenterDepth;
    }
    return Depth;
}

    //±ﬂ‘µπ‚º∆À„
float Character_Rim(float2 screenUV, float rimWidth, float rimLightThreshold)
{
    float2 uv = screenUV;

    float Center = SampleSceneDepth(uv);
    float dis = LinearEyeDepth(Center, _ZBufferParams);

    float DistanceAlpha = (1.0 - min(dis / 80, 1.0));

    float MaterialRimLightWidth = rimWidth;

    float Width   = 1.0f * MaterialRimLightWidth * DistanceAlpha;
    //float Width   = RimLightWidth * MaterialRimLightWidth * DistanceAlpha;
            
    float2 ans = float2(1 / _ScreenParams.x, 1  /  _ScreenParams.y);
    float2 Offset = ans * Width;

    float2 MaxUV    = float2(1, 1);		
    float UpLeft	= SampleDepthCmp(Center, uv+ float2(Offset.x,	Offset.y));
    float Up		= SampleDepthCmp(Center, uv + float2(0,			Offset.y));
    float UpRight	= SampleDepthCmp(Center, min(uv + float2(-Offset.x,		Offset.y), MaxUV));

    float dX = UpLeft - UpRight;
    float dY = UpLeft - Center + (Up - Center) * 2.0 + UpRight - Center;

    float Sobel = sqrt((dX*dX + dY*dY) * 5.0f);
            
    Sobel = step(rimLightThreshold * Center, Sobel);

    return Sobel * DistanceAlpha;
}




half3 PackNormal(half3 n)
{
    float2 octNormalWS = PackNormalOctQuadEncode(n); // values between [-1, +1], must use fp32 on some platforms.
    float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5); // values between [ 0, +1]
    return PackFloat2To888(remappedOctNormalWS); // values between [ 0, +1]
}



#endif