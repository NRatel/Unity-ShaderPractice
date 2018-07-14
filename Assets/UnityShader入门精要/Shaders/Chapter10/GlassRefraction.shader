// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}						//玻璃的材质纹理，默认为白色纹理
		_BumpMap ("Normal Map", 2D) = "bump" {}						//玻璃的法线纹理
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}		//用于模拟反射的环境纹理
		_Distortion ("Distortion", Range(0, 100)) = 10				//用于控制模拟折射时图像的扭曲程度
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0	//用于控制折射程度。为0时只包含反射，为1时只包含折射
	}
	SubShader {
		//虽然代码里不包含混合指令，但往往仍然需要把物体的渲染队列设置为透明队列，这样才能保证 其他所有不透明物体先于此物体绘制在屏幕上。
		//尽管后边的 RenderType 设置为了Opaque 这两者("Queue"="Transparent" "RenderType"="Opaque")看着矛盾,但实际服务于不同的需求,
		// RenderType 是为了在使用着色器替换（Shader Replacement）时，该物体可以在需要时被正确渲染，这通常发生在我们需要得到摄像机的深度和法线纹理时。
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		//关键字GrabPass定义了一个抓取屏幕图像的Pass。zai zhege Pass中定义了一个字符串，该字符串的内部名称决定了抓取得到的屏幕图像会被存入哪个纹理中，
	
		//实际上有两种使用方式，
		//1、直接使用 GrabPass{}，然后在后续的Pass中直接使用 _GrabPass来访问屏幕图像。但是当场景中有多个物体都使用了这样的形式来抓取屏幕时，这种方法的性能消耗比较大，
		//   因为对与每个使用它的物体，Unity都会为它单独进行依次昂贵的屏幕抓取操作。但这种方法可以让每个物体得到不同的屏幕图像，这取决于他们的渲染队列及渲染它们时当前的屏幕缓冲中的颜色。
		//
		//2、使用 GrabPass{"TextureName"}，正如本届中的实现，我们可以在后续的Pass中使用TextureName来访问屏幕图像。
		//   使用这种方法同样可以抓取屏幕，但Unity只会在每一帧为第一个使用名为TextureName的物体执行一次抓取屏幕的操作，而这个纹理同样可以在其他的Pass中被访问。
		//   这种方法更高效，因为不管场景中有多少物体使用了该命令，每一帧中Unity都只会执行一次抓取工作，
		//   但这也意味着所有物体都会使用同一张屏幕图像。不过，在大多数情况下着已经足够了。
		GrabPass { "_RefractionTex" }
		
		Pass {		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			sampler2D _MainTex;			
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;			//用来得到GrabPass指定名称的纹理	
			float4 _RefractionTex_TexelSize;	//用来得到GrabPass指定名称的“纹素”大小, 纹素为: (1/纹理宽, 1/纹理高)。
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.scrPos = ComputeGrabScreenPos(o.pos);			//用内置的 ComputeGrabScreenPos (声明在 UnityCG.cginc 中)函数计算得到对应被抓取的屏幕图像的采样坐标
				
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);	//_MainTex的采样坐标
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);	//_BumpMap的采样坐标
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;				//世界空间下的坐标
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);				//世界空间下的法线方向
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);				//世界空间下的切线方向
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;	//世界空间下的副切线方向
				
				//由于需要在片元着色器中把法线方向从切线空间（由法线纹理采样得到）变换到世界空间下，以便对CubeMap进行采样，
				//因此，需要在这里计算该顶点对应的从切线空间到世界空间的变换矩阵，并把该矩阵分别存储在TtoW0、TtoW1、TtoW2的xyz分量中，
				//这里面使用的数学方法就是，得到切线空间下的3个坐标轴（xyz轴分别对应了副切线、切线和法线的方向）在世界空间下的表示，
				//再一次按列组成一个变换矩阵即可。
				//TtoW0等值的w轴同样被利用起来，用于存储世界空间下的顶点坐标。
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {		
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));		//世界空间下的视角方向
				
				//对法线纹理进行采样，得到切线空间的法线方向
				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));	
				
				//使用 bump、_Distortion、_RefractionTex_TexelSize 来对屏幕图像的采样坐标进行偏移, 模拟折射效果，
				//_Distortion值越大，偏移量越大，玻璃背后的物体看起来变形程度越大。
				//这里使用切线空间的法线方向偏移，是因为该空间下的法线可以反映顶点局部空间下的法线方向。
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				//对srcPos 透视除法得到真正的屏幕坐标（原理可参见4.9.3节），
				//再使用该坐标对抓取的屏幕图像_RefractionTex进行采样，得到模拟的折射颜色
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				//把法线方向从切线空间变换到世界空间下（使用变换矩阵的每一行，即TtoW0、TtoW1、TtoW2分别和法线方向点乘，构成新的法线方向）
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				//得到视角方向相对于法线方向的反射方向
				fixed3 reflDir = reflect(-worldViewDir, bump);
				//对_MainTex纹理进行采样
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				//使用反射方向对Cubemap进行采样，并把结果和主纹理颜色相乘得到反射颜色
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				//使用 _RefractAmount属性对反射和折射颜色进行混合，得到最终颜色。
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;
				
				return fixed4(finalColor, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
