// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 11/Water" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}							//��������
		_Color ("Color Tint", Color) = (1, 1, 1, 1)						//����������ɫ
		_Magnitude ("Distortion Magnitude", Float) = 1					//ˮ�� ���η���
 		_Frequency ("Distortion Frequency", Float) = 1					//ˮ�� �����ٶ�
 		_InvWaveLength ("Distortion Inverse Wave Length", Float) = 10	//���Ʋ���(����Ƶ��)(�����ǲ����ĵ���)
 		_Speed ("Speed", Float) = 0.5									//�����ƶ��ٶ�
	}
	SubShader {
		// Need to disable batching because of the vertex animation

		//һЩSubShader��ʹ��Unity����������ʱ��������⣬��ʾ����ͨ����ǩ��ֱ��ָ���Ƿ�Ը�SubShaderʹ��������
		//��Щ��Ҫ���⴦���Shaderͨ������ָ ������ģ�Ϳռ�Ķ��㶯����Shader��
		//������Ϊ���������ϲ�������ص�ģ�ͣ�����Щģ�͸��Ե�ģ�Ϳռ�ͻᶪʧ��
		//�ڱ����У���Ҫ��ģ�Ϳռ��¶Զ���λ�ý���ƫ�ơ����������Ҫȡ���Ը�Shader�������������
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			//�ر����д��
			ZWrite Off
			//���������û��ģʽ
			Blend SrcAlpha OneMinusSrcAlpha
			//�ر��޳����ܣ� ����Ϊ����ˮ����ÿ���涼��ʾ��
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

				//��Ҫ���㶥����x�����ƫ��

				// _Frequency * _Time.y Ƶ�ʳ���ʱ�� ����һ��ʱ���񶯶��ٴ� �������Һ�����Ƶ��
				// (v.vertex.x + v.vertex.y + v.vertex.z) * _InvWaveLength ����λ�ó��Բ������� �ò�ͬλ�þ��в�ͬ��λ��
				// x�����񶯣�����Ӧ���� sin(z) ֻ����z���򼴿�(��׼����)(˽�ԸĶ� 2018��8��8�� ����ǿ)��
				// ����_Magnitude ���Ʒ���
				offset.x = sin(_Frequency * _Time.y + (v.vertex.z) * _InvWaveLength) * _Magnitude;

				//�������ƫ�ƣ��任���ü��ռ�
				o.pos = UnityObjectToClipPos(v.vertex + offset);
				
				//��������uv
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				//����y������������
				o.uv += float2(0.0, _Time.y * _Speed);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				//��uv���������
				fixed4 c = tex2D(_MainTex, i.uv);
				//������ɫ
				c.rgb *= _Color.rgb;
				
				return c;
			} 
			
			ENDCG
		}
	}
	FallBack "Transparent/VertexLit"
}
