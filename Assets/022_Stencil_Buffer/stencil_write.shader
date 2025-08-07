Shader "Tutorial/022_stencil_buffer/write"{
	//show values to edit in inspector
	Properties{
		[IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 0
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		// 材质完全不透明，与其他不透明几何体同时渲染
		Tags{ "RenderType"="Opaque" "Queue"="Geometry-1"}

		//stencil operation
		// 模板缓冲区写入操作
		// 在模板缓冲区中标记特定区域，供后续读取着色器使用
		// 这里写入的_StencilRef值将成为"当前像素的模板值"
		Stencil{
			Ref [_StencilRef]    // 模板参考值，要写入的值
			Comp Always          // 总是通过比较
			Pass Replace         // 通过时替换模板值
			// Pass Keep         // 保持原值，不写入新值
		}

		Pass{
			//don't draw color or depth
			// 不绘制颜色或深度，只写入模板缓冲区
			Blend Zero One
			ZWrite Off

			CGPROGRAM
			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag

			struct appdata{
				float4 vertex : POSITION;
			};

			struct v2f{
				float4 position : SV_POSITION;
			};

			v2f vert(appdata v){
				v2f o;
				//calculate the position in clip space to render the object
				// 计算裁剪空间中的位置来渲染对象
				o.position = UnityObjectToClipPos(v.vertex);
				return o;
			}

			// 片段着色器返回透明色
			// 这个着色器只用于写入模板缓冲区，不渲染可见颜色
			fixed4 frag(v2f i) : SV_TARGET{
				return 0;
			}

			ENDCG
		}
	}
}
