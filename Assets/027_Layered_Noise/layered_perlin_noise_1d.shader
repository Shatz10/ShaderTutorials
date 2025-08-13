Shader "Tutorial/027_layered_noise/1d" {
	// 1D分层Perlin噪声着色器：叠加多个不同频率的Perlin噪声
	// 核心原理：通过多尺度叠加创造丰富的细节，模拟真实世界的多尺度特征
	Properties {
		_CellSize ("Cell Size", Range(0, 2)) = 2
		_Roughness ("Roughness", Range(1, 8)) = 3
		_Persistance ("Persistance", Range(0, 1)) = 0.4
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "Random.cginc"

		//global shader variables
		// 分层噪声参数：OCTAVES控制叠加层数，越多层细节越丰富
		#define OCTAVES 4 

		float _CellSize;
		float _Roughness;    // 粗糙度：控制频率倍增因子
		float _Persistance;  // 持续性：控制振幅衰减因子

		struct Input {
			float3 worldPos;
		};

		float easeIn(float interpolator){
			return interpolator * interpolator * interpolator * interpolator * interpolator;
		}

		float easeOut(float interpolator){
			return 1 - easeIn(1 - interpolator);
		}

		float easeInOut(float interpolator){
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		float gradientNoise(float value){
			float fraction = frac(value);
			float interpolator = easeInOut(fraction);

			float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
			float previousCellLinePoint = previousCellInclination * fraction;

			float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
			float nextCellLinePoint = nextCellInclination * (fraction - 1);

			return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
		}

		// 分层噪声核心函数：叠加多个不同频率的Perlin噪声
		float sampleLayeredNoise(float value){
			float noise = 0;           // 累积噪声值
			float frequency = 1;       // 初始频率
			float factor = 1;          // 初始振幅因子

			[unroll]
			for(int i=0; i<OCTAVES; i++){
				// 生成当前层的Perlin噪声：value * frequency 控制频率，+ i * 0.72354 避免层间相关性
				noise = noise + gradientNoise(value * frequency + i * 0.72354) * factor;
				// 更新下一层的参数
				factor *= _Persistance;    // 振幅衰减：每层振幅乘以持续性因子
				frequency *= _Roughness;   // 频率倍增：每层频率乘以粗糙度因子
			}

			return noise;
		}

		// 表面着色器：将1D分层噪声可视化为等高线图
		void surf (Input i, inout SurfaceOutputStandard o) {
			// 将世界坐标转换为噪声坐标
			float value = i.worldPos.x / _CellSize;
			// 生成分层噪声（已经是[0,1]范围）
			float noise = sampleLayeredNoise(value);
			
			// 计算等高线：当前Y位置与噪声值的距离
			float dist = abs(noise - i.worldPos.y);
			// 获取像素高度用于抗锯齿
			float pixelHeight = fwidth(i.worldPos.y);
			// 创建平滑的等高线
			float lineIntensity = smoothstep(2*pixelHeight, pixelHeight, dist);
			o.Albedo = lerp(1, 0, lineIntensity);
		}
		ENDCG
	}
	FallBack "Standard"
}