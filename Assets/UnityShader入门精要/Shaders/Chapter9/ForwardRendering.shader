Shader "Unity Shaders Book/Chapter 9/ForwardRendering"
{
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
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				//漫反射 Lambert模型
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);

				//高光反射 Blinn-Pong模型
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				//光衰减值, 认为直射光不衰减
				fixed atten = 1.0;
				
				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
		
		//其他逐像素光源 Pass。 根据其他光源的个数，执行多次, 按光源重要程度顺序依次执行(重要程度与光强度、远近等有关)。
		//光源多时，影响性能。可设置光源的重要程度(逐像素变为逐顶点)。
		Pass {
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One	//混合系数，不必需
		
			CGPROGRAM
			
			//保证在Shader中使用光照变量可以被正确赋值
			#pragma multi_compile_fwdadd
			
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
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}  
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);

				//光照方向
				#ifdef USING_DIRECTIONAL_LIGHT
					//直射光 的光源方向就是 _WorldSpaceLightPos0.xyz
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					//_WorldSpaceLightPos0.xyz 表示世界空间下的光源位置, 它与世界空间下的顶点位置，就是光源方向
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				//漫反射 Lambert模型
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				
				//高光反射 Blinn-Pong模型
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				//直射光
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed atten = 1.0;	//直射光衰减系数恒为1.0
				#else
					//点光源
					#if defined (POINT)
						//世界空间顶点坐标转到光照空间
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
						//Unity 使用名为 _LightTexture0 的纹理来计算光源衰减，对角线上的纹理颜色值表示在光源空间下不同位置的点的衰减值，
						//(0, 0) 表示与光源位置重合的点，(1, 1)表示在光源空间下所关心的距离最远的点的衰减。
						//通过对_LightTexture0采样, 计算点光源的光衰减值
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
						//世界空间顶点坐标转到光照空间
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));							
						//通过对_LightTexture0采样,计算聚光光源的光衰减值
				        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;	//直射光恒为1.0
				    #endif
				#endif

				//注意，ForwardAdd Pass中不再计算环境光
				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}
