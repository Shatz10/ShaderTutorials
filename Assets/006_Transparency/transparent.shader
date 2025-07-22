Shader "Tutorial/006_Basic_Transparency"{
	Properties{
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader{
		Tags{ "RenderType"="Transparent" "Queue"="Transparent"}

		// 启用混合模式，实现半透明效果：
		// SrcAlpha 表示源颜色的 alpha 值（当前像素的透明度）
		// OneMinusSrcAlpha 表示 1 - 源颜色的 alpha 值（背景保留的比例）
		// 最终颜色 = 源颜色 * 源Alpha + 背景颜色 * (1 - 源Alpha)
		Blend SrcAlpha OneMinusSrcAlpha
		ZWrite off

		Pass{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;
			float4 _MainTex_ST;

			fixed4 _Color;

			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(appdata v){
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_TARGET{
				fixed4 col = tex2D(_MainTex, i.uv);
				col *= _Color;
				return col;
			}

			ENDCG
		}
	}
}