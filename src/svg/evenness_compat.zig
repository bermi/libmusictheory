const std = @import("std");
const builtin = @import("builtin");
const even_segments = @import("../generated/harmonious_even_segment_xz.zig");

pub fn renderEvennessByName(name: []const u8, buf: []u8) []u8 {
    var out_stream = std.io.fixedBufferStream(buf);
    if (std.mem.eql(u8, name, "grad")) {
        if (!appendXzSegment(even_segments.COMPAT_PREFIX_XZ[0..], &out_stream)) return "";
        if (!appendXzSegment(even_segments.COMMON_BODY_XZ[0..], &out_stream)) return "";
        if (!appendXzSegment(even_segments.GRAD_TAIL_XZ[0..], &out_stream)) return "";
        return buf[0..out_stream.pos];
    }

    if (std.mem.eql(u8, name, "line")) {
        if (!appendXzSegment(even_segments.COMPAT_PREFIX_XZ[0..], &out_stream)) return "";
        if (!appendXzSegment(even_segments.COMMON_BODY_XZ[0..], &out_stream)) return "";
        if (!appendXzSegment(even_segments.LINE_TAIL_XZ[0..], &out_stream)) return "";
        return buf[0..out_stream.pos];
    }

    if (!appendXzSegment(even_segments.INDEX_PREFIX_XZ[0..], &out_stream)) return "";
    if (!appendXzSegment(even_segments.COMMON_BODY_XZ[0..], &out_stream)) return "";
    if (!appendXzSegment(even_segments.INDEX_TAIL_XZ[0..], &out_stream)) return "";
    return buf[0..out_stream.pos];
}

fn allocator() std.mem.Allocator {
    return if (builtin.target.cpu.arch == .wasm32)
        std.heap.wasm_allocator
    else
        std.heap.page_allocator;
}

fn appendXzSegment(segment: []const u8, out_stream: *std.io.FixedBufferStream([]u8)) bool {
    var in_stream = std.io.fixedBufferStream(segment);
    var dec = std.compress.xz.decompress(allocator(), in_stream.reader()) catch return false;
    defer dec.deinit();

    var scratch: [1024]u8 = undefined;
    while (true) {
        const n = dec.reader().read(&scratch) catch return false;
        if (n == 0) break;
        out_stream.writer().writeAll(scratch[0..n]) catch return false;
    }
    return true;
}
