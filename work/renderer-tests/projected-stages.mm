#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <cstdio>
#include <cstdlib>

static void require(bool condition, NSString *message) {
    if (!condition) { fprintf(stderr, "%s\n", message.UTF8String); exit(1); }
}

int main(int argc, const char **argv) {
    @autoreleasepool {
        require(argc == 3, @"Usage: renderer-tests production.metal fixtures.metal");
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        require(device != nil, @"Metal device unavailable; GPU verification was not performed");
        NSError *error = nil;
        NSString *source = [NSString stringWithContentsOfFile:@(argv[1]) encoding:NSUTF8StringEncoding error:&error];
        require(source != nil, error.description);
        NSString *fixtures = [NSString stringWithContentsOfFile:@(argv[2]) encoding:NSUTF8StringEncoding error:&error];
        require(fixtures != nil, error.description);
        MTLCompileOptions *options = [MTLCompileOptions new];
        options.languageVersion = MTLLanguageVersion3_0;
        id<MTLLibrary> library = [device newLibraryWithSource:[source stringByAppendingString:fixtures] options:options error:&error];
        require(library != nil, error.description);
        id<MTLComputePipelineState> setup = [device newComputePipelineStateWithFunction:[library newFunctionWithName:@"regression_setup"] error:&error];
        require(setup != nil, error.description);
        MTLRenderPipelineDescriptor *pipeline = [MTLRenderPipelineDescriptor new];
        pipeline.vertexFunction = [library newFunctionWithName:@"regression_vertex"];
        pipeline.fragmentFunction = [library newFunctionWithName:@"fragment_main"];
        pipeline.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA8Unorm;
        id<MTLRenderPipelineState> render = [device newRenderPipelineStateWithDescriptor:pipeline error:&error];
        require(render != nil, error.description);
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:8 height:8 mipmapped:NO];
        desc.storageMode = MTLStorageModeShared;
        desc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        id<MTLTexture> target = [device newTextureWithDescriptor:desc];
        id<MTLTexture> white = [device newTextureWithDescriptor:desc];
        uint32_t pixels[64]; for (auto &pixel : pixels) pixel = 0xffffffff;
        [white replaceRegion:MTLRegionMake2D(0,0,8,8) mipmapLevel:0 withBytes:pixels bytesPerRow:32];
        id<MTLSamplerState> sampler = [device newSamplerStateWithDescriptor:[MTLSamplerDescriptor new]];
        id<MTLBuffer> uniforms = [device newBufferWithLength:2048 options:MTLResourceStorageModeShared];
        id<MTLBuffer> fragments = [device newBufferWithLength:2048 options:MTLResourceStorageModeShared];
        id<MTLBuffer> custom = [device newBufferWithLength:2048 options:MTLResourceStorageModeShared];
        id<MTLCommandQueue> queue = [device newCommandQueue];
        unsigned failures = 0;
        const char *names[] = {"solid selection", "disabled projected stage", "stage after disabled stage", "active projection outside", "active projection inside", "unbound projected stage", "nonprojected negative camera z", "disabled first stage", "uninitialized stage", "active second projection inside"};
        for (uint32_t testCase=0; testCase<10; ++testCase) {
            id<MTLCommandBuffer> command = [queue commandBuffer];
            id<MTLComputeCommandEncoder> compute = [command computeCommandEncoder];
            [compute setComputePipelineState:setup];
            [compute setBuffer:uniforms offset:0 atIndex:0];
            [compute setBuffer:fragments offset:0 atIndex:1];
            [compute setBuffer:custom offset:0 atIndex:2];
            [compute setBytes:&testCase length:4 atIndex:3];
            [compute dispatchThreads:MTLSizeMake(1,1,1) threadsPerThreadgroup:MTLSizeMake(1,1,1)];
            [compute endEncoding];
            MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
            pass.colorAttachments[0].texture = target;
            pass.colorAttachments[0].loadAction = MTLLoadActionClear;
            pass.colorAttachments[0].storeAction = MTLStoreActionStore;
            pass.colorAttachments[0].clearColor = MTLClearColorMake(0,0,0,0);
            id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
            [encoder setRenderPipelineState:render];
            [encoder setFragmentBuffer:uniforms offset:0 atIndex:1];
            [encoder setFragmentBuffer:fragments offset:0 atIndex:2];
            [encoder setFragmentBuffer:custom offset:0 atIndex:5];
            for (unsigned i=0;i<4;++i) {
                [encoder setFragmentTexture:white atIndex:i];
                [encoder setFragmentSamplerState:sampler atIndex:i];
            }
            [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
            [encoder endEncoding];
            [command commit]; [command waitUntilCompleted];
            require(command.status == MTLCommandBufferStatusCompleted, command.error.description);
            [target getBytes:pixels bytesPerRow:32 fromRegion:MTLRegionMake2D(0,0,8,8) mipmapLevel:0];
            uint32_t expected = testCase == 3 ? 0 : 0xff00ff00;
            bool passTest=true; for (auto pixel:pixels) passTest &= pixel == expected;
            printf("%s: %s\n", names[testCase], passTest ? "PASS" : "FAIL");
            failures += !passTest;
        }
        return failures ? 1 : 0;
    }
}
