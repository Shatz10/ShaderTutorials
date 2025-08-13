#ifndef WHITE_NOISE
#define WHITE_NOISE

// 白噪声生成库：使用哈希函数将坐标转换为随机值
// 基于确定性哈希，相同输入总是产生相同输出

//to 1d functions
// 生成1D随机值的函数

//get a scalar random value from a 3d value
// 从3D坐标生成标量随机值
float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
	//make value smaller to avoid artefacts
	// 将输入值压缩到[-1,1]范围，避免大数值精度问题
	float3 smallValue = sin(value);
	//get scalar value from 3d vector
	// 通过点积将3D向量转换为标量，不同dotDir产生不同随机序列
	float random = dot(smallValue, dotDir);
	//make value more random by making it bigger and then taking the factional part
	// 增强随机性：正弦函数增加非线性，大数乘法放大变化，frac取小数部分归一化到[0,1)
	random = frac(sin(random) * 143758.5453);
	return random;
}

float rand2dTo1d(float2 value, float2 dotDir = float2(12.9898, 78.233)){
	// 从2D坐标生成标量随机值，原理同3D版本
	float2 smallValue = sin(value);
	float random = dot(smallValue, dotDir);
	random = frac(sin(random) * 143758.5453);
	return random;
}

float rand1dTo1d(float3 value, float mutator = 0.546){
	// 从1D值生成标量随机值，添加mutator参数增加随机性
	float random = frac(sin(value + mutator) * 143758.5453);
	return random;
}

//to 2d functions
// 生成2D随机向量的函数

float2 rand3dTo2d(float3 value){
	// 从3D坐标生成2D随机向量，使用两个不同的点积方向
	return float2(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155))
	);
}

float2 rand2dTo2d(float2 value){
	// 从2D坐标生成2D随机向量，使用两个不同的点积方向
	return float2(
		rand2dTo1d(value, float2(12.989, 78.233)),
		rand2dTo1d(value, float2(39.346, 11.135))
	);
}

float2 rand1dTo2d(float value){
	// 从1D值生成2D随机向量，使用两个不同的mutator值
	return float2(
		rand2dTo1d(value, 3.9812),
		rand2dTo1d(value, 7.1536)
	);
}

//to 3d functions
// 生成3D随机向量的函数

float3 rand3dTo3d(float3 value){
	// 从3D坐标生成3D随机向量，使用三个不同的点积方向
	return float3(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
		rand3dTo1d(value, float3(73.156, 52.235, 09.151))
	);
}

float3 rand2dTo3d(float2 value){
	// 从2D坐标生成3D随机向量，使用三个不同的点积方向
	return float3(
		rand2dTo1d(value, float2(12.989, 78.233)),
		rand2dTo1d(value, float2(39.346, 11.135)),
		rand2dTo1d(value, float2(73.156, 52.235))
	);
}

float3 rand1dTo3d(float value){
	// 从1D值生成3D随机向量，使用三个不同的mutator值
	return float3(
		rand1dTo1d(value, 3.9812),
		rand1dTo1d(value, 7.1536),
		rand1dTo1d(value, 5.7241)
	);
}

#endif