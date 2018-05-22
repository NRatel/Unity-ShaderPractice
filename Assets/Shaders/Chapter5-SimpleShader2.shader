Shader "Unity Shaders Book/Chapter 5/SimpleShader2"
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

			//定义一个结构体
			struct a2v {
				float4 vertex : POSITION;	//由 模型空间的顶点坐标 填充变量
				float3 normal : NORMAL;		//由 模型空间 顶点的法线方向 填充变量
				float4 texcoord: TEXCOORD0;	//由 模型的第一套纹理坐标 填充变量

				//Unity 支持的语义有：POSITION、TANGENT、NORMAL、TEXCOORD0、TEXCOORD1、TEXCOORD2、TEXCOORD3、COLOR等。
				//它们是由使用该材质的MeshRender组件提供的，
				//在每帧调用DrawCall 时，MeshRender组件会把它负责渲染的模型数据发送给UnityShader。
				//一个模型包含一组三角面片,每个三角面片由三个顶点构成，每个顶点包含了一些数据，如顶点位置、法线、切线、纹理坐标、顶点颜色等。
			};

			//使用结构体作为输入参数
			float4 vert(a2v v) : SV_POSITION {
				return mul (UNITY_MATRIX_MVP, v.vertex);
			}

			// 本例中 片元着色器没有任何输入。
			// 输出(返回值)是 SV_Target 等同于告诉渲染器，把用户的输出颜色存储到一个渲染目标中，这里将输出到默认的帧缓存中。
			// 这里返回了一个表示白色的fixed4类型的变量。 (0, 0, 0)表示黑色，(1, 1, 1)表示白色，
			fixed4 frag() : SV_Target {
				return fixed4(1.0, 1.0, 1.0, 1.0);
			}
			ENDCG
		}
	}
}
