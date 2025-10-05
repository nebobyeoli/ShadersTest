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

// Example from Unity's shader code
// Transforms a clip-space vertex into a normalized UV coordinate (0-1)
// https://discussions.unity.com/t/custom-post-process-effect-creates-only-a-triangle-on-the-screen/219310/3
void TransformTriangleVertexToUV_float(float2 vertex,
	out float2 OutUV)
{
	// Maps vertex coordinates from [-1, 1] to [0, 1]
	OutUV = (vertex + 1.0) * 0.5;
}

// https://docs.unity3d.com/kr/2018.4/Manual/SinglePassStereoRendering.html
void TransformStereoScreenSpaceTex_float(float2 uv, float w,
	out float2 OutUV)
{
	float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
	OutUV = uv.xy * scaleOffset.xy + scaleOffset.zw * w;
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

//float3 SampleSceneNormals(float2 uv)
//{
//    return UnpackNormal(SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uv));
//}

// in.UV (or in.texcoord) of Varyings = UV node in shadergraph = TEXCOORD0 in shader code
void GetCornerUVs_float(float2 TEXCOORD0, float4 CameraOpaqueTexture_TexelSize, float Scale,
	out float2 bottomLeftUV, out float2 topRightUV, out float2 bottomRightUV, out float2 topLeftUV)
{
    float halfScaleFloor = floor(Scale * 0.5); // 0
    float halfScaleCeil = ceil(Scale * 0.5); // 1

    bottomLeftUV = TEXCOORD0 - float2(CameraOpaqueTexture_TexelSize.x, CameraOpaqueTexture_TexelSize.y) * halfScaleFloor;					// BtmLeft = TEXCOORD0 + (0, 0)
    topRightUV = TEXCOORD0 + float2(CameraOpaqueTexture_TexelSize.x, CameraOpaqueTexture_TexelSize.y) * halfScaleCeil;						// TopRght = TEXCOORD0 + (texelSize.x, texelSize.y)
    bottomRightUV = TEXCOORD0 + float2(CameraOpaqueTexture_TexelSize.x * halfScaleCeil, -CameraOpaqueTexture_TexelSize.y * halfScaleFloor); // BtmRght = TEXCOORD0 + (texelSize.x, 0)
    topLeftUV = TEXCOORD0 + float2(-CameraOpaqueTexture_TexelSize.x * halfScaleFloor, CameraOpaqueTexture_TexelSize.y * halfScaleCeil);		// TopLeft = TEXCOORD0 + (0, texelSize.y)
}

void NormalsSampler_float(
	float2 bottomLeftUV, float2 topRightUV, float2 bottomRightUV, float2 topLeftUV,
	float depth0, float depth1, float depth2, float depth3,
	float3 viewSpaceDir,
	half4 camBufferColor,
	
	out float3 normal0, out float3 normal1, out float3 normal2, out float3 normal3,
	out float3 viewNormal, out float NdotV,
	out float edgeDepth, out float edgeNormal,
	
	out float edge, out half4 OutColor)
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
	
    edge = max(edgeDepth, edgeNormal); 
	half4 edgeColor = half4(_Color.rgb, _Color.a * edge);

    //half4 camBufferColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, TEXCOORD0);
    AlphaBlend_half(edgeColor, camBufferColor, OutColor);
}

//// in.UV (or in.texcoord) of Varyings = UV node in shadergraph = TEXCOORD0 in shader code
//void FragSampler_float(float4 TEXCOORD0, float3 IN_ViewSpaceDir,
//	/*out float2 bottomLeftUV, out float2 topRightUV, out float2 bottomRightUV, out float2 topLeftUV,*/
//	out half4 OutColor)
//{
//	// TEXTURE2D_SAMPLER2D(_CameraOpaqueTexture/*_BaseMap*/, sampler_CameraOpaqueTexture/*sampler_BaseMap*/);
//	// Camera Opaque Texture URP: https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@7.1/manual/universalrp-asset.html
//    TEXTURE2D(_CameraOpaqueTexture);
//    //SAMPLER(sampler_CameraOpaqueTexture);
//    SamplerState sampler_CameraOpaqueTexture;
//	// _CameraNormalsTexture contains the view space normals transformed
//	// to be in the 0...1 range.
//    TEXTURE2D(_CameraNormalsTexture);
//    //SAMPLER(sampler_CameraNormalsTexture);
//    SamplerState sampler_CameraNormalsTexture;
//    TEXTURE2D(_CameraDepthTexture);
//    //SAMPLER(sampler_CameraDepthTexture);
//    SamplerState sampler_CameraDepthTexture;
	
//    float halfScaleFloor = floor(_Scale * 0.5);
//    float halfScaleCeil = ceil(_Scale * 0.5);

//    float2 bottomLeftUV = TEXCOORD0 - float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleFloor;
//    float2 topRightUV = TEXCOORD0 + float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleCeil;
//    float2 bottomRightUV = TEXCOORD0 + float2(_CameraOpaqueTexture_TexelSize.x * halfScaleCeil, -_CameraOpaqueTexture_TexelSize.y * halfScaleFloor);
//    float2 topLeftUV = TEXCOORD0 + float2(-_CameraOpaqueTexture_TexelSize.x * halfScaleFloor, _CameraOpaqueTexture_TexelSize.y * halfScaleCeil);

//	// sampling the depths
//	float depth0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomLeftUV).r;
//	float depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topRightUV).r;
//	float depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomRightUV).r;
//	float depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topLeftUV).r;
				
//	// sampling the normals
//	float3 normal0 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomLeftUV).rgb;
//	float3 normal1 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topRightUV).rgb;
//	float3 normal2 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomRightUV).rgb;
//	float3 normal3 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topLeftUV).rgb;
	
//	// Transform the view normal from the 0...1 range to the -1...1 range.
//	// modulate depthThreshold by the surface's normal
//	float3 viewNormal = normal0 * 2 - 1;
//	float NdotV = 1 - dot(viewNormal, -IN_ViewSpaceDir);
				
//	// Return a value in the 0...1 range depending on where NdotV lies 
//	// between _DepthNormalThreshold and 1.
//	float normalThreshold01 = saturate((NdotV - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
//	// Scale the threshold, and add 1 so that it is in the range of 1..._NormalThresholdScale + 1.
//	float normalThreshold = normalThreshold01 * _DepthNormalThresholdScale + 1;

//	// Modulate the threshold by the existing depth value;
//	// pixels further from the screen will require smaller differences
//	// to draw an edge.
//	float depthThreshold = _DepthThreshold * depth0 * normalThreshold;

//	float depthFiniteDifference0 = depth1 - depth0;
//	float depthFiniteDifference1 = depth3 - depth2;
//	// edgeDepth is calculated using the Roberts cross operator.
//	// The same operation is applied to the normal below.
//	// https://en.wikipedia.org/wiki/Roberts_cross
//	float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
//	edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

//	float3 normalFiniteDifference0 = normal1 - normal0;
//	float3 normalFiniteDifference1 = normal3 - normal2;
//	// Dot the finite differences with themselves to transform the 
//	// three-dimensional values to scalars.
//	float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
//	edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;


				
//    // half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
//    // return color;

//	float edge = max(edgeDepth, edgeNormal); // alpha

//	half4 edgeColor = half4(_Color.rgb, _Color.a * edge);

//	half4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, TEXCOORD0);
//	// float4 color = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.uv);
	
//    OutColor = edgeColor;
//	//AlphaBlend_float(edgeColor, color, OutColor);
//}

#endif // ADDITIONAL_LIGHT_INCLUDED
