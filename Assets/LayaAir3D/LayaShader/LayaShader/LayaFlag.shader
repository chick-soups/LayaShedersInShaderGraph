// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "LayaAir3D/LayaFlagMaterial"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.01
		albedoTexture("Albedo", 2D) = "white" {}
			// _MainTex("Albedo", 2D) = "white" {}
		smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
		smoothnessTextureScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Toggle][HideInInspector] useSmoothTexture("useSmoothTexture", Float) = 0.0
		smoothnessTexture("smoothnessTexture", 2D) = "white" {}
		[Gamma] metallic("Metallic", Range(0.0, 1.0)) = 0.0
		metallicGlossTexture("Metallic", 2D) = "white" {}
		normalTextureScale("Scale", Float) = 1.0
		normalTexture("Normal Map", 2D) = "bump" {}
		parallaxTextureScale("Height Scale", Range(0.005, 0.08)) = 0.02
		parallaxTexture("Height Map", 2D) = "black" {}
		occlusionTextureStrength("Strength", Range(0.0, 1.0)) = 1.0
		occlusionTexture("Occlusion", 2D) = "white" {}
		_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}
		tilingOffset("TillingOffset",Vector) = (1.0,1.0,0.0,0.0)
		[Toggle][HideInInspector] _IsDayTime("IsDayTime", Float) = 0.0
		//[HideInInspector] EmissionStrength("Emission Strength", Range(0.0, 1.0)) = 0.0
		[HideInInspector] EmissionStrengthTexture("Emission Strength", 2D) = "black" {}
		//[HideInInspector] dayNightTexture("Day and night", 2D) = "white" {}
		[HideInInspector] _Mode("__mode", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0

		[HideInInspector] _Frequency("Frequency", float) = 1                   	      //波动频率
		[HideInInspector] _AmplitudeStrength("Amplitude Strength", float) = 1           // 振幅强度
		[HideInInspector] _InvWaveLength("Inverse Wave Length", float) = 1             //波长的倒数（_InvWaveLength越小，波长越大）
		[HideInInspector] _Fold("Fold", Range(0.0, 2.0)) = 0.5                         //旗帜褶皱程度
		[HideInInspector] _TextureRow("TextureRow",Int) = 5
		[Toggle][HideInInspector] _LocalU("localU", Float) = 0.0						//锁定轴
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 300

		Pass
		{
			Name "FORWARD"
			Tags{"LightMode" = "ForwardBase"}

			Blend[_SrcBlend][_DstBlend]
			ZWrite[_ZWrite]

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature NORMALTEXTURE
			#pragma shader_feature _ ALPHATEST TRANSPARENTBLEND
			#pragma shader_feature _EMISSION
			#pragma shader_feature METALLICGLOSSTEXTURE
			#pragma shader_feature _ SMOOTHNESSSOURCE_ALBEDOTEXTURE_ALPHA
			#pragma shader_feature PARALLAXTEXTURE
			#pragma shader_feature _SMOOTHTEXTURE_
			#pragma shader_feature LOCALUVALUE

			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex vertFlagForwardBase
			#pragma fragment fragForwardBaseInternal

			#pragma multi_compile_fog
			#define LayaStandardPBR  1

			#include "../CGIncludes/LayaStandardcore.cginc"

			float _Frequency;
			float _AmplitudeStrength;
			float _InvWaveLength;
			float _Fold;
			int _TextureRow;
			VertexOutputForwardBase vertFlagForwardBase(VertexInput v)
			{
				VertexOutputForwardBase o;
				o = (VertexOutputForwardBase)0;
				float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
				o.tangentToWorldAndPackedData[0].w = posWorld.x;
				o.tangentToWorldAndPackedData[1].w = posWorld.y;
				o.tangentToWorldAndPackedData[2].w = posWorld.z;
				o.posWorld = posWorld.xyz;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.eyeVec.xyz = LayaNormalizePerVertexNormal(posWorld.xyz - _WorldSpaceCameraPos);
				o.tex = layaTexCoords(v);
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);

				// 初始化顶点偏移量
				float4 offset = float4(0.0, 0.0, 0.0, 0.0);
				// 计算偏移之前的顶点位置
				float4 v_before = mul(unity_ObjectToWorld, v.vertex);
				// 我们只希望对顶点的 Y 方向进行偏移（正弦型函数y=Asin(ωx+φ)+b）
				float percent = v.uv1.x;
				#ifdef LOCALUVALUE
					percent *= 1-v.uv1.y;
				#endif
				offset.y = _AmplitudeStrength * sin(_Frequency * _Time.y + (v_before.x + v_before.y) * _Fold * _InvWaveLength) * percent;

				//我们只需要把偏移量添加到顶点位置上，再进行正常的顶点变换即可
				o.pos = UnityObjectToClipPos(v.vertex + offset);

#ifdef _TANGENT_TO_WORLD
				float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				float3x3 tangentToWorld = CreateTangentToWorldPerVertex(normalWorld, tangentWorld.xyz, tangentWorld.w);
				o.tangentToWorldAndPackedData[0].xyz = tangentToWorld[0];
				o.tangentToWorldAndPackedData[1].xyz = tangentToWorld[1];
				o.tangentToWorldAndPackedData[2].xyz = tangentToWorld[2];
#else
				o.tangentToWorldAndPackedData[0].xyz = 0;
				o.tangentToWorldAndPackedData[1].xyz = 0;
				o.tangentToWorldAndPackedData[2].xyz = normalWorld;
#endif
				UNITY_TRANSFER_LIGHTING(o, v.uv1);
				o.ambientOrLightmapUV = LayaVertexGIForward(v, posWorld, normalWorld);
#ifdef PARALLAXTEXTURE
				TANGENT_SPACE_ROTATION;
				half3 viewDirForParallax = mul(rotation, ObjSpaceViewDir(v.vertex));
				o.tangentToWorldAndPackedData[0].w = viewDirForParallax.x;
				o.tangentToWorldAndPackedData[1].w = viewDirForParallax.y;
				o.tangentToWorldAndPackedData[2].w = viewDirForParallax.z;
#endif
				UNITY_TRANSFER_FOG_COMBINED_WITH_EYE_VEC(o, o.pos);

				return o;
			}
			ENDCG
		}
		Pass
		{
			Name "FORWARD_DELTA"
			Tags { "LightMode" = "ForwardAdd" }
			Blend[_SrcBlend] One
			Fog { Color(0,0,0,0)}
			ZWrite Off
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature NORMALTEXTURE
			#pragma shader_feature _ ALPHATEST TRANSPARENTBLEND
			#pragma shader_feature METALLICGLOSSTEXTURE
			#pragma shader_feature _ SMOOTHNESSSOURCE_ALBEDOTEXTURE_ALPHA
			#pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature ___ _DETAIL_MULX2
			#pragma shader_feature PARALLAXTEXTURE
			#pragma shader_feature ISDAYTIME


			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex vertForwardAdd
			#pragma fragment fragForwardAddInternal
			#define LayaStandardPBR  1

			#include "UnityPBSLighting.cginc"
			#include "AutoLight.cginc"
			#include "../CGIncludes/LayaStandardcore.cginc"

			ENDCG

		}

		// ------------------------------------------------------------------
	 // Extracts information for lightmapping, GI (emission, albedo, ...)
	 // This pass it not used during regular rendering.
	 Pass
	 {
		 Name "META"
		 Tags { "LightMode" = "Meta" }

		 Cull Off

		 CGPROGRAM
		 #pragma vertex vert_meta
		 #pragma fragment frag_meta

		 #pragma shader_feature _EMISSION
		 #pragma shader_feature_local _METALLICGLOSSMAP
		 #pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
		 #pragma shader_feature_local _DETAIL_MULX2
		 #pragma shader_feature EDITOR_VISUALIZATION

		 #include "UnityStandardMeta.cginc"
		 ENDCG
	 }
	}
	CustomEditor "FlagShaderGUI"
	FallBack "Standard"
}
