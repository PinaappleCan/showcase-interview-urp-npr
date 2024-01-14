using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
[CreateAssetMenu(menuName = "Rendering/AutoShadowColor")]
public class AutoShadowColor : ScriptableObject
{
    public bool _init;

    public bool _Debuging;

    [System.Serializable]
    public struct hueShift
    {
        [System.Serializable]
        public struct hueShifts
        {
            [Range(-80.0f, 80.0f)]
            public float _HueR, _HueR0, _HueYR, _HueYR0, _HueY, _HueY0, _HueGY, _HueGY0, _HueG, _HueG0,
                _HueBG, _HueBG0, _HueB, _HueB0, _HuePB, _HuePB0, _HueP, _HueP0, _HueRP, _HueRP0;
        }
        public hueShifts HueShifts;
    }
    public hueShift HUEShift = new hueShift { };



    [System.Serializable]
    public struct satShift
    {
        [System.Serializable]
        public struct satShifts
        {
            [Range(-30.0f, 50.0f)]
            public float _Sat0, _Sat1, _Sat2, _Sat3, _Sat4, _Sat5, _Sat6, _Sat7;
        }

        public satShifts SaturationShifts;
    }
    public satShift SatShift = new satShift { };



    [System.Serializable]
    public struct valShift
    {
        [System.Serializable]
        public struct brightShifts
        {
            [Range(-80.0f, 50.0f)]
            public float _Bright0, _Bright1, _Bright2, _Bright3, _Bright4, _Bright5, _Bright6, _Bright7;

        }
        public brightShifts BrightnessShifts;

    }
    public valShift ValShift = new valShift { };

    public string LutName;

    private float[] HueShiftsArray, SatShiftsArray, BrightShiftsArray;
    

#if UNITY_EDITOR
    private void OnValidate()
    {
        ResetParams();
    }
#endif

    private void ResetParams()
    {
        if (HueShiftsArray == null || HueShiftsArray.Length < 21)
        {
            HueShiftsArray = new float[21];
        }

        HueShiftsArray[0] = HUEShift.HueShifts._HueR;
        HueShiftsArray[1] = HUEShift.HueShifts._HueR0;
        HueShiftsArray[2] = HUEShift.HueShifts._HueYR;
        HueShiftsArray[3] = HUEShift.HueShifts._HueYR0;
        HueShiftsArray[4] = HUEShift.HueShifts._HueY;
        HueShiftsArray[5] = HUEShift.HueShifts._HueY0;
        HueShiftsArray[6] = HUEShift.HueShifts._HueGY;
        HueShiftsArray[7] = HUEShift.HueShifts._HueGY0;
        HueShiftsArray[8] = HUEShift.HueShifts._HueG;
        HueShiftsArray[9] = HUEShift.HueShifts._HueG0;
        HueShiftsArray[10] = HUEShift.HueShifts._HueBG;
        HueShiftsArray[11] = HUEShift.HueShifts._HueBG0;
        HueShiftsArray[12] = HUEShift.HueShifts._HueB;
        HueShiftsArray[13] = HUEShift.HueShifts._HueB0;
        HueShiftsArray[14] = HUEShift.HueShifts._HuePB;
        HueShiftsArray[15] = HUEShift.HueShifts._HuePB0;
        HueShiftsArray[16] = HUEShift.HueShifts._HueP;
        HueShiftsArray[17] = HUEShift.HueShifts._HueP0;
        HueShiftsArray[18] = HUEShift.HueShifts._HueRP;
        HueShiftsArray[19] = HUEShift.HueShifts._HueRP0;
        HueShiftsArray[20] = HUEShift.HueShifts._HueR;

        if (SatShiftsArray == null || SatShiftsArray.Length < 8) {
            SatShiftsArray = new float[8];
        }
            
        SatShiftsArray ??= new float[8];
        SatShiftsArray[0] = SatShift.SaturationShifts._Sat0;
        SatShiftsArray[1] = SatShift.SaturationShifts._Sat1;
        SatShiftsArray[2] = SatShift.SaturationShifts._Sat2;
        SatShiftsArray[3] = SatShift.SaturationShifts._Sat3;
        SatShiftsArray[4] = SatShift.SaturationShifts._Sat4;
        SatShiftsArray[5] = SatShift.SaturationShifts._Sat5;
        SatShiftsArray[6] = SatShift.SaturationShifts._Sat6;
        SatShiftsArray[7] = SatShift.SaturationShifts._Sat7;

        if (BrightShiftsArray == null || BrightShiftsArray.Length < 8)
        {
            BrightShiftsArray = new float[8];
        }

        BrightShiftsArray[0] = ValShift.BrightnessShifts._Bright0;
        BrightShiftsArray[1] = ValShift.BrightnessShifts._Bright1;
        BrightShiftsArray[2] = ValShift.BrightnessShifts._Bright2;
        BrightShiftsArray[3] = ValShift.BrightnessShifts._Bright3;
        BrightShiftsArray[4] = ValShift.BrightnessShifts._Bright4;
        BrightShiftsArray[5] = ValShift.BrightnessShifts._Bright5;
        BrightShiftsArray[6] = ValShift.BrightnessShifts._Bright6;
        BrightShiftsArray[7] = ValShift.BrightnessShifts._Bright7;

    }

    public void GetAutoShadowColorParams(ref float[] HueShifts, ref float[] SatShifts, ref float[] ValShifts)
    {
        ResetParams();

        HueShifts = HueShiftsArray;
        SatShifts = SatShiftsArray;
        ValShifts = BrightShiftsArray;
    }


}
