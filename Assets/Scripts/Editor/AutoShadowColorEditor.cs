using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditorInternal;
using System.IO;

[CustomEditor(typeof(AutoShadowColor))]
public class AutoShadowColorEditor : Editor
{
    private void OnValidate()
    {
        var init = serializedObject.FindProperty("_init");
        if (init?.boolValue == false)
            Setup();

        var debuging = serializedObject.FindProperty("_Debuging");
        if (debuging?.boolValue == false) {
            Shader.DisableKeyword(AutoShadowColorDebugToggle);
        }
        if (debuging?.boolValue == true) {
            Shader.EnableKeyword(AutoShadowColorDebugToggle);
        }
        
    }


    //设置抬头
    void DoSmallHeader(string header)
    {
        EditorGUI.indentLevel -= 1;
        EditorGUILayout.LabelField(header, EditorStyles.boldLabel);
        EditorGUI.indentLevel += 1;
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();


        DoSmallHeader("Hue");

        var hueShift = serializedObject.FindProperty("HUEShift");
        EditorGUILayout.PropertyField(hueShift, new GUIContent("HueShift", ""));

        DoSmallHeader("Saturation");

        var saturation = serializedObject.FindProperty("SatShift");
        EditorGUILayout.PropertyField(saturation, new GUIContent("SatShift", ""));

        DoSmallHeader("Value");

        var value = serializedObject.FindProperty("ValShift");
        EditorGUILayout.PropertyField(value, new GUIContent("ValShift", ""));

        DoSmallHeader("Debug");
        var debugToggle = serializedObject.FindProperty("_Debuging");
        EditorGUILayout.PropertyField(debugToggle, new GUIContent("Debug", ""));
        EditorGUILayout.Space();
        EditorGUILayout.BeginHorizontal();
        var lutName = serializedObject.FindProperty("LutName");
        EditorGUILayout.PropertyField(lutName, new GUIContent("LutName", ""));

        if (GUILayout.Button(new GUIContent("Save Lut Texture", "")))
        {
            SaveOfflineLut(lutName.stringValue, hueShift, saturation, value);
        }
        EditorGUILayout.EndHorizontal();

        EditorGUILayout.Space();
        EditorGUILayout.Space();
        EditorUtility.SetDirty(this);
        serializedObject.ApplyModifiedProperties();
    }

    void Setup()
    {
        AutoShadowColor asc = (AutoShadowColor)target;
        asc._init = true;
        EditorUtility.SetDirty(asc);
    }


    #region RT

    Vector2 LUTSize = new Vector2(1024, 32);//可以降为 256x16, 在灰色域上的拟合精度会有一点损失。

    RenderTexture AutoShadowLUT;

    RenderTexture autoShadowLUT
    {
        get
        {
            if (AutoShadowLUT == null)
            {
                AutoShadowLUT = new RenderTexture((int)LUTSize.x, (int)LUTSize.y, 32, RenderTextureFormat.ARGB32);
                AutoShadowLUT.name = "AutoShadowLutBaker";
            }
            return AutoShadowLUT;
        }
    }



    #endregion




    //保存Lut
    void SaveOfflineLut(string lutName, SerializedProperty hue, SerializedProperty Sat, SerializedProperty Val)
    {
        Shader lutShader = Shader.Find("BP/PPS_AutoShadowColor");
        Material lutMaterial = null;
        if (lutShader != null)
        {
            lutMaterial = new Material(lutShader);
            lutMaterial.hideFlags = HideFlags.HideAndDontSave;
        }
        if (lutMaterial == null)
        {
            Debug.LogError("No Auto Shadow Color Lut Materials");
        }


        //设置参数、渲染RT
        SetLutMaterialParameters(lutMaterial, hue, Sat, Val);
        Graphics.Blit(null, autoShadowLUT, lutMaterial);

        //写入保存Lut Texture
        WriteAutoShadowColorRT(autoShadowLUT, lutName);

        //release 释放
        ReleaseAutoShadowLut();
    }


    private void ReleaseAutoShadowLut()
    {
        if (autoShadowLUT != null)
        {
            autoShadowLUT.Release();
        }
    }

    private void WriteAutoShadowColorRT(RenderTexture renderTexture, string name)
    {
        int width = renderTexture.width;
        int height = renderTexture.height;
        Texture2D texture2D = new Texture2D(width, height, TextureFormat.ARGB32, false);
        RenderTexture.active = renderTexture;
        texture2D.ReadPixels(new Rect(0, 0, width, height), 0, 0);
        texture2D.Apply();
        string path = "Assets/Scripts/" + name + ".png";
        File.WriteAllBytes(path, texture2D.EncodeToPNG());
        AssetDatabase.Refresh();

        var texImporter = AssetImporter.GetAtPath(path) as TextureImporter;
        texImporter.textureType = TextureImporterType.Default;
        texImporter.wrapMode = TextureWrapMode.Clamp;
        texImporter.sRGBTexture = true;
        texImporter.mipmapEnabled = false;
        texImporter.SaveAndReimport();
    }



    float[] HueShiftsArray;
    float[] SaturationShiftsArray;
    float[] ValueShiftsArray;


    private void SetLutMaterialParameters(Material mat, SerializedProperty hue, SerializedProperty Sat, SerializedProperty Val)
    {
        var hueShifts = hue.FindPropertyRelative("HueShifts");
        HueShiftsArray ??= new float[21];
        HueShiftsArray[0] = hueShifts.FindPropertyRelative("_HueR").floatValue;
        HueShiftsArray[1] = hueShifts.FindPropertyRelative("_HueR0").floatValue;
        HueShiftsArray[2] = hueShifts.FindPropertyRelative("_HueYR").floatValue;
        HueShiftsArray[3] = hueShifts.FindPropertyRelative("_HueYR0").floatValue;
        HueShiftsArray[4] = hueShifts.FindPropertyRelative("_HueY").floatValue;
        HueShiftsArray[5] = hueShifts.FindPropertyRelative("_HueY0").floatValue;
        HueShiftsArray[6] = hueShifts.FindPropertyRelative("_HueGY").floatValue;
        HueShiftsArray[7] = hueShifts.FindPropertyRelative("_HueGY0").floatValue;

        HueShiftsArray[8] = hueShifts.FindPropertyRelative("_HueG").floatValue;
        HueShiftsArray[9] = hueShifts.FindPropertyRelative("_HueG0").floatValue;
        HueShiftsArray[10] = hueShifts.FindPropertyRelative("_HueBG").floatValue;
        HueShiftsArray[11] = hueShifts.FindPropertyRelative("_HueBG0").floatValue;
        HueShiftsArray[12] = hueShifts.FindPropertyRelative("_HueB").floatValue;
        HueShiftsArray[13] = hueShifts.FindPropertyRelative("_HueB0").floatValue;
        HueShiftsArray[14] = hueShifts.FindPropertyRelative("_HuePB").floatValue;
        HueShiftsArray[15] = hueShifts.FindPropertyRelative("_HuePB0").floatValue;
        HueShiftsArray[16] = hueShifts.FindPropertyRelative("_HueP").floatValue;
        HueShiftsArray[17] = hueShifts.FindPropertyRelative("_HueP0").floatValue;
        HueShiftsArray[18] = hueShifts.FindPropertyRelative("_HueRP").floatValue;
        HueShiftsArray[19] = hueShifts.FindPropertyRelative("_HueRP0").floatValue;
        HueShiftsArray[20] = hueShifts.FindPropertyRelative("_HueR").floatValue;

        //////////////////////////////Saturation//////////////////////////////
        var satShifts = Sat.FindPropertyRelative("SaturationShifts");
        SaturationShiftsArray ??= new float[8];
        SaturationShiftsArray[0] = satShifts.FindPropertyRelative("_Sat0").floatValue;
        SaturationShiftsArray[1] = satShifts.FindPropertyRelative("_Sat1").floatValue;
        SaturationShiftsArray[2] = satShifts.FindPropertyRelative("_Sat2").floatValue;
        SaturationShiftsArray[3] = satShifts.FindPropertyRelative("_Sat3").floatValue;
        SaturationShiftsArray[4] = satShifts.FindPropertyRelative("_Sat4").floatValue;
        SaturationShiftsArray[5] = satShifts.FindPropertyRelative("_Sat5").floatValue;
        SaturationShiftsArray[6] = satShifts.FindPropertyRelative("_Sat6").floatValue;
        SaturationShiftsArray[7] = satShifts.FindPropertyRelative("_Sat7").floatValue;


        //////////////////////////////Brightness//////////////////////////////

        var brightnessShifts = Val.FindPropertyRelative("BrightnessShifts");

        ValueShiftsArray ??= new float[8];
        ValueShiftsArray[0] = brightnessShifts.FindPropertyRelative("_Bright0").floatValue;
        ValueShiftsArray[1] = brightnessShifts.FindPropertyRelative("_Bright1").floatValue;
        ValueShiftsArray[2] = brightnessShifts.FindPropertyRelative("_Bright2").floatValue;
        ValueShiftsArray[3] = brightnessShifts.FindPropertyRelative("_Bright3").floatValue;
        ValueShiftsArray[4] = brightnessShifts.FindPropertyRelative("_Bright4").floatValue;
        ValueShiftsArray[5] = brightnessShifts.FindPropertyRelative("_Bright5").floatValue;
        ValueShiftsArray[6] = brightnessShifts.FindPropertyRelative("_Bright6").floatValue;
        ValueShiftsArray[7] = brightnessShifts.FindPropertyRelative("_Bright7").floatValue;



        mat.SetFloatArray(BakerShadowHueShiftsId, HueShiftsArray);
        mat.SetFloatArray(BakerShadowSatShiftsId, SaturationShiftsArray);
        mat.SetFloatArray(BakerShadowValShiftsId, ValueShiftsArray);

        mat.SetVector("_LUTParams", new Vector4(LUTSize.y, 0.5f / LUTSize.x, 0.5f / LUTSize.y, LUTSize.y / (LUTSize.y - 1)));
    }



    private static int BakerShadowHueShiftsId = Shader.PropertyToID("_HueShifts_Baker");
    private static int BakerShadowSatShiftsId = Shader.PropertyToID("_SatShifts_Baker");
    private static int BakerShadowValShiftsId = Shader.PropertyToID("_ValShifts_Baker");

    private static string AutoShadowColorDebugToggle = "_AUTOSHADOW_USE_DEBUG";
}
