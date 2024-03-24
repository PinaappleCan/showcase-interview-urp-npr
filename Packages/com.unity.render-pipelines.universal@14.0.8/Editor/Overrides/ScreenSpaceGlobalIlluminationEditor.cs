using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal
{
    [CustomEditor(typeof(ScreenSpaceGlobalIllumination))]

    public class ScreenSpaceGlobalIlluminationEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_SSGIIntensity;
        SerializedDataParameter m_SSGIThreshold;
        SerializedDataParameter m_SSGIDownsampleFullSeparate;
        SerializedDataParameter m_SSGIQuality;
        SerializedDataParameter m_SSGIBoundryFade;
        SerializedDataParameter m_SSGIDebug;


        public override void OnEnable()
        {
            var o = new PropertyFetcher<ScreenSpaceGlobalIllumination>(serializedObject);
            m_SSGIIntensity = Unpack(o.Find(x => x.SSGIIntensity));
            m_SSGIThreshold = Unpack(o.Find(x => x.SSGIThreshold));
            m_SSGIDownsampleFullSeparate = Unpack(o.Find(x => x.SSGIDownsampleFullSeparate));
            m_SSGIQuality = Unpack(o.Find(x => x.SSGIQuality));
            m_SSGIBoundryFade = Unpack(o.Find(x => x.SSGIBoundryFade));
            m_SSGIDebug = Unpack(o.Find(x => x.SSGIDebug));
        }

        public override void OnInspectorGUI()
        {
            PropertyField(m_SSGIIntensity);
            PropertyField(m_SSGIThreshold);
            PropertyField(m_SSGIDownsampleFullSeparate);
            PropertyField(m_SSGIQuality);
            PropertyField(m_SSGIBoundryFade);
            PropertyField(m_SSGIDebug);
        }
    }
}

