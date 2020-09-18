using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ShadowHelper : MonoBehaviour
{
    // Start is called before the first frame update
    public SkinnedMeshRenderer Renderer;
    public Light mainLight;
    private Vector4 _ShadowFadeParams = new Vector4(0.0f, 1.5f, 0.7f, 0.0f);

    // Update is called once per frame
    void Update()
    {
        UpdateShader();
    }

    private void UpdateShader()
    {
        Vector4 worldpos = transform.position;
        Vector3 shadowPlaneNrm = transform.up;
        //计算平面法线与平面上某一点的点乘，由于人物行走在平面上，人物脚下的点必定在平面上
        float nrmDotPos = Vector3.Dot(shadowPlaneNrm, worldpos);
        // Vector4 projdir = new Vector4(-0.2f,-0.8f,-0.6f,0);
        Vector4 projdir = mainLight.transform.forward;
        Material mat = Renderer.material;
        //   foreach (var mat in mMatList)
        //   {
        if (mat == null)
            return;

        mat.SetVector("_WorldPos", worldpos);
        mat.SetVector("_ShadowProjDir", projdir);
        //  mat.SetVector("_ShadowPlane", new Vector4(2.289143f, -11.88877f, 28.79983f, 0.0f));
        mat.SetVector("_ShadowPlane", new Vector4(shadowPlaneNrm.x, shadowPlaneNrm.y, shadowPlaneNrm.z, nrmDotPos));
        mat.SetVector("_ShadowFadeParams", _ShadowFadeParams);
        mat.SetFloat("_ShadowFalloff", 1.35f);
        //  }
    }
}
