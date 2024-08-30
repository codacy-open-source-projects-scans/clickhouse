#pragma once

#include <Common/PODArray.h>
#include <Compression/LZ4_decompress_faster.h>
#include <Compression/ICompressionCodec.h>
#include <IO/BufferBase.h>


namespace DB
{

class ReadBuffer;

/** Basic functionality for implementation of
  *  CompressedReadBuffer, CompressedReadBufferFromFile and CachedCompressedReadBuffer.
  */
class CompressedReadBufferBase
{
protected:
    ReadBuffer * compressed_in;

    /// If 'compressed_in' buffer has whole compressed block - then use it. Otherwise copy parts of data to 'own_compressed_buffer'.
    PODArray<char> own_compressed_buffer;
    /// Points to memory, holding compressed block.
    char * compressed_buffer = nullptr;

    /// Don't checksum on decompressing.
#if defined(FUZZER)
    bool disable_checksum = true;
#else
    bool disable_checksum = false;
#endif

    /// Allow reading data, compressed by different codecs from one file.
    bool allow_different_codecs;

    /// Report decompression errors as CANNOT_DECOMPRESS, not CORRUPTED_DATA
    bool external_data;

    /// Read compressed data into compressed_buffer. Get size of decompressed data from block header. Checksum if need.
    ///
    /// If always_copy is true then even if the compressed block is already stored in compressed_in.buffer()
    /// it will be copied into own_compressed_buffer.
    /// This is required for CheckingCompressedReadBuffer, since this is just a proxy.
    ///
    /// Returns number of compressed bytes read.
    size_t readCompressedData(size_t & size_decompressed, size_t & size_compressed_without_checksum, bool always_copy);

    /// Read compressed data into compressed_buffer for asynchronous decompression to avoid the situation of "read compressed block across the compressed_in".
    ///
    /// Compressed block may not be completely contained in "compressed_in" buffer which means compressed block may be read across the "compressed_in".
    /// For native LZ4/ZSTD, it has no problem in facing situation above because they are synchronous.
    /// But for asynchronous decompression, such as QPL deflate, it requires source and target buffer for decompression can not be overwritten until execution complete.
    ///
    /// Returns number of compressed bytes read.
    /// If Returns value > 0, means the address range for current block are maintained in "compressed_in", then asynchronous decompression can be called to boost performance.
    /// If Returns value == 0, it means current block cannot be decompressed asynchronously.Meanwhile, asynchronous requests for previous blocks should be flushed if any.
    size_t readCompressedDataBlockForAsynchronous(size_t & size_decompressed, size_t & size_compressed_without_checksum);

    /// Decompress into memory pointed by `to`
    void decompressTo(char * to, size_t size_decompressed, size_t size_compressed_without_checksum);

    /// This method can change location of `to` to avoid unnecessary copy if data is uncompressed.
    /// It is more efficient for compression codec NONE but not suitable if you want to decompress into specific location.
    void decompress(BufferBase::Buffer & to, size_t size_decompressed, size_t size_compressed_without_checksum);

    /// Flush all asynchronous decompress request.
    void flushAsynchronousDecompressRequests() const;

    /// Set decompression mode: Synchronous/Asynchronous/SoftwareFallback.
    /// The mode is "Synchronous" by default.
    /// flushAsynchronousDecompressRequests must be called subsequently once set "Asynchronous" mode.
    void setDecompressMode(ICompressionCodec::CodecMode mode) const;

public:
    /// 'compressed_in' could be initialized lazily, but before first call of 'readCompressedData'.
    explicit CompressedReadBufferBase(ReadBuffer * in = nullptr, bool allow_different_codecs_ = false, bool external_data_ = false);
    virtual ~CompressedReadBufferBase();

    /** Disable checksums.
      * For example, may be used when
      *  compressed data is generated by client, that cannot calculate checksums, and fill checksums with zeros instead.
      */
    void disableChecksumming()
    {
        disable_checksum = true;
    }

    /// Some compressed read buffer can do useful seek operation
    virtual void seek(size_t /* offset_in_compressed_file */, size_t /* offset_in_decompressed_block */) {}

    CompressionCodecPtr codec;
};

}