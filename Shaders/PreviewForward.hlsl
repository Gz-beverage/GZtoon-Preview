#ifndef GZ_PREVIEW_FORWARD_INCLUDED
#define GZ_PREVIEW_FORWARD_INCLUDED
#include "PreviewInput.hlsl"

struct Attributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS : SV_POSITION;
    float3 positionWS : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float4 tangentWS : TEXCOORD2;
    float2 uv : TEXCOORD3;
    float fog : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

Varyings PreviewVertex(Attributes input)
{
    Varyings output = (Varyings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    VertexPositionInputs position = GetVertexPositionInputs(input.positionOS.xyz);
    VertexNormalInputs normal = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.positionCS = position.positionCS;
    output.positionWS = position.positionWS;
    output.normalWS = normal.normalWS;
    output.tangentWS = float4(normal.tangentWS, input.tangentOS.w * GetOddNegativeScale());
    output.uv = input.uv;
    output.fog = ComputeFogFactor(position.positionCS.z);
    return output;
}

struct PreviewSurface
{
    BRDFData brdf;
    float3 normalWS, viewWS;
    float2 uv;
    float ao, rampY, rampMask, grade, noiseOffset, hairHighlight;
};

PreviewSurface PreviewBuildSurface(Varyings input, float3 albedo)
{
    PreviewSurface surface = (PreviewSurface)0;
    float2 uv = input.uv * _BaseTex_ST.xy + _BaseTex_ST.zw;
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal,
        input.uv * _Normal_ST.xy + _Normal_ST.zw), _NormalScale);
    float3 normal = SafeNormalize(input.normalWS);
    float3 tangent = SafeNormalize(input.tangentWS.xyz);
    float3 bitangent = cross(normal, tangent) * input.tangentWS.w;
    surface.normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(normalTS, float3x3(tangent, bitangent, normal)));
    surface.viewWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
    surface.uv = input.uv;
    float roughness = saturate(PreviewChannel(SAMPLE_TEXTURE2D(_RoughnessTex, sampler_RoughnessTex, uv), _RoughnessMask) * _Smoothness2);
    float metallic = saturate(PreviewChannel(SAMPLE_TEXTURE2D(_RoughnessTex1, sampler_RoughnessTex1, uv), _metallicMack) * _metallic);
    surface.ao = lerp(1.0, PreviewChannel(SAMPLE_TEXTURE2D(_RoughnessTex2, sampler_RoughnessTex2, uv), _AoMask), saturate(_AoStrength));
    half alpha = 1;
    InitializeBRDFData(albedo, metallic, half3(0, 0, 0), 1.0 - roughness, alpha, surface.brdf);
    surface.rampY = _GZDiffuseRampRow;
    surface.rampMask = 0;
    if (_GZDiffuseRampEnabled > 0.5)
    {
        surface.rampMask = PreviewChannel(SAMPLE_TEXTURE2D(_ShadingGradeMap1, sampler_ShadingGradeMap1, input.uv), _ShadingGradeMapChannelMask1);
        surface.rampMask = lerp(surface.rampMask, 1.0 - surface.rampMask, saturate(_ShadingGradeMapInvertColor1));
        if (_GZDiffuseRampRowMapEnabled > 0.5)
        {
            float value = PreviewChannel(SAMPLE_TEXTURE2D(_TextureSample4, sampler_TextureSample4, input.uv), _AoMask2);
            value = lerp(value, 1.0 - value, saturate(_AoTexReversal2));
            surface.rampY = lerp(_RampLightingUvYRemapStart, _RampLightingUvYRemapEnd, value);
        }
        if (_GZDiffuseRampDitherEnabled > 0.5 && _GZDiffuseRampDitherStrength > 0)
            surface.noiseOffset = (InterleavedGradientNoise(floor(input.positionCS.xy), 0) - 0.5)
                * _GZDiffuseRampDitherStrength * _RampLightingTex_TexelSize.x;
    }
    if (_GZShadingGradeMapEnabled > 0.5)
    {
        float value = PreviewChannel(SAMPLE_TEXTURE2D(_ShadingGradeMap, sampler_ShadingGradeMap,
            input.uv * _ShadingGradeMap_ST.xy + _ShadingGradeMap_ST.zw), _ShadingGradeMapChannelMask);
        value = lerp(value, 1.0 - value, saturate(_ShadingGradeMapInvertColor));
        value = PreviewRemap(value, _ShadingGradeMapRemapStart, _ShadingGradeMapRemapEnd);
        surface.grade = (lerp(0.5, value, _ShadingGradeMapStrength) - 0.5)
            * _ShadingGradeMapApplyRange + _ShadingGradeMapMidPointOffset;
    }
#if defined(GZ_PREVIEW_HAIR)
    if (_GZHairUVHighlightEnabled > 0.5)
    {
        float2 highlightUV = input.uv + float2(0, -dot(surface.viewWS, SafeNormalize(_FaceUpDirWS.xyz)) * _AnisotropicSize + _AnisotropicOffset);
        highlightUV = highlightUV * _HairHighlightUVST.xy + _HairHighlightUVST.zw;
        if (_GZHairUVControlEnabled > 0.5)
        {
            float4 control = SAMPLE_TEXTURE2D_LOD(_SpecMask_STUV, sampler_LinearClamp, input.uv, 0);
            highlightUV = highlightUV * control.rg + control.ba;
        }
        float mask = PreviewChannel(SAMPLE_TEXTURE2D(_SpecMask, sampler_SpecMask, highlightUV), _SpecMaskRGBA);
        surface.hairHighlight = lerp(mask, 1.0 - mask, saturate(_InvertSpecMask));
    }
#endif
    return surface;
}

float3 PreviewEvaluateLight(PreviewSurface surface, Light light)
{
    float3 direction = SafeNormalize(light.direction);
    float noL = saturate(dot(surface.normalWS, direction));
    float coordinate = PreviewRemap(saturate((dot(surface.normalWS, direction) + surface.grade) * 0.5 + 0.5),
        _NOLRemapStart, _NOLRampEnd);
#if defined(GZ_PREVIEW_FACE)
    coordinate = PreviewFaceCoordinate(surface.uv, direction);
#endif
    coordinate = min(surface.ao, saturate(coordinate * light.shadowAttenuation));
    float3 diffuseColor = lerp(_PBRShadowColor.rgb, 1.0, coordinate);
    if (_GZDiffuseRampEnabled > 0.5)
    {
        float rampX = coordinate > 0 && coordinate < 1 ? saturate(coordinate + surface.noiseOffset) : coordinate;
        float3 ramp = SAMPLE_TEXTURE2D_LOD(_RampLightingTex, sampler_LinearClamp, float2(rampX, surface.rampY), 0).rgb;
        diffuseColor = lerp(diffuseColor, PreviewRampColorCorrection(ramp), surface.rampMask);
    }
    float3 diffuse = surface.brdf.diffuse * diffuseColor;
    float3 specular = surface.brdf.specular * DirectBRDFSpecular(surface.brdf, surface.normalWS, direction, surface.viewWS)
        * noL * light.shadowAttenuation * _specTermIntensity * _Color3.rgb;
#if defined(GZ_PREVIEW_HAIR)
    specular += surface.hairHighlight * _HairHighlightColor.rgb * _AnisotropicRange1 * noL * light.shadowAttenuation;
#endif
    return (diffuse + specular) * light.color * light.distanceAttenuation;
}

half4 PreviewFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    float4 base = PreviewBase(input.uv * _BaseTex_ST.xy + _BaseTex_ST.zw);
    PreviewClip(base.a);
    PreviewSurface surface = PreviewBuildSurface(input, base.rgb);
    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
#if defined(_MAIN_LIGHT_SHADOWS_SCREEN)
    shadowCoord = float4(GetNormalizedScreenSpaceUV(input.positionCS), 0, 1);
#endif
    float3 color = PreviewEvaluateLight(surface, GetMainLight(shadowCoord, input.positionWS, half4(1, 1, 1, 1)));
    InputData inputData = (InputData)0;
    inputData.positionWS = input.positionWS;
    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
#if defined(_ADDITIONAL_LIGHTS) || defined(_ADDITIONAL_LIGHTS_VERTEX)
#if USE_CLUSTER_LIGHT_LOOP
    UNITY_LOOP for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); ++lightIndex)
    {
        CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
        color += PreviewEvaluateLight(surface, GetAdditionalLight(lightIndex, input.positionWS, half4(1, 1, 1, 1)));
    }
#endif
    uint lightCount = GetAdditionalLightsCount();
    LIGHT_LOOP_BEGIN(lightCount)
        color += PreviewEvaluateLight(surface, GetAdditionalLight(lightIndex, input.positionWS, half4(1, 1, 1, 1)));
    LIGHT_LOOP_END
#endif
    float3 indirectDiffuse = SampleSH(surface.normalWS) * surface.ao * _Indirectdiffusereflectionintensity;
    float3 indirectSpecular = GlossyEnvironmentReflection(reflect(-surface.viewWS, surface.normalWS), input.positionWS,
        surface.brdf.perceptualRoughness, surface.ao, inputData.normalizedScreenSpaceUV) * _Indirectlightspecularintensity;
    color += EnvironmentBRDF(surface.brdf, indirectDiffuse, indirectSpecular,
        Pow4(1.0 - saturate(dot(surface.normalWS, surface.viewWS))));
    color += _EmissionColor.rgb;
    return half4(MixFog(color, input.fog), 1);
}
#endif
