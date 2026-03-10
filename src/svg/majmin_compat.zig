const std = @import("std");
const builtin = @import("builtin");
const pack_data = @import("../generated/harmonious_majmin_scene_pack_xz.zig");
const majmin_scene = @import("majmin_scene.zig");

const SCALE_I128: i128 = 100_000_000_000_000_000;
const MARKER_HREF: u8 = 0x1d;
const MARKER_STYLE: u8 = 0x1e;
const MARKER_D: u8 = 0x1f;
const MARKER_NUM: u8 = 0x01;

const LEGACY_KIND_COUNT: usize = 2;
const LEGACY_VARIANT_COUNT: usize = 2;

const MODE_TRANS_VALUES = [_]i8{ -1, 0, 1, 10, 11, 2, 3, 4, 5, 6, 7, 8, 9 };

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

const DRef = struct {
    template_id: u16,
    offset_id: u16,
};

const ModeGroupModel = struct {
    family: majmin_scene.Family,
    rotation: i8,
    skeleton_id: u16,
    href_slot_count: u16,
    style_slot_count: u16,
    d_slot_count: u16,
    href_base_count: u16,
    style_base_count: u16,
    d_base_count: u16,
    href_slot_base: [pack_data.MODE_MAX_HREF_SLOT_COUNT]u16,
    style_slot_base: [pack_data.MODE_MAX_STYLE_SLOT_COUNT]u16,
    d_slot_base: [pack_data.MODE_MAX_D_SLOT_COUNT]u16,
    href_map: [pack_data.MODE_TRANS_COUNT][pack_data.MODE_MAX_HREF_BASE_COUNT]u16,
    style_map: [pack_data.MODE_TRANS_COUNT][pack_data.MODE_MAX_STYLE_BASE_COUNT]u16,
    d_map: [pack_data.MODE_TRANS_COUNT][pack_data.MODE_MAX_D_BASE_COUNT]DRef,
};

const ScaleFamilyModel = struct {
    family: majmin_scene.Family,
    skeleton_id: u16,
    href_base_count: u16,
    style_base_count: u16,
    d_base_count: u16,
    href_slot_base: [pack_data.SCALE_HREF_SLOT_COUNT]u16,
    style_slot_base: [pack_data.SCALE_STYLE_SLOT_COUNT]u16,
    d_slot_base: [pack_data.SCALE_D_SLOT_COUNT]u16,
    href_map: [pack_data.SCALE_TRANS_COUNT][pack_data.SCALE_HREF_BASE_COUNT]u16,
    style_map: [pack_data.SCALE_TRANS_COUNT][pack_data.SCALE_STYLE_BASE_COUNT]u16,
    d_map: [pack_data.SCALE_TRANS_COUNT][pack_data.SCALE_D_BASE_COUNT]DRef,
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
var mode_group_models: [pack_data.MODE_GROUP_COUNT]ModeGroupModel = undefined;
var scale_family_models: [pack_data.SCALE_FAMILY_COUNT]ScaleFamilyModel = undefined;
var legacy_payload_off: [LEGACY_KIND_COUNT][LEGACY_VARIANT_COUNT]u32 = [_][LEGACY_VARIANT_COUNT]u32{
    [_]u32{ 0, 0 },
    [_]u32{ 0, 0 },
};
var legacy_payload_len: [LEGACY_KIND_COUNT][LEGACY_VARIANT_COUNT]u32 = [_][LEGACY_VARIANT_COUNT]u32{
    [_]u32{ 0, 0 },
    [_]u32{ 0, 0 },
};
var legacy_payload_present: [LEGACY_KIND_COUNT][LEGACY_VARIANT_COUNT]bool = [_][LEGACY_VARIANT_COUNT]bool{
    [_]bool{ false, false },
    [_]bool{ false, false },
};

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

fn familyFromId(id: u16) ?majmin_scene.Family {
    return switch (id) {
        0 => .dntri,
        1 => .hex,
        2 => .rhomb,
        3 => .uptri,
        else => null,
    };
}

fn decodeSignedI8(raw: u16) ?i8 {
    const signed16: i16 = @bitCast(raw);
    if (signed16 < std.math.minInt(i8) or signed16 > std.math.maxInt(i8)) return null;
    return @as(i8, @intCast(signed16));
}

fn parsePackIfNeeded() bool {
    if (parsed_ready) return true;
    if (!decodePackIfNeeded()) return false;

    if (decoded_pack.len < 8) return false;
    if (!std.mem.eql(u8, decoded_pack[0..8], "MJM3\x00\x00\x00\x00")) return false;

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
    const mode_group_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const scale_family_count = readU32At(cursor) orelse return false;
    cursor += 4;
    const legacy_count = readU32At(cursor) orelse return false;
    cursor += 4;

    if (skeleton_count != @as(u32, @intCast(pack_data.SKELETON_COUNT))) return false;
    if (style_count != @as(u32, @intCast(pack_data.STYLE_COUNT))) return false;
    if (href_count != @as(u32, @intCast(pack_data.HREF_COUNT))) return false;
    if (template_count != @as(u32, @intCast(pack_data.TEMPLATE_COUNT))) return false;
    if (offset_count != @as(u32, @intCast(pack_data.OFFSET_COUNT))) return false;
    if (mode_group_count != @as(u32, @intCast(pack_data.MODE_GROUP_COUNT))) return false;
    if (scale_family_count != @as(u32, @intCast(pack_data.SCALE_FAMILY_COUNT))) return false;
    if (legacy_count != @as(u32, @intCast(pack_data.LEGACY_COUNT))) return false;

    var i: usize = 0;
    while (i < pack_data.SKELETON_COUNT) : (i += 1) {
        const len = readU32At(cursor) orelse return false;
        cursor += 4;
        const len_usize: usize = @intCast(len);
        if (cursor + len_usize > decoded_pack.len) return false;
        skeleton_off[i] = @as(u32, @intCast(cursor));
        skeleton_len[i] = len;
        cursor += len_usize;
    }

    i = 0;
    while (i < pack_data.STYLE_COUNT) : (i += 1) {
        const len = readU16At(cursor) orelse return false;
        cursor += 2;
        const len_usize: usize = @intCast(len);
        if (cursor + len_usize > decoded_pack.len) return false;
        style_off[i] = @as(u32, @intCast(cursor));
        style_len[i] = len;
        cursor += len_usize;
    }

    i = 0;
    while (i < pack_data.HREF_COUNT) : (i += 1) {
        const len = readU16At(cursor) orelse return false;
        cursor += 2;
        const len_usize: usize = @intCast(len);
        if (cursor + len_usize > decoded_pack.len) return false;
        href_off[i] = @as(u32, @intCast(cursor));
        href_len[i] = len;
        cursor += len_usize;
    }

    i = 0;
    while (i < pack_data.TEMPLATE_COUNT) : (i += 1) {
        const fmt_len = readU32At(cursor) orelse return false;
        cursor += 4;
        const num_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const fmt_len_usize: usize = @intCast(fmt_len);
        if (cursor + fmt_len_usize > decoded_pack.len) return false;
        const fmt_off = cursor;
        cursor += fmt_len_usize;

        const num_count_usize: usize = @intCast(num_count);
        if (cursor + num_count_usize > decoded_pack.len) return false;
        const flags_off = cursor;
        cursor += num_count_usize;

        const base_bytes: usize = num_count_usize * 16;
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
    while (i < pack_data.OFFSET_COUNT) : (i += 1) {
        const dx = readI128At(cursor) orelse return false;
        cursor += 16;
        const dy = readI128At(cursor) orelse return false;
        cursor += 16;
        offsets[i] = .{ .dx = dx, .dy = dy };
    }

    i = 0;
    while (i < pack_data.MODE_GROUP_COUNT) : (i += 1) {
        const family_id = readU16At(cursor) orelse return false;
        cursor += 2;
        const rotation_raw = readU16At(cursor) orelse return false;
        cursor += 2;
        const skeleton_id = readU16At(cursor) orelse return false;
        cursor += 2;
        const href_slot_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const style_slot_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const d_slot_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const href_base_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const style_base_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const d_base_count = readU16At(cursor) orelse return false;
        cursor += 2;

        if (skeleton_id >= @as(u16, @intCast(pack_data.SKELETON_COUNT))) return false;
        if (href_slot_count > @as(u16, @intCast(pack_data.MODE_MAX_HREF_SLOT_COUNT))) return false;
        if (style_slot_count > @as(u16, @intCast(pack_data.MODE_MAX_STYLE_SLOT_COUNT))) return false;
        if (d_slot_count > @as(u16, @intCast(pack_data.MODE_MAX_D_SLOT_COUNT))) return false;
        if (href_base_count > @as(u16, @intCast(pack_data.MODE_MAX_HREF_BASE_COUNT))) return false;
        if (style_base_count > @as(u16, @intCast(pack_data.MODE_MAX_STYLE_BASE_COUNT))) return false;
        if (d_base_count > @as(u16, @intCast(pack_data.MODE_MAX_D_BASE_COUNT))) return false;

        var model: ModeGroupModel = undefined;
        model.family = familyFromId(family_id) orelse return false;
        model.rotation = decodeSignedI8(rotation_raw) orelse return false;
        model.skeleton_id = skeleton_id;
        model.href_slot_count = href_slot_count;
        model.style_slot_count = style_slot_count;
        model.d_slot_count = d_slot_count;
        model.href_base_count = href_base_count;
        model.style_base_count = style_base_count;
        model.d_base_count = d_base_count;

        var slot_i: usize = 0;
        while (slot_i < @as(usize, href_slot_count)) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= href_base_count) return false;
            model.href_slot_base[slot_i] = base_index;
        }

        slot_i = 0;
        while (slot_i < @as(usize, style_slot_count)) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= style_base_count) return false;
            model.style_slot_base[slot_i] = base_index;
        }

        slot_i = 0;
        while (slot_i < @as(usize, d_slot_count)) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= d_base_count) return false;
            model.d_slot_base[slot_i] = base_index;
        }

        var trans_i: usize = 0;
        while (trans_i < pack_data.MODE_TRANS_COUNT) : (trans_i += 1) {
            var base_i: usize = 0;
            while (base_i < @as(usize, href_base_count)) : (base_i += 1) {
                const id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (id >= @as(u16, @intCast(pack_data.HREF_COUNT))) return false;
                model.href_map[trans_i][base_i] = id;
            }

            base_i = 0;
            while (base_i < @as(usize, style_base_count)) : (base_i += 1) {
                const id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (id >= @as(u16, @intCast(pack_data.STYLE_COUNT))) return false;
                model.style_map[trans_i][base_i] = id;
            }

            base_i = 0;
            while (base_i < @as(usize, d_base_count)) : (base_i += 1) {
                const template_id = readU16At(cursor) orelse return false;
                cursor += 2;
                const offset_id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (template_id >= @as(u16, @intCast(pack_data.TEMPLATE_COUNT))) return false;
                if (offset_id >= @as(u16, @intCast(pack_data.OFFSET_COUNT))) return false;
                model.d_map[trans_i][base_i] = .{
                    .template_id = template_id,
                    .offset_id = offset_id,
                };
            }
        }

        mode_group_models[i] = model;
    }

    i = 0;
    while (i < pack_data.SCALE_FAMILY_COUNT) : (i += 1) {
        const family_id = readU16At(cursor) orelse return false;
        cursor += 2;
        const skeleton_id = readU16At(cursor) orelse return false;
        cursor += 2;
        const href_base_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const style_base_count = readU16At(cursor) orelse return false;
        cursor += 2;
        const d_base_count = readU16At(cursor) orelse return false;
        cursor += 2;

        if (skeleton_id >= @as(u16, @intCast(pack_data.SKELETON_COUNT))) return false;
        if (href_base_count > @as(u16, @intCast(pack_data.SCALE_HREF_BASE_COUNT))) return false;
        if (style_base_count > @as(u16, @intCast(pack_data.SCALE_STYLE_BASE_COUNT))) return false;
        if (d_base_count > @as(u16, @intCast(pack_data.SCALE_D_BASE_COUNT))) return false;

        var model: ScaleFamilyModel = undefined;
        model.family = familyFromId(family_id) orelse return false;
        model.skeleton_id = skeleton_id;
        model.href_base_count = href_base_count;
        model.style_base_count = style_base_count;
        model.d_base_count = d_base_count;

        var slot_i: usize = 0;
        while (slot_i < pack_data.SCALE_HREF_SLOT_COUNT) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= href_base_count) return false;
            model.href_slot_base[slot_i] = base_index;
        }

        slot_i = 0;
        while (slot_i < pack_data.SCALE_STYLE_SLOT_COUNT) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= style_base_count) return false;
            model.style_slot_base[slot_i] = base_index;
        }

        slot_i = 0;
        while (slot_i < pack_data.SCALE_D_SLOT_COUNT) : (slot_i += 1) {
            const base_index = readU16At(cursor) orelse return false;
            cursor += 2;
            if (base_index >= d_base_count) return false;
            model.d_slot_base[slot_i] = base_index;
        }

        var trans_i: usize = 0;
        while (trans_i < pack_data.SCALE_TRANS_COUNT) : (trans_i += 1) {
            var base_i: usize = 0;
            while (base_i < @as(usize, href_base_count)) : (base_i += 1) {
                const id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (id >= @as(u16, @intCast(pack_data.HREF_COUNT))) return false;
                model.href_map[trans_i][base_i] = id;
            }

            base_i = 0;
            while (base_i < @as(usize, style_base_count)) : (base_i += 1) {
                const id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (id >= @as(u16, @intCast(pack_data.STYLE_COUNT))) return false;
                model.style_map[trans_i][base_i] = id;
            }

            base_i = 0;
            while (base_i < @as(usize, d_base_count)) : (base_i += 1) {
                const template_id = readU16At(cursor) orelse return false;
                cursor += 2;
                const offset_id = readU16At(cursor) orelse return false;
                cursor += 2;
                if (template_id >= @as(u16, @intCast(pack_data.TEMPLATE_COUNT))) return false;
                if (offset_id >= @as(u16, @intCast(pack_data.OFFSET_COUNT))) return false;
                model.d_map[trans_i][base_i] = .{
                    .template_id = template_id,
                    .offset_id = offset_id,
                };
            }
        }

        scale_family_models[i] = model;
    }

    var kind_i: usize = 0;
    while (kind_i < LEGACY_KIND_COUNT) : (kind_i += 1) {
        var variant_i: usize = 0;
        while (variant_i < LEGACY_VARIANT_COUNT) : (variant_i += 1) {
            legacy_payload_present[kind_i][variant_i] = false;
            legacy_payload_off[kind_i][variant_i] = 0;
            legacy_payload_len[kind_i][variant_i] = 0;
        }
    }

    i = 0;
    while (i < pack_data.LEGACY_COUNT) : (i += 1) {
        const kind_id = readU16At(cursor) orelse return false;
        cursor += 2;
        const variant = readU16At(cursor) orelse return false;
        cursor += 2;
        const payload_len = readU32At(cursor) orelse return false;
        cursor += 4;

        if (kind_id >= @as(u16, @intCast(LEGACY_KIND_COUNT))) return false;
        if (variant < 1 or variant > @as(u16, LEGACY_VARIANT_COUNT)) return false;

        const payload_len_usize: usize = @intCast(payload_len);
        if (cursor + payload_len_usize > decoded_pack.len) return false;

        const kind_index: usize = @intCast(kind_id);
        const variant_index: usize = @intCast(variant - 1);
        if (legacy_payload_present[kind_index][variant_index]) return false;

        legacy_payload_present[kind_index][variant_index] = true;
        legacy_payload_off[kind_index][variant_index] = @as(u32, @intCast(cursor));
        legacy_payload_len[kind_index][variant_index] = payload_len;

        cursor += payload_len_usize;
    }

    kind_i = 0;
    while (kind_i < LEGACY_KIND_COUNT) : (kind_i += 1) {
        var variant_i: usize = 0;
        while (variant_i < LEGACY_VARIANT_COUNT) : (variant_i += 1) {
            if (!legacy_payload_present[kind_i][variant_i]) return false;
        }
    }

    if (cursor != decoded_pack.len) return false;
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

fn modeTranspositionIndex(transposition: i8) ?usize {
    for (MODE_TRANS_VALUES, 0..) |candidate, idx| {
        if (candidate == transposition) return idx;
    }
    return null;
}

fn modeGroupIndex(family: majmin_scene.Family, rotation: i8) ?usize {
    var i: usize = 0;
    while (i < mode_group_models.len) : (i += 1) {
        const model = mode_group_models[i];
        if (model.family == family and model.rotation == rotation) return i;
    }
    return null;
}

fn scaleFamilyModelIndex(family: majmin_scene.Family) ?usize {
    var i: usize = 0;
    while (i < scale_family_models.len) : (i += 1) {
        if (scale_family_models[i].family == family) return i;
    }
    return null;
}

fn legacyKindIndex(kind: Kind) usize {
    return switch (kind) {
        .modes => 0,
        .scales => 1,
    };
}

fn renderLegacy(kind: Kind, image_index: usize, buf: []u8) []u8 {
    if (image_index >= LEGACY_VARIANT_COUNT) return "";
    const kind_index = legacyKindIndex(kind);
    if (!legacy_payload_present[kind_index][image_index]) return "";

    const start = @as(usize, legacy_payload_off[kind_index][image_index]);
    const len = @as(usize, legacy_payload_len[kind_index][image_index]);
    if (start + len > decoded_pack.len) return "";
    if (len > buf.len) return "";

    std.mem.copyForwards(u8, buf[0..len], decoded_pack[start .. start + len]);
    return buf[0..len];
}

fn renderModes(image_index: usize, buf: []u8) []u8 {
    if (image_index >= majmin_scene.MODES_COUNT) return "";
    if (image_index < LEGACY_VARIANT_COUNT) return renderLegacy(.modes, image_index, buf);

    const scene = majmin_scene.sceneForIndex(.modes, image_index) orelse return "";
    const group_index = modeGroupIndex(scene.family, scene.rotation) orelse return "";
    const transposition_index = modeTranspositionIndex(scene.transposition) orelse return "";
    const model = mode_group_models[group_index];

    const skeleton_index: usize = @intCast(model.skeleton_id);
    if (skeleton_index >= skeleton_off.len) return "";
    const skeleton_start = @as(usize, skeleton_off[skeleton_index]);
    const skeleton_size = @as(usize, skeleton_len[skeleton_index]);
    if (skeleton_start + skeleton_size > decoded_pack.len) return "";
    const skeleton = decoded_pack[skeleton_start .. skeleton_start + skeleton_size];

    const href_slot_count: usize = model.href_slot_count;
    const style_slot_count: usize = model.style_slot_count;
    const d_slot_count: usize = model.d_slot_count;
    const href_base_count: usize = model.href_base_count;
    const style_base_count: usize = model.style_base_count;
    const d_base_count: usize = model.d_base_count;

    var href_i: usize = 0;
    var style_i: usize = 0;
    var d_i: usize = 0;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    for (skeleton) |ch| {
        switch (ch) {
            MARKER_HREF => {
                if (href_i >= href_slot_count) return "";
                const base_index: usize = model.href_slot_base[href_i];
                if (base_index >= href_base_count) return "";
                const id = model.href_map[transposition_index][base_index];
                const text = getStringById(href_off[0..], href_len[0..], @as(usize, id)) orelse return "";
                w.writeAll(text) catch return "";
                href_i += 1;
            },
            MARKER_STYLE => {
                if (style_i >= style_slot_count) return "";
                const base_index: usize = model.style_slot_base[style_i];
                if (base_index >= style_base_count) return "";
                const id = model.style_map[transposition_index][base_index];
                const text = getStringById(style_off[0..], style_len[0..], @as(usize, id)) orelse return "";
                w.writeAll(text) catch return "";
                style_i += 1;
            },
            MARKER_D => {
                if (d_i >= d_slot_count) return "";
                const base_index: usize = model.d_slot_base[d_i];
                if (base_index >= d_base_count) return "";
                const d_ref = model.d_map[transposition_index][base_index];
                renderTemplatePath(w, @as(usize, d_ref.template_id), @as(usize, d_ref.offset_id)) catch return "";
                d_i += 1;
            },
            else => w.writeByte(ch) catch return "",
        }
    }

    if (href_i != href_slot_count or style_i != style_slot_count or d_i != d_slot_count) return "";
    return buf[0..stream.pos];
}

fn renderScales(image_index: usize, buf: []u8) []u8 {
    if (image_index >= majmin_scene.SCALES_COUNT) return "";
    if (image_index < LEGACY_VARIANT_COUNT) return renderLegacy(.scales, image_index, buf);

    const scene = majmin_scene.sceneForIndex(.scales, image_index) orelse return "";
    const family_index = scaleFamilyModelIndex(scene.family) orelse return "";
    if (scene.transposition < 0 or scene.transposition >= @as(i8, @intCast(pack_data.SCALE_TRANS_COUNT))) return "";
    const transposition_index: usize = @intCast(scene.transposition);

    const model = scale_family_models[family_index];
    const skeleton_index: usize = @intCast(model.skeleton_id);
    if (skeleton_index >= skeleton_off.len) return "";

    const skeleton_start = @as(usize, skeleton_off[skeleton_index]);
    const skeleton_size = @as(usize, skeleton_len[skeleton_index]);
    if (skeleton_start + skeleton_size > decoded_pack.len) return "";
    const skeleton = decoded_pack[skeleton_start .. skeleton_start + skeleton_size];

    const href_base_count: usize = model.href_base_count;
    const style_base_count: usize = model.style_base_count;
    const d_base_count: usize = model.d_base_count;

    var href_i: usize = 0;
    var style_i: usize = 0;
    var d_i: usize = 0;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    for (skeleton) |ch| {
        switch (ch) {
            MARKER_HREF => {
                if (href_i >= pack_data.SCALE_HREF_SLOT_COUNT) return "";
                const base_index: usize = model.href_slot_base[href_i];
                if (base_index >= href_base_count) return "";
                const id = model.href_map[transposition_index][base_index];
                const text = getStringById(href_off[0..], href_len[0..], @as(usize, id)) orelse return "";
                w.writeAll(text) catch return "";
                href_i += 1;
            },
            MARKER_STYLE => {
                if (style_i >= pack_data.SCALE_STYLE_SLOT_COUNT) return "";
                const base_index: usize = model.style_slot_base[style_i];
                if (base_index >= style_base_count) return "";
                const id = model.style_map[transposition_index][base_index];
                const text = getStringById(style_off[0..], style_len[0..], @as(usize, id)) orelse return "";
                w.writeAll(text) catch return "";
                style_i += 1;
            },
            MARKER_D => {
                if (d_i >= pack_data.SCALE_D_SLOT_COUNT) return "";
                const base_index: usize = model.d_slot_base[d_i];
                if (base_index >= d_base_count) return "";
                const d_ref = model.d_map[transposition_index][base_index];
                renderTemplatePath(w, @as(usize, d_ref.template_id), @as(usize, d_ref.offset_id)) catch return "";
                d_i += 1;
            },
            else => w.writeByte(ch) catch return "",
        }
    }

    if (href_i != pack_data.SCALE_HREF_SLOT_COUNT or style_i != pack_data.SCALE_STYLE_SLOT_COUNT or d_i != pack_data.SCALE_D_SLOT_COUNT) return "";
    return buf[0..stream.pos];
}

pub fn render(kind: Kind, image_index: usize, buf: []u8) []u8 {
    if (!parsePackIfNeeded()) return "";
    return switch (kind) {
        .modes => renderModes(image_index, buf),
        .scales => renderScales(image_index, buf),
    };
}
