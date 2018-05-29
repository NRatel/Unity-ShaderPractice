// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

//凹凸映射_世界空间下的法线纹理
Shader "Unity Shaders Book/Chapter 7/NormalMapInWorldSpace"
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

				//因为不能传递矩阵，所以将矩阵分为多行进行传递。float3x3
				//但是，为了充分利用插值寄存器的存储空间，将世界空间下的顶点位置存储在这些变量的w分量中, 所以定义为float4
				float4 tangentToWorld0 : TEXCOORD1;	//tangentToWorld变换矩阵的第一行
				float4 tangentToWorld1 : TEXCOORD2; //tangentToWorld变换矩阵的第二行
				float4 tangentToWorld2 : TEXCOORD3; //tangentToWorld变换矩阵的第三行
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				//xy存放_MainTex的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//zw存放_BumpMap的纹理坐标
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;	//由法线和切线算出副法线

				o.tangentToWorld0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.tangentToWorld1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.tangentToWorld2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i): SV_Target {
				float3 worldPos = float3(i.tangentToWorld0.w, i.tangentToWorld1.w, i.tangentToWorld2.w);
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);	//利用tex2D对法线纹理_BumpMap进行采样。

				//法线纹理存储的是法线经过映射的像素值, 需要把它反映射回来。
				fixed3 tangentNormal = UnpackNormal(packedNormal);		//反映射, 需要将纹理类型设置为NormalMap。UnpackNormal方法定义在 UnityCG.cginc 中
				tangentNormal.xy *= _BumpScale;							//xy分量乘以凹凸程度进行缩放, 得到最终的xy分量
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));	//因为法线是单位矢量,所以z分量可以由xy分量计算出来

				//将法线从切线空间变换到世界空间
				fixed3 bump = normalize(half3(dot(i.tangentToWorld0.xyz, tangentNormal), dot(i.tangentToWorld1.xyz, tangentNormal), dot(i.tangentToWorld2.xyz, tangentNormal)));

				fixed3 C_light = _LightColor0.rgb;
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;	
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

				//通常，使用纹理来代替物体的漫反射颜色。
				//漫反射计算公式： C_difuse = (C_light * M_diffuse) * max(0, dot(n, l))
				fixed3 diffuse = (C_light * albedo) * saturate(dot(bump, lightDir));

				fixed3 halfDir = normalize(viewDir + lightDir);
				fixed3 M_specular = _Specular.rgb;
				float M_gloss = _Gloss;

				//高光反射计算公式： (C_light * M_specular) * pow(saturate(dot(n, h)), M_gloss);
				fixed3 specular = (C_light * M_specular) * pow(saturate(dot(bump, halfDir)), M_gloss);	//注意原书写的不一致，是因为向量点乘满足交换律。
				
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Specular"
}
