Shader "Tutorial/018_Normal_Postprocessing"{
	//show values to edit in inspector
	Properties{
		[HideInInspector]_MainTex ("Texture", 2D) = "white" {}
		_upCutoff ("up cutoff", Range(0,1)) = 0.7
		_topColor ("top color", Color) = (1,1,1,1)
	}

	SubShader{
		// markers that specify that we don't need culling 
		// or comparing/writing to the depth buffer
		Cull Off
		ZWrite Off 
		ZTest Always

		Pass{
			CGPROGRAM
			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//the rendered screen so far
			sampler2D _MainTex;
			//matrix to convert from view space to world space
			float4x4 _viewToWorld;
			
			//the depth normals texture
			//Unity 自动提供的深度法线纹理
			//当在C#脚本中设置 cam.depthTextureMode |= DepthTextureMode.DepthNormals 时
			//Unity会自动生成这个纹理，并在shader中通过这个名称自动绑定
			//无需手动声明或设置，这是Unity的内置功能
			//
			//深度法线纹理 vs 法线纹理的区别：
			//1. 深度法线纹理：包含深度+法线信息，RGBA四通道编码
			//   - R,G: 编码的法线XY分量
			//   - B,A: 编码的深度信息
			//   - 适用：需要同时使用深度和法线的后处理效果
			//2. 法线纹理：只包含法线信息，RGB三通道
			//   - 直接存储法线XYZ分量
			//   - 适用：只需要法线信息的场景，性能更好
			sampler2D _CameraDepthNormalsTexture;

			//effect customisation
			float _upCutoff;
			float4 _topColor;


			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				//从Unity自动提供的深度法线纹理中读取数据
				//这个纹理包含了每个像素的深度和法线信息
				//RGBA四个通道分别编码了法线XY分量和深度信息
				float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

				//解码深度法线数据
				//DecodeDepthNormal是Unity提供的函数，用于从深度法线纹理中提取深度和法线
				//输入：depthnormal (RGBA编码的数据)
				//输出：depth (0-1范围的深度值), normal (视图空间法线)
				//
				//DecodeDepthNormal的实际实现原理：
				//1. 法线解码：直接从RG通道读取编码的法线XY分量
				//   - depthnormal.xy 包含编码的法线XY分量
				//   - 法线Z分量通过 Z = sqrt(1 - X² - Y²) 计算得出
				//2. 深度解码：使用DecodeFloatRG函数解码BA通道
				//   - depthnormal.zw 包含编码的深度信息
				//   - DecodeFloatRG(depthnormal.zw) 将两个通道解码为浮点数
				//
				//手动解码示例（如果不用DecodeDepthNormal函数）：
				//float3 normal;
				//normal.xy = depthnormal.xy * 2.0 - 1.0;  // 从[0,1]转换到[-1,1]
				//normal.z = sqrt(1.0 - dot(normal.xy, normal.xy));  // 计算Z分量
				//float depth = DecodeFloatRG(depthnormal.zw);  // 解码深度
				float3 normal;
				float depth;
				DecodeDepthNormal(depthnormal, depth, normal);

				//将深度转换为从相机到远裁剪面的距离（以世界单位计）
				//_ProjectionParams.z 是远裁剪面的距离
				//depth原本是0-1范围，乘以远裁剪面距离得到实际距离
				depth = depth * _ProjectionParams.z;

				//将法线从视图空间转换到世界空间
				//_viewToWorld矩阵是从C#脚本传递过来的相机视图到世界空间的变换矩阵
				//只取3x3部分进行法线变换（忽略位移部分）
				normal = mul((float3x3)_viewToWorld, normal);
				// // 正确的变换顺序
				// worldNormal = viewToWorldMatrix × viewNormal
				// // 数学表示
				// [worldNormal.x]   [m11 m12 m13]   [viewNormal.x]
				// [worldNormal.y] = [m21 m22 m23] × [viewNormal.y]
				// [worldNormal.z]   [m31 m32 m33]   [viewNormal.z]


				// // 这是错误的！
				// worldNormal = viewNormal × viewToWorldMatrix
				// // 数学上无法计算
				// [viewNormal.x]   [m11 m12 m13]   = ???
				// [viewNormal.y] × [m21 m22 m23]   = 维度不匹配
				// [viewNormal.z]   [m31 m32 m33]

				//计算法线与上方向(0,1,0)的点积，得到"向上"的程度
				//点积结果范围：-1到1，值越大表示法线越向上
				float up = dot(float3(0,1,0), normal);
				//使用step函数：如果up >= _upCutoff则返回1，否则返回0
				//这创建了一个硬边界，只有足够"向上"的表面才会被着色
				up = step(_upCutoff, up);
				
				//读取原始渲染结果（屏幕纹理）
				float4 source = tex2D(_MainTex, i.uv);
				//根据up值混合原始颜色和顶部颜色
				//up * _topColor.a 控制混合强度
				//lerp函数：在source和_topColor之间进行线性插值
				float4 col = lerp(source, _topColor, up * _topColor.a);
				return col;
			}
			ENDCG
		}
	}
}

