const std = @import("std");
const builtin = @import("builtin");
const pack_data = @import("generated/harmonious_name_pack_xz.zig");

var decoded_ready: bool = false;
var decoded_pack: []u8 = &[_]u8{};

var kind_counts: []u32 = &[_]u32{};
var kind_starts: []u32 = &[_]u32{};
var name_offsets: []u32 = &[_]u32{};
var name_lengths: []u16 = &[_]u16{};

fn allocator() std.mem.Allocator {
    return if (builtin.target.cpu.arch == .wasm32)
        std.heap.wasm_allocator
    else
        std.heap.page_allocator;
}

fn decodeIfNeeded() bool {
    if (decoded_ready) return true;

    const alloc = allocator();

    var in_stream = std.io.fixedBufferStream(pack_data.PACK_XZ[0..]);
    var dec = std.compress.xz.decompress(alloc, in_stream.reader()) catch return false;
    defer dec.deinit();

    const out = alloc.alloc(u8, pack_data.PACK_RAW_LEN) catch return false;
    var keep_out = false;
    defer if (!keep_out) alloc.free(out);

    var out_pos: usize = 0;
    while (true) {
        if (out_pos > out.len) return false;
        const n = dec.reader().read(out[out_pos..]) catch return false;
        if (n == 0) break;
        out_pos += n;
    }
    if (out_pos != out.len) return false;

    decoded_pack = out;
    if (!parseDecoded()) {
        decoded_pack = &[_]u8{};
        return false;
    }
    keep_out = true;
    decoded_ready = true;
    return true;
}

fn readU16At(off: usize) ?u16 {
    if (off + 2 > decoded_pack.len) return null;
    const bytes = decoded_pack[off .. off + 2];
    return std.mem.readInt(u16, @as(*const [2]u8, @ptrCast(bytes.ptr)), .little);
}

fn readU32At(off: usize) ?u32 {
    if (off + 4 > decoded_pack.len) return null;
    const bytes = decoded_pack[off .. off + 4];
    return std.mem.readInt(u32, @as(*const [4]u8, @ptrCast(bytes.ptr)), .little);
}

fn parseDecoded() bool {
    if (decoded_pack.len < 16) return false;
    if (!std.mem.eql(u8, decoded_pack[0..8], "HNP1\x00\x00\x00\x00")) return false;

    var cursor: usize = 8;
    const kind_count_u32 = readU32At(cursor) orelse return false;
    cursor += 4;
    const total_names_u32 = readU32At(cursor) orelse return false;
    cursor += 4;

    const kind_count: usize = @intCast(kind_count_u32);
    const total_names: usize = @intCast(total_names_u32);

    if (kind_count != pack_data.KIND_COUNT) return false;
    if (total_names != pack_data.TOTAL_NAME_COUNT) return false;

    const alloc = allocator();
    const tmp_kind_counts = alloc.alloc(u32, kind_count) catch return false;
    errdefer alloc.free(tmp_kind_counts);
    const tmp_kind_starts = alloc.alloc(u32, kind_count + 1) catch return false;
    errdefer alloc.free(tmp_kind_starts);
    const tmp_name_offsets = alloc.alloc(u32, total_names) catch return false;
    errdefer alloc.free(tmp_name_offsets);
    const tmp_name_lengths = alloc.alloc(u16, total_names) catch return false;
    errdefer alloc.free(tmp_name_lengths);

    tmp_kind_starts[0] = 0;
    var running: u32 = 0;

    var kind_i: usize = 0;
    while (kind_i < kind_count) : (kind_i += 1) {
        const count = readU32At(cursor) orelse return false;
        cursor += 4;
        tmp_kind_counts[kind_i] = count;
        running += count;
        tmp_kind_starts[kind_i + 1] = running;
    }

    if (running != total_names_u32) return false;

    var name_i: usize = 0;
    while (name_i < total_names) : (name_i += 1) {
        const name_len = readU16At(cursor) orelse return false;
        cursor += 2;

        const name_len_usize: usize = @intCast(name_len);
        if (cursor + name_len_usize > decoded_pack.len) return false;

        tmp_name_offsets[name_i] = @as(u32, @intCast(cursor));
        tmp_name_lengths[name_i] = name_len;
        cursor += name_len_usize;
    }

    if (cursor != decoded_pack.len) return false;

    kind_counts = tmp_kind_counts;
    kind_starts = tmp_kind_starts;
    name_offsets = tmp_name_offsets;
    name_lengths = tmp_name_lengths;
    return true;
}

pub fn kindCount() usize {
    if (!decodeIfNeeded()) return 0;
    return kind_counts.len;
}

pub fn imageCount(kind_index: usize) usize {
    if (!decodeIfNeeded()) return 0;
    if (kind_index >= kind_counts.len) return 0;
    return @as(usize, @intCast(kind_counts[kind_index]));
}

pub fn imageName(kind_index: usize, image_index: usize) ?[]const u8 {
    if (!decodeIfNeeded()) return null;
    if (kind_index >= kind_counts.len) return null;

    const start: usize = @intCast(kind_starts[kind_index]);
    const end: usize = @intCast(kind_starts[kind_index + 1]);
    const count = end - start;
    if (image_index >= count) return null;

    const global_index = start + image_index;
    const off: usize = @intCast(name_offsets[global_index]);
    const len: usize = @intCast(name_lengths[global_index]);
    return decoded_pack[off .. off + len];
}
