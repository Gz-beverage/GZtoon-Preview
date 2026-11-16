using System;
using System.Linq;
using UnityEditor;
using UnityEngine;

namespace GZToon.Preview.Editor
{
    public sealed class PreviewShaderGUI : ShaderGUI
    {
        MaterialEditor editor;
        MaterialProperty[] properties;

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] materialProperties)
        {
            editor = materialEditor;
            properties = materialProperties;
            var material = (Material)editor.target;
            EditorGUILayout.LabelField("GZtoon Preview", EditorStyles.boldLabel);
            EditorGUILayout.Space(3);
            var names = new[] { "基础 / Base", "脸部 / Face", "头发 / Hair" };
            int current = material.shader.name.EndsWith("Face", StringComparison.Ordinal) ? 1 :
                material.shader.name.EndsWith("Hair", StringComparison.Ordinal) ? 2 : 0;
            EditorGUI.showMixedValue = editor.targets.Cast<Material>().Any(item => item.shader != material.shader);
            EditorGUI.BeginChangeCheck();
            int selected = EditorGUILayout.Popup("材质用途 / Profile", current, names);
            if (EditorGUI.EndChangeCheck())
            {
                var shader = Shader.Find("GZtoon/Preview/" + new[] { "Base", "Face", "Hair" }[selected]);
                Undo.RecordObjects(editor.targets, "Change GZtoon Preview Profile");
                foreach (Material item in editor.targets)
                {
                    item.shader = shader;
                    ValidateMaterial(item);
                }
                editor.PropertiesChanged();
                GUIUtility.ExitGUI();
            }
            EditorGUI.showMixedValue = false;
            Section("base", "底色与法线 / Surface", () => Fields("_BaseTex", "_BaseColor", "_Normal", "_NormalScale", "_GZAlphaClip", "_GZAlphaCutoff"));
            Section("pbr", "粗糙度、金属度与 AO / PBR", () => Fields("_RoughnessTex", "_RoughnessMask", "_Smoothness2", "_RoughnessTex1", "_metallicMack", "_metallic", "_RoughnessTex2", "_AoMask", "_AoStrength", "_specTermIntensity", "_Color3"));
            Section("diffuse", "直接漫反射 / Diffuse", () =>
            {
                Fields("_NOLRemapStart", "_NOLRampEnd", "_PBRShadowColor", "_GZDiffuseRampEnabled");
                Section("ramp", "颜色 Ramp / Color Ramp", () => Fields("_RampLightingTex", "_GZDiffuseRampRow"));
                Section("row", "Ramp Y 贴图 / Row Map", () => Fields("_GZDiffuseRampRowMapEnabled", "_TextureSample4", "_AoMask2", "_AoTexReversal2", "_RampLightingUvYRemapStart", "_RampLightingUvYRemapEnd"));
                Section("mask", "Ramp 区域遮罩 / Region Mask", () => Fields("_ShadingGradeMap1", "_ShadingGradeMapChannelMask1", "_ShadingGradeMapInvertColor1"));
                Section("grade", "明暗分级图 / Grade Map", () => Fields("_GZShadingGradeMapEnabled", "_ShadingGradeMap", "_ShadingGradeMapChannelMask", "_ShadingGradeMapInvertColor", "_ShadingGradeMapRemapStart", "_ShadingGradeMapRemapEnd", "_ShadingGradeMapStrength", "_ShadingGradeMapApplyRange", "_ShadingGradeMapMidPointOffset"));
                Section("dither", "抖动 / Dither", () => Fields("_GZDiffuseRampDitherEnabled", "_GZDiffuseRampDitherStrength"));
                Section("grading", "Ramp 颜色校正 / Color Correction", () => Fields("_GZCCRampEnabled", "_GZCCRampExposure", "_GZCCRampHue", "_GZCCRampSaturation", "_GZCCRampContrast", "_GZCCRampGamma", "_GZCCRampTint"));
            });
            if (current == 1)
                Section("face", "脸部 SDF / Face SDF", () => Fields("_faceSDF", "_AoMask4", "_Vector4", "_GZFaceSDFMirrorUV", "_ShadowOffset", "_ShadowOffset1", "_FaceFrontDirWS", "_FaceRightDirWS", "_FaceUpDirWS"));
            if (current == 2)
                Section("hair", "UV 高光 / Hair Highlight", () => Fields("_GZHairUVHighlightEnabled", "_SpecMask", "_SpecMaskRGBA", "_InvertSpecMask", "_HairHighlightUVST", "_GZHairUVControlEnabled", "_SpecMask_STUV", "_AnisotropicSize", "_AnisotropicOffset", "_AnisotropicRange1", "_HairHighlightColor"));
            Section("environment", "环境光与自发光 / Environment", () => Fields("_Indirectdiffusereflectionintensity", "_Indirectlightspecularintensity", "_EmissionColor"));
            Section("outline", "描边 / Outline", () => Fields("_GZOutlinePassEnabled", "_Thickness1", "_Color1189"));
            editor.EnableInstancingField();
            editor.RenderQueueField();
        }

        void Section(string key, string label, Action content)
        {
            string preference = "GZtoon.Preview.Foldout." + key;
            bool expanded = SessionState.GetBool(preference, key == "base" || key == "diffuse");
            bool selected = EditorGUILayout.Foldout(expanded, label, true, EditorStyles.foldoutHeader);
            if (selected != expanded) SessionState.SetBool(preference, selected);
            if (!selected) return;
            using (new EditorGUI.IndentLevelScope()) content();
            EditorGUILayout.Space(4);
        }

        void Fields(params string[] names)
        {
            foreach (string name in names)
            {
                var property = FindProperty(name, properties, false);
                if (property == null) continue;
                if (property.propertyType == UnityEngine.Rendering.ShaderPropertyType.Texture)
                {
                    editor.TexturePropertySingleLine(new GUIContent(property.displayName), property);
                    if (name == "_BaseTex" || name == "_Normal" || name == "_ShadingGradeMap")
                        editor.TextureScaleOffsetProperty(property);
                }
                else editor.ShaderProperty(property, property.displayName);
            }
        }

        public override void ValidateMaterial(Material material)
        {
            if (!material || !material.HasProperty("_GZAlphaClip")) return;
            bool clipped = material.GetFloat("_GZAlphaClip") > .5f;
            material.SetOverrideTag("RenderType", clipped ? "TransparentCutout" : "Opaque");
            material.renderQueue = clipped ? (int)UnityEngine.Rendering.RenderQueue.AlphaTest : (int)UnityEngine.Rendering.RenderQueue.Geometry;
            if (!material.GetTexture("_RampLightingTex"))
                material.SetTexture("_RampLightingTex", PreviewTools.LoadDefaultRamp());
        }
    }
}
