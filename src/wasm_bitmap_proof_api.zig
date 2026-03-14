const std = @import("std");
const svg_compat = @import("harmonious_svg_compat.zig");
const bitmap_compat = @import("bitmap_compat.zig");

var c_string_slots: [8][32]u8 = [_][32]u8{[_]u8{0} ** 32} ** 8;
var c_string_slot_index: usize = 0;
var compat_svg_buf: [4 * 1024 * 1024]u8 = undefined;
var wasm_client_scratch: [8 * 1024 * 1024]u8 = undefined;

fn writeCString(text: []const u8) [*c]const u8 {
    const slot = &c_string_slots[c_string_slot_index % c_string_slots.len];
    c_string_slot_index += 1;
    const n = @min(text.len, slot.len - 1);
    std.mem.copyForwards(u8, slot[0..n], text[0..n]);
    slot[n] = 0;
    return &slot[0];
}

fn copyOut(bytes: []const u8, buf: [*c]u8, buf_size: u32) u32 {
    const total = @as(u32, @intCast(bytes.len));
    if (buf == null or buf_size == 0) return total;

    const cap = @as(usize, @intCast(buf_size));
    const copy_len = @min(bytes.len, cap - 1);
    if (copy_len > 0) std.mem.copyForwards(u8, buf[0..copy_len], bytes[0..copy_len]);
    buf[copy_len] = 0;
    return total;
}

export fn lmt_wasm_scratch_ptr() callconv(.C) [*c]u8 {
    return &wasm_client_scratch[0];
}

export fn lmt_wasm_scratch_size() callconv(.C) u32 {
    return @as(u32, @intCast(wasm_client_scratch.len));
}

export fn lmt_svg_compat_kind_count() callconv(.C) u32 {
    return @as(u32, @intCast(svg_compat.kindCount()));
}

export fn lmt_svg_compat_kind_name(kind_index: u32) callconv(.C) [*c]const u8 {
    const name = svg_compat.kindName(@as(usize, kind_index)) orelse return writeCString("");
    return writeCString(name);
}

export fn lmt_svg_compat_kind_directory(kind_index: u32) callconv(.C) [*c]const u8 {
    const directory = svg_compat.kindDirectory(@as(usize, kind_index)) orelse return writeCString("");
    return writeCString(directory);
}

export fn lmt_svg_compat_image_count(kind_index: u32) callconv(.C) u32 {
    return @as(u32, @intCast(svg_compat.imageCount(@as(usize, kind_index))));
}

export fn lmt_svg_compat_image_name(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    const name = svg_compat.imageName(@as(usize, kind_index), @as(usize, image_index)) orelse return 0;
    return copyOut(name, buf, buf_size);
}

export fn lmt_svg_compat_generate(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    const svg = svg_compat.generateByIndex(@as(usize, kind_index), @as(usize, image_index), &compat_svg_buf);
    if (svg.len == 0) return 0;
    return copyOut(svg, buf, buf_size);
}

export fn lmt_bitmap_proof_scale_numerator() callconv(.C) u32 {
    return bitmap_compat.SCALE_NUMERATOR;
}

export fn lmt_bitmap_proof_scale_denominator() callconv(.C) u32 {
    return bitmap_compat.SCALE_DENOMINATOR;
}

export fn lmt_bitmap_compat_kind_supported(kind_index: u32) callconv(.C) u32 {
    return if (bitmap_compat.kindSupported(@as(usize, kind_index))) 1 else 0;
}

export fn lmt_bitmap_compat_target_width(kind_index: u32, image_index: u32) callconv(.C) u32 {
    return bitmap_compat.targetWidth(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_target_height(kind_index: u32, image_index: u32) callconv(.C) u32 {
    return bitmap_compat.targetHeight(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_required_rgba_bytes(kind_index: u32, image_index: u32) callconv(.C) u32 {
    return bitmap_compat.requiredRgbaBytes(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_render_candidate_rgba(kind_index: u32, image_index: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (out_rgba == null) return 0;
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderCandidateRgba(@as(usize, kind_index), @as(usize, image_index), out) catch return 0;
    return @as(u32, @intCast(len));
}

export fn lmt_bitmap_compat_render_reference_svg_rgba(kind_index: u32, svg_ptr: [*c]const u8, svg_len: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (svg_ptr == null or out_rgba == null or svg_len == 0) return 0;
    const svg = svg_ptr[0..@as(usize, svg_len)];
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderReferenceSvgRgba(@as(usize, kind_index), svg, out) catch return 0;
    return @as(u32, @intCast(len));
}
