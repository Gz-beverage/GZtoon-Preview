Shader "GZtoon/Preview/Base"
{
    Properties
    {
        _BaseTex("底色贴图 / Base Texture", 2D) = "white" {}
        _BaseColor("底色 / Base Color", Color) = (1,1,1,1)
        [Normal] _Normal("法线 / Normal", 2D) = "bump" {}
        _NormalScale("法线强度 / Normal Strength", Range(0,2)) = 1
        [ToggleUI] _GZAlphaClip("Alpha 裁剪 / Alpha Clip", Float) = 0
        _GZAlphaCutoff("裁剪阈值 / Cutoff", Range(0,1)) = 0.5
        _RoughnessTex("粗糙度贴图 / Roughness", 2D) = "white" {}
        _RoughnessMask("粗糙度通道 / RGBA Channel", Vector) = (1,0,0,0)
        _Smoothness2("粗糙度缩放 / Roughness Scale", Range(0,1)) = 0.5
        _RoughnessTex1("金属度贴图 / Metallic", 2D) = "white" {}
        _metallicMack("金属度通道 / RGBA Channel", Vector) = (1,0,0,0)
        _metallic("金属度缩放 / Metallic Scale", Range(0,1)) = 0
        _RoughnessTex2("AO 贴图 / Occlusion", 2D) = "white" {}
        _AoMask("AO 通道 / RGBA Channel", Vector) = (1,0,0,0)
        _AoStrength("AO 强度 / Occlusion Strength", Range(0,1)) = 1
        _specTermIntensity("GGX 高光强度 / Specular Strength", Range(0,2)) = 1
        [HDR] _Color3("GGX 高光颜色 / Specular Tint", Color) = (1,1,1,1)
        _NOLRemapStart("漫反射起点 / Diffuse Start", Range(0,1)) = 0.5
        _NOLRampEnd("漫反射终点 / Diffuse End", Range(0,1)) = 1
        [HDR] _PBRShadowColor("非 Ramp 阴影颜色 / Non-Ramp Shadow", Color) = (0.12,0.12,0.14,1)
        [ToggleUI] _GZDiffuseRampEnabled("使用颜色 Ramp / Enable Color Ramp", Float) = 1
        _RampLightingTex("漫反射 Ramp / Diffuse Ramp", 2D) = "white" {}
        _GZDiffuseRampRow("固定 Y / Fixed Y", Range(0,1)) = 0.5
        [ToggleUI] _GZDiffuseRampRowMapEnabled("使用 Y 贴图 / Enable Y Map", Float) = 0
        _TextureSample4("Y 贴图 / Y Map", 2D) = "white" {}
        _AoMask2("Y 通道 / RGBA Channel", Vector) = (0,0,1,0)
        [ToggleUI] _AoTexReversal2("反转 Y / Invert Y", Float) = 0
        _RampLightingUvYRemapStart("Y 起点 / Y Start", Range(0,1)) = 0
        _RampLightingUvYRemapEnd("Y 终点 / Y End", Range(0,1)) = 1
        _ShadingGradeMap1("Ramp 遮罩 / Ramp Mask", 2D) = "white" {}
        _ShadingGradeMapChannelMask1("遮罩通道 / RGBA Channel", Vector) = (1,0,0,0)
        [ToggleUI] _ShadingGradeMapInvertColor1("反转遮罩 / Invert Mask", Float) = 0
        [ToggleUI] _GZShadingGradeMapEnabled("使用明暗分级图 / Enable Grade Map", Float) = 0
        _ShadingGradeMap("明暗分级图 / Grade Map", 2D) = "gray" {}
        _ShadingGradeMapChannelMask("分级图通道 / RGBA Channel", Vector) = (1,0,0,0)
        [ToggleUI] _ShadingGradeMapInvertColor("反转分级图 / Invert Grade", Float) = 0
        _ShadingGradeMapRemapStart("分级图起点 / Grade Start", Range(0,1)) = 0
        _ShadingGradeMapRemapEnd("分级图终点 / Grade End", Range(0,1)) = 1
        _ShadingGradeMapStrength("分级图强度 / Grade Strength", Range(0,1)) = 1
        _ShadingGradeMapApplyRange("分级图范围 / Grade Range", Range(0,4)) = 1
        _ShadingGradeMapMidPointOffset("分级图偏移 / Grade Offset", Range(-1,1)) = 0
        [ToggleUI] _GZDiffuseRampDitherEnabled("启用抖动 / Enable Dither", Float) = 0
        _GZDiffuseRampDitherStrength("抖动强度（纹素）/ Dither Texels", Range(0,2)) = 1
        [ToggleUI] _GZCCRampEnabled("启用颜色校正 / Color Correction", Float) = 0
        _GZCCRampExposure("曝光 EV / Exposure", Range(-8,8)) = 0
        _GZCCRampHue("色相（度）/ Hue Degrees", Range(-180,180)) = 0
        _GZCCRampSaturation("饱和度 / Saturation", Range(0,2)) = 1
        _GZCCRampContrast("对比度 / Contrast", Range(0,2)) = 1
        _GZCCRampGamma("Gamma", Range(0.1,3)) = 1
        [HDR] _GZCCRampTint("染色 / Tint", Color) = (1,1,1,1)
        _Indirectdiffusereflectionintensity("SH 环境光 / SH Intensity", Range(0,3)) = 1
        _Indirectlightspecularintensity("反射探针 / Reflection Intensity", Range(0,3)) = 1
        [HDR] _EmissionColor("自发光 / Emission", Color) = (0,0,0,1)
        _faceSDF("脸部 SDF / Face SDF", 2D) = "gray" {}
        _AoMask4("SDF 通道 / RGBA Channel", Vector) = (1,0,0,0)
        _Vector4("SDF UV 偏移 / UV Offset", Vector) = (0,0,0,0)
        [ToggleUI] _GZFaceSDFMirrorUV("反转左右 / Mirror Sides", Float) = 0
        _ShadowOffset("SDF 明暗偏移 / Threshold Offset", Range(-1,1)) = 0
        _ShadowOffset1("SDF 柔软度 / Softness", Range(0,0.5)) = 0.03
        _FaceFrontDirWS("头部前向 / Head Forward", Vector) = (0,0,1,0)
        _FaceRightDirWS("头部右向 / Head Right", Vector) = (1,0,0,0)
        _FaceUpDirWS("头部向上 / Head Up", Vector) = (0,1,0,0)
        [ToggleUI] _GZHairUVHighlightEnabled("启用 UV 高光 / UV Highlight", Float) = 1
        _SpecMask("高光遮罩 / Highlight Mask", 2D) = "black" {}
        _SpecMaskRGBA("高光通道 / RGBA Channel", Vector) = (1,0,0,0)
        [ToggleUI] _InvertSpecMask("反转高光 / Invert Highlight", Float) = 0
        _HairHighlightUVST("UV 缩放与偏移 / UV Scale Offset", Vector) = (1,1,0,0)
        [ToggleUI] _GZHairUVControlEnabled("使用 UV 控制图 / UV Control Map", Float) = 0
        _SpecMask_STUV("UV 控制图（RG 缩放 BA 偏移）/ Control", 2D) = "white" {}
        _AnisotropicSize("视角位移 / View Shift", Range(-1,1)) = 0.1
        _AnisotropicOffset("高光偏移 / Highlight Offset", Range(-1,1)) = 0
        _AnisotropicRange1("高光强度 / Highlight Strength", Range(0,8)) = 1
        [HDR] _HairHighlightColor("高光颜色 / Highlight Color", Color) = (0.5,0.45,0.35,1)
        [ToggleUI] _GZOutlinePassEnabled("启用描边 / Enable Outline", Float) = 1
        _Thickness1("描边宽度（世界单位）/ Width", Range(0,0.05)) = 0.0075
        _Color1189("描边颜色 / Outline Color", Color) = (0.025,0.025,0.04,1)
    }
    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
        Cull Back
        HLSLINCLUDE
        #pragma target 4.5
        #define GZ_PREVIEW_BASE 1
        ENDHLSL
        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForwardOnly" }
            ZWrite On
            HLSLPROGRAM
            #pragma vertex PreviewVertex
            #pragma fragment PreviewFragment
            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile _ _CLUSTER_LIGHT_LOOP
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_ATLAS
            #include "PreviewForward.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex PreviewAuxVertex
            #pragma fragment PreviewAuxFragment
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #define GZ_PREVIEW_SHADOW 1
            #include "PreviewAuxiliary.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ZWrite On
            ColorMask 0
            HLSLPROGRAM
            #pragma vertex PreviewAuxVertex
            #pragma fragment PreviewAuxFragment
            #pragma multi_compile_instancing
            
            #define GZ_PREVIEW_DEPTH 1
            #include "PreviewAuxiliary.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormalsOnly" }
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex PreviewAuxVertex
            #pragma fragment PreviewAuxFragment
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
            #define GZ_PREVIEW_NORMALS 1
            #include "PreviewAuxiliary.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags { "LightMode"="GZtoonPreviewOutline" }
            ZWrite On
            Cull Front
            HLSLPROGRAM
            #pragma vertex PreviewAuxVertex
            #pragma fragment PreviewAuxFragment
            #pragma multi_compile_instancing
            
            #define GZ_PREVIEW_OUTLINE 1
            #include "PreviewAuxiliary.hlsl"
            ENDHLSL
        }
    }
    CustomEditor "GZToon.Preview.Editor.PreviewShaderGUI"
    Fallback Off
}
