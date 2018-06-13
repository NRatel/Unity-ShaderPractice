// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unity Shaders Book/Chapter 9/AlphaTestWithShadow" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Main Tex", 2D) = "white" {}
		_Cutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Off
			
			CGPROGRAM
			
			//保证在Shader中使用光照衰减等光照变量可以被正确赋值，必不可少
			#pragma multi_compile_fwdbase
			
			#pragma vertex vert
			#pragma fragment frag
			
			//光照参数需要的宏
			#include "Lighting.cginc"
			//计算阴影需要的宏
			#include "AutoLight.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;
			
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
				//内置宏， 声明一个用于对阴影纹理采样的坐标。 
				//这个宏的参数需要是下一个可用的插值寄存器的索引值。 此处已占用TEXCOORD0、TEXCOORD1、TEXCOORD2 所以是3
				SHADOW_COORDS(3)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			 	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
			 	
			 	//内置宏， 用于在顶点着色器中计算上一步声明的阴影纹理坐标。
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed4 texColor = tex2D(_MainTex, i.uv);

				clip (texColor.a - _Cutoff);
				
				fixed3 albedo = texColor.rgb * _Color.rgb;
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
							 	
			 	//内置宏，计算光照衰减系数值 和 阴影系数值
				//它接收三个参数，它会将光照衰减和阴影值相乘后的结果存储到第一个参数中.
				//参数1，atten 不需要声明，会在UNITY_LIGHT_ATTENUATION中自动声明。
				//参数2，是片元着色器的传入结构体 v2f。 这个参数会被传递给 SHADOW_ATTENUATION 计算阴影系数值。
				//参数3，这个参数会用于计算光源空间下的坐标，再对光照衰减纹理采样，来得到光照衰减。
				//使用它，可以让 ForwardBase 和 ForwardAdd 中的处理一致：
				//		ForwardBase中不用单独处理阴影，ForwardAdd不用单独判断光源类型处理光照衰减 。
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
			 	
				return fixed4(ambient + diffuse * atten, 1.0);
			}
			
			ENDCG
		}
	}

	//投射阴影，不会处理镂空部分
	//FallBack "VertexLit"						
	//投射阴影，会处理镂空部分。 注意它的透明度测试属性是 _Cutoff， 所以本Shader中的透明度测试属性也必须是 _Cutoff 否则将不可用。
	//注意，同时应该把模型MeshRender的 CastShadows 改为TwoSided, 让Unity在计算阴影映射纹理时，计算所有面的深度信息
	FallBack "Transparent/Cutout/VertexLit"		
}
