// Shader targeted for low end devices. Single Pass Forward Rendering.
Shader "PlanarShadow/Shadow"
{
	// Keep properties of StandardSpecular shader for upgrade reasons.
	Properties
	{
		[MainTexture] _BaseColor("Base Color", Color) = (1, 1, 1, 1)
		[MainColor] _BaseMap("Base Map (RGB) Smoothness / Alpha (A)", 2D) = "white" {}

		_Cutoff("Alpha Clipping", Range(0.0, 1.0)) = 0.5

		_SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0.5)
		_SpecGlossMap("Specular Map", 2D) = "white" {}
		[Enum(Specular Alpha,0,Albedo Alpha,1)] _SmoothnessSource("Smoothness Source", Float) = 0.0
		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0

		[HideInInspector] _BumpScale("Scale", Float) = 1.0
		[NoScaleOffset] _BumpMap("Normal Map", 2D) = "bump" {}

		_EmissionColor("Emission Color", Color) = (0,0,0)
		[NoScaleOffset]_EmissionMap("Emission Map", 2D) = "white" {}

		// Blending state
		[HideInInspector] _Surface("__surface", Float) = 0.0
		[HideInInspector] _Blend("__blend", Float) = 0.0
		[HideInInspector] _AlphaClip("__clip", Float) = 0.0
		[HideInInspector] _SrcBlend("__src", Float) = 1.0
		[HideInInspector] _DstBlend("__dst", Float) = 0.0
		[HideInInspector] _ZWrite("__zw", Float) = 1.0
		[HideInInspector] _Cull("__cull", Float) = 2.0

		[ToogleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

			// Editmode props
			[HideInInspector] _QueueOffset("Queue offset", Float) = 0.0
			[HideInInspector] _Smoothness("SMoothness", Float) = 0.5

			// ObsoleteProperties
			[HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
			[HideInInspector] _Color("Base Color", Color) = (1, 1, 1, 1)
			[HideInInspector] _Shininess("Smoothness", Float) = 0.0
			[HideInInspector] _GlossinessSource("GlossinessSource", Float) = 0.0
			[HideInInspector] _SpecSource("SpecularHighlights", Float) = 0.0


			 _ShadowInvLen("ShadowInvLen", float) = 1.0 //0.4449261
	}

		SubShader
			{
				Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"}
				LOD 300
				Pass
				{
					Name "Universal2D"
					Tags{ "LightMode" = "UniversalForward" }
				//Tags{"LightMode" = "LightweightForward"}
				//Tags{"LightMode" = "SRPDefaultUnlit"}
				Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }

				HLSLPROGRAM
				// Required to compile gles 2.0 with standard srp library
				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x

				#pragma vertex vert
				#pragma fragment frag
				#pragma shader_feature _ALPHATEST_ON
				#pragma shader_feature _ALPHAPREMULTIPLY_ON

				#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
				ENDHLSL
			}

			Pass
			{
				Name "Universal2D"
				Tags{ "LightMode" = "Universal2D" }
				Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }

				HLSLPROGRAM
				// Required to compile gles 2.0 with standard srp library
				#pragma prefer_hlslcc gles
				#pragma exclude_renderers d3d11_9x

				#pragma vertex vert
				#pragma fragment frag
				#pragma shader_feature _ALPHATEST_ON
				#pragma shader_feature _ALPHAPREMULTIPLY_ON

				#include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
				#include "Packages/com.unity.render-pipelines.universal/Shaders/Utils/Universal2D.hlsl"
				ENDHLSL
			}


			Pass
			{

					//Tags{"LightMode" = "ShadowCaster"}
					Tags{"LightMode" = "SRPDefaultUnlit"}
					//Tags{"LightMode" = "ShadowCaster"}
					//Tags{"LightMode" = "LightweightForward"}
					//Tags{"LightMode" = "SRPDefaultUnlit"}
					Blend SrcAlpha  OneMinusSrcAlpha
					ZWrite Off
					Cull Back
					ColorMask RGB

					Stencil
					{
						Ref 0
						Comp Equal
						WriteMask 255
						ReadMask 255
				//Pass IncrSat
				Pass Invert
				Fail Keep
				ZFail Keep
			}

			//CGPROGRAM
			HLSLPROGRAM
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#pragma vertex vert
			#pragma fragment frag

			CBUFFER_START(UnityPerFrame)
	        float4x4 unity_MatrixVP;
            CBUFFER_END

            CBUFFER_START(UnityPerDraw)
	        float4x4 unity_ObjectToWorld;
            CBUFFER_END
            #define UNITY_MATRIX_M unity_ObjectToWorld
			float4 _ShadowPlane;
			float4 _ShadowProjDir;
			float4 _WorldPos;
			float _ShadowInvLen;
			float4 _ShadowFadeParams;
			float _ShadowFalloff;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 xlv_TEXCOORD0 : TEXCOORD0;
				float3 xlv_TEXCOORD1 : TEXCOORD1;
			};

			v2f vert(appdata v)
			{
				v2f o;
				float3 lightdir = normalize(_ShadowProjDir);
				//float3 worldpos = mul(unity_ObjectToWorld, v.vertex).xyz;
				//float3 worldpos = TransformObjectToWorld(v.vertex.xyz);
				float4 worldPos = mul(UNITY_MATRIX_M, float4(v.vertex.xyz, 1.0));
				// _ShadowPlane.w = p0 * n  // 平面的w分量就是p0 * n
				float distance = (_ShadowPlane.w - dot(_ShadowPlane.xyz, worldPos.xyz)) / dot(_ShadowPlane.xyz, lightdir.xyz);
				worldPos = worldPos + distance * float4(lightdir.xyz, 0.0);
				//o.vertex = mul(unity_MatrixVP, float4(worldpos, 1.0));
				//o.vertex = TransformWorldToHClip(float4(worldpos, 1.0));
				o.vertex = mul(unity_MatrixVP, worldPos);
				o.xlv_TEXCOORD0 = _WorldPos.xyz;
				o.xlv_TEXCOORD1 = worldPos;
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float3 posToPlane_2 = (i.xlv_TEXCOORD0 - i.xlv_TEXCOORD1);
				float4 color;
				color.xyz = float3(0.0, 0.0, 0.0);

				// 下面两种阴影衰减公式都可以使用(当然也可以自己写衰减公式)
				// 王者荣耀的衰减公式
				color.w = (pow((1.0 - clamp(((sqrt(dot(posToPlane_2, posToPlane_2)) * _ShadowInvLen) - _ShadowFadeParams.x), 0.0, 1.0)), _ShadowFadeParams.y) * _ShadowFadeParams.z);

				// 另外的阴影衰减公式
				//color.w = 1.0 - saturate(distance(i.xlv_TEXCOORD0, i.xlv_TEXCOORD1) * _ShadowFalloff);

				return color;
			}
			//ENDCG
			ENDHLSL
		}
			}
				Fallback "Hidden/Universal Render Pipeline/FallbackError"
				//  CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.SimpleLitShader"
}





