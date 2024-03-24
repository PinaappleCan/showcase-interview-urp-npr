using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenuForRenderPipeline("Post-processing/ScreenSpaceGlobalIllumination", typeof(UniversalRenderPipeline))]
    public class ScreenSpaceGlobalIllumination : VolumeComponent, IPostProcessComponent
    {
        public ClampedFloatParameter SSGIIntensity = new ClampedFloatParameter(0.0f, 0.0f, 20.0f, true);
        public ClampedFloatParameter SSGIThreshold = new ClampedFloatParameter(0.293f, 0.0f, 1.0f, false);

        public BoolParameter SSGIDownsampleFullSeparate = new BoolParameter(false, false);

        public ClampedIntParameter SSGIQuality = new ClampedIntParameter(2, 1, 2);

        public BoolParameter SSGIBoundryFade = new BoolParameter(true);

        public BoolParameter SSGIDebug = new BoolParameter(true);
        public bool IsActive()
        {
            return SSGIIntensity.value > 0.0f;
        }

        public bool IsTileCompatible()
        {
            return false;
        }
    }
}
