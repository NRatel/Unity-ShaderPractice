using UnityEngine;
using System.Collections;

//调整屏幕亮度、饱和度和对比度
public class BrightnessSaturationAndContrast : PostEffectsBase {

	public Shader briSatConShader;          //自己指定的Shader (Brightness Saturation And Contrast)
	private Material briSatConMaterial;     //由briSatConShader 创建的材质
    public Material material {              //
		get {
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}  
	}

	[Range(0.0f, 3.0f)]
	public float brightness = 1.0f;         //调整亮度的参数

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;         //调整饱和度的参数

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;           //调整对比度的参数

	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

			Graphics.Blit(src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
