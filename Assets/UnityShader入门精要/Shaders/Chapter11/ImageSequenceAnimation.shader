Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)				//
		_MainTex ("Image Sequence", 2D) = "white" {}			//包含了所有关键帧的纹理
    	_HorizontalAmount ("Horizontal Amount", Float) = 4		//水平方向关键帧个数
    	_VerticalAmount ("Vertical Amount", Float) = 4			//竖直方向关键帧个数
    	_Speed ("Speed", Range(1, 100)) = 30					//播放速度
	}
	SubShader {
		//由于序列帧图像通常是透明纹理，所以设置Pass的状态如下以渲染透明效果
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			//关闭深度写入
			ZWrite Off
			//开启并设置混合模式
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;
			  
			struct a2v {  
			    float4 vertex : POSITION; 
			    float2 texcoord : TEXCOORD0;
			};  
			
			struct v2f {  
			    float4 pos : SV_POSITION;
			    float2 uv : TEXCOORD0;
			};  
			
			v2f vert (a2v v) {  
				v2f o;  
				//顶点变换-模型空间到裁剪空间
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);  
				//使用Unity内置的TRANSFORM_TEX方法计算uv
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
				return o;
			}  
			
			fixed4 frag (v2f i) : SV_Target {
				//根据时间，计算当前应显示的帧的行和列索引
				//_Time 为float4类型，它是Unity内置的时间变量： _Time的xyzw分量分别是(t/20,t,2t,3t)（t是自该场景加载开始所经过的时间。）
				
				//模拟时间 = 真实时间 * 速度
				float time = floor(_Time.y * _Speed);  
				float row = floor(time / _HorizontalAmount);	//行索引
				float column = time - row * _HorizontalAmount;	//列索引
				
				//将原uv坐标按行数和列数进行等分，得到每个子图像的纹理坐标范围
//				half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
				//用当前的行列数对上面的结果进行偏移，得到当前子图像的纹理坐标
				//注意： 对竖直方向的坐标偏移需要使用减法，
				//这是因为在Unity中，纹理坐标竖直方向的顺序和序列帧纹理中的顺序是相反的。
//				uv.x += column / _HorizontalAmount;
//				uv.y -= row / _VerticalAmount;
	
				//这块，是对对上边注释部分计算的整理
				half2 uv = i.uv + half2(column, -row);
				uv.x /=  _HorizontalAmount;
				uv.y /= _VerticalAmount;
				
				//根据uv对纹理进行采样
				fixed4 c = tex2D(_MainTex, uv);
				//调整颜色
				c.rgb *= _Color;
				
				return c;
			}
			
			ENDCG
		}  
	}
	FallBack "Transparent/VertexLit"
}
