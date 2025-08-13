Shader "Tutorial/025_value_noise/1d" {
	// 1D值噪声着色器：通过插值将离散随机值连接成连续噪声
	// 原理：在相邻单元格的随机值之间进行线性插值
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

		// 缓动函数：使噪声过渡更自然，避免线性插值的"网格"效果
		float easeIn(float interpolator){
			return interpolator * interpolator;  // 二次函数，开始慢结束快
		}

		float easeOut(float interpolator){
			return 1 - easeIn(1 - interpolator);  // 二次函数，开始快结束慢
		}

		float easeInOut(float interpolator){
			// 混合easeIn和easeOut，创造平滑的S形曲线
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		// 1D值噪声核心函数：在相邻单元格的随机值之间进行插值
		float valueNoise(float value){
			// 获取相邻两个单元格的随机值
			float previousCellNoise = rand1dTo1d(floor(value));  // 前一个单元格
			float nextCellNoise = rand1dTo1d(ceil(value));      // 后一个单元格
			// 计算在单元格内的位置 [0,1)
			float interpolator = frac(value);
			// 应用缓动函数使过渡更平滑
			interpolator = easeInOut(interpolator);
			// 在两个随机值之间进行线性插值
			return lerp(previousCellNoise, nextCellNoise, interpolator);
		}

		// 表面着色器：将1D噪声可视化为等高线图
		void surf (Input i, inout SurfaceOutputStandard o) {
			// 将世界坐标转换为噪声坐标，_CellSize控制噪声频率
			float value = i.worldPos.x / _CellSize;
			// 生成1D值噪声
			float noise = valueNoise(value);

			// 计算当前Y位置与噪声值的距离，用于绘制等高线
			float dist = abs(noise - i.worldPos.y);
			// 获取像素高度，用于抗锯齿
			float pixelHeight = fwidth(i.worldPos.y);
			// 使用smoothstep创建平滑的等高线
			float lineIntensity = smoothstep(pixelHeight, 2*pixelHeight, dist);
			// dist = 0（在等高线上）：lineIntensity ≈ 0 → 黑色线条
			// dist > 0（远离等高线）：lineIntensity ≈ 1 → 白色背景
			// 等价于 o.Albedo = float3(lineIntensity, lineIntensity, lineIntensity);
			o.Albedo = lineIntensity;
		}
		ENDCG
	}
	FallBack "Standard"
}