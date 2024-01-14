using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class AutoShadowColorConfig : MonoBehaviour
{
    public Texture m_MonsterLut;
    public bool m_Debuging;
    public AutoShadowColor m_Asset;

    
    private Vector2 lutSize = new Vector2(1024.0f, 32.0f);
    private float[] m_HueShifts = new float[21];
    private float[] m_SatShifts = new float[8];
    private float[] m_ValShifts = new float[8];

    private void OnValidate()
    {

    }
    private void Update()
    {
        OnSetup();
    }

    private void OnSetup()
    {
        if (m_Debuging)
        {
            Shader.EnableKeyword(AUTOSHADOW_USE_DEBUG);
            if (m_Asset == null) return;
            
            m_Asset.GetAutoShadowColorParams(ref m_HueShifts,ref m_SatShifts,ref m_ValShifts);

            
            Shader.SetGlobalFloatArray(AUTO_SHADOW_COLOR_HUE, m_HueShifts);
            Shader.SetGlobalFloatArray(AUTO_SHADOW_COLOR_SAT, m_SatShifts);
            Shader.SetGlobalFloatArray(AUTO_SHADOW_COLOR_VAL, m_ValShifts);
            
        }
        else {
            Shader.DisableKeyword(AUTOSHADOW_USE_DEBUG);
            if (m_MonsterLut != null)
            {
                Shader.SetGlobalTexture(CHARACTER_MONSTER_AUTO_SHADOW_LUT, m_MonsterLut);
                Shader.SetGlobalVector(LUTScaleOffset, new Vector4(1 / lutSize.x, 1 / lutSize.y, lutSize.y - 1, 0.0f));

            }
        }
    }

    private static int CHARACTER_MONSTER_AUTO_SHADOW_LUT = Shader.PropertyToID("_MonsterLUT");
    private static int LUTScaleOffset = Shader.PropertyToID("LUTScaleOffset");

    private static string AUTOSHADOW_USE_DEBUG = "_AUTOSHADOW_USE_DEBUG";
    private static int AUTO_SHADOW_COLOR_HUE = Shader.PropertyToID("_HueShifts_Monster");
    private static int AUTO_SHADOW_COLOR_SAT = Shader.PropertyToID("_SatShifts_Monster");
    private static int AUTO_SHADOW_COLOR_VAL = Shader.PropertyToID("_ValShifts_Monster");
}
