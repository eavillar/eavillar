Shader "Special/Unlit/Christmas Card"
{
    Properties
    {
        _skytop ("Color Top", color) = (1,1,1,1)
        _skybtom ("Color Bottom", color) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
    
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST, _skybtom, _skytop;

            float Star(float2 uv, float flare){
                float d = length(uv);
                float m = .00625/d;  
                float rays = max(0, 1.-abs(uv.x*uv.y*1000.)); 
                m += (rays*flare)*.1;
                rays = max(0., 1.-abs(uv.x*uv.y*1000.));
                m *= smoothstep(.5, .1, d);
                return m;
            }

            float Hash21(float2 p){
                p = frac(p*float2(123.34, 456.21));
                p += dot(p, p+45.32);
                return frac(p.x*p.y);
            }

            float3 StarLayer(float2 uv){
                float3 col = float3(0,0,0);
                float2 gv = frac(uv)-.5;
                float2 id = floor(uv);
                for(int y=-1;y<=2;y++){
                    for(int x=-1; x<=2; x++){
                        float2 offs = float2(x,y);
                        float n = Hash21(id+offs);
                        float size = frac(n*2.132);
                        float star = Star(gv-offs-float2(n, frac(n*34.))+.5, smoothstep(.8,.9,size)*.46);
                        float3 color = sin(float3(.2,.3,.9)*frac(n*2345.2)*6.28318)*.25+.75;
                        color = color*float3(.9,.59,.9+size);
                        star *= sin(_Time.y*3.+n*6.28318)*.25+.5;
                        col += star*size*color;
                    }
                }
                return col;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv * float2(_MainTex_ST.x+1.0, _MainTex_ST.y+1.75) + float2(_MainTex_ST.z, _MainTex_ST.w);
                o.uv0 = v.uv0;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

 
            fixed4 frag (v2f i) : SV_Target
            {
                float2 vertex = i.vertex.xy;
                float2 r = _ScreenParams.xy;
                float2 st = vertex / r;
                float3 c; float l; float z = _Time.y; 
                float2 uv0 = float2(i.uv.x,i.uv.y+sin(_Time.y*.25)*.25);
                float2 uv1 = i.uv0;
                float mask = 1-distance(i.uv0.xy, float2(0.75,0.25));
                for( int i=0; i<3; i++){
                    float2 uv1 = uv0;
                    float2 p = vertex.xy/_ScreenParams.xy;
                    p-= 1.35 * .6;
                    p.x*=r.x/r.y;
                    z+= 102;
                    l = length(p);
                    uv1+=p/l*(sin(z*.0025)+2)*abs(cos(l*5.-z*.25));
                    c[i] =.01027/length(abs(fmod(uv1,1)+.610))*2.5;
                }
                float3 stars = float3(0,0,0);
                float t = _Time.y*.000162;
                for(float i=0.; i<1.; i+=1./3){
                    float depth =1- frac(i*i);
                    float scale = lerp(105., 2.5, depth);
                    float fade = depth*smoothstep(.12,.9,depth);
                    stars += StarLayer(uv1*scale+i*453.2+_Time.xy*.10035)*fade;
                }
                float3 color = float3(uv0.y,uv0.y,uv0.y);
                float3 outRGB = lerp(_skytop,_skybtom,color)+lerp(float3(c/l), float3(0.5,.21,.1),pow(mask,.374));
                outRGB *= (1.-distance(fmod(uv1,float2(1,1)),float2(0.65,0.65)))*.642;
                return float4(outRGB+lerp( float3(0,0,0),stars, color),1);
            }
            ENDCG
        }
    }
}
