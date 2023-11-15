using UnityEngine.Rendering.Universal;
using UnityEngine.UIElements;

namespace UnityEditor.Rendering.Universal { 

    [CustomEditor(typeof(PostOutline))]
    sealed class PostOutlineEditor : VolumeComponentEditor 
    {
        SerializedDataParameter m_intensity;

        SerializedDataParameter m_farIntensity;

        SerializedDataParameter m_shadowIntensity;

        SerializedDataParameter m_farShadowIntensity;

        SerializedDataParameter m_intensityDistance;

        SerializedDataParameter m_outlineColor;

        SerializedDataParameter m_outlineWidth;

        SerializedDataParameter m_depthOutlineScale;

        SerializedDataParameter m_depthOutlineThreshold;

        SerializedDataParameter m_colorOutlineScale;

        SerializedDataParameter m_normalOutlineScale;

        SerializedDataParameter m_colorTorresContrast;

        SerializedDataParameter m_colorTorresAlpha;

        SerializedDataParameter m_colorTorresBlurScale;


        public override void OnEnable()
        {
            var o = new PropertyFetcher<PostOutline>(serializedObject);

            m_intensity = Unpack(o.Find(x => x.intensity));
            m_farIntensity = Unpack(o.Find(x => x.farIntensity));
            m_shadowIntensity = Unpack(o.Find(x => x.shadowIntensity));
            m_farShadowIntensity = Unpack(o.Find(x => x.farShadowIntensity));
            m_intensityDistance = Unpack(o.Find(x => x.intensityDistance));
            m_outlineColor = Unpack(o.Find(x => x.outlineColor));
            m_outlineWidth = Unpack(o.Find(x => x.outlineWidth));
            m_depthOutlineScale = Unpack(o.Find(x => x.depthOutlineScale));
            m_depthOutlineThreshold = Unpack(o.Find(x => x.depthOutlineThreshold));
            m_colorOutlineScale = Unpack(o.Find(x => x.colorOutlineScale));
            m_normalOutlineScale = Unpack(o.Find(x => x.normalOutlineScale));
            m_colorTorresContrast = Unpack(o.Find(x => x.colorTorresContrast));
            m_colorTorresAlpha = Unpack(o.Find(x => x.colorTorresAlpha));
            m_colorTorresBlurScale = Unpack(o.Find(x => x.colorTorresBlurScale));
        }


        public override void OnInspectorGUI()
        {
            PropertyField(m_intensity);
            PropertyField(m_farIntensity);
            PropertyField(m_shadowIntensity);
            PropertyField(m_farShadowIntensity);
            PropertyField(m_intensityDistance);
            PropertyField(m_outlineColor);
            PropertyField(m_outlineWidth);
            PropertyField(m_depthOutlineScale);
            PropertyField(m_depthOutlineThreshold);
            PropertyField(m_colorOutlineScale);
            PropertyField(m_normalOutlineScale);
            PropertyField(m_colorTorresContrast);
            PropertyField(m_colorTorresAlpha);
            PropertyField(m_colorTorresBlurScale);
        }

    }
}