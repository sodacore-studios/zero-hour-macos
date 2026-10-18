// Test fixtures are appended to the production shader for GPU regression tests.
vertex FragmentIn regression_vertex(uint id [[vertex_id]]) {
    FragmentIn out = {};
    float2 positions[3] = {float2(-1, -1), float2(3, -1), float2(-1, 3)};
    out.position = float4(positions[id], 0, 1);
    out.color = float4(0, 1, 0, 1);
    out.texCoord = float2(0.5);
    out.texCoord2 = float2(0.5);
    out.camPosZ = -1;
    return out;
}

kernel void regression_setup(device Uniforms &u [[buffer(0)]],
                             device FragmentUniforms &f [[buffer(1)]],
                             device CustomPSUniforms &p [[buffer(2)]],
                             constant uint &testCase [[buffer(3)]]) {
    u = {};
    f = {};
    p = {};
    u.useProjection = 1;
    f.stages[0].colorOp = D3DTOP_SELECTARG1;
    f.stages[0].colorArg1 = D3DTA_DIFFUSE;
    f.stages[0].alphaOp = D3DTOP_SELECTARG1;
    f.stages[0].alphaArg1 = D3DTA_DIFFUSE;
    f.stages[1].colorOp = D3DTOP_DISABLE;
    // A prior projected terrain/shadow pass leaves these states behind.
    uint staleStage = testCase == 2 ? 2 : 1;
    u.texMatrix[staleStage] = float4x4(1);
    u.texMatrix[staleStage][3].z = -1;
    u.texTransformFlags[staleStage] = 256 | 3;
    f.hasTexture[staleStage] = 1;
    if (testCase == 2) {
        f.stages[2].colorOp = D3DTOP_MODULATE;
        f.stages[2].colorArg1 = D3DTA_TEXTURE;
        f.stages[2].colorArg2 = D3DTA_CURRENT;
    }
    if (testCase == 3 || testCase == 4) {
        u.texTransformFlags[1] = 0;
        u.texMatrix[0] = float4x4(1);
        u.texMatrix[0][3].z = testCase == 3 ? -1 : 1;
        u.texTransformFlags[0] = 256 | 3;
        f.hasTexture[0] = 1;
        f.stages[0].colorOp = D3DTOP_MODULATE;
        f.stages[0].colorArg1 = D3DTA_TEXTURE;
        f.stages[0].colorArg2 = D3DTA_DIFFUSE;
    }
    if (testCase == 0) u.texTransformFlags[1] = 0;
    if (testCase == 5 || testCase == 6 || testCase == 9) {
        f.stages[1].colorOp = D3DTOP_MODULATE;
        f.stages[1].colorArg1 = D3DTA_TEXTURE;
        f.stages[1].colorArg2 = D3DTA_CURRENT;
    }
    if (testCase == 5) f.hasTexture[1] = 0;
    if (testCase == 6) {
        u.texTransformFlags[1] = 0;
        f.texCoordIndex[1] = 0x00010000;
    }
    if (testCase == 7) f.stages[0].colorOp = D3DTOP_DISABLE;
    if (testCase == 8) f.stages[1].colorOp = 0;
    if (testCase == 9) u.texMatrix[1][3].z = 1;
}
