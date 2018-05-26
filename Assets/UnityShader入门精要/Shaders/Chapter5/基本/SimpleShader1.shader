//认识基本声明和方法
Shader "Unity Shaders Book/Chapter 5/SimpleShader1"
{
	Properties
	{	
	}

	SubShader
	{	
		Pass
		{
			CGPROGRAM
			//函数名为vert 的函数包含了顶点着色器代码
			#pragma vertex vert		
			
			//函数名为frag 的函数包含了片元着色器代码
			#pragma fragment frag

			//逐顶点执行
			//输入参数 v 包含了这个顶点的位置, 这是通过 POSITION 指定的。
			//输出(返回值)是 该顶点在裁剪空间中的位置, 这是通过 SV_POSITION 指定的。。
			//POSITION 和 SV_POSITION 都是Cg/HLSL的语义, 它们是不可省略的。 这些语义告诉系统用户需要哪些输入值，以及用户输出的是什么。
			float4 vert(float4 v : POSITION) : SV_POSITION {
				return mul (UNITY_MATRIX_MVP, v);
			} 

			//逐片元执行
			//本例中 片元着色器没有任何输入。
			//输出(返回值)是 SV_Target 等同于告诉渲染器，把用户的输出颜色存储到一个渲染目标中，这里将输出到默认的帧缓存中。
			//这里返回了一个表示白色的fixed4类型的变量。 (0, 0, 0)表示黑色，(1, 1, 1)表示白色，
			fixed4 frag() : SV_Target {
				return fixed4(1.0, 1.0, 1.0, 1.0);
			}
			ENDCG
		}
	}
}
