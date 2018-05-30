//渐变纹理
Shader "Unity Shaders Book/Chapter 7/RampTexture"
{
	Properties
	{	
		_Color ("Color Tint", Color) = (1, 1, 1, 1)		//漫反射系数 ，控制漫反射的颜色
		_Specular ("Specular", Color) = (1, 1, 1, 1)	//高光反射系数 ，控制高光反射的颜色	
		_Gloss ("Gloss", Range(8.0, 256)) = 20			//高光反射光泽度(反光度)，控制高光区域的大小

		_RampTex ("Ramp Tex", 2D) = "white" {}			//纹理, 默认为名为"white"的内置的全白纹理
	}

	SubShader
	{	
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"

			fixed4 _Color;
			fixed4 _Specular;
			float _Gloss;
			sampler2D _RampTex;
			//注意：_RampTex_ST 名字不是随便起的，
			//在Unity中，_ST是缩放(Scale)和平移(Translation)的缩写,可以得到该纹理的缩放和平移(偏移)值，
			//_RampTex_ST.xy存放的是缩放值,而_RampTex_ST.zw存储的是偏移值,这些值可以在材质面板的纹理属性中调节。
			float4 _RampTex_ST;	 

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);					//Unity内置方法计算uv
				//o.uv = v.texcoord.xy + _RampTex_ST.xy + _RampTex_ST.zw;	//自己计算uv
				return o;
			}

			fixed4 frag(v2f i): SV_Target {
				fixed3 worldNormal = i.worldNormal;
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 C_light = _LightColor0.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
				fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
				fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;	
				fixed3 diffuse = C_light * diffuseColor;

				//fixed3 albedo = tex2D(_RampTex, i.uv).rgb * _Color.rgb;	
				//fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
				//fixed3 diffuse = (C_light * albedo) * (0.5 * dot(worldNormal, worldLightDir) + 0.5);

				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				fixed3 halfDir = normalize(viewDir + worldLightDir);
				fixed3 M_specular = _Specular.rgb;
				float M_gloss = _Gloss;

				//高光反射计算公式： (C_light * M_specular) * pow(saturate(dot(n, h)), M_gloss);
				fixed3 specular = (C_light * M_specular) * pow(saturate(dot(worldNormal, halfDir)), M_gloss);	//注意原书写的不一致，是因为向量点乘满足交换律。

				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Specular"
}
