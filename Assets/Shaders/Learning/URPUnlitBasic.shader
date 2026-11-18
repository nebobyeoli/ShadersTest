Shader "Learning/URPUnlitBasic"
{
    // user settable properties, hidable with [HideInInspector] prefix
    Properties
    {
        [MainColor] _BaseColor("Base Color", Color) = (1, 1, 1, 1)  // interesting that precision isn't defined here
        [MainTexture] _BaseMap("Base Map", 2D) = "white" {}     // "{}": "deprecated texture options block required by older ShaderLab syntax(Unity 2021 LTS & earlier), at end of 2D/3D/Cube property"
    }

    SubShader
    {
        // determines how/when to use a given SubShader or Pass
        Tags
        {
            "RenderPipeline" = "UniversalPipeline" // ex. HDRenderPipeline
            "RenderType" = "Opaque" // ex. Transparent / AlphaTest
            "Queue" = "Geometry" // when in the render loop the object gets rendered // "Geometry": for Opaques, before Transparents
        }

        // can use 1 or more Passes, ex. + depth buffer/shadow casting/lightmapping
        Pass
        {
            HLSLPROGRAM // using HLSL (High Level Shader Language)

            #pragma vertex vert     // use function "vert" for vertex shader
            #pragma fragment frag   // use function "frag" for fragment shader
            
            /**
             * - vertex shader (determines where EACH VERTEX OF A MESH is drawn on screen)
             *   - OS = Object Space = each vertex position is relative to the mesh pivot point
             *   - CS = Clip Space = each vertex position is relative to the screen viewport
             * 
             * - rasterization (mesh vertices -> pixels(fragments))
             * 
             * - fragment shader (determines COLOR OF EACH PIXEL)
             */
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            

            /**
             * CBUFFER_START:
             * for compability with the SRP(Scriptable Render Pipeline = URP/HDRP/CustomSRP) batcher
             * (increase CPU performance for batch handling of same shader variants)
             * 
             * "Never put TEXTURE2D/SAMPLER declarations inside CBUFFER_START,
             *  bc only numerical values (float/half/int/vector/matrix) belong in a constant buffer"
             */
            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;       // redeclare here to be usable in HLSL code?
                float4 _BaseMap_ST;     // ST = Scale & Translation (= tiling & offset)
            CBUFFER_END
            
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);


            // struct Attributes (or "appdata/VertexInput") = INPUT of vertex shader
            struct Attributes
            {
                float4 positionOS : POSITION;   // position(Object Space) : (ACTUAL VERTEX POSITION DATA)
                float2 uv : TEXCOORD0;          // uv : (ACTUAL UV0/1/2 OF A MESH)
            };

            // struct Varyings (or "v2f/VertexOutput") = OUTPUT of vertex shader, INPUT of fragment shader
            struct Varyings
            {
                // SV_POSITION = "System Value semantic"
                // = tells the rasterizer which position data to use between pipelines(= when converting vertices -> pixels)
                float4 positionHCS : SV_POSITION; // HCS = Homogeneous Clip Space = H: explicitly mention 4d(=xyz,w) homogeneous coord system

                float2 uv : TEXCOORD0;
            };

            // returns = OUTPUT of vertex shader, INPUT of fragment shader
            Varyings vert(Attributes IN/* vertex data Attributes */)
            {
                Varyings OUT; // = (Varyings)0; // set default values

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // TransformObjectTo H omogeneous Clip Space
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            // returns = OUTPUT of fragment shader(= color output on screen)
            /**
             * "half4 is better for performance & is enough color range for color output"
             *  (ex. float4: use for Normal/UV/complex number of color calcs)
             * 
             * SV_Target = semantic for WHERE TO BIND the color output
             *           = screen output color
             */
            half4 frag(Varyings IN) : SV_Target
            {
                // return _BaseColor;

                half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;
                return color;
            }
            ENDHLSL
        }
    }
}
