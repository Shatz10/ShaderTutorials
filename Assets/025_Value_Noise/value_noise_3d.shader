Shader "Tutorial/025_value_noise/3d" {
	// 3D值噪声着色器：通过三线性插值将3D网格的随机值连接成连续噪声
	// 原理：在2x2x2网格的八个角点之间进行三线性插值
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

		// 3D值噪声核心函数：在2x2x2网格的八个角点之间进行三线性插值
		float3 ValueNoise3d(float3 value){
			// 计算三个方向的插值因子，应用缓动函数
			float interpolatorX = easeInOut(frac(value.x));
			float interpolatorY = easeInOut(frac(value.y));
			float interpolatorZ = easeInOut(frac(value.z));

			// 三重嵌套循环处理8个角点，使用三线性插值
			float3 cellNoiseZ[2];
			[unroll] // 循环展开优化：消除循环开销，不需要循环控制变量
			for(int z=0;z<=1;z++){
				float3 cellNoiseY[2];
				[unroll]
				for(int y=0;y<=1;y++){
					float3 cellNoiseX[2];
					// 这样计算来源于三线性插值公式：
					// f(x,y,z) = Σ(i,j,k=0,1) f(i,j,k) * (1-x)^(1-i) * x^i * (1-y)^(1-j) * y^j * (1-z)^(1-k) * z^k
					// 计算过程简化
					// 步骤1：X插值（4次）
					// (0,0,0)-(1,0,0) → 插值结果1
					// (0,1,0)-(1,1,0) → 插值结果2  
					// (0,0,1)-(1,0,1) → 插值结果3
					// (0,1,1)-(1,1,1) → 插值结果4

					// 步骤2：Y插值（2次）
					// 结果1-结果2 → 插值结果A
					// 结果3-结果4 → 插值结果B

					// 步骤3：Z插值（1次）
					// 结果A-结果B → 最终噪声值
					
					[unroll]
					for(int x=0;x<=1;x++){
						// 计算当前角点的坐标
						float3 cell = floor(value) + float3(x, y, z);
						// 获取该角点的3D随机值
						cellNoiseX[x] = rand3dTo3d(cell);
					}
					// X方向插值：在两个X角点之间插值
					cellNoiseY[y] = lerp(cellNoiseX[0], cellNoiseX[1], interpolatorX);
				}
				// Y方向插值：在两个Y角点之间插值
				cellNoiseZ[z] = lerp(cellNoiseY[0], cellNoiseY[1], interpolatorY);
			}
			// Z方向插值：在两个Z角点之间插值，得到最终噪声值
			float3 noise = lerp(cellNoiseZ[0], cellNoiseZ[1], interpolatorZ);
			return noise;
		}

		// 表面着色器：直接显示3D值噪声
		void surf (Input i, inout SurfaceOutputStandard o) {
			// 使用XYZ三维坐标，_CellSize控制噪声频率
			float3 value = i.worldPos.xyz / _CellSize;
			// 生成3D值噪声
			float3 noise = ValueNoise3d(value);

			o.Albedo = noise;
		}
		ENDCG
	}
	FallBack "Standard"
}