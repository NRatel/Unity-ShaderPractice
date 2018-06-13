// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

//Shader代码主要用来接受阴影， 投射阴影功能在 FallBack Specular =》 VerLit Sahder中
Shader "Unity Shaders Book/Chapter 9/Shadow" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		
		//环境光、自发光、最亮的直射光等光源的 Pass。只执行一次。
		Pass {
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			//保证在Shader中使用光照衰减等光照变量可以被正确赋值，必不可少
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			//光照参数需要的宏
			#include "Lighting.cginc"
			//计算阴影需要的宏
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;				//为了宏可正确使用，变量名必须为vertex
				float3 normal : NORMAL;
			};
			
			struct v2f {								
				float4 pos : SV_POSITION;				//为了宏可正确使用，变量名必须为pos
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				//内置宏， 声明一个用于对阴影纹理采样的坐标。 
				//这个宏的参数需要是下一个可用的插值寄存器的索引值。 此处已占用TEXCOORD0、TEXCOORD1所以是2
				SHADOW_COORDS(2)	
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);

			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	
			 	//内置宏， 用于在顶点着色器中计算上一步声明的阴影纹理坐标。
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//漫反射
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
				//高光反射
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				//衰减系数值
				fixed atten = 1.0;
				
				//内置宏，计算阴影系数值
				fixed shadow = SHADOW_ATTENUATION(i);
				
				return fixed4(ambient + (diffuse + specular) * atten * shadow, 1.0);
			}
			
			ENDCG
		}
	
		//其他逐像素光源 Pass。 根据其他光源的个数，执行多次, 按光源重要程度顺序依次执行(重要程度与光强度、远近等有关)。
		//光源多时，影响性能。可设置光源的重要程度(逐像素变为逐顶点)。
		Pass {
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One
		
			CGPROGRAM
			
			//保证在Shader中使用光照变量可以被正确赋值
			#pragma multi_compile_fwdadd
			//需要计算阴影时启用，代替multi_compile_fwdadd
			//#pragma multi_compile_fwdadd_fullshadows
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 position : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.position = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif

			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;
				#else
					float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
					fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				#endif
			 	
				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}