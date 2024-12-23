using System;
using System.Collections;
using UnityEngine;

public class Molten : MonoBehaviour
{
    private bool startMolten;
    private float startTime;
    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.H))
        {
            startMolten = true;
            StartCoroutine(CoMolten());
        }

        if (startMolten)
        {
            Renderer renderer = GetComponent<Renderer>();
            Material material = renderer.material;
            material.SetFloat("_Blend", Time.time - startTime);
        }
    }

    IEnumerator CoMolten()
    {
        startTime = Time.time;
        yield return new WaitForSeconds(1);
        startMolten = false;
    }
}