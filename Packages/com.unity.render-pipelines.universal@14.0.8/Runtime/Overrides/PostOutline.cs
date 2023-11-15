using System;

namespace UnityEngine.Rendering.Universal { 

    [Serializable, VolumeComponentMenuForRenderPipeline("Post-processing/Depth Of Field", typeof(UniversalRenderPipeline))]
    public sealed class PostOutline : VolumeComponent, IPostProcessComponent
    {

        public MinFloatParameter intensity = new MinFloatParameter(1.2f, 0.0f);

        public MinFloatParameter farIntensity = new MinFloatParameter(1.0f, 0.0f);

        public MinFloatParameter shadowIntensity = new MinFloatParameter(0.6f, 0.0f);

        public MinFloatParameter farShadowIntensity = new MinFloatParameter(1.0f, 0.0f);

        public MinFloatParameter intensityDistance = new MinFloatParameter(3000.0f, 0.0f);

        public ColorParameter outlineColor = new ColorParameter(Color.black);

        public MinFloatParameter outlineWidth = new MinFloatParameter(2.0f, 0.0f);

        public MinFloatParameter depthOutlineScale = new MinFloatParameter(1.0f, 0.0f);

        public MinFloatParameter depthOutlineThreshold = new MinFloatParameter(0.3f, 0.0f);

        public MinFloatParameter colorOutlineScale = new MinFloatParameter(1.0f, 0.0f);

        public MinFloatParameter normalOutlineScale = new MinFloatParameter(2.0f, 0.0f);

        public MinFloatParameter colorTorresContrast = new MinFloatParameter(0.21f, 0.0f);

        public MinFloatParameter colorTorresAlpha = new MinFloatParameter(0.5f, 0.0f);

        public MinFloatParameter colorTorresBlurScale = new MinFloatParameter(0.0f, 0.0f);

        public bool IsActive() => intensity.value > 0.0f;
        
        public bool IsTileCompatible() => false;
    }
}
