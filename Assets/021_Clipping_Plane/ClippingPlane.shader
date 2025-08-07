Shader "Tutorial/021_Clipping_Plane"{
	//show values to edit in inspector
	Properties{
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR]_Emission ("Emission", color) = (0,0,0)

		[HDR]_CutoffColor("Cutoff Color", Color) = (1,0,0,0)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		// render faces regardless if they point towards the camera or away from it
		Cull Off

		CGPROGRAM
		//the shader is a surface shader, meaning that it will be extended by unity in the background 
		//to have fancy lighting and other features
		//our surface shader function is called surf and we use our custom lighting model
		//fullforwardshadows makes sure unity adds the shadow passes the shader might need
		//vertex:vert makes the shader use vert as a vertex shader function
		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

		float4 _Plane;

		float4 _CutoffColor;

		//input struct which is automatically filled by unity
		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float facing : VFACE;
		};

		//the surface shader function which sets parameters the lighting function then uses
		// 表面着色器函数，设置光照函数使用的参数
		void surf (Input i, inout SurfaceOutputStandard o) {
			//calculate signed distance to plane
			// 计算点到平面的有符号距离
			// dot(i.worldPos, _Plane.xyz)：计算点沿平面法线方向的投影距离
			// 正值表示点在法线方向（平面"上方"），负值表示点在法线反方向（平面"下方"）
			float distance = dot(i.worldPos, _Plane.xyz);
			// 加上平面到原点的偏移量，得到完整的有符号距离
			distance = distance + _Plane.w;
			//discard surface above plane
			// 丢弃平面法线方向上的所有片段（裁剪操作）
			// 当distance > 0时，-distance < 0，片段被丢弃
			clip(-distance);

			// 将面朝向信息转换为插值因子
			// i.facing：正面=1.0，背面=-1.0
			// 转换后：正面=1.0，背面=0.0
			// 用于区分正面和背面的材质属性
			// lerp() 函数期望插值因子在 [0,1] 范围内，而 i.facing 的范围是 [-1,1]
			float facing = i.facing * 0.5 + 0.5;
			// 正面和背面互换，现在内部是原本的颜色，外面是裁剪面的颜色
			// float facing = -i.facing * 0.5 + 0.5;
			
			//normal color stuff
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb * facing;
			o.Metallic = _Metallic * facing;
			o.Smoothness = _Smoothness * facing;
			o.Emission = lerp(_CutoffColor, _Emission, facing);
		}
		ENDCG
	}
	FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}