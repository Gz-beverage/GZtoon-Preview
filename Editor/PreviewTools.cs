using System.IO;
using System.Linq;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace GZToon.Preview.Editor
{
    public static class PreviewTools
    {
        public static string PackageRoot => UnityEditor.PackageManager.PackageInfo.FindForAssembly(typeof(PreviewTools).Assembly)?.assetPath ?? "Packages/com.gztoon.preview";
        public static Texture LoadDefaultRamp() => AssetDatabase.LoadAssetAtPath<Texture2D>(PackageRoot + "/Textures/DefaultRamp.png");

        [MenuItem("Assets/Create/GZtoon Preview/Base Material", false, 310)]
        static void CreateBaseMaterial() => CreateMaterial("Base");
        [MenuItem("Assets/Create/GZtoon Preview/Face Material", false, 311)]
        static void CreateFaceMaterial() => CreateMaterial("Face");
        [MenuItem("Assets/Create/GZtoon Preview/Hair Material", false, 312)]
        static void CreateHairMaterial() => CreateMaterial("Hair");

        static void CreateMaterial(string profile)
        {
            var material = new Material(Shader.Find("GZtoon/Preview/" + profile));
            material.SetTexture("_RampLightingTex", LoadDefaultRamp());
            ProjectWindowUtil.CreateAsset(material, "GZtoon " + profile + ".mat");
        }

        [MenuItem("Tools/GZtoon Preview/Install Outline on Current Renderer")]
        public static void InstallOutline()
        {
            var pipeline = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;
            if (!pipeline)
            {
                EditorUtility.DisplayDialog("GZtoon Preview", "请先在 Graphics 或 Quality 中指定 URP 管线资产。", "确定");
                return;
            }
            var serialized = new SerializedObject(pipeline);
            int index = serialized.FindProperty("m_DefaultRendererIndex").intValue;
            var renderer = serialized.FindProperty("m_RendererDataList").GetArrayElementAtIndex(index).objectReferenceValue as ScriptableRendererData;
            if (!renderer || renderer.rendererFeatures.Any(feature => feature is PreviewOutlineFeature)) return;
            Undo.RecordObject(renderer, "Install GZtoon Preview Outline");
            var feature = ScriptableObject.CreateInstance<PreviewOutlineFeature>();
            feature.name = "GZtoon Preview Outline";
            Undo.RegisterCreatedObjectUndo(feature, "Create GZtoon Preview Outline");
            AssetDatabase.AddObjectToAsset(feature, renderer);
            renderer.rendererFeatures.Add(feature);
            renderer.SetDirty();
            EditorUtility.SetDirty(renderer);
            AssetDatabase.SaveAssets();
            Selection.activeObject = renderer;
        }

        [MenuItem("Tools/GZtoon Preview/Create Basic Post-processing Volume")]
        public static void CreateBasicVolume()
        {
            const string folder = "Assets/GZtoonPreview";
            Directory.CreateDirectory(folder);
            AssetDatabase.Refresh();
            var profile = ScriptableObject.CreateInstance<VolumeProfile>();
            string path = AssetDatabase.GenerateUniqueAssetPath(folder + "/BasicPostProcessing.asset");
            AssetDatabase.CreateAsset(profile, path);
            ConfigureBasicVolume(profile);
            var gameObject = new GameObject("GZtoon Preview Volume");
            Undo.RegisterCreatedObjectUndo(gameObject, "Create GZtoon Preview Volume");
            var volume = gameObject.AddComponent<Volume>();
            volume.isGlobal = true;
            volume.sharedProfile = profile;
            if (Camera.main)
            {
                var cameraData = Camera.main.GetUniversalAdditionalCameraData();
                Undo.RecordObject(cameraData, "Enable Basic Post-processing");
                cameraData.renderPostProcessing = true;
                cameraData.antialiasing = AntialiasingMode.FastApproximateAntialiasing;
            }
            AssetDatabase.SaveAssets();
            Selection.activeGameObject = gameObject;
        }

        public static void ConfigureBasicVolume(VolumeProfile profile)
        {
            var bloom = profile.Add<Bloom>(true);
            bloom.intensity.Override(.15f);
            bloom.threshold.Override(1);
            bloom.scatter.Override(.55f);
            var tone = profile.Add<Tonemapping>(true);
            tone.mode.Override(TonemappingMode.Neutral);
            var color = profile.Add<ColorAdjustments>(true);
            color.postExposure.Override(0);
            color.contrast.Override(0);
            color.saturation.Override(0);
            foreach (var component in profile.components)
                if (!AssetDatabase.Contains(component)) AssetDatabase.AddObjectToAsset(component, profile);
            EditorUtility.SetDirty(profile);
        }
    }
}
