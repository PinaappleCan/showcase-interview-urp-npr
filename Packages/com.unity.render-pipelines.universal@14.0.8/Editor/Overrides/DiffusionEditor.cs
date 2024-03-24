using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal { 
    [CustomEditor(typeof(Diffusion))]
    public class DiffusionEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_scale;
        SerializedDataParameter m_crossCenterWeight;
        SerializedDataParameter m_kernelSizePercent;
        SerializedDataParameter m_filterSize;
        SerializedDataParameter m_tintColor;


        public override void OnEnable()
        {
            var o = new PropertyFetcher<Diffusion>(serializedObject);
            m_scale = Unpack(o.Find(x => x.Scale));
            m_crossCenterWeight = Unpack(o.Find(x => x.CrossCenterWeight));
            m_kernelSizePercent = Unpack(o.Find(x => x.KernelSizePercent));
            m_filterSize = Unpack(o.Find(x => x.FilterSize));
            m_tintColor = Unpack(o.Find(x => x.TintColor));

        }

        public override void OnInspectorGUI()
        {
            PropertyField(m_scale);
            PropertyField(m_crossCenterWeight);
            PropertyField(m_kernelSizePercent);
            PropertyField(m_filterSize);
            PropertyField(m_tintColor);
        }

    }
}
