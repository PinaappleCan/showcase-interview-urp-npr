using UnityEngine.Rendering.Universal;

namespace UnityEditor.Rendering.Universal { 
    [CustomEditor(typeof(Diffusion))]
    public class DiffusionEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_scale;
        public override void OnEnable()
        {
            var o = new PropertyFetcher<Diffusion>(serializedObject);
            m_scale = Unpack(o.Find(x => x.Scale));
        }

        public override void OnInspectorGUI()
        {
            PropertyField(m_scale);
        }

    }
}
