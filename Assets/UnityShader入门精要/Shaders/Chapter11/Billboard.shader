// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//广告牌： 始终面向摄像机
Shader "Unity Shaders Book/Chapter 11/Billboard" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}								//主纹理
		_Color ("Color Tint", Color) = (1, 1, 1, 1)							//控制整体颜色
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1		//调整是固定法线还是固定指向上的方向，即约束垂直方向的程度
	}
	SubShader {
		// Need to disable batching because of the vertex animation

		//一些SubShader在使用Unity的批处理功能时会出现问题，提示可以通过标签来直接指明是否对该SubShader使用批处理
		//这些需要特殊处理的Shader通常就是指 包含了模型空间的顶点动画的Shader。
		//这是因为，批处理会合并所有相关的模型，而这些模型各自的模型空间就会丢失。
		//在本例中，需要使用物体的模型空间下的位置来作为锚点进行计算，因此需要取消对该Shader的批处理操作
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			//关闭深度写入
			ZWrite Off
			//开启并设置混合模式
			Blend SrcAlpha OneMinusSrcAlpha
			//关闭剔除功能， 这是为了让广告牌的每个面都能显示
			Cull Off
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;
			
			struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (a2v v) {
				v2f o;

				//选择模型空间的原点作为广告牌的锚点(应该说是pivot吧？旋转中点)
				float3 center = float3(0, 0, 0);

				//利用内置变量_WorldSpaceCameraPos 获取世界空间下的视角位置，并用unity_WorldToObject 变换到模型空间下
				float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
				
				//使用观察位置减去中心点，得到法线方向
				float3 normalDir = viewer - center;

				//使用_VerticalBillboarding控制垂直方向上的约束度
				//当_VerticalBillboarding为1时，意味着法线方向固定为视角方向； 当_VerticalBillboarding为0时，意味着向上方向固定为(0, 1, 0)。
				normalDir.y = normalDir.y * _VerticalBillboarding;
				//对计算得到的法线方向进行归一化
				normalDir = normalize(normalDir);

				//获取近似的向上的方向 
				//为了防止法线方向和向上方向平行(如果平行，那么叉积得到的结果将是错误的)，我们对法线方向的y分量进行判断，以得到合适的向上方向。
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);

				//根据法线方向和近似的向上方向 叉积得到向右方向，并对结果归一化
				float3 rightDir = normalize(cross(upDir, normalDir));
				//根据法线方向和准确的向右方向 叉积得到最终的、准确的向上方向。
				upDir = normalize(cross(normalDir, rightDir));
				
				//根据原始的位置相对于锚点的偏移量以及三个正交基矢量，计算得到新的顶点位置
				float3 centerOffs = v.vertex.xyz - center;
				float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;
				
				//把模型空间的顶点位置变换到裁剪空间
				o.pos = UnityObjectToClipPos(float4(localPos, 1));
				//计算uv
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {
				//根据uv采样
				fixed4 c = tex2D (_MainTex, i.uv);
				//调整颜色
				c.rgb *= _Color.rgb;
				
				return c;
			}
			
			ENDCG
		}
	} 
	FallBack "Transparent/VertexLit"
}
