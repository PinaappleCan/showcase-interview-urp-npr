using System;

namespace UnityEngine.Rendering.Universal 
{ 
    [Serializable, VolumeComponentMenuForRenderPipeline("Post-processing/Global Character Config", typeof(UniversalRenderPipeline))]    
    public sealed partial class GlobalCharacterConfig : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter lutDebuging = new BoolParameter(false);

        public TextureParameter monsterLut = new TextureParameter(null);
        public bool IsActive() => lutDebuging.value;

        public bool IsTileCompatible() => false;
    }
}