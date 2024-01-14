using UnityEngine.Rendering.Universal;
using UnityEngine;


namespace UnityEditor.Rendering.Universal 
{
    [CustomEditor(typeof(GlobalCharacterConfig))]
    sealed class GlobalCharacterConfigEditor : VolumeComponentEditor
    {
        SerializedDataParameter m_monsterLut;

        public override void OnEnable()
        {
            var o = new PropertyFetcher<GlobalCharacterConfig>(serializedObject);

            m_monsterLut = Unpack(o.Find(x => x.monsterLut));
        }

        public override void OnInspectorGUI()
        {
            PropertyField(m_monsterLut);
        }

    }
}
