//自定义属性参数，控制Shader表现
Shader "Unity Shaders Book/Chapter 5/SimpleShader4"
{
	Properties
	{	
		//声明一个Color类型的属性, 初始值为白色
		_Color("Color Tint", Color) = (1.0, 1.0, 1.0)
	}

	SubShader
	{	
		Pass
		{
			CGPROGRAM
			#pragma vertex vert		
			#pragma fragment frag

			// ShaderLab Properties中的类型与Cg中变量类型的匹配表：
			/* + ------------------------------------------------------------------ +
			 | Color,Vector <==> float4, half4, fixed4;								|
			 | Range, Float <==> float, half, fixed									|
			 | 2D <==> sampler2D													|
			 | 3D <==> sampler3D													|
			 + -------------------------------------------------------------------- + */

			//在CG代码中，定义一个与属性名和类型都匹配的变量。 前面可加 uniform 关键字，在UnityShader中可省略。
			fixed4 _Color;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord: TEXCOORD0;	
			};

			struct v2f {
				float4 pos : POSITION;
				fixed3 color : COLOR0;	
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5); 
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 c = i.color;
				c += _Color.rgb;	//使用_Color控制颜色输出
				return fixed4(c, 1.0);	
			}
			ENDCG
		}
	}
}
