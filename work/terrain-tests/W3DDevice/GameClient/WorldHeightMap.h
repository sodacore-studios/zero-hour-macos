#pragma once
#define MAP_XY_FACTOR 10.0f
#define VERTEX_BUFFER_TILE_LENGTH 32
struct WorldHeightMap { int getXExtent()const{return 1001;} int getYExtent()const{return 1001;} int getBorderSizeInline()const{return 500;} };
