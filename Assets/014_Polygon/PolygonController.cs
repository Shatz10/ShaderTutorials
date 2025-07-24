using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
[RequireComponent(typeof(Renderer))]
public class PolygonController : MonoBehaviour {
	
	public Vector2[] corners;

	private Material _mat;

	void Start(){
		UpdateMaterial();
	}

	void OnValidate(){
		UpdateMaterial();
	}
	
	void UpdateMaterial(){
		//fetch material if we haven't already
		if(_mat == null)
			_mat = GetComponent<Renderer>().sharedMaterial;
		
		// unity API 只允许我们传递 4d 向量，而 1000 可变长度的原因是，正如我之前提到的，着色器不支持动态数组长度
		//allocate and fill array to pass
		Vector4[] vec4Corners = new Vector4[1000];
		for(int i=0;i<corners.Length;i++){
			vec4Corners[i] = corners[i];
		}

		//pass array to material
		_mat.SetVectorArray("_corners", vec4Corners);
		_mat.SetInt("_cornerCount", corners.Length);
	}

	private void Update()
	{
		isLeftOfLine(corners[0], corners[1], corners[2]);
	}

	float isLeftOfLine(Vector2 pos, Vector2 linePoint1, Vector2 linePoint2){
		//variables we need for our calculations
		Vector2 lineDirection = linePoint2 - linePoint1;
		Vector2 lineNormal = new Vector2(-lineDirection.y, lineDirection.x);

		Vector2 toPos = pos - linePoint1;
		
		Debug.DrawLine(new Vector3(0, 0, 0), lineDirection, Color.red);
		Debug.DrawLine(new Vector3(0, 0, 0), lineNormal, Color.green);

		//which side the tested position is on
		float side = Vector2.Dot(toPos, lineNormal);
		side = side > 0 ? 1 : 0;
		return side;
	}

}

