Shader "HLSL/Unlit/Uvs Canvas Lines Modified"
{
    Properties
    {
        [Header(Main Texture)]
        [Space(2)]
        [NoScaleOffset]_BaseMap("Texture", 2D) = "white" {}
        [NoScaleOffset]_BaseMap2("Texture2", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _BaseColor2("Color 2", Color) = (1, 1, 1, 1)
        _shadowColor ("Shadow color", color) = (1,1,1,1)
        _FresnelPower ("Fresnel Intensity", float) = 1.0
        _FresnelPower2 ("Fresnel Intensity", float) = 1.0
        _mvmntInt ("Stretch", float) = 1.0
        _Cutoff ("Cutoff", float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100
        Cull Off

        Pass
        {
            Name "Unlit"
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON
            #pragma multi_compile_instancing
            #pragma multi_compile_local _ _CLIP_ENABLE
            #pragma instancing_options nolightprobe nolightmap
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl" 

            CBUFFER_START(UnityPerMaterial) 
                        float4 _shadowColor,_BaseMap_ST, _BaseColor, _BaseColor2;
                        float _Cutoff, _FresnelPower, _mvmntInt, _FresnelPower2;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                half3  normal : NORMAL;
                half4  tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3  normalDir : TEXCOORD1;
                half3  worldPos : TEXCOORD2;
                half  dotOut : TEXCOORD3;
                float3 positionWS               : TEXCOORD4;
                float fogCoord                  : TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_BaseMap2);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_BaseMap2);

            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                o.normalDir = GetVertexNormalInputs(v.normal.xyz).normalWS;
                o.worldPos = mul(unity_ObjectToWorld, v.positionOS).xyz;
                float3 normalizeLD = normalize (float3(1.96,5.04,2));
                float3 normalizeNmls = normalize (normalize(mul(v.normal,(float3x3)UNITY_MATRIX_I_M)));
                float dotOut = dot(normalizeLD, normalizeNmls);
                dotOut = dotOut * 0.5;
                dotOut = 0.5 + dotOut;
                dotOut = dotOut * 0.82; //attenuation value
                dotOut = dotOut * 2.0;
                o.dotOut = dotOut;
                float stretch = sin(_Time.y*_mvmntInt);
				float time = _Time * .205;
				float2 curvas = sin(time*v.positionOS.z * .5)*.05;
				float floating = sin(time*.05)*.15;
				float geoMvmnt = v.positionOS.x + _Time.x * 2.5;
				geoMvmnt = (geoMvmnt * 2) - 1;
				geoMvmnt = geoMvmnt*.57079633 * 0.5;
				geoMvmnt = cos(geoMvmnt * 2)*v.positionOS.x*stretch + curvas*v.positionOS.x*v.positionOS.x;
				float3 geoMvmntmoving = float3(v.positionOS.x, (v.positionOS.y + geoMvmnt), v.positionOS.z ); 
				float3 outMvmnt = float3(v.positionOS.x, v.positionOS.y+floating, v.positionOS.z+floating);
				v.positionOS.xyz = geoMvmntmoving + outMvmnt;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.vertex = vertexInput.positionCS;
                o.positionWS = vertexInput.positionWS;
                o.fogCoord = ComputeFogFactor(v.positionOS.z);
                o.uv = v.uv * float2(_BaseMap_ST.x, _BaseMap_ST.y) + float2(_BaseMap_ST.z, _BaseMap_ST.w);
                return o;
            }

            float3 uvMod (float2 uv)
            {
                float2 lines = uv.yx * uv.yy + uv.xx;
                for(int i=1; i<int(4); i++){
                    lines.x+=.15*sin(lines.y+_Time.y*.75);
                    lines.y+=.35*cos(lines.x+_Time.y*.2);
                }
                float modOut = cos(lines.y+lines.x+2)*.5+.5*3.141529;
                float3 col = float3(modOut,modOut,modOut);
                return col;
            }

            half4 frag(Varyings i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                float3 normalDir = i.normalDir;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float fresnel = (pow(1.0-max(0,dot(normalDir, viewDirection)),_FresnelPower))*cos(_Time.y+float3(.2,.4,.8));
                float fresnel2 = (pow(1.0-max(0,dot(normalDir, viewDirection)),_FresnelPower));
                half4 shadowRim = lerp(_shadowColor, float4(1,1,1,1), i.dotOut);
                float2 uv = (i.uv/_ScreenParams.xy) * 2000;
                uv+=_Time.y*0.005;
                float3 outRGB01 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap,uvMod(uv));
                float3 outRGB02 = SAMPLE_TEXTURE2D(_BaseMap2, sampler_BaseMap2,uvMod(uv)+_Time.y*.12);
                float3 col = float3(0,0,0);
                //Shadow Receiver 
                // #ifdef _MAIN_LIGHT_SHADOWS
                //     VertexPositionInputs vertexInput = (VertexPositionInputs)0;
                //     vertexInput.positionWS = i.positionWS;
    
                //     float4 shadowCoord = GetShadowCoord(vertexInput);
                //     half shadowAttenutation = MainLightRealtimeShadow(shadowCoord);
                //     col = lerp(half4(1,1,1,1), _shadowColor, (1.0 - shadowAttenutation) * _shadowColor.a);
                //     col.rgb = MixFogColor(col.rgb, half3(1,1,1), i.fogCoord);
                // #endif                  
                col+=outRGB01;
                col*=lerp(col,outRGB02,outRGB01.r*2)+fresnel;
                float3 outRGB=lerp(col*_BaseColor, col*_BaseColor2, i.normalDir.y + i.normalDir.y)*cos(_Time.y+uv.xyx+float3(.2,.4,.8));
                clip(1.0-(col.r*2.0+-1.0*cos(_Time.y+float3(.2,.4,.8))) + _Cutoff);
                return half4(pow((outRGB*shadowRim) * 2.5,.86), 1);
            }
            ENDHLSL
        }

        Pass {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
        
            ZWrite On
            ZTest LEqual
        
            HLSLPROGRAM
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x gles
            #pragma multi_compile_instancing
            // #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float3 _LightDirection;

             struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                half3  normal : NORMAL;
                half4  tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv        : TEXCOORD0;
                float4 vertex : SV_POSITION;
                half3  normalDir : TEXCOORD1;
                half3  worldPos : TEXCOORD2;
                half  dotOut : TEXCOORD3;
                float3 positionWS               : TEXCOORD4;
                float3 positionCS               : TEXCOORD6;
                float fogCoord                  : TEXCOORD5;
            };

                float4 _shadowColor,_BaseMap_ST, _BaseColor, _BaseColor2, _ShadowBias;
                float _Cutoff, _FresnelPower, _mvmntInt, _FresnelPower2;

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_BaseMap2);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_BaseMap2);

            float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
            {
                float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
                float scale = invNdotL * _ShadowBias.y;
                positionWS = lightDirection * _ShadowBias.xxx + positionWS;
                positionWS = normalWS * scale.xxx + positionWS;
                return positionWS;
            }                           

            float4 GetShadowPositionHClip(Attributes input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normal);
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));
            #if UNITY_REVERSED_Z
                positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #else
                positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
            #endif
                return positionCS;
            }

            Varyings ShadowPassVertex(Attributes v)
            {
                Varyings o = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(v);
                o.normalDir = GetVertexNormalInputs(v.normal.xyz).normalWS;
                o.worldPos = mul(unity_ObjectToWorld, v.positionOS).xyz;
                 float stretch = sin(_Time.y*_mvmntInt);
				float time = _Time * .205;
				float2 curvas = sin(time*v.positionOS.z * .5)*.05;
				float floating = sin(time*.05)*.15;
				float geoMvmnt = v.positionOS.x + _Time.x * 2.5;
				geoMvmnt = (geoMvmnt * 2) - 1;
				geoMvmnt = geoMvmnt*.57079633 * 0.5;
				geoMvmnt = cos(geoMvmnt * 2)*v.positionOS.x*stretch + curvas*v.positionOS.x*v.positionOS.x;
				float3 geoMvmntmoving = float3(v.positionOS.x, (v.positionOS.y + geoMvmnt), v.positionOS.z ); 
				float3 outMvmnt = float3(v.positionOS.x, v.positionOS.y+floating, v.positionOS.z+floating);
				v.positionOS.xyz = geoMvmntmoving + outMvmnt;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
                o.vertex = vertexInput.positionCS;
                o.positionCS = GetShadowPositionHClip(v);
                o.positionWS = vertexInput.positionWS;
                o.fogCoord = ComputeFogFactor(v.positionOS.z);
                o.uv = v.uv * float2(_BaseMap_ST.x, _BaseMap_ST.y) + float2(_BaseMap_ST.z, _BaseMap_ST.w);

                return o;
            }

            float3 uvMod (float2 uv)
            {
                float2 lines = uv.yx * uv.yy + uv.xx;
                for(int i=1; i<int(4); i++){
                    lines.x+=.15*sin(lines.y+_Time.y*.75);
                    lines.y+=.35*cos(lines.x+_Time.y*.2);
                }
                float modOut = cos(lines.y+lines.x+2)*.5+.5*3.141529;
                float3 col = float3(modOut,modOut,modOut);
                return col;
            }

            half4 ShadowPassFragment(Varyings i) : SV_Target
            {
                // UNITY_SETUP_INSTANCE_ID(i);
                float3 normalDir = i.normalDir;
                float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float fresnel = (pow(1.0-max(0,dot(normalDir, viewDirection)),_FresnelPower))*cos(_Time.y+float3(.2,.4,.8));
                float fresnel2 = (pow(1.0-max(0,dot(normalDir, viewDirection)),_FresnelPower));
                float2 uv = (i.uv/_ScreenParams.xy) * 2000;
                uv+=_Time.y*0.005;
                float3 outRGB01 = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap,uvMod(uv));
                float3 outRGB02 = SAMPLE_TEXTURE2D(_BaseMap2, sampler_BaseMap2,uvMod(uv)+_Time.y*.12);
                float3 col = float3(0,0,0);
         
                col+=outRGB01;
                col*=lerp(col,outRGB02,outRGB01.r*2)+fresnel;

                // float3 outRGB=lerp(col*_BaseColor, col*_BaseColor2, i.normalDir.y + i.normalDir.y)*cos(_Time.y+uv.xyx+float3(.2,.4,.8));
                clip(1.0-(col.r*2.0+-1.0*cos(_Time.y+float3(.2,.4,.8))) + _Cutoff);
                return half4(col, 1);
            }
            ENDHLSL
        }
            

    }
    
}
