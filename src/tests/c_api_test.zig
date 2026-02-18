const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");

const c = @cImport({
    @cInclude("libmusictheory.h");
});

const LmtKeyContext = extern struct {
    tonic: u8,
    quality: u8,
};

const LmtFretPos = extern struct {
    string: u8,
    fret: u8,
};

extern fn lmt_pcs_from_list(pcs_ptr: [*c]const u8, count: u8) callconv(.c) u16;
extern fn lmt_pcs_to_list(set: u16, out: [*c]u8) callconv(.c) u8;
extern fn lmt_pcs_cardinality(set: u16) callconv(.c) u8;
extern fn lmt_pcs_transpose(set: u16, semitones: u8) callconv(.c) u16;
extern fn lmt_pcs_invert(set: u16) callconv(.c) u16;
extern fn lmt_pcs_complement(set: u16) callconv(.c) u16;
extern fn lmt_pcs_is_subset(small: u16, big: u16) callconv(.c) bool;

extern fn lmt_prime_form(set: u16) callconv(.c) u16;
extern fn lmt_forte_prime(set: u16) callconv(.c) u16;
extern fn lmt_is_cluster_free(set: u16) callconv(.c) bool;
extern fn lmt_evenness_distance(set: u16) callconv(.c) f32;

extern fn lmt_scale(scale_type: u8, tonic: u8) callconv(.c) u16;
extern fn lmt_mode(mode_type: u8, root: u8) callconv(.c) u16;
extern fn lmt_spell_note(pc: u8, key_ctx: LmtKeyContext) callconv(.c) [*c]const u8;

extern fn lmt_chord(chord_kind: u8, root: u8) callconv(.c) u16;
extern fn lmt_chord_name(set: u16) callconv(.c) [*c]const u8;
extern fn lmt_roman_numeral(chord_set: u16, key_ctx: LmtKeyContext) callconv(.c) [*c]const u8;

extern fn lmt_fret_to_midi(string: u8, fret: u8, tuning_ptr: [*c]const u8) callconv(.c) u8;
extern fn lmt_midi_to_fret_positions(note: u8, tuning_ptr: [*c]const u8, out: [*c]LmtFretPos) callconv(.c) u8;

extern fn lmt_svg_clock_optc(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_fret(frets_ptr: [*c]const i8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_chord_staff(chord_kind: u8, root: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_wasm_scratch_ptr() callconv(.c) [*c]u8;
extern fn lmt_wasm_scratch_size() callconv(.c) u32;
extern fn lmt_svg_compat_kind_count() callconv(.c) u32;
extern fn lmt_svg_compat_kind_name(kind_index: u32) callconv(.c) [*c]const u8;
extern fn lmt_svg_compat_kind_directory(kind_index: u32) callconv(.c) [*c]const u8;
extern fn lmt_svg_compat_image_count(kind_index: u32) callconv(.c) u32;
extern fn lmt_svg_compat_image_name(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_compat_generate(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32;

test "c abi header layout and constants" {
    try testing.expectEqual(@as(usize, 2), @sizeOf(c.lmt_pitch_class_set));
    try testing.expectEqual(@as(usize, 2), @sizeOf(c.lmt_key_context));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_key_context, "tonic"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_key_context, "quality"));
    try testing.expectEqual(@as(c_int, 0), c.LMT_SCALE_DIATONIC);
    try testing.expectEqual(@as(c_int, 16), c.LMT_MODE_WHOLE_TONE);
    try testing.expectEqual(@as(c_int, 3), c.LMT_CHORD_AUGMENTED);
}

test "c abi set operations" {
    const triad = [_]u8{ 0, 4, 7 };
    const set = lmt_pcs_from_list(@ptrCast(&triad), @intCast(triad.len));

    try testing.expectEqual(@as(u16, 0x091), set);
    try testing.expectEqual(@as(u8, 3), lmt_pcs_cardinality(set));

    var out: [12]u8 = undefined;
    const count = lmt_pcs_to_list(set, @ptrCast(&out));
    try testing.expectEqual(@as(u8, 3), count);
    try testing.expectEqualSlices(u8, &[_]u8{ 0, 4, 7 }, out[0..count]);

    const transposed = lmt_pcs_transpose(set, 2);
    try testing.expectEqual(@as(u16, 0x244), transposed);

    const inverted = lmt_pcs_invert(set);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 5, 8 })), inverted);

    const complement = lmt_pcs_complement(set);
    try testing.expectEqual(@as(u8, 9), lmt_pcs_cardinality(complement));

    try testing.expect(lmt_pcs_is_subset(lmt_pcs_from_list(@ptrCast(&[_]u8{ 0, 7 }), 2), set));
    try testing.expect(!lmt_pcs_is_subset(lmt_pcs_from_list(@ptrCast(&[_]u8{ 1, 7 }), 2), set));
}

test "c abi classification" {
    const set = lmt_pcs_from_list(@ptrCast(&[_]u8{ 0, 4, 7 }), 3);
    try testing.expectEqual(set, lmt_prime_form(set));
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 3, 7 })), lmt_forte_prime(set));
    try testing.expect(lmt_is_cluster_free(set));
    try testing.expect(lmt_evenness_distance(set) > 0.0);
}

test "c abi scales modes and spelling" {
    const diatonic = lmt_scale(c.LMT_SCALE_DIATONIC, 0);
    try testing.expectEqual(@as(u16, 0x0AB5), diatonic);

    const dorian = lmt_mode(c.LMT_MODE_DORIAN, 0);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 2, 3, 5, 7, 9, 10 })), dorian);

    const key_ctx = LmtKeyContext{ .tonic = 0, .quality = c.LMT_KEY_MAJOR };
    const spelled = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_spell_note(1, key_ctx))), 0);
    try testing.expectEqualStrings("C#", spelled);
}

test "c abi chords and roman numerals" {
    const c_major = lmt_chord(c.LMT_CHORD_MAJOR, 0);
    const c_minor = lmt_chord(c.LMT_CHORD_MINOR, 0);

    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 4, 7 })), c_major);
    try testing.expectEqual(@as(u16, pcs.fromList(&[_]u4{ 0, 3, 7 })), c_minor);

    const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_chord_name(c_major))), 0);
    try testing.expectEqualStrings("Major", name);

    const key_ctx = LmtKeyContext{ .tonic = 0, .quality = c.LMT_KEY_MAJOR };
    const roman = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_roman_numeral(c_major, key_ctx))), 0);
    try testing.expectEqualStrings("I", roman);
}

test "c abi guitar functions" {
    const tuning = [_]u8{ 40, 45, 50, 55, 59, 64 };

    try testing.expectEqual(@as(u8, 40), lmt_fret_to_midi(0, 0, @ptrCast(&tuning)));

    var out: [6]LmtFretPos = undefined;
    const count = lmt_midi_to_fret_positions(60, @ptrCast(&tuning), @ptrCast(&out));
    try testing.expect(count > 0);
    try testing.expectEqual(@as(u8, 0), out[0].string);
}

test "c abi svg generators" {
    var svg_buf: [8192]u8 = [_]u8{0} ** 8192;
    const c_major = lmt_chord(c.LMT_CHORD_MAJOR, 0);

    const len1 = lmt_svg_clock_optc(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len1 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    const len2 = lmt_svg_fret(@ptrCast(&frets), @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len2 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));

    const len3 = lmt_svg_chord_staff(c.LMT_CHORD_MAJOR, 0, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len3 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
}

test "c abi harmonious compatibility surface" {
    try testing.expect(lmt_wasm_scratch_ptr() != null);
    try testing.expect(lmt_wasm_scratch_size() >= 4 * 1024 * 1024);

    const kind_count = lmt_svg_compat_kind_count();
    try testing.expect(kind_count >= 10);

    const kind_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_svg_compat_kind_name(0))), 0);
    try testing.expect(kind_name.len > 0);

    const kind_dir = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(lmt_svg_compat_kind_directory(0))), 0);
    try testing.expect(kind_dir.len > 0);

    const image_count = lmt_svg_compat_image_count(0);
    try testing.expect(image_count > 0);

    var name_buf: [512]u8 = [_]u8{0} ** 512;
    const name_len = lmt_svg_compat_image_name(0, 0, @ptrCast(&name_buf), @intCast(name_buf.len));
    try testing.expect(name_len > 0);
    try testing.expect(std.mem.indexOfScalar(u8, name_buf[0..name_len], '.') != null);

    var svg_buf: [4 * 1024 * 1024]u8 = [_]u8{0} ** (4 * 1024 * 1024);
    const svg_len = lmt_svg_compat_generate(0, 0, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(svg_len > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..5], "<svg ") or std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
}
