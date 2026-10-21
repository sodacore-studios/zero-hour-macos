#import "MetalIndexBuffer8.h"
#import "MetalVertexBuffer8.h"
#import <Metal/Metal.h>
#include <windows.h>  // macOS Win32 type shim
#include <cstdio>
#include <cstring>

extern void *g_MetalMTLDevice;

// Shared storage with copy-on-write for updates after GPU binding, matching
// the vertex buffer lifetime rules.

MetalIndexBuffer8::MetalIndexBuffer8(unsigned int count, bool is32bit)
    : m_Count(count), m_Is32Bit(is32bit), m_RefCount(1), m_MTLBuffer(nullptr),
      m_SysMemCopy(nullptr) {
  uint32_t size = count * (is32bit ? 4 : 2);
  if (g_MetalMTLDevice) {
    id<MTLDevice> device = (__bridge id<MTLDevice>)g_MetalMTLDevice;
    id<MTLBuffer> buf =
        [device newBufferWithLength:size
                            options:MTLResourceStorageModeShared];
    m_MTLBuffer = (__bridge_retained void *)buf;
  } else {
    m_SysMemCopy = new uint8_t[size];
  }
}

MetalIndexBuffer8::~MetalIndexBuffer8() {
  delete[] m_SysMemCopy;
  if (m_MTLBuffer) {
    id<MTLBuffer> buf = (__bridge_transfer id<MTLBuffer>)m_MTLBuffer;
    buf = nil;
  }
}

STDMETHODIMP MetalIndexBuffer8::QueryInterface(REFIID riid, void **ppvObj) {
  return E_NOINTERFACE;
}

STDMETHODIMP_(ULONG) MetalIndexBuffer8::AddRef() { return ++m_RefCount; }

STDMETHODIMP_(ULONG) MetalIndexBuffer8::Release() {
  if (--m_RefCount == 0) {
    delete this;
    return 0;
  }
  return m_RefCount;
}

STDMETHODIMP MetalIndexBuffer8::GetDevice(IDirect3DDevice8 **ppDevice) {
  return E_NOTIMPL;
}

STDMETHODIMP MetalIndexBuffer8::SetPrivateData(REFGUID guid, const void *pData,
                                               DWORD SizeOfData, DWORD Flags) {
  return E_NOTIMPL;
}

STDMETHODIMP MetalIndexBuffer8::GetPrivateData(REFGUID guid, void *pData,
                                               DWORD *pSizeOfData) {
  return E_NOTIMPL;
}

STDMETHODIMP MetalIndexBuffer8::FreePrivateData(REFGUID guid) {
  return E_NOTIMPL;
}

STDMETHODIMP_(DWORD) MetalIndexBuffer8::SetPriority(DWORD PriorityNew) {
  return 0;
}

STDMETHODIMP_(DWORD) MetalIndexBuffer8::GetPriority() { return 0; }

STDMETHODIMP_(void) MetalIndexBuffer8::PreLoad() {}

STDMETHODIMP_(D3DRESOURCETYPE) MetalIndexBuffer8::GetType() {
  return D3DRTYPE_INDEXBUFFER;
}

STDMETHODIMP MetalIndexBuffer8::Lock(UINT OffsetToLock, UINT SizeToLock,
                                     BYTE **ppbData, DWORD Flags) {
  if (!ppbData)
    return E_POINTER;

  // Shared storage does not synchronize CPU writes with queued GPU reads.
  // Preserve the previous backing store once a draw has referenced it. Metal
  // retains that store until the command buffer finishes; no GPU wait is needed.
  // NOOVERWRITE remains the caller's promise to touch only unused ranges.
  const bool discard = (Flags & D3DLOCK_DISCARD) != 0;
  const bool preserve = m_GPUReferenced &&
      !(Flags & (D3DLOCK_READONLY | D3DLOCK_NOOVERWRITE));
  if (m_MTLBuffer && (discard || preserve)) {
    id<MTLBuffer> oldBuffer = (__bridge id<MTLBuffer>)m_MTLBuffer;
    id<MTLBuffer> replacement =
        [oldBuffer.device newBufferWithLength:m_Count * (m_Is32Bit ? 4 : 2)
                                      options:MTLResourceStorageModeShared];
    if (!replacement) {
      *ppbData = nullptr;
      return E_OUTOFMEMORY;
    }
    if (!discard)
      memcpy(replacement.contents, oldBuffer.contents, m_Count * (m_Is32Bit ? 4 : 2));
    id<MTLBuffer> releasedBuffer = (__bridge_transfer id<MTLBuffer>)m_MTLBuffer;
    m_MTLBuffer = (__bridge_retained void *)replacement;
    m_GPUReferenced = false;
    (void)releasedBuffer;
  }

  if (m_MTLBuffer) {
    id<MTLBuffer> buf = (__bridge id<MTLBuffer>)m_MTLBuffer;
    *ppbData = (BYTE *)[buf contents] + OffsetToLock;
    return D3D_OK;
  }

  *ppbData = m_SysMemCopy + OffsetToLock;
  return D3D_OK;
}

STDMETHODIMP MetalIndexBuffer8::Unlock() {
  return D3D_OK;
}

void *MetalIndexBuffer8::GetMTLBuffer() {
  if (m_MTLBuffer) {
    m_GPUReferenced = true;
    return m_MTLBuffer;
  }

  id<MTLDevice> device = g_MetalMTLDevice
                             ? (__bridge id<MTLDevice>)g_MetalMTLDevice
                             : MTLCreateSystemDefaultDevice();
  if (!device)
    return nullptr;

  uint32_t size = m_Count * (m_Is32Bit ? 4 : 2);

  if (m_SysMemCopy) {
    id<MTLBuffer> buf =
        [device newBufferWithBytes:m_SysMemCopy
                            length:size
                           options:MTLResourceStorageModeShared];
    m_MTLBuffer = (__bridge_retained void *)buf;
    delete[] m_SysMemCopy;
    m_SysMemCopy = nullptr;
  } else {
    id<MTLBuffer> buf =
        [device newBufferWithLength:size
                            options:MTLResourceStorageModeShared];
    m_MTLBuffer = (__bridge_retained void *)buf;
  }

  m_GPUReferenced = m_MTLBuffer != nullptr;
  return m_MTLBuffer;
}

STDMETHODIMP MetalIndexBuffer8::GetDesc(D3DINDEXBUFFER_DESC *pDesc) {
  if (pDesc) {
    pDesc->Format = m_Is32Bit ? D3DFMT_INDEX32 : D3DFMT_INDEX16;
    pDesc->Type = D3DRTYPE_INDEXBUFFER;
    pDesc->Usage = 0;
    pDesc->Pool = D3DPOOL_MANAGED;
    pDesc->Size = m_Count * (m_Is32Bit ? 4 : 2);
    return D3D_OK;
  }
  return E_POINTER;
}
