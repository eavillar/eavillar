Shader "HLSL/Unlit/Uvs Canvas Lines"
{
    Properties
    {
        [Header(Main Texture)]
        [Space(2)]
        [NoScaleOffset]_BaseMap("Texture", 2D) = "white" {}
        [NoScaleOffset]_BaseMap2("Texture2", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)

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
            TEXTURE2D(_BaseMap2);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_BaseMap2);
            float4 _BaseMap_ST, _BaseColor;



            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.vertex = vertexInput.positionCS;
                o.uv = v.uv * float2(_BaseMap_ST.x, _BaseMap_ST.y) + float2(_BaseMap_ST.z, _BaseMap_ST.w);
                return o;
            }

            float3 lineTexture (float2 uv)
            {
                float2 lines = uv.yx * uv.yy + uv.xx;
                for(int i=1; i<int(4); i++){
                    lines.x+=.15*sin(lines.y+_Time.y*.75);
                    lines.y+=.35*cos(lines.x+_Time.y*.2);
                }
                float outlines = cos(lines.y+lines.x+2)*.5+.5*3.141529;
                float3 col = float3(outlines,outlines,outlines);
                return col;
            }

            half4 frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float2 uv = (i.uv/_ScreenParams.xy) * 1500;
                uv+=_Time.y*0.005;
                float3 outRGB01 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap,lineTexture(uv));
                float3 outRGB02 = SAMPLE_TEXTURE2D(_BaseMap2, sampler_BaseMap2,lineTexture(uv)+_Time.y*.12);
                float3 col = float3(0,0,0);
                col+=outRGB01;
                col*=lerp(col,outRGB02,outRGB01.r*2);
                return half4(col*_BaseColor, 1);
            }
            ENDHLSL
        }

    }
    FallBack "Hidden/InternalErrorShader"
}
