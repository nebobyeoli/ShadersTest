using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

internal class OutlinePass : ScriptableRenderPass
{
    ProfilingSampler m_ProfilingSampler = new ProfilingSampler("ColorBlit");
    Material m_Material;
    RTHandle m_CameraColorTarget;

    //float m_Intensity;
    // add parameters for Outline.shader
    int m_Scale = 1;
    Color m_Color = Color.white;

    float m_DepthThreshold = 0.2f;
    float m_DepthNormalThreshold = 0.5f;
    float m_DepthNormalThresholdScale = 7;

    float m_NormalThreshold = 0.4f;


    public OutlinePass(Material material)
    {
        m_Material = material;
        renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }

    //public void SetTarget(RTHandle colorHandle, float intensity)
    public void SetTarget(RTHandle colorHandle,
        int scale, Color color,
        float depthThreshold, float depthNormalThreshold, float depthNormalThresholdScale,
        float normalThreshold
        )
    {
        m_CameraColorTarget = colorHandle;
        //m_Intensity = intensity;
        m_Scale = scale;
        m_Color = color;
        m_DepthThreshold = depthThreshold;
        m_DepthNormalThreshold = depthNormalThreshold;
        m_DepthNormalThresholdScale = depthNormalThresholdScale;
        m_NormalThreshold = normalThreshold;
    }

    [System.Obsolete]
    public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
    {
        ConfigureTarget(m_CameraColorTarget);
    }

    [System.Obsolete]
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
    {
        var cameraData = renderingData.cameraData;
        if (cameraData.camera.cameraType != CameraType.Game)
            return;

        if (m_Material == null)
            return;

        CommandBuffer cmd = CommandBufferPool.Get();
        using (new ProfilingScope(cmd, m_ProfilingSampler))
        {
            //m_Material.SetFloat("_Intensity", m_Intensity);
            m_Material.SetInt("_Scale", m_Scale);
            m_Material.SetColor("_Color", m_Color);
            m_Material.SetFloat("_DepthThreshold", m_DepthThreshold);
            m_Material.SetFloat("_DepthNormalThreshold", m_DepthNormalThreshold);
            m_Material.SetFloat("_DepthNormalThresholdScale", m_DepthNormalThresholdScale);
            m_Material.SetFloat("_NormalThreshold", m_NormalThreshold);
            Blitter.BlitCameraTexture(cmd, m_CameraColorTarget, m_CameraColorTarget, m_Material, 0);
        }
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        CommandBufferPool.Release(cmd);
    }
}