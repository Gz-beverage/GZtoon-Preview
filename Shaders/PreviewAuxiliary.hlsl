#ifndef GZ_PREVIEW_AUXILIARY_INCLUDED
#define GZ_PREVIEW_AUXILIARY_INCLUDED
#include "PreviewInput.hlsl"

float3 _LightDirection, _LightPosition;
struct AuxAttributes
{
    float4 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};
struct AuxVaryings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normalWS : TEXCOORD1;
    float4 tangentWS : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};
AuxVaryings PreviewAuxVertex(AuxAttributes input)
{
    AuxVaryings output = (AuxVaryings)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
    VertexNormalInputs normal = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    output.normalWS = normal.normalWS;
    output.tangentWS = float4(normal.tangentWS, input.tangentOS.w * GetOddNegativeScale());
    output.uv = input.uv;
#if defined(GZ_PREVIEW_SHADOW)
    float3 lightDirection = _LightDirection;
#if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
    lightDirection = SafeNormalize(_LightPosition - positionWS);
#endif
    output.positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normal.normalWS, lightDirection));
#if UNITY_REVERSED_Z
    output.positionCS.z = min(output.positionCS.z, UNITY_NEAR_CLIP_VALUE * output.positionCS.w);
#else
    output.positionCS.z = max(output.positionCS.z, UNITY_NEAR_CLIP_VALUE * output.positionCS.w);
#endif
#else
#if defined(GZ_PREVIEW_OUTLINE)
    positionWS += normal.normalWS * _Thickness1;
#endif
    output.positionCS = TransformWorldToHClip(positionWS);
#endif
    return output;
}
half4 PreviewAuxFragment(AuxVaryings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    PreviewClip(PreviewBase(input.uv * _BaseTex_ST.xy + _BaseTex_ST.zw).a);
#if defined(GZ_PREVIEW_OUTLINE)
    clip(_GZOutlinePassEnabled - 0.5);
    return _Color1189;
#elif defined(GZ_PREVIEW_NORMALS)
    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_Normal, sampler_Normal,
        input.uv * _Normal_ST.xy + _Normal_ST.zw), _NormalScale);
    float3 bitangent = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w;
    float3 normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(normalTS,
        float3x3(input.tangentWS.xyz, bitangent, input.normalWS)));
#if defined(_GBUFFER_NORMALS_OCT)
    float2 oct = PackNormalOctQuadEncode(normalWS);
    return half4(PackFloat2To888(saturate(oct * 0.5 + 0.5)), 0);
#else
    return half4(normalWS, 0);
#endif
#else
    return 0;
#endif
}
#endif
