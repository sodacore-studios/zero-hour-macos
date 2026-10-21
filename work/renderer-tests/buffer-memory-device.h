// A deterministic in-memory implementation of the Metal buffer selectors used
// by the production classes. CI does not require a physical GPU for these tests.
@interface TestBuffer : NSObject
@property(nonatomic, strong) NSMutableData *storage;
@property(nonatomic, strong) id device;
- (void *)contents;
@end
@implementation TestBuffer
- (void *)contents { return self.storage.mutableBytes; }
@end

@interface TestDevice : NSObject
@property(nonatomic) BOOL failAllocation;
- (id)newBufferWithLength:(NSUInteger)length options:(MTLResourceOptions)options;
- (id)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length options:(MTLResourceOptions)options;
@end
@implementation TestDevice
- (id)newBufferWithLength:(NSUInteger)length options:(MTLResourceOptions)options {
  (void)options;
  if (self.failAllocation) return nil;
  TestBuffer *buffer = [TestBuffer new];
  buffer.storage = [NSMutableData dataWithLength:length];
  buffer.device = self;
  return buffer;
}
- (id)newBufferWithBytes:(const void *)bytes length:(NSUInteger)length options:(MTLResourceOptions)options {
  TestBuffer *buffer = [self newBufferWithLength:length options:options];
  if (buffer) memcpy(buffer.contents, bytes, length);
  return buffer;
}
@end

template<class Buffer> bool checkMemory(Buffer &buffer, const char *name, TestDevice *device) {
  unsigned failed = 0;
  auto check = [&](bool value, const char *description) {
    printf("%s: %s: %s\n", name, description, value ? "PASS" : "FAIL");
    failed += !value;
  };
  BYTE *bytes = nullptr;
  check(buffer.Lock(0, 64, nullptr, 0) == E_POINTER, "null output rejected");
  buffer.Lock(0, 64, &bytes, 0);
  memset(bytes, 0x31, 64);
  BYTE *initial = bytes;
  buffer.Unlock();
  buffer.Lock(0, 64, &bytes, 0);
  check(bytes == initial, "unbound writes reuse storage");
  buffer.Unlock();
  id<MTLBuffer> original = (__bridge id<MTLBuffer>)buffer.GetMTLBuffer();
  buffer.Lock(16, 16, &bytes, 0);
  memset(bytes, 0x72, 16);
  BYTE *replacement = bytes - 16;
  buffer.Unlock();
  bool unchanged = true, preserved = true;
  for (unsigned i = 0; i < 64; ++i) {
    unchanged &= ((BYTE *)original.contents)[i] == 0x31;
    preserved &= replacement[i] == (i >= 16 && i < 32 ? 0x72 : 0x31);
  }
  check(unchanged, "bound backing store remains immutable");
  check(preserved, "partial update preserves untouched bytes");
  buffer.Lock(0, 64, &bytes, 0);
  check(bytes == replacement, "consecutive writes reuse new storage");
  buffer.Unlock();
  void *current = buffer.GetMTLBuffer();
  buffer.Lock(0, 64, &bytes, D3DLOCK_READONLY);
  check(bytes == replacement, "read-only locks retain backing store");
  buffer.Unlock();
  buffer.Lock(32, 16, &bytes, D3DLOCK_NOOVERWRITE);
  check(bytes == replacement + 32, "no-overwrite appends retain backing store");
  memset(bytes, 0x93, 16);
  buffer.Unlock();
  device.failAllocation = YES;
  check(buffer.Lock(0, 16, &bytes, 0) == E_OUTOFMEMORY && bytes == nullptr,
        "allocation failure returns no writable pointer");
  check(buffer.GetMTLBuffer() == current, "allocation failure preserves original ownership");
  device.failAllocation = NO;
  buffer.Lock(0, 64, &bytes, D3DLOCK_DISCARD);
  memset(bytes, 0x54, 64);
  buffer.Unlock();
  id<MTLBuffer> discarded = (__bridge id<MTLBuffer>)buffer.GetMTLBuffer();
  check((__bridge void *)discarded != current, "discard replaces backing store");
  buffer.Lock(0, 64, &bytes, D3DLOCK_READONLY);
  bool written = true;
  for (unsigned i = 0; i < 64; ++i) written &= bytes[i] == 0x54;
  buffer.Unlock();
  check(written, "discarded storage accepts new contents");
  return failed == 0;
}
