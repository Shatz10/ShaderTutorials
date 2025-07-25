Shader "Tutorial/012_Fresnel" {
	//show values to edit in inspector
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)

		_FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
		[PowerSlider(4)] _FresnelExponent ("Fresnel Exponent", Range(0.25, 4)) = 1
	}
	SubShader {
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		//the shader is a surface shader, meaning that it will be extended by unity in the background to have fancy lighting and other features
		//our surface shader function is called surf and we use the standard lighting model, which means PBR lighting
		//fullforwardshadows makes sure unity adds the shadow passes the shader might need
		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0
		#pragma enable_d3d11_debug_symbols 

		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

		float3 _FresnelColor;
		float _FresnelExponent;

		//input struct which is automatically filled by unity
		struct Input {
			float2 uv_MainTex;
			float3 worldNormal;
			float3 viewDir;
			INTERNAL_DATA
		};

		//the surface shader function which sets parameters the lighting function then uses
		void surf (Input i, inout SurfaceOutputStandard o) {
			//sample and tint albedo texture
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;

			//just apply the values for metalness and smoothness
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;

			//get the dot product between the normal and the view direction
			// 计算法线和视线的点积，值范围[-1,1]，但这里通常在[0,1]之间
			// 点积越大，说明法线和视线越接近（正对摄像机，中心）；点积越小，说明越接近垂直（靠近物体边缘）
			float fresnel = dot(i.worldNormal, i.viewDir);
			//invert the fresnel so the big values are on the outside
			// Fresnel 效应在边缘最强，所以用 1 - fresnel，把中心变成0，边缘变成1
			// saturate 保证结果在[0,1]之间
			fresnel = saturate(1 - fresnel);
			//raise the fresnel value to the exponents power to be able to adjust it
			// 用幂函数调整边缘高亮的锐利程度，指数越大，边缘越细越亮
			fresnel = pow(fresnel, _FresnelExponent);
			//combine the fresnel value with a color
			// Fresnel 结果乘以颜色，得到最终的边缘高光色
			float3 fresnelColor = fresnel * _FresnelColor;
			//apply the fresnel value to the emission
			// 把 Fresnel 颜色加到自发光上，实现边缘发光效果
			o.Emission = _Emission + fresnelColor;
		}
		ENDCG
	}
	FallBack "Standard"
}

