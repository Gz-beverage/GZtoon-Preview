#ifndef GZ_PREVIEW_INPUT_INCLUDED
#define GZ_PREVIEW_INPUT_INCLUDED
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseTex_ST, _BaseColor, _Normal_ST;
float4 _RoughnessMask, _metallicMack, _AoMask;
float _NormalScale, _Smoothness2, _metallic, _AoStrength;
float _GZAlphaClip, _GZAlphaCutoff;
float _NOLRemapStart, _NOLRampEnd, _GZDiffuseRampEnabled, _GZDiffuseRampRow;
float4 _PBRShadowColor, _RampLightingTex_TexelSize;
float _GZDiffuseRampRowMapEnabled, _AoTexReversal2, _RampLightingUvYRemapStart, _RampLightingUvYRemapEnd;
float4 _AoMask2, _ShadingGradeMapChannelMask1;
float _ShadingGradeMapInvertColor1, _GZDiffuseRampDitherEnabled, _GZDiffuseRampDitherStrength;
float _GZShadingGradeMapEnabled, _ShadingGradeMapInvertColor;
float4 _ShadingGradeMap_ST, _ShadingGradeMapChannelMask;
float _ShadingGradeMapRemapStart, _ShadingGradeMapRemapEnd;
float _ShadingGradeMapStrength, _ShadingGradeMapApplyRange, _ShadingGradeMapMidPointOffset;
float _GZCCRampEnabled, _GZCCRampExposure, _GZCCRampHue, _GZCCRampSaturation;
float _GZCCRampContrast, _GZCCRampGamma;
float4 _GZCCRampTint;
float _Indirectdiffusereflectionintensity, _Indirectlightspecularintensity, _specTermIntensity;
float4 _Color3, _EmissionColor;
float4 _AoMask4, _Vector4, _FaceFrontDirWS, _FaceRightDirWS, _FaceUpDirWS;
float _ShadowOffset, _ShadowOffset1, _GZFaceSDFMirrorUV;
float4 _SpecMaskRGBA, _HairHighlightUVST, _HairHighlightColor;
float _GZHairUVHighlightEnabled, _GZHairUVControlEnabled, _InvertSpecMask;
float _AnisotropicSize, _AnisotropicOffset, _AnisotropicRange1;
float _GZOutlinePassEnabled, _Thickness1;
float4 _Color1189;
CBUFFER_END

TEXTURE2D(_BaseTex); SAMPLER(sampler_BaseTex);
TEXTURE2D(_Normal); SAMPLER(sampler_Normal);
TEXTURE2D(_RoughnessTex); SAMPLER(sampler_RoughnessTex);
TEXTURE2D(_RoughnessTex1); SAMPLER(sampler_RoughnessTex1);
TEXTURE2D(_RoughnessTex2); SAMPLER(sampler_RoughnessTex2);
TEXTURE2D(_RampLightingTex);
TEXTURE2D(_TextureSample4); SAMPLER(sampler_TextureSample4);
TEXTURE2D(_ShadingGradeMap1); SAMPLER(sampler_ShadingGradeMap1);
TEXTURE2D(_ShadingGradeMap); SAMPLER(sampler_ShadingGradeMap);
TEXTURE2D(_faceSDF);
TEXTURE2D(_SpecMask); SAMPLER(sampler_SpecMask);
TEXTURE2D(_SpecMask_STUV);

float4 PreviewBase(float2 uv)
{
    return SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, uv) * _BaseColor;
}

void PreviewClip(float alpha)
{
    if (_GZAlphaClip > 0.5) clip(alpha - _GZAlphaCutoff);
}

float PreviewChannel(float4 value, float4 channel)
{
    return saturate(dot(value, channel));
}

float PreviewRemap(float value, float start, float end)
{
    // Equal endpoints explicitly select a hard threshold.
    return start == end ? step(start, value) : saturate((value - start) / (end - start));
}

float3 PreviewRampColorCorrection(float3 color)
{
    if (_GZCCRampEnabled < 0.5) return color;
    color *= exp2(_GZCCRampExposure);
    float3 hsv = RgbToHsv(max(color, 0.0));
    hsv.x = frac(hsv.x + _GZCCRampHue / 360.0);
    color = HsvToRgb(hsv);
    float luminance = dot(color, float3(0.2126, 0.7152, 0.0722));
    color = lerp(luminance.xxx, color, _GZCCRampSaturation);
    color = (color - 0.18) * _GZCCRampContrast + 0.18;
    color = pow(max(color, 0.0), rcp(max(_GZCCRampGamma, 0.01)));
    return color * _GZCCRampTint.rgb;
}

float PreviewFaceCoordinate(float2 uv, float3 lightDirection)
{
    float3 front = SafeNormalize(_FaceFrontDirWS.xyz);
    float3 right = SafeNormalize(_FaceRightDirWS.xyz);
    float3 up = SafeNormalize(_FaceUpDirWS.xyz);
    float3 projected = lightDirection - up * dot(lightDirection, up);
    float planeLength = dot(projected, projected);
    projected *= rsqrt(max(planeLength, 1e-8));
    bool mirror = dot(projected, right) < 0.0;
    if (_GZFaceSDFMirrorUV > 0.5) mirror = !mirror;
    uv += _Vector4.xy;
    uv.x = mirror ? 1.0 - uv.x : uv.x;
    float value = PreviewChannel(SAMPLE_TEXTURE2D_LOD(_faceSDF, sampler_LinearClamp, uv, 0), _AoMask4);
    float threshold = saturate(0.5 - 0.5 * dot(projected, front) + _ShadowOffset);
    float result = _ShadowOffset1 <= 0.0 ? step(threshold, value) :
        smoothstep(threshold - _ShadowOffset1, threshold + _ShadowOffset1, value);
    float confidence = smoothstep(0.00030458649, 0.00121797487, planeLength);
    return lerp(saturate(0.5 + 0.5 * dot(lightDirection, up)), result, confidence);
}
#endif
