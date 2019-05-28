Shader "Unity Shaders Book/Chapter 11/Scrolling Background2" {
	Properties {
		_MainTex ("Base Layer (RGB)", 2D) = "white" {}			//第一层纹理(下层)
		_DetailTex ("2nd Layer (RGB)", 2D) = "white" {}			//第二层纹理(上层)
		_ScrollX ("Base layer Scroll Speed", Float) = 1.0		//第一层滚动速度
		_Scroll2X ("2nd layer Scroll Speed", Float) = 1.0		//第二层滚动速度
		_Multiplier ("Layer Multiplier", Float) = 1				//控制纹理整体亮度
	}
	SubShader {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_nicest 
			//#pragma fragmentoption ARB_precision_hint_fastest
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;
			sampler2D _DetailTex;
			float4 _MainTex_ST;
			float4 _DetailTex_ST;
			float _ScrollX;
			float _Scroll2X;
			float _Multiplier;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;
				//基本操作。模型空间顶点变换到裁剪空间
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);	
				
				//首先使用Unity内置的TRANSFORM_TEX方法计算uv，然后利用_Time.y 在水平方向(x方向)上对纹理坐标进行偏移
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);

				//计算第二张纹理的uv
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);
				
				//两张图片的uv保存到一个float4中，为了减少插值寄存器空间
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				//根据uv 对纹理采样
				fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
				fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);
				
				//使用第二层(上层)纹理的透明通道混合两张纹理
				fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);

				//调整整体颜色
				c.rgb *= _Multiplier;
				
				return c;
			}
			
			ENDCG
		}
	}
	FallBack "VertexLit"
}
