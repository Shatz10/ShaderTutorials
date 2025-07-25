Shader "Tutorial/015_vertex_manipulation" {
	//show values to edit in inspector
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)

		_Amplitude ("Wave Size", Range(0,1)) = 0.4
		_Frequency ("Wave Freqency", Range(1, 8)) = 2
		_AnimationSpeed ("Animation Speed", Range(0,5)) = 1
	}
	SubShader {
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		//the shader is a surface shader, meaning that it will be extended by unity in the background 
		//to have fancy lighting and other features
		//our surface shader function is called surf and we use our custom lighting model
		//fullforwardshadows makes sure unity adds the shadow passes the shader might need
		//vertex:vert makes the shader use vert as a vertex shader function
		//addshadows tells the surface shader to generate a new shadow pass based on out vertex shader
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
		#pragma target 3.0

		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

		float _Amplitude;
		float _Frequency;
		float _AnimationSpeed;

		//input struct which is automatically filled by unity
		struct Input {
			float2 uv_MainTex;
		};

		void vert(inout appdata_full data){
			// 复制当前顶点位置
			float4 modifiedPos = data.vertex;
			// 用正弦函数让顶点的 y 坐标随 x 坐标和时间变化，实现波浪效果
			modifiedPos.y += sin(data.vertex.x * _Frequency + _Time.y * _AnimationSpeed) * _Amplitude;
			
			// 计算沿切线方向微小偏移后的顶点位置
			float3 posPlusTangent = data.vertex + data.tangent * 0.01;
			// 对偏移后的位置同样进行波浪扰动
			posPlusTangent.y += sin(posPlusTangent.x * _Frequency + _Time.y * _AnimationSpeed) * _Amplitude;

			// 通过法线和切线叉积得到副切线（bitangent）
			float3 bitangent = cross(data.normal, data.tangent);
			// 计算沿副切线微小偏移后的顶点位置
			float3 posPlusBitangent = data.vertex + bitangent * 0.01;
			// 对副切线偏移后的位置同样进行波浪扰动
			posPlusBitangent.y += sin(posPlusBitangent.x * _Frequency + _Time.y * _AnimationSpeed) * _Amplitude;

			// 得到扰动后切线和副切线的方向向量
			float3 modifiedTangent = posPlusTangent - modifiedPos;
			float3 modifiedBitangent = posPlusBitangent - modifiedPos;

			// 用扰动后的切线和副切线重新计算法线，实现法线随顶点波动而动态变化
			float3 modifiedNormal = cross(modifiedTangent, modifiedBitangent);
			data.normal = normalize(modifiedNormal);
			
			// 把最终的顶点位置写回，完成顶点的波动变形
			data.vertex = modifiedPos;
		}

		//the surface shader function which sets parameters the lighting function then uses
		void surf (Input i, inout SurfaceOutputStandard o) {
			//sample and tint albedo texture
			fixed4 col = tex2D(_MainTex, i.uv_MainTex);
			col *= _Color;
			o.Albedo = col.rgb;
			//just apply the values for metalness, smoothness and emission
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Emission = _Emission;
		}
		ENDCG
	}
	FallBack "Standard"
}

