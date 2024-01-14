#ifndef GBUFFER_SHADINGMODEL_ID_INCLUDE
    #define GBUFFER_SHADINGMODEL_ID_INCLUDE


#define GBUFFER_SHADING_MODEL_ID_COUNT 100

#define CHARACTER_ID 50
#define CHARACTER_ID_PERCENT 0.5

#define CHARACTER_MONSTER_ID 40
#define CHARACTER_MONSTER_ID_PERCENT 0.4


float GetGBufferID(float val)
{
    float id = floor(GBUFFER_SHADING_MODEL_ID_COUNT * val + 0.5);
    return id;
}

bool IsCharaID(float val)
{
    return GetGBufferID(val) <= CHARACTER_MONSTER_ID;
}

bool IsMonsterID(float val)
{
    return GetGBufferID(val) == CHARACTER_MONSTER_ID;
}

float GetGBufferID_Monster()
{
    return CHARACTER_MONSTER_ID;
}

#endif