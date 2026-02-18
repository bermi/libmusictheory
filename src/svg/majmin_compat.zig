const std = @import("std");
const builtin = @import("builtin");
const pack_data = @import("../generated/harmonious_majmin_compat_xz.zig");

const SCALE_I128: i128 = 100_000_000_000_000_000;
const MARKER_HREF: u8 = 0x1d;
const MARKER_STYLE: u8 = 0x1e;
const MARKER_D: u8 = 0x1f;
const MARKER_NUM: u8 = 0x01;

pub const Kind = enum {
    modes,
    scales,
};

const TemplateInfo = struct {
    fmt_off: u32,
    fmt_len: u32,
    num_count: u16,
    flags_off: u32,
    base_off: u32,
};

const OffsetInfo = struct {
    dx: i128,
    dy: i128,
};

const FileInfo = struct {
    skeleton_id: u32,
    href_count: u16,
    style_count: u16,
    d_count: u16,
    href_off: u32,
    style_off: u32,
    d_off: u32,
};

var decoded_ready: bool = false;
var parsed_ready: bool = false;

var decoded_pack: []u8 = &[_]u8{};

var skeleton_off: [pack_data.SKELETON_COUNT]u32 = undefined;
var skeleton_len: [pack_data.SKELETON_COUNT]u32 = undefined;
var style_off: [pack_data.STYLE_COUNT]u32 = undefined;
var style_len: [pack_data.STYLE_COUNT]u16 = undefined;
var href_off: [pack_data.HREF_COUNT]u32 = undefined;
var href_len: [pack_data.HREF_COUNT]u16 = undefined;
var templates: [pack_data.TEMPLATE_COUNT]TemplateInfo = undefined;
var offsets: [pack_data.OFFSET_COUNT]OffsetInfo = undefined;
var files: [pack_data.FILE_COUNT]FileInfo = undefined;

fn decodePackIfNeeded() bool {
    if (decoded_ready) return true;

    const allocator = if (builtin.target.cpu.arch == .wasm32)
        std.heap.wasm_allocator
    else
        std.heap.page_allocator;

    var in_stream = std.io.fixedBufferStream(pack_data.PACK_XZ[0..]);
    var dec = std.compress.xz.decompress(allocator, in_stream.reader()) catch return false;
    defer dec.deinit();

    const out = allocator.alloc(u8, pack_data.PACK_RAW_LEN) catch return false;
    errdefer allocator.free(out);

    var out_pos: usize = 0;
    while (true) {
        if (out_pos > out.len) return false;
        const n = dec.reader().read(out[out_pos..]) catch return false;
        if (n == 0) break;
        out_pos += n;
    }

    if (out_pos != out.len) return false;
    decoded_pack = out;
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

fn readI128At(off: usize) ?i128 {
    if (off + 16 > decoded_pack.len) return null;
    const bytes = decoded_pack[off .. off + 16];
    return std.mem.readInt(i128, @as(*const [16]u8, @ptrCast(bytes.ptr)), .little);
}

fn parsePackIfNeeded() bool {
    if (parsed_ready) return true;
    if (!decodePackIfNeeded()) return false;

    if (decoded_pack.len < 8) return false;
    if (!std.mem.eql(u8, decoded_pack[0..8], "MJMN2\x00\x00\x00")) return false;

    var cursor: usize = 8;

    const skeleton_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const style_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const href_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const template_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const offset_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const file_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const mode_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const scale_count = readU32At(cursor) orelse return false;
    cursor += 4;

    if (skeleton_count != pack_data.SKELETON_COUNT) return false;
    if (style_count != pack_data.STYLE_COUNT) return false;
    if (href_count != pack_data.HREF_COUNT) return false;
    if (template_count != pack_data.TEMPLATE_COUNT) return false;
    if (offset_count != pack_data.OFFSET_COUNT) return false;
    if (file_count != pack_data.FILE_COUNT) return false;
    if (mode_count != pack_data.MODE_COUNT) return false;
    if (scale_count != pack_data.SCALE_COUNT) return false;

    var i: usize = 0;
    while (i < skeleton_count) : (i += 1) {
        const len = readU32At(cursor) orelse return false;
        cursor += 4;
        if (cursor + len > decoded_pack.len) return false;
        skeleton_off[i] = @as(u32, @intCast(cursor));
        skeleton_len[i] = len;
        cursor += len;
    }

    i = 0;
    while (i < style_count) : (i += 1) {
        const len = readU16At(cursor) orelse return false;
        cursor += 2;
        if (cursor + len > decoded_pack.len) return false;
        style_off[i] = @as(u32, @intCast(cursor));
        style_len[i] = len;
        cursor += len;
    }

    i = 0;
    while (i < href_count) : (i += 1) {
        const len = readU16At(cursor) orelse return false;
        cursor += 2;
        if (cursor + len > decoded_pack.len) return false;
        href_off[i] = @as(u32, @intCast(cursor));
        href_len[i] = len;
        cursor += len;
    }

    i = 0;
    while (i < template_count) : (i += 1) {
        const fmt_len = readU32At(cursor) orelse return false;
        cursor += 4;
        const num_count = readU16At(cursor) orelse return false;
        cursor += 2;
        if (cursor + fmt_len > decoded_pack.len) return false;
        const fmt_off = cursor;
        cursor += fmt_len;

        if (cursor + num_count > decoded_pack.len) return false;
        const flags_off = cursor;
        cursor += num_count;

        const base_bytes: usize = @as(usize, num_count) * 16;
        if (cursor + base_bytes > decoded_pack.len) return false;
        const base_off = cursor;
        cursor += base_bytes;

        templates[i] = .{
            .fmt_off = @as(u32, @intCast(fmt_off)),
            .fmt_len = fmt_len,
            .num_count = num_count,
            .flags_off = @as(u32, @intCast(flags_off)),
            .base_off = @as(u32, @intCast(base_off)),
        };
    }

    i = 0;
    while (i < offset_count) : (i += 1) {
        const dx = readI128At(cursor) orelse return false;
        cursor += 16;
        const dy = readI128At(cursor) orelse return false;
        cursor += 16;
        offsets[i] = .{ .dx = dx, .dy = dy };
    }

    i = 0;
    while (i < file_count) : (i += 1) {
        const skeleton_id = readU32At(cursor) orelse return false;
        cursor += 4;
        const href_count_file = readU16At(cursor) orelse return false;
        cursor += 2;
        const style_count_file = readU16At(cursor) orelse return false;
        cursor += 2;
        const d_count_file = readU16At(cursor) orelse return false;
        cursor += 2;

        const href_off_file = cursor;
        const href_bytes = @as(usize, href_count_file) * 2;
        if (cursor + href_bytes > decoded_pack.len) return false;
        cursor += href_bytes;

        const style_off_file = cursor;
        const style_bytes = @as(usize, style_count_file) * 2;
        if (cursor + style_bytes > decoded_pack.len) return false;
        cursor += style_bytes;

        const d_off_file = cursor;
        const d_bytes = @as(usize, d_count_file) * 4;
        if (cursor + d_bytes > decoded_pack.len) return false;
        cursor += d_bytes;

        files[i] = .{
            .skeleton_id = skeleton_id,
            .href_count = href_count_file,
            .style_count = style_count_file,
            .d_count = d_count_file,
            .href_off = @as(u32, @intCast(href_off_file)),
            .style_off = @as(u32, @intCast(style_off_file)),
            .d_off = @as(u32, @intCast(d_off_file)),
        };
    }

    parsed_ready = true;
    return true;
}

fn writeScaledDecimal(writer: anytype, value: i128) !void {
    var v = value;
    if (v < 0) {
        try writer.writeByte('-');
        v = -v;
    }

    const int_part: i128 = @divTrunc(v, SCALE_I128);
    const frac_part: i128 = @mod(v, SCALE_I128);

    var int_buf: [64]u8 = undefined;
    const int_text = try std.fmt.bufPrint(int_buf[0..], "{d}", .{int_part});
    try writer.writeAll(int_text);

    if (frac_part == 0) return;

    try writer.writeByte('.');

    var frac_buf: [17]u8 = undefined;
    var tmp: u128 = @as(u128, @intCast(frac_part));
    var idx: usize = 17;
    while (idx > 0) {
        idx -= 1;
        const digit: u8 = @as(u8, @intCast(tmp % 10));
        frac_buf[idx] = '0' + digit;
        tmp /= 10;
    }

    var end: usize = 17;
    while (end > 0 and frac_buf[end - 1] == '0') : (end -= 1) {}
    try writer.writeAll(frac_buf[0..end]);
}

fn renderTemplatePath(writer: anytype, template_id: usize, offset_id: usize) !void {
    if (template_id >= templates.len or offset_id >= offsets.len) return error.CorruptInput;
    const t = templates[template_id];
    const off = offsets[offset_id];

    const fmt_start = @as(usize, t.fmt_off);
    const fmt_end = fmt_start + @as(usize, t.fmt_len);
    if (fmt_end > decoded_pack.len) return error.CorruptInput;
    const fmt = decoded_pack[fmt_start..fmt_end];

    const flags_start = @as(usize, t.flags_off);
    const base_start = @as(usize, t.base_off);
    var slot: usize = 0;

    for (fmt) |ch| {
        if (ch != MARKER_NUM) {
            try writer.writeByte(ch);
            continue;
        }

        if (slot >= t.num_count) return error.CorruptInput;
        const flag = decoded_pack[flags_start + slot];
        const base = readI128At(base_start + slot * 16) orelse return error.CorruptInput;

        const value: i128 = switch (flag) {
            1 => base + off.dx,
            2 => base + off.dy,
            else => base,
        };
        try writeScaledDecimal(writer, value);
        slot += 1;
    }

    if (slot != t.num_count) return error.CorruptInput;
}

fn getStringById(off_table: []const u32, len_table: []const u16, id: usize) ?[]const u8 {
    if (id >= off_table.len) return null;
    const start = @as(usize, off_table[id]);
    const len = @as(usize, len_table[id]);
    if (start + len > decoded_pack.len) return null;
    return decoded_pack[start .. start + len];
}

pub fn render(kind: Kind, image_index: usize, buf: []u8) []u8 {
    if (!parsePackIfNeeded()) return "";

    const file_index = switch (kind) {
        .modes => image_index,
        .scales => pack_data.MODE_COUNT + image_index,
    };
    if (file_index >= files.len) return "";

    const f = files[file_index];
    if (f.skeleton_id >= skeleton_off.len) return "";

    const skeleton_start = @as(usize, skeleton_off[f.skeleton_id]);
    const skeleton_size = @as(usize, skeleton_len[f.skeleton_id]);
    if (skeleton_start + skeleton_size > decoded_pack.len) return "";
    const skeleton = decoded_pack[skeleton_start .. skeleton_start + skeleton_size];

    var href_i: usize = 0;
    var style_i: usize = 0;
    var d_i: usize = 0;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    for (skeleton) |ch| {
        switch (ch) {
            MARKER_HREF => {
                if (href_i >= f.href_count) return "";
                const id = readU16At(@as(usize, f.href_off) + href_i * 2) orelse return "";
                const text = getStringById(href_off[0..], href_len[0..], id) orelse return "";
                w.writeAll(text) catch return "";
                href_i += 1;
            },
            MARKER_STYLE => {
                if (style_i >= f.style_count) return "";
                const id = readU16At(@as(usize, f.style_off) + style_i * 2) orelse return "";
                const text = getStringById(style_off[0..], style_len[0..], id) orelse return "";
                w.writeAll(text) catch return "";
                style_i += 1;
            },
            MARKER_D => {
                if (d_i >= f.d_count) return "";
                const base = @as(usize, f.d_off) + d_i * 4;
                const tid = readU16At(base) orelse return "";
                const oid = readU16At(base + 2) orelse return "";
                renderTemplatePath(w, tid, oid) catch return "";
                d_i += 1;
            },
            else => w.writeByte(ch) catch return "",
        }
    }

    if (href_i != f.href_count or style_i != f.style_count or d_i != f.d_count) return "";
    return buf[0..stream.pos];
}
