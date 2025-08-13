Shader "Tutorial/026_perlin_noise/1d" {
	// 1D Perlin噪声着色器：使用梯度向量消除网格对齐问题
	// 核心原理：角点存储梯度方向，通过点积计算影响，比Value Noise更自然
	Properties {
		_CellSize ("Cell Size", Range(0, 1)) = 1
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0

		#include "Random.cginc"

		float _CellSize;

		struct Input {
			float3 worldPos;
		};

		// 缓动函数：Perlin噪声使用5次方缓动，比Value Noise的2次方更平滑
		float easeIn(float interpolator){
			return interpolator * interpolator * interpolator * interpolator * interpolator;  // 5次方，更平滑的过渡
		}

		float easeOut(float interpolator){
			return 1 - easeIn(1 - interpolator);  // 对称的缓出函数
		}

		float easeInOut(float interpolator){
			// 混合easeIn和easeOut，创造更平滑的S形曲线
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		// Perlin噪声核心函数：使用梯度向量和点积计算，消除网格对齐
		float gradientNoise(float value){
			// 计算在单元格内的位置和插值因子
			float fraction = frac(value);
			float interpolator = easeInOut(fraction);

			// 获取前一个单元格的梯度（-1到1的随机方向）
			float previousCellInclination = rand1dTo1d(floor(value)) * 2 - 1;
			// 计算前一个单元格的影响：梯度 × 距离向量（点积）
			float previousCellLinePoint = previousCellInclination * fraction;

			// 获取后一个单元格的梯度
			float nextCellInclination = rand1dTo1d(ceil(value)) * 2 - 1;
			// 计算后一个单元格的影响：梯度 × 距离向量（注意距离是负的）
			float nextCellLinePoint = nextCellInclination * (fraction - 1);

			// 在两个影响值之间进行平滑插值
			return lerp(previousCellLinePoint, nextCellLinePoint, interpolator);
		}

		// 表面着色器：将1D Perlin噪声可视化为等高线图
		void surf (Input i, inout SurfaceOutputStandard o) {
			// 将世界坐标转换为噪声坐标
			float value = i.worldPos.x / _CellSize;
			// 生成Perlin噪声并调整到[0,1]范围（Perlin噪声范围是[-0.5,0.5]）
			float noise = gradientNoise(value) + 0.5;
			
			// 计算等高线：当前Y位置与噪声值的距离
			float dist = abs(noise - i.worldPos.y);
			// 获取像素高度用于抗锯齿
			float pixelHeight = fwidth(i.worldPos.y);
			// 创建平滑的等高线（注意参数顺序：从白色到黑色）
			float lineIntensity = smoothstep(2*pixelHeight, pixelHeight, dist);
			o.Albedo = lerp(1, 0, lineIntensity);
		}
		ENDCG
	}
	FallBack "Standard"
}