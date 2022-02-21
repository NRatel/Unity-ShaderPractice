// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Vertex Animation With Shadow" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_Magnitude ("Distortion Magnitude", Float) = 1
 		_Frequency ("Distortion Frequency", Float) = 1
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10
 		_Speed ("Speed", Float) = 0.5
	}
	SubShader {
		// Need to disable batching because of the vertex animation
		//Tags {"DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Off
			
			CGPROGRAM  
			#pragma vertex vert 
			#pragma fragment frag
			
			#include "UnityCG.cginc" 
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct a2v {
			    float4 vertex : POSITION;
			    float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};
			
			v2f vert(a2v v) {
				v2f o;
				
				float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);

				//需要计算顶点在x方向的偏移

				// _Frequency * _Time.y 频率乘以时间 代表一定时间振动多少次 控制正弦函数的频率
				// (v.vertex.x + v.vertex.y + v.vertex.z) * _InvWaveLength 顶点位置乘以波长倒数 让不同位置具有不同的位移
				// x方向振动，所以应该是 sin(z) 只保留z方向即可(标准正弦)(私自改动 2018年8月8日 聂红强)。
				// 乘以_Magnitude 控制幅度
				offset.x = sin(_Frequency * _Time.y + v.vertex.z * _InvWaveLength) * _Magnitude;
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv +=  float2(0.0, _Time.y * _Speed);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//用uv对纹理采样
				fixed4 c = tex2D(_MainTex, i.uv);
				//调整颜色
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDCG
		}
		
		// 阴影的Pass
		Pass {
			Tags { "LightMode" = "ShadowCaster" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_shadowcaster
			
			#include "UnityCG.cginc"
			
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
			float _Speed;
			
			struct v2f { 
			    V2F_SHADOW_CASTER;	//Unity内置宏， 定义阴影投射需要的变量
			};
			
			//按正常去昂Pass的处理来剔除片元或进行顶点动画，以便阴影和物体正常渲染的结果匹配
			v2f vert(appdata_base v) {
				v2f o;
				
				float4 offset;
				offset.yzw = float3(0.0, 0.0, 0.0);

				offset.x = sin(_Frequency * _Time.y + v.vertex.z * _InvWaveLength) * _Magnitude;
				v.vertex = v.vertex + offset;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)	//Unity内置宏， 处理阴影投射需要的变量
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
			    SHADOW_CASTER_FRAGMENT(i)	//Unity内置宏，完成阴影投射部分，把结果输出到深度图和阴影映射纹理中。
			}
			ENDCG
		}
	}
	FallBack "VertexLit"
}
