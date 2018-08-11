Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}		//Graphics.Blit(src, dest, material); 将把第一个参数传递给Shader的 _MainTex 属性
		
		//对于脚本控制的Shader 属性展示名其实可以省略。
		_Brightness ("Brightness", Float) = 1			
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
	}

	SubShader {
		//定义 用于屏幕后处理的Pass
		Pass {  
			//屏幕后处理，实际上是在场景中绘制了一个与屏幕同宽高的四边形面片，为了防止它对其他物体产生影响,需要设置相关的渲染状态。
			//这些状态设置可以认为是用于屏幕后处理的Shader的标配

			ZTest Always 
			Cull Off 

			//关闭深度写入，为了防止它“挡住”在其后面被渲染的物体。
			//例如，如果当前的OnRenderImage函数在所有不透明的Pass执行完毕后立即被调用，不关闭深度写入就会影响后面透明的Pass的渲染。
			ZWrite Off
			
			CGPROGRAM  
			#pragma vertex vert  
			#pragma fragment frag  
			  
			#include "UnityCG.cginc"  
			  
			sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;
			  
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {		//使用了 appdata_img 代替 a2v 结构体，定义于UnityCG.cginc中，它包含了图像处理时必需的顶点坐标和纹理坐标等变量。
				v2f o;
				
				//顶点从模型空间变换到裁剪空间
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				//计算uv
				o.uv = v.texcoord;
						 
				return o;
			}
		
			fixed4 frag(v2f i) : SV_Target {
				//使用uv对纹理采样
				fixed4 renderTex = tex2D(_MainTex, i.uv);  
				  
				//使用 _Brightness 调整亮度，
				//相乘即可
				fixed3 finalColor = renderTex.rgb * _Brightness;
				
				//使用 _Saturation 调整饱和度
				//首先，计算该像素对应的亮度值luminance，通过对每个颜色分量乘以一个特定的系数再相加得到
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				//然后，使用luminance创建一个饱和度为0的颜色值。
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				//最后，在luminanceColor和_Saturation之间进行插值，从而得到希望的饱和度颜色。
				finalColor = lerp(luminanceColor, finalColor, _Saturation);
				
				//使用 _Contrast 调整对比度
				//首先，创建一个对比度为0的颜色值(各分量均为0.5)
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				//然后，在avgColor和_Contrast之间进行插值，从而得到最终的处理结果。
				finalColor = lerp(avgColor, finalColor, _Contrast);
				
				return fixed4(finalColor, renderTex.a);  
			}  
			  
			ENDCG
		}  
	}
	
	Fallback Off
}
