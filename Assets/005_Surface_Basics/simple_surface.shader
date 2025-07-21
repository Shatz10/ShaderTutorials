Shader "Tutorial/005_surface" {
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

		struct Input {
			float2 uv_MainTex;
		};

		void surf (Input i, inout SurfaceOutputStandard o) {
			// 用主纹理和 UV 坐标采样颜色
			fixed4 col = tex2D(_MainTex, i.uv_MainTex); // 见上面注释2、3
			// 乘以 Tint 色
			col *= _Color;
			// 把结果赋值给 Albedo（基础色）
			o.Albedo = col.rgb; // 见上面注释1
			// 金属度：控制表面是金属还是非金属，1为完全金属，0为非金属
			o.Metallic = _Metallic;
			// 光滑度：控制表面高光/反射的锐利程度，1为非常光滑（镜面），0为粗糙
			o.Smoothness = _Smoothness;
			// 自发光：让物体自己发光，不受光照影响
			o.Emission = _Emission;
		}
		ENDCG
	}
	FallBack "Standard"
}