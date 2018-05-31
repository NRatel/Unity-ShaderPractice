//透明度混合
Shader "NRatelShader/AlphaBlend"
{
	Properties
	{	
		_Color("Main Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}
		_AlphaScale ("AlphaScale", Range(0, 1)) = 1		//控制整体透明度
	}

	SubShader
	{	
		//SubShader的标签设置，详见32页表格。
		//"Queue" = "Transparent" : 设为Transparent渲染队列。使用了透明度混合的物体需要使用这个队列
		//"IgnoreProjector" = "true" : true表示 这个Shader不会受投影器(Projector)的影响。
		//"RenderType" = "Transparent": RenderType标签常被用于着色器替换功能。RenderType标签把这个Shader归入到提前定义的组(Transparent:半透明着色器)中。
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "true" "RenderType" = "Transparent"}
		Pass
		{
			Tags {"LightMode" = "ForwardBase" }
				
			//状态设置指令, 详见31页表格。
			ZWrite Off								//关闭该Pass的深度写入
			Blend SrcAlpha OneMinusSrcAlpha			//开启并设置Pass的混合模式

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;

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

				fixed3 albedo = texColor.rgb * _Color.rgb;
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				
				fixed3 C_light = _LightColor0.rgb;

				//通常，使用纹理来代替物体的漫反射颜色。
				//漫反射计算公式： C_difuse = (C_light * M_diffuse) * max(0, dot(n, l))
				fixed3 diffuse = (C_light * albedo) * max(0, dot(worldNormal, worldLightDir));

				//这里只需使用贴图对应像素真实透明度和透明度缩放的乘积。
				return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
			}

			ENDCG
		}
	}

	Fallback "Tranparent/Cutoff/VertexLit"
}
