Shader "Custom/Outline"
{
    // Properties
    // {
    //     [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    //     [MainTexture] _BaseMap("Base Map", 2D) = "white"
    // }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
		LOD 100
		ZWrite Off Cull Off
        // Cull Off ZWrite Off ZTest Always

		// guide(legacy): https://roystan.net/articles/outline-shader/
		// source:        https://github.com/IronWarrior/UnityOutlineShader/
        Pass
        {
			Name "OutlinePass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			
            // // The Blit.hlsl file provides the vertex shader (Vert),
            // // the input structure (Attributes1) and the output structure (Varyings1)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex vert1 // vert1 is the problem//what is pragma vertex
            #pragma fragment frag
			
			// TEXTURE2D_SAMPLER2D(_CameraOpaqueTexture/*_BaseMap*/, sampler_CameraOpaqueTexture/*sampler_BaseMap*/);
            TEXTURE2D(_CameraOpaqueTexture);
            SAMPLER(sampler_CameraOpaqueTexture);
			// _CameraNormalsTexture contains the view space normals transformed
			// to be in the 0...1 range.
            TEXTURE2D(_CameraNormalsTexture);
            SAMPLER(sampler_CameraNormalsTexture);
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);

            // CBUFFER_START(UnityPerMaterial)
            //     // half4 _BaseColor;
            //     float4 _CameraOpaqueTexture_ST;//_BaseMap_ST
            // CBUFFER_END
			
			// Data pertaining to _CameraOpaqueTexture's dimensions.
			// https://docs.unity3d.com/Manual/SL-PropertiesInPrograms.html
			float4 _CameraOpaqueTexture_TexelSize;

			float _Scale;
			half4 _Color;
			
			float _DepthThreshold;
			float _DepthNormalThreshold;
			float _DepthNormalThresholdScale;

			float _NormalThreshold;

			// This matrix is populated in OutlineRendererFeature.cs.
			float4x4 _ClipToView;
			
			// Example from Unity's shader code
			// Transforms a clip-space vertex into a normalized UV coordinate (0-1)
			// https://discussions.unity.com/t/custom-post-process-effect-creates-only-a-triangle-on-the-screen/219310/3
			float2 TransformTriangleVertexToUV(float2 vertex)
			{
				// Maps vertex coordinates from [-1, 1] to [0, 1]
				float2 uv = (vertex + 1.0) * 0.5;
				return uv;
			}

			// https://docs.unity3d.com/kr/2018.4/Manual/SinglePassStereoRendering.html
			float2 TransformStereoScreenSpaceTex(float2 uv, float w)
			{
				float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
				return uv.xy * scaleOffset.xy + scaleOffset.zw * w;
			}

			// Combines the top and bottom colors using normal blending.
			// https://en.wikipedia.org/wiki/Blend_modes#Normal_blend_mode
			// This performs the same operation as Blend SrcAlpha OneMinusSrcAlpha.
			float4 alphaBlend(float4 top, float4 bottom)
			{
				float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
				float alpha = top.a + bottom.a * (1 - top.a);

				return float4(color, alpha);
			}
			
			struct Attributes0
			{
				uint vertexID : SV_VertexID;
			};
            struct Attributes1
            {
				uint vertexID : SV_VertexID; //// <<??
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
			
            struct Varyings0
            {
                float4 vertex : SV_POSITION;
                float2 uv   : TEXCOORD0;
            };
            struct Varyings1
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float2 texcoordStereo : TEXCOORD1;
				float3 viewSpaceDir : TEXCOORD2;
			// #if STEREO_INSTANCING_ENABLED
			// 	uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
			// #endif
            };

			/*******************************************************/
			Varyings0 vert0(Attributes0 IN) // this is from blit.hlsl, this works
			{
				Varyings0 OUT;

				OUT.vertex = GetFullScreenTriangleVertexPosition(IN.vertexID);
				OUT.uv   = GetFullScreenTriangleTexCoord(IN.vertexID);

				return OUT;
			}
			// Varyings Vert(Attributes0 IN)
			// {
            //  Varyings1 OUT;
            //  OUT.vertex = TransformObjectToHClip(IN.positionOS.xyz);
            //  OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
            //  return OUT;
			// }
			Varyings1 vert1(Attributes1 IN)
			{
				Varyings1 OUT;
				// OUT.vertex = float4(IN.positionOS.xy, 0.0, 1.0);
				OUT.vertex = GetFullScreenTriangleVertexPosition(IN.vertexID);
				OUT.uv   = DYNAMIC_SCALING_APPLY_SCALEBIAS(GetFullScreenTriangleTexCoord(IN.vertexID));//IN.positionOS.xy //??
				OUT.viewSpaceDir = mul(_ClipToView, OUT.vertex).xyz;
				// OUT.uv = TransformTriangleVertexToUV(IN.positionOS.xy);
				// OUT.uv = DYNAMIC_SCALING_APPLY_SCALEBIAS(TransformTriangleVertexToUV(IN.positionOS.xy));

			// #if UNITY_UV_STARTS_AT_TOP
			// 	OUT.uv = OUT.uv * float2(1.0, -1.0) + float2(0.0, 1.0);
			// #endif

				OUT.texcoordStereo = TransformStereoScreenSpaceTex(OUT.uv, 1.0);

				return OUT;
			}
			/*******************************************************/


			
			
            half4 frag0 (Varyings input) : SV_Target
            {
                // UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                // Sample the color from the input texture
                float4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, input.texcoord);

                // Output the color from the texture, with the green value set to the chosen intensity
                return color * float4(0, 1.5, 0, 1);
            }

            half4 frag(Varyings1 IN) : SV_Target
            {
                float halfScaleFloor = floor(_Scale * 0.5);
				float halfScaleCeil = ceil(_Scale * 0.5);

				float2 bottomLeftUV = IN.uv - float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleFloor;
				float2 topRightUV = IN.uv + float2(_CameraOpaqueTexture_TexelSize.x, _CameraOpaqueTexture_TexelSize.y) * halfScaleCeil;  
				float2 bottomRightUV = IN.uv + float2(_CameraOpaqueTexture_TexelSize.x * halfScaleCeil, -_CameraOpaqueTexture_TexelSize.y * halfScaleFloor);
				float2 topLeftUV = IN.uv + float2(-_CameraOpaqueTexture_TexelSize.x * halfScaleFloor, _CameraOpaqueTexture_TexelSize.y * halfScaleCeil);

				// sampling the depths
				float depth0 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomLeftUV).r;
				float depth1 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topRightUV).r;
				float depth2 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, bottomRightUV).r;
				float depth3 = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, topLeftUV).r;
				
				// sampling the normals
				float3 normal0 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomLeftUV).rgb;
				float3 normal1 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topRightUV).rgb;
				float3 normal2 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, bottomRightUV).rgb;
				float3 normal3 = SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, topLeftUV).rgb;

				// Transform the view normal from the 0...1 range to the -1...1 range.
				// modulate depthThreshold by the surface's normal
				float3 viewNormal = normal0 * 2 - 1;
				float NdotV = 1 - dot(viewNormal, -IN.viewSpaceDir);
				
				// Return a value in the 0...1 range depending on where NdotV lies 
				// between _DepthNormalThreshold and 1.
				float normalThreshold01 = saturate((NdotV - _DepthNormalThreshold) / (1 - _DepthNormalThreshold));
				// Scale the threshold, and add 1 so that it is in the range of 1..._NormalThresholdScale + 1.
				float normalThreshold = normalThreshold01 * _DepthNormalThresholdScale + 1;

				// Modulate the threshold by the existing depth value;
				// pixels further from the screen will require smaller differences
				// to draw an edge.
				float depthThreshold = _DepthThreshold * depth0 * normalThreshold;

				float depthFiniteDifference0 = depth1 - depth0;
				float depthFiniteDifference1 = depth3 - depth2;
				// edgeDepth is calculated using the Roberts cross operator.
				// The same operation is applied to the normal below.
				// https://en.wikipedia.org/wiki/Roberts_cross
				float edgeDepth = sqrt(pow(depthFiniteDifference0, 2) + pow(depthFiniteDifference1, 2)) * 100;
				edgeDepth = edgeDepth > depthThreshold ? 1 : 0;

				float3 normalFiniteDifference0 = normal1 - normal0;
				float3 normalFiniteDifference1 = normal3 - normal2;
				// Dot the finite differences with themselves to transform the 
				// three-dimensional values to scalars.
				float edgeNormal = sqrt(dot(normalFiniteDifference0, normalFiniteDifference0) + dot(normalFiniteDifference1, normalFiniteDifference1));
				edgeNormal = edgeNormal > _NormalThreshold ? 1 : 0;


				
                // half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                // return color;

				float edge = max(edgeDepth, edgeNormal);

				half4 edgeColor = half4(_Color.rgb, _Color.a * edge);

				half4 color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.uv);
				// float4 color = SAMPLE_TEXTURE2D_X(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, IN.uv);
				
				return alphaBlend(edgeColor, color);
            }
            ENDHLSL
        }
    }
}
