Shader "LayaAir3D/LayaGlassMateial" {
    Properties{
        _Glass_Color("Glass_Color", Color) = (0.5,0.5,0.5,1)
        _Refraction_Int("Refraction_Int", Range(0, 1)) = 0.1
        _Glass_AmbientLight_Int("Glass_AmbientLight_Int", Range(0, 2)) = 1
        [NoScaleOffset]_Refraction("Refraction", 2D) = "bump" {}
        [NoScaleOffset]_Glass_AmbientLight("Glass_AmbientLight", 2D) = "white" {}
        tilingOffset("TillingOffset",Vector) = (1.0,1.0,0.0,0.0)
        [HideInInspector]_Cutoff("Alpha cutoff", Range(0,1)) = 0.1
        [HideInInspector]_SrcBlend("__src", Float) = 5
        [HideInInspector]_DstBlend("__dst", Float) = 10
        [HideInInspector]_ZWrite("__zw", Float) = 0
        [HideInInspector]_ZTest("__zt", Float) = 2
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _Mode("__mode", Float) = 0.0
    }
        SubShader{
            Tags {
               "IgnoreProjector" = "True"
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
            }
            LOD 100
            Pass {
                Name "FORWARD"
                Tags {
                    "LightMode" = "ForwardBase"
                }
                Blend [_SrcBlend] [_DstBlend]
                ZWrite [_ZWrite]

                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #define UNITY_PASS_FORWARDBASE
                #include "UnityCG.cginc"
                #include "UnityPBSLighting.cginc"
                #include "UnityStandardBRDF.cginc"
                #pragma multi_compile_fwdbase
                #pragma multi_compile_fog
            // #pragma only_renderers d3d9 d3d11 glcore gles gles3 metal d3d11_9x 
             #pragma target 3.0
             uniform fixed4 _Glass_Color;
             uniform sampler2D _Refraction; 
             uniform float4 tilingOffset;
             uniform fixed _Refraction_Int;
             uniform fixed _Glass_Alpha;
             uniform fixed _Glass_AmbientLight_Int;
             uniform sampler2D _Glass_AmbientLight;
             struct VertexInput {
                 float4 vertex : POSITION;
                 float3 normal : NORMAL;
                 float4 tangent : TANGENT;
                 float2 texcoord0 : TEXCOORD0;
             };
             struct VertexOutput {
                 float4 pos : SV_POSITION;
                 float2 uv0 : TEXCOORD0;
                 float4 posWorld : TEXCOORD1;
                 float3 normalDir : TEXCOORD2;
                 float3 tangentDir : TEXCOORD3;
                 float3 bitangentDir : TEXCOORD4;
                 UNITY_FOG_COORDS(5)
             };
             float2 transform_Tex(float2 tex, float4 name)
             {
                 return tex.xy * name.xy + name.zw;
             }
             float2 ToRadialCoords(float3 coords)
             {
                 float3 normalizedCoords = normalize(coords);
                 float latitude = acos(normalizedCoords.y);
                 float longitude = atan2(normalizedCoords.z, normalizedCoords.x);
                 float2 sphereCoords = float2(longitude, latitude) * float2(0.5 / UNITY_PI, 1.0 / UNITY_PI);
                 return float2(0.5, 1.0) - sphereCoords;
             }
             VertexOutput vert(VertexInput v) {
                 VertexOutput o = (VertexOutput)0;
                 o.uv0 = v.texcoord0;
                 o.normalDir = UnityObjectToWorldNormal(v.normal);
                 o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
                 o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                 o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                 float3 lightColor = _LightColor0.rgb;
                 o.pos = UnityObjectToClipPos(v.vertex);
                 UNITY_TRANSFER_FOG(o,o.pos);
                 return o;
             }
             float4 frag(VertexOutput i) : COLOR {
                 float2 image180ScaleAndCutoff = float2(1, 1);
                 float4 layout3DScaleAndOffset = float4(0, 0, 1, 1);
                 i.normalDir = normalize(i.normalDir);
                 float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
                 float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                 float UvScale_DiffuseInt = 1.0;
                 float2 UvMult = (i.uv0 * UvScale_DiffuseInt);
                 fixed3 _Refraction_var = UnpackNormal(tex2D(_Refraction, transform_Tex(UvMult, tilingOffset)));
                 float3 normalLocal = lerp(fixed3(0,0,1),_Refraction_var.rgb,_Refraction_Int);
                 float3 normalDirection = normalize(mul(normalLocal, tangentTransform)); // Perturbed normals
                 float3 viewReflectDirection = reflect(-viewDirection, normalDirection);
                 float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
                 float3 lightColor = _LightColor0.rgb;
                 float3 halfDirection = normalize(viewDirection + lightDirection);
                 ////// Lighting:
                float attenuation = 1;
                float3 attenColor = attenuation * _LightColor0.xyz;
                float Pi = 3.141592654;
                float InvPi = 0.31830988618;
            ///////// Gloss:
                float gloss = 0.8;
                float perceptualRoughness = 1.0 - 0.8;
                float roughness = perceptualRoughness * perceptualRoughness;
                float specPow = exp2(gloss * 10.0 + 1.0);

                ////// Specular:
                float NdotL = saturate(dot(normalDirection, lightDirection));
                float LdotH = saturate(dot(lightDirection, halfDirection));
                float3 specularColor = UvScale_DiffuseInt;
                float specularMonochrome;
                float3 diffuseColor = float3(UvScale_DiffuseInt,UvScale_DiffuseInt,UvScale_DiffuseInt); // Need this for specular when using metallic
                diffuseColor = DiffuseAndSpecularFromMetallic(diffuseColor, specularColor, specularColor, specularMonochrome);
                specularMonochrome = 1.0 - specularMonochrome;
                float NdotV = abs(dot(normalDirection, viewDirection));
                float NdotH = saturate(dot(normalDirection, halfDirection));
                float VdotH = saturate(dot(viewDirection, halfDirection));
                float visTerm = SmithJointGGXVisibilityTerm(NdotL, NdotV, roughness);
                float normTerm = GGXTerm(NdotH, roughness);
                float specularPBL = (visTerm * normTerm) * UNITY_PI;
                #ifdef UNITY_COLORSPACE_GAMMA
                    specularPBL = sqrt(max(1e-4h, specularPBL));
                #endif
                specularPBL = max(0, specularPBL * NdotL);
                #if defined(_SPECULARHIGHLIGHTS_OFF)
                    specularPBL = 0.0;
                #endif
                half surfaceReduction;
                #ifdef UNITY_COLORSPACE_GAMMA
                    surfaceReduction = 1.0 - 0.28 * roughness * perceptualRoughness;
                #else
                    surfaceReduction = 1.0 / (roughness * roughness + 1.0);
                #endif
                specularPBL *= any(specularColor) ? 1.0 : 0.0;
                float3 directSpecular = attenColor * specularPBL * FresnelTerm(specularColor, LdotH);
                half grazingTerm = saturate(gloss + specularMonochrome);
                float2 tc = ToRadialCoords(viewReflectDirection);
                if (tc.x > image180ScaleAndCutoff[1])
                    return half4(0, 0, 0, 1);
                tc.x = fmod(tc.x * image180ScaleAndCutoff[0], 1);
                tc = (tc + layout3DScaleAndOffset.xy) * layout3DScaleAndOffset.zw;
                float3 indirectSpecular = tex2D(_Glass_AmbientLight, tc).rgb * _Glass_AmbientLight_Int;
                indirectSpecular *= FresnelLerp(specularColor, grazingTerm, NdotV);
                indirectSpecular *= surfaceReduction;
                float3 specular = (directSpecular + indirectSpecular);
/////// Diffuse:
                NdotL = max(0.0,dot(normalDirection, lightDirection));
                half fd90 = 0.5 + 2 * LdotH * LdotH * (1 - gloss);
                float nlPow5 = Pow5(1 - NdotL);
                float nvPow5 = Pow5(1 - NdotV);
                float3 directDiffuse = ((1 + (fd90 - 1) * nlPow5) * (1 + (fd90 - 1) * nvPow5) * NdotL) * attenColor;
                float3 indirectDiffuse = float3(0,0,0);
                indirectDiffuse += UNITY_LIGHTMODEL_AMBIENT.rgb; // Ambient Light
                float3 diffuse = (directDiffuse + indirectDiffuse) * diffuseColor* _Glass_Color.rgb;
                ////// Emissive:
                float3 emissive = _Glass_Color.rgb;
            /// Final Color:
                float3 finalColor = diffuse + specular + emissive;
                fixed4 finalRGBA = fixed4(finalColor, _Glass_Color.a);
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
        

        }
       CustomEditor "LayaGlassGUI"
            FallBack "Diffuse"
}
