// TheSuperHackers @fix Match the terrain window to the actual camera frustum.
#pragma once
#include "WW3D2/camera.h"
#include "W3DDevice/GameClient/WorldHeightMap.h"
#include <algorithm>
#include <cmath>

namespace TerrainViewBounds {
struct Bounds { int minX, minY, maxX, maxY; };

inline Bounds calculate(const CameraClass& camera, const WorldHeightMap& map,
                        float minHeight, float maxHeight) {
    Bounds full = {0, 0, map.getXExtent()-1, map.getYExtent()-1};
    Vector2 planeMin, planeMax;
    camera.Get_View_Plane(planeMin, planeMax);
    const Matrix3D& transform = camera.Get_Transform();
    const Vector3 eye = camera.Get_Position();
    float minX = 1.0e30f, minY = 1.0e30f, maxX = -1.0e30f, maxY = -1.0e30f;
    for (int y=0; y<2; ++y) {
        for (int x=0; x<2; ++x) {
            const float sx = x ? planeMax.X : planeMin.X;
            const float sy = y ? planeMax.Y : planeMin.Y;
            const Vector3 ray(sx*transform[0][0]+sy*transform[0][1]-transform[0][2],
                              sx*transform[1][0]+sy*transform[1][1]-transform[1][2],
                              sx*transform[2][0]+sy*transform[2][1]-transform[2][2]);
            // A horizon-crossing frustum can see any part of the finite map.
            if (ray.Z >= -0.0001f) return full;
            for (int z=0; z<2; ++z) {
                const float height = z ? maxHeight : minHeight;
                const float t = std::max(0.0f, (height-eye.Z)/ray.Z);
                const float wx = eye.X + t*ray.X;
                const float wy = eye.Y + t*ray.Y;
                minX = std::min(minX, wx); maxX = std::max(maxX, wx);
                minY = std::min(minY, wy); maxY = std::max(maxY, wy);
            }
        }
    }
    const float border = map.getBorderSizeInline();
    auto lower = [border](float v, int limit) {
        return (int)std::max(0.0f, std::min((float)limit, std::floor(v/MAP_XY_FACTOR+border)));
    };
    auto upper = [border](float v, int limit) {
        return (int)std::max(0.0f, std::min((float)limit, std::ceil(v/MAP_XY_FACTOR+border)));
    };
    return {lower(minX, full.maxX), lower(minY, full.maxY),
            upper(maxX, full.maxX), upper(maxY, full.maxY)};
}
inline int drawSize(int low, int high, int minimum) {
    // One tile of margin on each side; tile-sized growth avoids frequent reallocations.
    const int tile = VERTEX_BUFFER_TILE_LENGTH;
    const int cells = high-low+2*tile;
    return std::max(minimum, 1+((cells+tile-1)/tile)*tile);
}
}
