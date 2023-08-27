#ifdef BORDER_FOG
    #ifdef OVERWORLD
        #include "/lib/atmospherics/sky.glsl"
    #elif defined NETHER
        #include "/lib/colors/skyColors.glsl"
    #endif

    void DoBorderFog(inout vec3 color, float lPlayerPosXZ, float VdotU, float VdotS, float dither) {
        #if defined OVERWORLD || defined END
            float fog = lPlayerPosXZ / far;
			//fog = 0;
            fog *= fog;
            //fog *= fog;
            //fog *= fog;
            fog = 1 - exp(-3.5 * fog) * 1.2;
        #endif
        #ifdef NETHER
            float fog = lPlayerPosXZ / far;
            fog *= fog;
            fog *= fog;
            fog = 1.0 - exp(-8.0 * fog);
        #endif

        if (fog > 0.0) {
            fog = clamp(fog, 0.0, 1.0);
            #ifdef OVERWORLD
                vec3 fogColorM = GetSky(VdotU, VdotS, dither, true, false);
            #elif defined NETHER
                vec3 fogColorM = netherSkyColor;
            #else 
                vec3 fogColorM = endSkyColor;
            #endif
            color = mix(color, fogColorM, fog);
        }
    }
#endif

#ifdef ATMOSPHERIC_FOG
    #include "/lib/colors/lightAndAmbientColors.glsl"
    #include "/lib/colors/skyColors.glsl"

    #ifdef CAVE_FOG
        #include "/lib/atmospherics/fog/caveFactor.glsl"
    #endif

    // SRATA: Atm. fog starts reducing above this altitude
    // CRFTM: Atm. fog continues reducing for this meters
    #ifdef OVERWORLD
        float atmFogSRATA = 70.1;
        float atmFogCRFTM = 90.0;
    #else
        float atmFogSRATA = 55.1;
        float atmFogCRFTM = 30.0;
    #endif

    float GetAtmFogAltitudeFactor(float altitude) {
        float altitudeFactor = pow2(1.0 - clamp(altitude - atmFogSRATA, 0.0, atmFogCRFTM) / atmFogCRFTM);
        altitudeFactor = mix(altitudeFactor, 1.0, rainFactor * 0.2);
        return altitudeFactor;
    }

    void DoAtmosphericFog(inout vec3 color, float lViewPos, vec3 playerPos) {
        float fog = sqrt2(min1(max0(lViewPos - 16.0 - 16.0 * invRainFactor) / 200.0)) * (0.9 - 0.2 * invRainFactor);
        
        float altitudeFactor = GetAtmFogAltitudeFactor(playerPos.y + cameraPosition.y);

        #ifdef OVERWORLD
            altitudeFactor *= 1- 0.75 * eyeBrightnessM * GetAtmFogAltitudeFactor(cameraPosition.y) * invRainFactor;
        #endif

        fog *= altitudeFactor * 1 - 0.5;

        #ifdef OVERWORLD
            fog *= 0.2 + 0.8 * eyeBrightnessM;
            #ifdef CAVE_FOG
                float caveFactor = GetCaveFactor();
                float caveFog = 1.0 - exp(- lViewPos * 0.015);
                fog = mix(fog, caveFog * 0.9, caveFactor);
            #endif
        #endif

        if (fog > 0.0) {
            fog = clamp(fog, 0.0, 1.0);
            #ifdef OVERWORLD
                vec3 fogColorM = mix(nightUpSkyColor * 2.5, vec3(0.46,0.66 , 1* 1) * (1.3 - invNoonFactor * 0.5), sunFactor) ;
                     fogColorM = mix(fogColorM, mix(nightMiddleSkyColor, dayMiddleSkyColor, sunFactor), rainFactor);

                #ifdef CAVE_FOG
                    fogColorM = mix(caveFogColor, fogColorM, eyeBrightnessM);
                #endif
            #else
                vec3 fogColorM = endSkyColor;
            #endif
            color = mix(color, fogColorM, fog);
        }
    }
#endif

#include "/lib/atmospherics/fog/waterFog.glsl"

void DoWaterFog(inout vec3 color, float lViewPos) {
    float fog = GetWaterFog(lViewPos);

    color = mix(color, waterFogColor, fog);
}

void DoLavaFog(inout vec3 color, float lViewPos) {
    float fog = (lViewPos * 3.0 - gl_Fog.start) * gl_Fog.scale;

    #ifdef LESS_LAVA_FOG
        fog = sqrt(fog) * 0.4;
    #endif

    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, fogColor * 5.0, fog);
}

void DoPowderSnowFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos;
    fog *= fog;
    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, fogColor, fog);
}

void DoBlindnessFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos * 0.3 * blindness;
    fog *= fog;
    fog = 1.0 - exp(-fog);

    fog = clamp(fog, 0.0, 1.0);
    color = mix(color, vec3(0.0), fog);
}

void DoDarknessFog(inout vec3 color, float lViewPos) {
    float fog = lViewPos * 0.075 * darknessFactor;
    fog *= fog;
    fog *= fog;
    color *= exp(-fog);
}

void DoFog(inout vec3 color, float lViewPos, vec3 playerPos, float VdotU, float VdotS, float dither) {
    #ifdef ATMOSPHERIC_FOG
        DoAtmosphericFog(color, lViewPos, playerPos);
    #endif
    #ifdef BORDER_FOG
        DoBorderFog(color, length(playerPos.xz), VdotU, VdotS, dither);
    #endif

    if (isEyeInWater == 1) DoWaterFog(color, lViewPos);
    else if (isEyeInWater == 2) DoLavaFog(color, lViewPos);
    else if (isEyeInWater == 3) DoPowderSnowFog(color, lViewPos);
    
    if (blindness > 0.00001) DoBlindnessFog(color, lViewPos);
    if (darknessFactor > 0.00001) DoDarknessFog(color, lViewPos);
}