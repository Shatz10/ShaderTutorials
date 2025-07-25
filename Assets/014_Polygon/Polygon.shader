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
				// 通过点积判断pos在直线的哪一侧
				// 如果结果大于0，pos在左侧；小于0则在右侧
				float side = dot(toPos, lineNormal);
				// 用step函数将结果转为0或1，表示是否在左侧
				side = step(0, side);
				return side;
			}

			//the fragment shader
			fixed4 frag(v2f i) : SV_TARGET{

				float outsideTriangle = 0;
				
				[loop]
				for(uint index;index<_cornerCount;index++){
					outsideTriangle += isLeftOfLine(i.worldPos.xy, _corners[index], _corners[(index+1) % _cornerCount]);
				}

				clip(-outsideTriangle);
				return _Color;
			}

			ENDCG
		}
	}
}


