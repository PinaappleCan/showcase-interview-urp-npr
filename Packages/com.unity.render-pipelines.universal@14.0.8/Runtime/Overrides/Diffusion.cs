using System;


namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenuForRenderPipeline("Post-processing/Diffusion", typeof(UniversalRenderPipeline))]
    public sealed class Diffusion : VolumeComponent, IPostProcessComponent
    {
        public ClampedFloatParameter Scale = new ClampedFloatParameter(0f, 0f, 8f, true);
        public bool IsActive()
        {
            return Scale.value > 0.0f;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
        
    }
}
