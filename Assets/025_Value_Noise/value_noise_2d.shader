Shader "Tutorial/025_value_noise/2d" {
	// 2D值噪声着色器：通过双线性插值将2D网格的随机值连接成连续噪声
	// 原理：在2x2网格的四个角点之间进行双线性插值
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

		float easeIn(float interpolator){
			return interpolator * interpolator;
		}

		float easeOut(float interpolator){
			return 1 - easeIn(1 - interpolator);
		}

		float easeInOut(float interpolator){
			float easeInValue = easeIn(interpolator);
			float easeOutValue = easeOut(interpolator);
			return lerp(easeInValue, easeOutValue, interpolator);
		}

		// 2D值噪声核心函数：在2x2网格的四个角点之间进行双线性插值
		float ValueNoise2d(float2 value){
			// 获取2x2网格四个角点的随机值
			float upperLeftCell = rand2dTo1d(float2(floor(value.x), ceil(value.y)));   // 左上角
			float upperRightCell = rand2dTo1d(float2(ceil(value.x), ceil(value.y)));   // 右上角
			float lowerLeftCell = rand2dTo1d(float2(floor(value.x), floor(value.y)));  // 左下角
			float lowerRightCell = rand2dTo1d(float2(ceil(value.x), floor(value.y)));  // 右下角

			// 计算X和Y方向的插值因子，应用缓动函数
			float interpolatorX = easeInOut(frac(value.x));
			float interpolatorY = easeInOut(frac(value.y));

			// 因为双线性插值的标准/传统约定，所以下面是这样计算的
			// 标准公式：f(x,y) = f(0,0)(1-x)(1-y) + f(1,0)x(1-y) + f(0,1)(1-x)y + f(1,1)xy
			// (0,1) upperLeft  --------  upperRight (1,1)
			// 		|                    |
			// 		|    插值点          |
			// 		|                    |
			// (0,0) lowerLeft  --------  lowerRight (1,0)
			// 双线性插值：先X方向，再Y方向
			float upperCells = lerp(upperLeftCell, upperRightCell, interpolatorX);  // 上边插值
			float lowerCells = lerp(lowerLeftCell, lowerRightCell, interpolatorX);  // 下边插值
			float noise = lerp(lowerCells, upperCells, interpolatorY);              // Y方向插值
			return noise;
		}

		// 表面着色器：直接显示2D值噪声
		void surf (Input i, inout SurfaceOutputStandard o) {
			// 使用XZ平面坐标，_CellSize控制噪声频率
			float2 value = i.worldPos.xz / _CellSize;
			// 生成2D值噪声
			float noise = ValueNoise2d(value);

			o.Albedo = noise;
		}
		ENDCG
	}
	FallBack "Standard"
}