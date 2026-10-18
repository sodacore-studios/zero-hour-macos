#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "MetalVertexBuffer8.h"
#include "MetalIndexBuffer8.h"
#include <cstdio>
#include <cstring>

void *g_MetalMTLDevice = nullptr;
#include "buffer-memory-device.h"

// Delay submission deliberately: queued draws must retain the bytes that were
// current when their buffer was bound, even if the CPU prepares another frame.
template<class Buffer> bool checkBuffer(Buffer &buffer, const char *name,
                                       id<MTLDevice> device) {
  constexpr unsigned size = 64;
  BYTE *bytes = nullptr;
  if (buffer.Lock(0, size, &bytes, 0) != D3D_OK) return false;
  memset(bytes, 0x31, size);
  buffer.Unlock();
  id<MTLBuffer> original = (__bridge id<MTLBuffer>)buffer.GetMTLBuffer();
  id<MTLBuffer> output = [device newBufferWithLength:size options:MTLResourceStorageModeShared];
  id<MTLCommandQueue> queue = [device newCommandQueue];
  id<MTLCommandBuffer> command = [queue commandBuffer];
  id<MTLBlitCommandEncoder> encoder = [command blitCommandEncoder];
  [encoder copyFromBuffer:original sourceOffset:0 toBuffer:output destinationOffset:0 size:size];
  [encoder endEncoding];
  if (buffer.Lock(16, 16, &bytes, 0) != D3D_OK) return false;
  memset(bytes, 0x72, 16);
  buffer.Unlock();
  [command commit];
  [command waitUntilCompleted];
  bool stable = command.status == MTLCommandBufferStatusCompleted;
  for (unsigned i = 0; i < size; ++i)
    stable &= ((BYTE *)output.contents)[i] == 0x31;
  printf("%s: queued GPU read survives normal write: %s\n", name, stable ? "PASS" : "FAIL");
  if (buffer.Lock(0, size, &bytes, D3DLOCK_READONLY) != D3D_OK) return false;
  bool preserved = true;
  for (unsigned i = 0; i < size; ++i)
    preserved &= bytes[i] == (i >= 16 && i < 32 ? 0x72 : 0x31);
  buffer.Unlock();
  printf("%s: partial update preserves other bytes: %s\n", name, preserved ? "PASS" : "FAIL");
  return stable && preserved;
}
int main(int argc, char **argv) {
  @autoreleasepool {
    if (argc == 2 && strcmp(argv[1], "--cpu") == 0) {
      TestDevice *device = [TestDevice new];
      g_MetalMTLDevice = (__bridge void *)device;
      MetalVertexBuffer8 vertex(0, 4, 16);
      MetalIndexBuffer8 index16(32, false), index32(16, true);
      bool passed = checkMemory(vertex, "vertex", device);
      passed &= checkMemory(index16, "index16", device);
      passed &= checkMemory(index32, "index32", device);
      // Verify buffers created before the graphics device are uploaded correctly.
      g_MetalMTLDevice = nullptr;
      MetalVertexBuffer8 deferredVertex(0, 4, 16);
      MetalIndexBuffer8 deferredIndex(32, false);
      g_MetalMTLDevice = (__bridge void *)device;
      passed &= checkMemory(deferredVertex, "deferred vertex", device);
      passed &= checkMemory(deferredIndex, "deferred index", device);
      return passed ? 0 : 1;
    }
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) { fprintf(stderr, "Metal device required\n"); return 2; }
    g_MetalMTLDevice = (__bridge void *)device;
    MetalVertexBuffer8 vertex(0, 4, 16);
    MetalIndexBuffer8 index16(32, false), index32(16, true);
    bool passed = checkBuffer(vertex, "vertex", device);
    passed &= checkBuffer(index16, "index16", device);
    passed &= checkBuffer(index32, "index32", device);
    return passed ? 0 : 1;
  }
}
