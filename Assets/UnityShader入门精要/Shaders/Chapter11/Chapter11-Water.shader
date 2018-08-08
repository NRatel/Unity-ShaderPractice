Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}							//河流纹理
		_Color ("Color Tint", Color) = (1, 1, 1, 1)						//控制整体颜色
		_Magnitude ("Distortion Magnitude", Float) = 1					//水波 变形幅度
 		_Frequency ("Distortion Frequency", Float) = 1					//水波 变形速度
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10	//控制波长(波的频率)(这里是波长的倒数)
 		_Speed ("Speed", Float) = 0.5									//控制移动速度
	}
	SubShader {
		// Need to disable batching because of the vertex animation

		//一些SubShader在使用Unity的批处理功能时会出现问题，提示可以通过标签来直接指明是否对该SubShader使用批处理
		//这些需要特殊处理的Shader通常就是指 包含了模型空间的顶点动画的Shader。
		//这是因为，批处理会合并所有相关的模型，而这些模型各自的模型空间就会丢失。
		//在本例中，需要在模型空间下对顶点位置进行偏移。因此这里需要取消对该Shader的批处理操作。
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			//关闭深度写入
			ZWrite Off
			//开启并设置混合模式
			Blend SrcAlpha OneMinusSrcAlpha
			//关闭剔除功能， 这是为了让水流的每个面都显示。
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
				// x方向振动，所以应该是 sin(z) 只保留z方向即可(标准正弦)(私自改动 2018年8岳8日 聂红强)。
				// 乘以_Magnitude 控制幅度
				offset.x = sin(_Frequency * _Time.y + (v.vertex.z) * _InvWaveLength) * _Magnitude;

				//顶点加上偏移，变换到裁剪空间
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex + offset);
				
				//计算纹理uv
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				//纹理y方向上做动画
				o.uv += float2(0.0, _Time.y * _Speed);
				
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
	}
	FallBack "Transparent/VertexLit"
}
