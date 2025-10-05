#ifndef ADDITIONAL_LIGHT_INCLUDED
#define ADDITIONAL_LIGHT_INCLUDED

// see: Outline_alphaBlend.shader

/* _CameraOpaqueTexture_TexelSize
 * : defined as global Vector4 in FullBlitOutline.shadergraph
 *
 * _Scale, _Color, _DepthThreshold, _DepthNormalThreshold, _DepthNormalThresholdScale, _NormalThreshold
 * : defined as usable property reference in FullBlitOutline.shadergraph
 */

// https://discussions.unity.com/t/scene-depth-texture-texel-size-in-shadergraph-urp/1561917/3
void CameraOpaqueTextureTexelSize_float(
	out float Width, out float Height, out float OneOverWidth, out float OneOverHeight)
{
    Width = _CameraOpaqueTexture_TexelSize.z;
    Height = _CameraOpaqueTexture_TexelSize.w;
    OneOverWidth = _CameraOpaqueTexture_TexelSize.x;
    OneOverHeight = _CameraOpaqueTexture_TexelSize.y;
}

// Combines the top and bottom colors using normal blending.
// https://en.wikipedia.org/wiki/Blend_modes#Normal_blend_mode
// This performs the same operation as Blend SrcAlpha OneMinusSrcAlpha.
void AlphaBlend_half(half4 top, half4 bottom,
	out half4 OutColor)
{
	half3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
	half alpha = top.a + bottom.a * (1 - top.a);

	OutColor = half4(color, alpha);
}

void ReScaleForTexel_float(
	float2 refResolution,
	float Scale, float screenWidth, float screenHeight,
	out float OutScale)
{
    OutScale = Scale * (screenHeight / refResolution.y);
}

// in.UV (or in.texcoord) of Varyings = UV node in shadergraph = TEXCOORD0 in shader code
void GetCornerUVs_float(
	float2 TEXCOORD0, float4 CameraOpaqueTexture_TexelSize, float Scale,
	out float2 bottomLeftUV, out float2 topRightUV, out float2 bottomRightUV, out float2 topLeftUV)
{
    float halfScaleFloor = floor(Scale * 0.5); // ex: 0
    float halfScaleCeil = ceil(Scale * 0.5);   // ex: 1

    bottomLeftUV = TEXCOORD0 - float2(CameraOpaqueTexture_TexelSize.x, CameraOpaqueTexture_TexelSize.y) * halfScaleFloor;					// ex: BtmLeft = TEXCOORD0 + (0, 0)
    topRightUV = TEXCOORD0 + float2(CameraOpaqueTexture_TexelSize.x, CameraOpaqueTexture_TexelSize.y) * halfScaleCeil;						// ex: TopRght = TEXCOORD0 + (texelSize.x, texelSize.y)
    bottomRightUV = TEXCOORD0 + float2(CameraOpaqueTexture_TexelSize.x * halfScaleCeil, -CameraOpaqueTexture_TexelSize.y * halfScaleFloor); // ex: BtmRght = TEXCOORD0 + (texelSize.x, 0)
    topLeftUV = TEXCOORD0 + float2(-CameraOpaqueTexture_TexelSize.x * halfScaleFloor, CameraOpaqueTexture_TexelSize.y * halfScaleCeil);		// ex: TopLeft = TEXCOORD0 + (0, texelSize.y)
}

void NormalsSampler_float(
	float2 bottomLeftUV, float2 topRightUV, float2 bottomRightUV, float2 topLeftUV,
	float3 viewSpaceDir,
	out float3 normal0, out float3 normal1, out float3 normal2, out float3 normal3,
	out float3 viewNormal, out float NdotV)
{
	//normal0 = SampleSceneNormals(bottomLeftUV); // same result with same "redeclaration error of unity given"
	//normal1 = SampleSceneNormals(topRightUV);
	//normal2 = SampleSceneNormals(bottomRightUV);
    //normal3 = SampleSceneNormals(topLeftUV);
    normal0 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomLeftUV).rgb;
    normal1 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topRightUV).rgb;
    normal2 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomRightUV).rgb;
    normal3 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topLeftUV).rgb;
	
    viewNormal = normal0 * 2 - 1;
    NdotV = 1 - dot(viewNormal, -viewSpaceDir);
}
	
void GetEdgeDepth_float(
	float depth0, float depth1, float depth2, float depth3,
	float3 normal0, float3 normal1, float3 normal2, float3 normal3,
	float NdotV,
	out float edgeDepth, out float edgeNormal)
{
	float normalThreshold01 = saturate((NdotV - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
	float normalThreshold = normalThreshold01 * _DepthNormalThresholdScale + 1;

	float depthThreshold = _DepthThreshold * depth0 * normalThreshold;
	
	float depthFiniteDifference0 = depth1 - depth0;
	float depthFiniteDifference1 = depth3 - depth2;
	edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
	edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

	float3 normalFiniteDifference0 = normal1 - normal0;
	float3 normalFiniteDifference1 = normal3 - normal2;
	edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
	edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;
}
	
void GetFinalColor_float(
	float edgeDepth, float edgeNormal, half4 CameraBufferBlitColor,
	out float isEdge, out half4 OutColor)
{
    isEdge = max(edgeDepth, edgeNormal); 
	half4 edgeColor = half4(_Color.rgb, _Color.a * isEdge);

    //half4 CameraBufferBlitColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, TEXCOORD0);
    AlphaBlend_half(edgeColor, CameraBufferBlitColor, OutColor);
}

#endif // ADDITIONAL_LIGHT_INCLUDED
