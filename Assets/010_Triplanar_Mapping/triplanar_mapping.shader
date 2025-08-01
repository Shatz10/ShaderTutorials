﻿Shader "Tutorial/010_Triplanar_Mapping"{
	//show values to edit in inspector
	Properties{
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Sharpness ("Blend sharpness", Range(1, 64)) = 1
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;
			float _Sharpness;

			struct appdata{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float3 normal : NORMAL;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate world position of vertex
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = worldPos.xyz;
				// 法线只受旋转和缩放影响，不受位移影响，所以只取4x4矩阵的前3x3部分（旋转和缩放），忽略位移部分。
				// 这样可以正确地将法线从物体空间变换到世界空间。
				// 理论上，法线变换应使用ObjectToWorld的逆转置矩阵（Inverse Transpose），以保证在有非均匀缩放时法线方向正确。
				// 但如果模型没有非均匀缩放（只有旋转和平移），此时逆矩阵（unity_WorldToObject）和逆转置矩阵效果一样，所以直接用逆矩阵也能得到正确结果。
				float3 worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
				o.normal = normalize(worldNormal);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				// return fixed4(i.normal.xyz, 1);
				
				//calculate UV coordinates for three projections
				float2 uv_front = TRANSFORM_TEX(i.worldPos.xy, _MainTex);
				float2 uv_side = TRANSFORM_TEX(i.worldPos.zy, _MainTex);
				float2 uv_top = TRANSFORM_TEX(i.worldPos.xz, _MainTex);
				
				//read texture at uv position of the three projections
				fixed4 col_front = tex2D(_MainTex, uv_front);
				fixed4 col_side = tex2D(_MainTex, uv_side);
				fixed4 col_top = tex2D(_MainTex, uv_top);

				//generate weights from world normals
				float3 weights = i.normal;
				//show texture on both sides of the object (positive and negative)
				weights = abs(weights);
				//make the transition sharper
				weights = pow(weights, _Sharpness);
				//make it so the sum of all components is 1
				weights = weights / (weights.x + weights.y + weights.z);

				//combine weights with projected colors
				col_front *= weights.z;
				col_side *= weights.x;
				col_top *= weights.y;

				//combine the projected colors
				fixed4 col = col_front + col_side + col_top;

				//multiply texture color with tint color
				col *= _Color;

				return col;
			}

			ENDCG
		}
	}
	FallBack "Standard" //fallback adds a shadow pass so we get shadows on other objects
}