Shader "Tutorial/014_Polygon"
{
	//show values to edit in inspector
	Properties{
		_Color ("Color", Color) = (0, 0, 0, 1)
	}

	SubShader{
		//the material is completely non-transparent and is rendered at the same time as the other opaque geometry
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		Pass{
			CGPROGRAM

			//include useful shader functions
			#include "UnityCG.cginc"

			//define vertex and fragment shader
			#pragma vertex vert
			#pragma fragment frag

			fixed4 _Color;

			//the variables for the corners
			uniform float2 _corners[1000];
			uniform uint _cornerCount;

			//the object data that's put into the vertex shader
			struct appdata{
				float4 vertex : POSITION;
			};

			//the data that's used to generate fragments and can be read by the fragment shader
			struct v2f{
				float4 position : SV_POSITION;
				float3 worldPos : TEXCOORD0;
			};

			//the vertex shader
			v2f vert(appdata v){
				v2f o;
				//convert the vertex positions from object space to clip space so they can be rendered
				o.position = UnityObjectToClipPos(v.vertex);
				//calculate and assign vertex position in the world
				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.worldPos = worldPos.xyz;
				return o;
			}

			//return 1 if a thing is left of the line, 0 if not
			// 判断一个点是否在一条线的左侧，如果在左侧返回1，否则返回0
			float isLeftOfLine(float2 pos, float2 linePoint1, float2 linePoint2){
				//variables we need for our calculations
				// 计算线段的方向向量，方向为从linePoint1指向linePoint2（即goal - start）
				float2 lineDirection = linePoint2 - linePoint1;
				// 将方向向量逆时针旋转90度，得到线的左侧法线
				// 具体做法是交换x和y，并对新的x分量取负号
				// 这样得到的lineNormal指向线的左侧（如果对y取负则指向右侧）
				float2 lineNormal = float2(-lineDirection.y, lineDirection.x);
				// 计算从linePoint1指向要测试点pos的向量
				float2 toPos = pos - linePoint1;

				//which side the tested position is on
				// 如果点积为正，则指向该点的向量指向与线法线的方向相同，并且它位于线法线指向的一侧。
				// 如果点积为负数，则指向点的向量指向与线法线的方向相反，并且该点位于另一侧。
				// 如果点积恰好为零，则指向该点的向量与直线法线正交，并且该点位于该直线上。
				float side = dot(toPos, lineNormal);
				// 防止交接处出现渐变
				// step(edge, x)，其中edge是阈值，x是输入值。如果x小于edge，函数返回0；否则返回1。
				side = step(0, side);
				return side;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{

				float outsideTriangle = 0;

				//The problem that emerges when we use that plus one is that at the last point we acess the array at a point we didn’t set, but we want to go back to the first point instead
				[loop]
				for(uint index;index<_cornerCount;index++){
					outsideTriangle += isLeftOfLine(i.worldPos.xy, _corners[index], _corners[(index+1) % _cornerCount]);
				}

				// 如果 x < 0，则当前像素会被丢弃（discard），不会进行后续的颜色写入、混合等操作。
				// 如果 x >= 0，则像素会被正常渲染。
				// 由于上面的函数计算，
				// 多边形边上和内部 outsideTriangle 为 0，则 clip 函数会丢弃该像素，因为 -0 为 0，小于 0 的值会被丢弃。
				// 多边形外部 outsideTriangle 为 1，则 clip 函数不会丢弃该像素，因为 -1 小于 0。
				clip(-outsideTriangle);
				// 反向挖空效果
				//clip(outsideTriangle - 0.5);
				return _Color;
			}

			ENDCG
		}
	}
}


