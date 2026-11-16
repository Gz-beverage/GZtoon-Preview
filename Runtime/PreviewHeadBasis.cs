using UnityEngine;

namespace GZToon.Preview
{
    [ExecuteAlways, DisallowMultipleComponent]
    public sealed class PreviewHeadBasis : MonoBehaviour
    {
        public Transform head;
        public Renderer[] targets = System.Array.Empty<Renderer>();
        MaterialPropertyBlock block;
        static readonly int Front = Shader.PropertyToID("_FaceFrontDirWS");
        static readonly int Right = Shader.PropertyToID("_FaceRightDirWS");
        static readonly int Up = Shader.PropertyToID("_FaceUpDirWS");

        void LateUpdate()
        {
            block ??= new MaterialPropertyBlock();
            Transform basis = head ? head : transform;
            foreach (Renderer target in targets)
            {
                if (!target) continue;
                target.GetPropertyBlock(block);
                block.SetVector(Front, basis.forward);
                block.SetVector(Right, basis.right);
                block.SetVector(Up, basis.up);
                target.SetPropertyBlock(block);
            }
        }

        void OnDisable()
        {
            if (block == null) return;
            foreach (Renderer target in targets)
            {
                if (!target) continue;
                target.GetPropertyBlock(block);
                Material material = target.sharedMaterial;
                block.SetVector(Front, material && material.HasProperty(Front) ? material.GetVector(Front) : Vector3.forward);
                block.SetVector(Right, material && material.HasProperty(Right) ? material.GetVector(Right) : Vector3.right);
                block.SetVector(Up, material && material.HasProperty(Up) ? material.GetVector(Up) : Vector3.up);
                target.SetPropertyBlock(block);
            }
        }
    }
}
