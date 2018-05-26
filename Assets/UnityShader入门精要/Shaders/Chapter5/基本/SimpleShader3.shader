Shader "Unity Shaders Book/Chapter 5/SimpleShader3"
{
	Properties
	{	
	}

	SubShader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vert		
			#pragma fragment frag

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;				//顶点的法线方向，分量范围是[-1.0, 1.0]。
				float4 texcoord: TEXCOORD0;	
			};

			//定义一个结构体 v2f 。命名含义:用于vertex着色器 向 fragment着色器传递的数据结构。
			struct v2f {
				float4 pos : POSITION;
				fixed3 color : COLOR0;	//COLOR0 语义可以用于存储颜色信息
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5); //将法线分量的范围映射到了[0.0, 1.0]。
				return o;
			}

			//片元着色器的输出 实际 是将 顶点着色器的输出进行插值后得到的结果
			fixed4 frag(v2f i) : SV_Target{
				return fixed4(i.color, 1.0);	//将插值后的i.color 显示到屏幕上
			}
			ENDCG
		}
	}
}
