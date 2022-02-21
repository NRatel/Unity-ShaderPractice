// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//BlinnPong模型 逐像素高光反射
Shader "Unity Shaders Book/Chapter 6/Specular_BlinnPong_PixelLevel"
{
	Properties
	{	
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)		//漫反射系数 ，控制漫反射的颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)	//高光反射系数 ，控制高光反射的颜色	
		_Gloss ("Gloss", Range(8.0, 256)) = 20			//高光反射光泽度(反光度)，控制高光区域的大小
	}

	SubShader
	{	
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			//引入光照相关的内置变量
			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert(a2v v) {
				v2f o;
				//将顶点坐标从 模型空间 变换到 裁剪空间
				o.pos = UnityObjectToClipPos(v.vertex);

				//世界空间的法线方向(归一化向量) (公式中的n) 。 (从 模型空间 变换到 世界空间。)
				o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));	//直接由模型空间到世界空间的矩阵进行变换
				//o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));	//或由世界空间到模型空间的逆矩阵变换

				o.worldPos = mul(unity_ObjectToWorld, v.vertex);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				//环境光 (公式中的 C_ambient)
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

				fixed3 worldNormal = i.worldNormal;

				//入射光方向(世界空间的直射光) (归一化向量) (公式中的l) 。
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				//光源信息。 _LightColor0是Unity内置变量, 表示访问该Pass处理的光源的颜色和强度信息(注意要定义合适的LightMode标签)
				fixed3 C_light = _LightColor0.rgb;

				//自己控制的漫反射系数
				fixed3 M_diffuse = _Diffuse.rgb;

				//漫反射计算公式： C_difuse = (C_light * M_diffuse) * max(0, dot(n, l))
				fixed3 diffuse = (C_light * M_diffuse) * saturate(dot(worldNormal, worldLightDir));

				//--------------------------------计算高光部分--------------------------------

				//视角方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				//half方向,(由视角方向和入射光方向相加再归一化获得)。
				//公式：h = normalize(v + l)
				fixed3 halfDir = normalize(viewDir + worldLightDir);

				//自己控制的高光反射系数
				fixed3 M_specular = _Specular.rgb;

				//自己控制的高光反射光泽度
				float M_gloss = _Gloss;

				//高光反射计算公式： (C_light * M_specular) * pow(saturate(dot(n, h)), M_gloss);
				fixed3 specular = (C_light * M_specular) * pow(saturate(dot(worldNormal, halfDir)), M_gloss);	//注意原书写的不一致，是因为向量点乘满足交换律。

				//结合环境光、漫反射和高光反射
				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}


			ENDCG
		}
	}
}
