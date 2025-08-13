using UnityEngine;
using UnityEngine.Serialization;

//behaviour which should lie on the same gameobject as the main camera
public class PostprocessingBlur : MonoBehaviour {
	//material that's applied when doing postprocessing
	[FormerlySerializedAs("postprocessMaterial"), SerializeField]
	public Material PostprocessMaterial;

	//method which is automatically called by unity after the camera is done rendering
	// Unity在相机渲染完成后自动调用的方法
	void OnRenderImage(RenderTexture source, RenderTexture destination){
		//draws the pixels from the source texture to the destination texture
		// 从源纹理绘制像素到目标纹理
		var temporaryTexture = RenderTexture.GetTemporary(source.width, source.height);
		// 第一次Blit：垂直模糊（Pass 0）
		// 输入：原始图像，输出：临时纹理，只在Y方向进行模糊
		Graphics.Blit(source, temporaryTexture, PostprocessMaterial, 0);
		// 第二次Blit：水平模糊（Pass 1）
		// 输入：临时纹理，输出：最终结果，只在X方向进行模糊
		// 分离式模糊：从O(n²)复杂度降到O(2n)复杂度，性能优化
		Graphics.Blit(temporaryTexture, destination, PostprocessMaterial, 1);
		RenderTexture.ReleaseTemporary(temporaryTexture);
	}
}