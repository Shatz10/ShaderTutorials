Shader "Tutorial/022_stencil_buffer/read" {
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)

		[IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 0
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		//stencil operation
		// 模板缓冲区读取操作
		// 只在模板值等于_StencilRef的像素上渲染
		// 这是硬件级的早期测试，在片段着色器之前自动执行
		// 比较过程：当前像素模板值（来自write阶段） == _StencilRef（read阶段设置）
		Stencil{
			Ref [_StencilRef]    // 模板参考值，要匹配的值
			Comp Equal           // 比较操作：只在和_StencilRef模板值相等时渲染
		}

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

		// 表面着色器函数
		// 只有通过模板测试的像素才会执行这里的代码
		// 模板测试是硬件级的，在片段着色器之前自动执行
		// 模板测试通过条件：write阶段写入的值 == read阶段的_StencilRef值
		void surf (Input i, inout SurfaceOutputStandard o) {
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Emission = _Emission;
		}
		ENDCG
	}
	FallBack "Standard"
}