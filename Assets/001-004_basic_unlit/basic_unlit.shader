﻿Shader "Tutorial/001-004_Basic_Unlit"{
	//show values to edit in inspector
	Properties{
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		// float4 _MainTex_ST; // （原有，已被自定义参数替代）
		_MyTexST ("My Tex ST", Vector) = (1,1,0,0) // 新增：自定义UV变换参数
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry" }

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader functions
			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler2D _MainTex;
			// float4 _MainTex_ST; // （原有，已被自定义参数替代）
			float4 _MyTexST; // 新增：自定义UV变换参数

			//tint of the texture
			fixed4 _Color;

			//the mesh data thats read by the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data thats passed from the vertex to the fragment shader and interpolated by the rasterizer
			struct v2f {
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			//the vertex shader function
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered correctly
				o.position = UnityObjectToClipPos(v.vertex);
				//apply the texture transforms to the UV coordinates and pass them to the v2f struct
				// o.uv = TRANSFORM_TEX(v.uv, _MainTex); // （原有，已被自定义参数替代）
				o.uv = v.uv * _MyTexST.xy + _MyTexST.zw; // 新增：用自定义参数控制UV
				return o;
			}

			//the fragment shader function
			fixed3 frag(v2f i) : SV_TARGET{
			    //read the texture color at the uv coordinate
				fixed3 col = tex2D(_MainTex, i.uv);
				//multiply the texture color and tint color
				col *= _Color;
				//return the final color to be drawn on screen
				return col;
			}
			
			ENDCG
		}
	}
	Fallback "VertexLit"
}
