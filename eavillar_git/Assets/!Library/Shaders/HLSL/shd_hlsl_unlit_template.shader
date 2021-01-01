Shader "HLSL/Unlit/Template"
{
    Properties
    {
        [Header(Main Texture)]
        [Space(2)]
        _BaseMap("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)

        [Space(2)]
        [Header(Cutoff)]
        [Toggle(_CLIP_ENABLE)] 
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5

        // Editmode props
         _QueueOffset("Queue offset", Float) = 0.0
        
        // ObsoleteProperties
         _MainTex("BaseMap", 2D) = "white" {}
         _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
         _SampleGI("SampleGI", float) = 0.0 // needed from bakedlit
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100



        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            // #pragma shader_feature _ALPHATEST_ON
            // #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ _CLIP_ENABLE
            #pragma instancing_options nolightprobe nolightmap


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
            // #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

           TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4,_BaseMap_ST)           
                UNITY_DEFINE_INSTANCED_PROP(float4,_BaseColor)           
                UNITY_DEFINE_INSTANCED_PROP(half,_Cutoff)           
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;

                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                half2 uv = input.uv;
                half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
                half3 color = texColor.rgb * _BaseColor.rgb;
                half alpha = texColor.a * _BaseColor.a;
                half cutOff = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_Cutoff);

                AlphaDiscard(alpha, cutOff);
                return half4(color, alpha);
            }
            ENDHLSL
        }

    }
    FallBack "Hidden/InternalErrorShader"
}
