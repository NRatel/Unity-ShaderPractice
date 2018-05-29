//凹凸映射_切线空间下的法线纹理
Shader "Unity Shaders Book/Chapter 7/NormalMapInTangentSpace"
{
	Properties
	{	
		_Color ("Color Tint", Color) = (1, 1, 1, 1)		//漫反射系数 ，控制漫反射的颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)	//高光反射系数 ，控制高光反射的颜色	
		_Gloss ("Gloss", Range(8.0, 256)) = 20			//高光反射光泽度(反光度)，控制高光区域的大小

		_MainTex ("Main Tex", 2D) = "white" {}			//纹理, 默认为名为"white"的内置的全白纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}			//法线纹理，默认为"bump"的内置的模型自带的法线纹理
		_BumpScale ("Bump Scale", float) = 1.0			//用于控制凹凸程度，为0时意味着该法线纹理不会对光照产生任何影响
	}

	SubShader
	{	
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			sampler2D _MainTex;
			float4 _MainTex_ST;	 
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent :TANGENT;	//需要用 normal 和 tangent 构建切线空间，注意是float4,因为需要用tangent.w来决定切线空间的负切线方向
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				//xy存放_MainTex的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//zw存放_BumpMap的纹理坐标
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				//副法线, 由法线和切线的叉积，乘以 切线的w分量。w决定了正反方向
				//float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//rotation 为模型空间到切线空间的变换矩阵
				//float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

				TANGENT_SPACE_ROTATION;	//此内置宏定义 在UnityCG.cginc中。其中定义了上面的binormal和rotation

				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;
				return o;
			}

			fixed4 frag(v2f i): SV_Target {
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);	//利用tex2D对法线纹理_BumpMap进行采样。

				//法线纹理存储的是法线经过映射的像素值, 需要把它反映射回来。
				fixed3 tangentNormal;
				tangentNormal = UnpackNormal(packedNormal);		//反映射
				tangentNormal.xy *= _BumpScale;					//xy分量乘以凹凸程度 得到最终的xy分量
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));	//因为法线是单位矢量,所以z分量可以由xy分量计算出来

				fixed3 C_light = _LightColor0.rgb;

				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;	
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				//通常，使用纹理来代替物体的漫反射颜色。
				//漫反射计算公式： C_difuse = (C_light * M_diffuse) * max(0, dot(n, l))
				fixed3 diffuse = (C_light * albedo) * saturate(dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentViewDir + tangentLightDir);
				fixed3 M_specular = _Specular.rgb;
				float M_gloss = _Gloss;

				//高光反射计算公式： (C_light * M_specular) * pow(saturate(dot(n, h)), M_gloss);
				fixed3 specular = (C_light * M_specular) * pow(saturate(dot(tangentNormal, halfDir)), M_gloss);	//注意原书写的不一致，是因为向量点乘满足交换律。

				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Specular"
}
