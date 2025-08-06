Shader "Tutorial/019_OutlinesPostprocessed"
{
	//show values to edit in inspector
	Properties{
		[HideInInspector]_MainTex ("Texture", 2D) = "white" {}
		_OutlineColor ("Outline Color", Color) = (0,0,0,1)
		_NormalMult ("Normal Outline Multiplier", Range(0,4)) = 1
		_NormalBias ("Normal Outline Bias", Range(1,4)) = 1
		_DepthMult ("Depth Outline Multiplier", Range(0,4)) = 1
		_DepthBias ("Depth Outline Bias", Range(1,4)) = 1
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
			//the depth normals texture
			sampler2D _CameraDepthNormalsTexture;
			//texelsize of the depthnormals texture
			float4 _CameraDepthNormalsTexture_TexelSize;

			//variables for customising the effect
			float4 _OutlineColor;
			float _NormalMult;
			float _NormalBias;
			float _DepthMult;
			float _DepthBias;

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

			// 比较当前像素与相邻像素的深度和法线差异
			// inout参数：深度轮廓和法线轮廓的累积值
			// baseDepth/baseNormal：当前像素的深度和法线
			// uv：当前像素的UV坐标
			// offset：相邻像素的偏移量（如(1,0)表示右侧像素）
			void Compare(inout float depthOutline, inout float normalOutline, 
					float baseDepth, float3 baseNormal, float2 uv, float2 offset){
				// 读取相邻像素的深度法线数据
				float4 neighborDepthnormal = tex2D(_CameraDepthNormalsTexture, 
						uv + _CameraDepthNormalsTexture_TexelSize.xy * offset);
				float3 neighborNormal;
				float neighborDepth;
				// 解码深度法线纹理，提取深度和法线信息
				DecodeDepthNormal(neighborDepthnormal, neighborDepth, neighborNormal);
				// 将深度值转换为世界空间距离
				neighborDepth = neighborDepth * _ProjectionParams.z;

				// 计算深度差异（正值表示当前像素更近）
				float depthDifference = baseDepth - neighborDepth;
				// 累积深度轮廓值
				depthOutline = depthOutline + depthDifference;

				// 计算法线向量差异
				float3 normalDifference = baseNormal - neighborNormal;
				// 将3D向量差异转换为标量值（曼哈顿距离）|Δx| + |Δy| + |Δz|
				// 这样可以高效地检测法线在任意方向上的变化
				normalDifference = normalDifference.r + normalDifference.g + normalDifference.b;
				// 累积法线轮廓值
				normalOutline = normalOutline + normalDifference;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{
				//read depthnormal
				float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);

				//decode depthnormal
				float3 normal;
				float depth;
				DecodeDepthNormal(depthnormal, depth, normal);

				//get depth as distance from camera in units 
				depth = depth * _ProjectionParams.z;

				float depthDifference = 0;
				float normalDifference = 0;

				Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(1, 0));
				Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, 1));
				Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(0, -1));
				Compare(depthDifference, normalDifference, depth, normal, i.uv, float2(-1, 0));

				depthDifference = depthDifference * _DepthMult;
				depthDifference = saturate(depthDifference);
				depthDifference = pow(depthDifference, _DepthBias);

				normalDifference = normalDifference * _NormalMult;
				normalDifference = saturate(normalDifference);
				normalDifference = pow(normalDifference, _NormalBias);

				float outline = normalDifference + depthDifference;
				float4 sourceColor = tex2D(_MainTex, i.uv);
				float4 color = lerp(sourceColor, _OutlineColor, outline);
				return color;
			}
			ENDCG
		}
	}
}
