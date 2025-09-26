using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class OutlineRendererFeature : ScriptableRendererFeature
{
    public Shader m_Shader;

    //public float m_Intensity;
    // add parameters for Outline.shader
    public int m_Scale = 1;
    public float m_DepthThreshold = 0.2f;

    [Range(0, 1)]
    public float m_NormalThreshold = 0.4f;

    [Range(0, 1)]
    public float m_DepthNormalThreshold = 0.5f;
    public float m_DepthNormalThresholdScale = 7;
    
    public Color m_Color = Color.white;


    Material m_Material;

    OutlinePass m_RenderPass = null;

    public override void AddRenderPasses(ScriptableRenderer renderer,
                                    ref RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
            renderer.EnqueuePass(m_RenderPass);
    }

    [System.Obsolete]
    public override void SetupRenderPasses(ScriptableRenderer renderer,
                                        in RenderingData renderingData)
    {
        if (renderingData.cameraData.cameraType == CameraType.Game)
        {
            // Calling ConfigureInput with the ScriptableRenderPassInput.Color argument
            // ensures that the opaque texture is available to the Render Pass.
            m_RenderPass.ConfigureInput(ScriptableRenderPassInput.Color);
            //m_RenderPass.SetTarget(renderer.cameraColorTargetHandle, m_Intensity);
            m_RenderPass.SetTarget(renderer.cameraColorTargetHandle,
                m_Scale, m_DepthThreshold, m_NormalThreshold,
                m_DepthNormalThreshold, m_DepthNormalThresholdScale,
                m_Color);
        }
    }

    public override void Create()
    {
        m_Material = CoreUtils.CreateEngineMaterial(m_Shader);
        m_RenderPass = new OutlinePass(m_Material);
    }

    protected override void Dispose(bool disposing)
    {
        CoreUtils.Destroy(m_Material);
    }
}
