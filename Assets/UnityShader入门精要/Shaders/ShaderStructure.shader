// 此处定义 Shader 在材质Inspector上选择时的路径。
Shader "NRatelShader/ShaderStructure"
{
	//属性定义
	Properties
	{	
		//此处定义属性。参考《UnityShader入门精要》第29-30页。
		/* + ------------------------------------------------------------------ +
		 |							此处定义属性。								| 
		 | 规则: 属性字段名 ("显示名称", 属性类型) = 默认值						|
		 | 示例: _MainTex ("Texture", 2D) = "white" {}							|
		 | 类型选择: Int、Float、Range(min,max)、Color、Vector、2D、Cube、3D。	|
		 + -------------------------------------------------------------------- + */

	}

	//一个Shader文件至少包含一个, 可包含多个, Unity会依次判断, 选择第一个能再目标平台运行的SubShader, 如果都不支持,就会使用FallBack指定的Shader。
	SubShader
	{	
		//此处定义SubShader的Tags(可选的)。 参考《UnityShader入门精要》第31-32页。
		/* + ------------------------------------------------------------------ +
		 | 规则: Tags { "键_标签名"="值_标签值" }								|
		 | 示例: Tags { "RanderType"="Opaque" }									|
		 | 类型选择: Queue、RenderType、DisableBatching、ForceNoShadowCast、	|
		 |			IgnorProjector、CanUseSproteAtlas、PreviewType				|
		 | 作用: 告诉Unity渲染引擎何时及怎样渲染这个对象						|
		 + -------------------------------------------------------------------- + */
		
		//此处定义SubShader的渲染状态RenderSetUp(可选的)。参考《UnityShader入门精要》第31页。
		/* + ------------------------------------------------------------------ +
		 | 规则: 状态名 状态值													|
		 | 示例: Cull Back														|
		 | 类型选择: Cll、ZTest、ZWrite、Blend。								|
		 | 作用: 设置这些状态后,会应用到所有Pass, 可以在Pass中再次定义覆盖。	|
		 + -------------------------------------------------------------------- + */

		// 表面着色器的代码，写在SubShader中的 CGPROGRAM 和 ENDCG 之间而非Pass中。
		// 表面着色器不关心Pass的定义和渲染,由Unity自动处理这些。
		CGPROGRAM
		ENDCG


		//-------------------------如果使用表面着色器, 则不需要定义Pass-----------------------

		Pass
		{
			//此处定义Pass的Name。 参考《UnityShader入门精要》第32页。
			/* + ------------------------------------------------------------------ +
			| 规则: Name "Pass名称"													|
			| 示例: Name "MyNRatelPassName"											|
			| 作用: 通过这个名称, 使用ShaderLab的UsePass。							|
			|       如 UsePass "NRatelShader/MYNRATELPASSNAME" (内部会变大写)		|
			+ --------------------------------------------------------------------- + */

			//此处定义Pass的Tags。 参考《UnityShader入门精要》第32页。
			/* + ------------------------------------------------------------------ +
			| 规则: Tags { "键_标签名"="值_标签值" }								|
			| 示例: Tags { "LightMode"="ForwardBase" }								|
			| 类型选择: LightMode、RequireOpetions									|
			| 作用: 注意它不同于SubShader的Tag。									|
			|		但也用于告诉Unity渲染引擎怎样渲染这个对象。						|
			+ --------------------------------------------------------------------- + */
			
			//顶点着色器、片元着色器 的代码写在Pass的 CGPROGRAM 和 ENDCG 之间。
			CGPROGRAM
			ENDCG
		}

		// 除了普通Pass定义, 
		// 还可以使用ShaderLab的 UsePass "NRatelShader/XXXNRATELPASSNAME"。复用其他Shader中的Pass。
		// 还可以GrabPass 负责抓取屏幕并将结果存储在一张纹理中, 以用于后续的Pass处理。
	}

	//此处定义Fallback(可选的)。 参考《UnityShader入门精要》第33页。
	/* + ------------------------------------------------------------------ +
	| 规则: Fallback "name"	或 Fallback Off									|
	| 示例: Fallback "VertexLit"											|
	| 作用: 设置最低级别的Pass。											|
	+ --------------------------------------------------------------------- + */
}
