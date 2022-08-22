//#if UNITY_EDITOR  
using System;
using UnityEngine;
using UnityEditor;

public class LayaGlassGUI : ShaderGUI
{

    public override void AssignNewShaderToMaterial(Material material, Shader oldShader, Shader newShader)
    {
        material.shader = newShader;
        material.EnableKeyword("EnableLighting");
        onChangeRender(material, (RenderMode)material.GetFloat("_Mode"));
    }
    public enum RenderMode
    {
        /**äÖÈ¾×´Ì¬_²»Í¸Ã÷¡£*/
        Opaque = 0,
        /**äÖÈ¾×´Ì¬_Í¸Ã÷²âÊÔ¡£*/
        Cutout = 1,
        /**äÖÈ¾×´Ì¬_Í¸Ã÷»ìºÏ¡£*/
        Transparent = 2,
        /**äÖÈ¾×´Ì¬_×Ô¶¨Òå¡£*/
        Custom = 3
    }

    public enum SrcBlendMode
    {
        //Blend factor is (0, 0, 0, 0).
        Zero = 0,
        //Blend factor is (1, 1, 1, 1).
        One = 1,
        //Blend factor is (Rd, Gd, Bd, Ad).
        DstColor = 2,
        //Blend factor is (Rs, Gs, Bs, As).
        SrcColor = 3,
        //Blend factor is (1 - Rd, 1 - Gd, 1 - Bd, 1 - Ad).
        OneMinusDstColor = 4,
        //Blend factor is (As, As, As, As).
        SrcAlpha = 5,
        //Blend factor is (1 - Rs, 1 - Gs, 1 - Bs, 1 - As).
        OneMinusSrcColor = 6,
        //Blend factor is (Ad, Ad, Ad, Ad).
        DstAlpha = 7,
        //Blend factor is (1 - Ad, 1 - Ad, 1 - Ad, 1 - Ad).
        OneMinusDstAlpha = 8,
        //Blend factor is (f, f, f, 1); where f = min(As, 1 - Ad).
        SrcAlphaSaturate = 9,
        //Blend factor is (1 - As, 1 - As, 1 - As, 1 - As).
        OneMinusSrcAlpha = 10
    }

    public enum DstBlendMode
    {
        //Blend factor is (0, 0, 0, 0).
        Zero = 0,
        //Blend factor is (1, 1, 1, 1).
        One = 1,
        //Blend factor is (Rd, Gd, Bd, Ad).
        DstColor = 2,
        //Blend factor is (Rs, Gs, Bs, As).
        SrcColor = 3,
        //Blend factor is (1 - Rd, 1 - Gd, 1 - Bd, 1 - Ad).
        OneMinusDstColor = 4,
        //Blend factor is (As, As, As, As).
        SrcAlpha = 5,
        //Blend factor is (1 - Rs, 1 - Gs, 1 - Bs, 1 - As).
        OneMinusSrcColor = 6,
        //Blend factor is (Ad, Ad, Ad, Ad).
        DstAlpha = 7,
        //Blend factor is (1 - Ad, 1 - Ad, 1 - Ad, 1 - Ad).
        OneMinusDstAlpha = 8,
        //Blend factor is (f, f, f, 1); where f = min(As, 1 - Ad).
        SrcAlphaSaturate = 9,
        //Blend factor is (1 - As, 1 - As, 1 - As, 1 - As).
        OneMinusSrcAlpha = 10
    }

    public enum CullMode
    {
        CULL_NONE = 0,
        CULL_FRONT = 1,
        CULL_BACK = 2,
    }

    public enum DepthWrite
    {
        OFF = 0,
        ON = 1
    }

    public enum DepthTest
    {
        OFF = 0,
        Never = 1,
        LESS = 2,
        EQUAL = 3,
        LEQUAL = 4,
        GREATER = 5,
        NOTEQUAL = 6,
        GEQUAL = 7,
        ALWAYS = 8
    }

    public enum LightingMode
    {
        ON = 0,
        OFF = 1,
    }


    MaterialProperty refractionTexture = null;
    MaterialProperty albedoColor = null;
    MaterialProperty renderMode = null;
    MaterialProperty refractionRange = null;
    MaterialProperty ambientLight_Int = null;
    MaterialProperty ambientLight = null;
    MaterialProperty tilingOffset = null;

    MaterialEditor m_MaterialEditor;



    public void FindProperties(MaterialProperty[] props)
    {
        refractionTexture = FindProperty("_Refraction", props);
        albedoColor = FindProperty("_Glass_Color", props);
        renderMode = FindProperty("_Mode", props);
        refractionRange = FindProperty("_Refraction_Int", props);
        ambientLight_Int = FindProperty("_Glass_AmbientLight_Int", props);
        ambientLight = FindProperty("_Glass_AmbientLight", props);
        tilingOffset = FindProperty("tilingOffset", props);
    }



    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] props)
    {
        // render the default gui
        FindProperties(props);
        m_MaterialEditor = materialEditor;
        Material material = materialEditor.target as Material;

        ShaderPropertiesGUI(material);
    }

    public void ShaderPropertiesGUI(Material material)
    {
        onChangeRender(material, 0);
        // Use default labelWidth
        EditorGUIUtility.labelWidth = 0f;

        // Detect any changes to the material
        EditorGUI.BeginChangeCheck();
        {

            //albedo
            m_MaterialEditor.ShaderProperty(albedoColor, "²£Á§ÑÕÉ«");

            m_MaterialEditor.TexturePropertySingleLine(Styles.albedoText, refractionTexture);
            m_MaterialEditor.ShaderProperty(refractionRange, "·¨ÏßÆ«ÒÆ");
            m_MaterialEditor.ShaderProperty(ambientLight_Int, "·´ÉäÏµÊý");
            m_MaterialEditor.TexturePropertySingleLine(Styles.ambientLightText,ambientLight);

            GUILayout.Label(Styles.tillingOffset);
            m_MaterialEditor.VectorProperty(tilingOffset, "");
        }
    }

    public void onChangeRender(Material material, RenderMode mode)
    {

        material.SetInt("_Mode", 0);
        material.SetInt("_AlphaTest", 0);
        material.SetInt("_AlphaBlend", 0);
        material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        material.SetInt("_ZWrite", 2);
        material.SetInt("_ZTest", 2);
        material.DisableKeyword("_ALPHATEST_ON");
        material.DisableKeyword("_ALPHABLEND_ON");
        material.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;

    }

    public static class Styles
    {
        public static GUIStyle optionsButton = "PaneOptions";
        public static GUIContent uvSetLabel = new GUIContent("UV Set");
        public static GUIContent[] uvSetOptions = new GUIContent[] { new GUIContent("UV channel 0"), new GUIContent("UV channel 1") };

        public static string emptyTootip = "";
        public static GUIContent albedoText = new GUIContent("ÕÛÉäÌùÍ¼", "ÕÛÉäÌùÍ¼ (RGB)");
        public static GUIContent ambientLightText = new GUIContent("·´É«ÌùÍ¼", "·´É«ÌùÍ¼ (RGB)");
        public static GUIContent tillingOffset = EditorGUIUtility.TrTextContent("ÌùÍ¼Æ«ÒÆ", "ÌùÍ¼Ëõ·ÅÆ«ÒÆ");
    }
}
