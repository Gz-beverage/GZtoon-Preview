using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

namespace GZToon.Preview
{
    public sealed class PreviewOutlineFeature : ScriptableRendererFeature
    {
        OutlinePass pass;

        public override void Create()
        {
            pass = new OutlinePass { renderPassEvent = RenderPassEvent.AfterRenderingOpaques };
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.cameraType != CameraType.Preview)
                renderer.EnqueuePass(pass);
        }

        sealed class OutlinePass : ScriptableRenderPass
        {
            static readonly ShaderTagId Tag = new ShaderTagId("GZtoonPreviewOutline");
            sealed class Data { internal RendererListHandle renderers; }

            public override void RecordRenderGraph(RenderGraph graph, ContextContainer frameData)
            {
                var resources = frameData.Get<UniversalResourceData>();
                var camera = frameData.Get<UniversalCameraData>();
                var rendering = frameData.Get<UniversalRenderingData>();
                var lights = frameData.Get<UniversalLightData>();
                var drawing = RenderingUtils.CreateDrawingSettings(Tag, rendering, camera, lights, camera.defaultOpaqueSortFlags);
                var filtering = new FilteringSettings(RenderQueueRange.opaque, camera.camera.cullingMask);
                using (var builder = graph.AddRasterRenderPass<Data>("GZtoon Preview Outline", out var data))
                {
                    data.renderers = graph.CreateRendererList(new RendererListParams(rendering.cullResults, drawing, filtering));
                    builder.UseRendererList(data.renderers);
                    builder.SetRenderAttachment(resources.activeColorTexture, 0, AccessFlags.ReadWrite);
                    builder.SetRenderAttachmentDepth(resources.activeDepthTexture, AccessFlags.ReadWrite);
                    builder.SetRenderFunc(static (Data value, RasterGraphContext context) => context.cmd.DrawRendererList(value.renderers));
                }
            }

#pragma warning disable CS0618, CS0672
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                var drawing = CreateDrawingSettings(Tag, ref renderingData, renderingData.cameraData.defaultOpaqueSortFlags);
                var filtering = new FilteringSettings(RenderQueueRange.opaque, renderingData.cameraData.camera.cullingMask);
                context.DrawRenderers(renderingData.cullResults, ref drawing, ref filtering);
            }
#pragma warning restore CS0618, CS0672
        }
    }
}
