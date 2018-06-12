//透明度测试
Shader "Unity Shaders Book/Chapter 8/AlphaTestBothSided"
{
	Properties
	{	
		_Color("Main Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		_Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5		//用于调用clip进行透明度测试时使用的判断条件。它的范围是(0, 1),是因为纹理像素的透明度范围就在此范围内
	}

	SubShader
	{	
		//SubShader的标签设置，详见32页表格。
		//"Queue" = "AlphaTest" : 设为AlphaTest队列。需要透明度测试的物体使用这个队列(Unity5以上)
		//"IgnoreProjector" = "true" : true表示 这个Shader不会受投影器(Projector)的影响。
		//"RenderType" = "TransparentCutout": RenderType标签常被用于着色器替换功能。RenderType标签把这个Shader归入到提前定义的组(TransparentCutout:蒙皮透明着色器)中。
		//通常，使用透明测试的Shader都应该在SubShader中设置这三个标签。
		Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "true" "RenderType" = "TransparentCutout"}
		Pass
		{
			Tags {"LightMode" = "ForwardBase" }

			//双面渲染设置
			//Cull Back		//背对着摄像机的渲染图元不会被渲染，默认。
			//Cull Front	//朝着摄像机的渲染图元不会被渲染。
			Cull Off		//关闭剔除,所有渲染图元都会被渲染。

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

			struct a2v{
				float3 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcood : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

			v2f vert(a2v v){
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcood, _MainTex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed4 texColor = tex2D(_MainTex, i.uv);

				// clip() 将舍弃给定参数为负的像素的输出颜色
				// 即 _MainTex上透明通道a 小于 _Cutoff的像素将被舍弃
				clip(texColor.a - _Cutoff);	// 相当于 if((texColor.a-_Cutoff) < 0.0){ discard; }

				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 C_light = _LightColor0.rgb;

				//通常，使用纹理来代替物体的漫反射颜色。
				//漫反射计算公式： C_difuse = (C_light * M_diffuse) * max(0, dot(n, l))
				fixed3 diffuse = (C_light * albedo) * max(0, dot(worldNormal, worldLightDir));

				return fixed4(ambient + diffuse, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Tranparent/Cutoff/VertexLit"
}
