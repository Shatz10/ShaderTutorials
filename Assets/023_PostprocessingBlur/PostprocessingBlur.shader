Shader "Tutorial/023_Postprocessing_Blur"{
	//show values to edit in inspector
	// 后处理模糊着色器：实现分离式高斯模糊
	// 包含两个Pass：垂直模糊（Pass 0）和水平模糊（Pass 1）
	Properties{
		[HideInInspector]_MainTex ("Texture", 2D) = "white" {}
		_BlurSize("Blur Size", Range(0,0.5)) = 0
		[KeywordEnum(Low, Medium, High)] _Samples ("Sample amount", Float) = 0
		[Toggle(GAUSS)] _Gauss ("Gaussian Blur", float) = 0
		[PowerSlider(3)]_StandardDeviation("Standard Deviation (Gauss only)", Range(0.00, 0.3)) = 0.02
	}

	SubShader{
		// markers that specify that we don't need culling 
		// or reading/writing to the depth buffer
		// 标记：不需要剔除、深度缓冲读写，因为这是全屏后处理
		Cull Off
		ZWrite Off 
		ZTest Always


		//Vertical Blur
		// 垂直模糊Pass（Pass 0）：只在Y方向进行模糊
		Pass{
			CGPROGRAM
			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _SAMPLES_LOW _SAMPLES_MEDIUM _SAMPLES_HIGH
			// #pragma shader_feature GAUSS

			//texture and transforms of the texture
			// 纹理和变换参数
			sampler2D _MainTex;
			float _BlurSize;
			float _StandardDeviation;

			#define PI 3.14159265359
			#define E 2.71828182846

		#if _SAMPLES_LOW
			#define SAMPLES 10
		#elif _SAMPLES_MEDIUM
			#define SAMPLES 30
		#else
			#define SAMPLES 100
		#endif

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
			// 片段着色器：实现垂直方向的模糊采样
			fixed4 frag(v2f i) : SV_TARGET{
			#if GAUSS
				//failsafe so we can use turn off the blur by setting the deviation to 0
				// 安全措施：当标准差为0时关闭模糊
				if(_StandardDeviation == 0)
				return tex2D(_MainTex, i.uv);
			#endif
				//init color variable
				// 初始化颜色变量
				float4 col = 0;
			#if GAUSS
				float sum = 0;
			#else
				float sum = SAMPLES;
			#endif
				//iterate over blur samples
				// 遍历模糊采样点
				for(float index = 0; index < SAMPLES; index++){
					//get the offset of the sample
					// 计算采样偏移量（垂直方向）
					float offset = (index/(SAMPLES-1) - 0.5) * _BlurSize;
					//get uv coordinate of sample
					// 获取采样点的UV坐标（只在Y方向偏移）
					float2 uv = i.uv + float2(0, offset);
				#if !GAUSS
					//simply add the color if we don't have a gaussian blur (box)
					// 简单盒式模糊：直接累加颜色
					col += tex2D(_MainTex, uv);
				#else
					//calculate the result of the gaussian function
					// 计算高斯函数结果
					float stDevSquared = _StandardDeviation*_StandardDeviation;
					float gauss = (1 / sqrt(2*PI*stDevSquared)) * pow(E, -((offset*offset)/(2*stDevSquared)));
					//add result to sum
					// 累加高斯权重
					sum += gauss;
					//multiply color with influence from gaussian function and add it to sum color
					// 用高斯权重乘以颜色并累加
					col += tex2D(_MainTex, uv) * gauss;
				#endif
				}
				//divide the sum of values by the amount of samples
				// 除以权重总和进行归一化
				col = col / sum;
				return col;
			}

			ENDCG
		}

		//Horizontal Blur
		// 水平模糊Pass（Pass 1）：只在X方向进行模糊
		Pass{
			CGPROGRAM
			//include useful shader functions
			#include "UnityCG.cginc"

			#pragma multi_compile _SAMPLES_LOW _SAMPLES_MEDIUM _SAMPLES_HIGH
			#pragma shader_feature GAUSS

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			//texture and transforms of the texture
			sampler2D _MainTex;
			float _BlurSize;
			float _StandardDeviation;

			#define PI 3.14159265359
			#define E 2.71828182846

		#if _SAMPLES_LOW
			#define SAMPLES 10
		#elif _SAMPLES_MEDIUM
			#define SAMPLES 30
		#else
			#define SAMPLES 100
		#endif

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
			// 片段着色器：实现水平方向的模糊采样
			fixed4 frag(v2f i) : SV_TARGET{
			#if GAUSS
				//failsafe so we can use turn off the blur by setting the deviation to 0
				// 安全措施：当标准差为0时关闭模糊
				if(_StandardDeviation == 0)
				return tex2D(_MainTex, i.uv);
			#endif
				//calculate aspect ratio
				// 计算宽高比，确保水平模糊在不同分辨率下效果一致
				float invAspect = _ScreenParams.y / _ScreenParams.x;
				//init color variable
				// 初始化颜色变量
				float4 col = 0;
			#if GAUSS
				float sum = 0;
			#else
				float sum = SAMPLES;
			#endif
				//iterate over blur samples
				// 遍历模糊采样点
				for(float index = 0; index < SAMPLES; index++){
					//get the offset of the sample
					// 计算采样偏移量（水平方向，考虑宽高比）
					float offset = (index/(SAMPLES-1) - 0.5) * _BlurSize * invAspect;
					//get uv coordinate of sample
					// 获取采样点的UV坐标（只在X方向偏移）
					float2 uv = i.uv + float2(offset, 0);
				#if !GAUSS
					//simply add the color if we don't have a gaussian blur (box)
					// 简单盒式模糊：直接累加颜色
					col += tex2D(_MainTex, uv);
				#else
					//calculate the result of the gaussian function
					// 计算高斯函数结果
					float stDevSquared = _StandardDeviation*_StandardDeviation;
					float gauss = (1 / sqrt(2*PI*stDevSquared)) * pow(E, -((offset*offset)/(2*stDevSquared)));
					//add result to sum
					// 累加高斯权重
					sum += gauss;
					//multiply color with influence from gaussian function and add it to sum color
					// 用高斯权重乘以颜色并累加
					col += tex2D(_MainTex, uv) * gauss;
				#endif
				}
				//divide the sum of values by the amount of samples
				// 除以权重总和进行归一化
				col = col / sum;
				return col;
			}

			ENDCG
		}
	}
}