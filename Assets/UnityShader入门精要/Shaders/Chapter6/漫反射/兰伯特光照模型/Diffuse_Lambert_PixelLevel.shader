//兰伯特光照模型 逐像素漫反射 (更加平滑的光照效果)
Shader "Unity Shaders Book/Chapter 6/Diffuse_Lambert_PixelLevel"
{
	Properties
	{	
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
	}

	SubShader
	{	
		Pass
		{
			//LightMode用于定义该Pass在Unity光照流水线中的角色
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			//引入光照相关的内置变量
			#include "Lighting.cginc"

			//定义与Properties中定义的属性相关联的变量
			fixed4 _Diffuse;
			 
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				fixed3 worldNormal : TEXCOOD0;
			};

			v2f vert(a2v v) {
				v2f o;

				//将顶点坐标从 模型空间 变换到 裁剪空间
				o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
				//世界空间的法线方向(归一化向量) (公式中的n) 。 (从 模型空间 变换到 世界空间。)
				o.worldNormal = normalize(mul(unity_ObjectToWorld, v.normal));
				//o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));	//或由世界空间到模型空间的逆矩阵变换
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

				//最后加上环境光
				fixed3 color = ambient + diffuse;

				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Diffuse"
}
