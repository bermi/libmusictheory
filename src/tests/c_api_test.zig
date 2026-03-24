const std = @import("std");
const testing = std.testing;

const pcs = @import("../pitch_class_set.zig");

const c = @cImport({
    @cInclude("libmusictheory.h");
    @cInclude("libmusictheory_compat.h");
});

const LmtKeyContext = extern struct {
    tonic: u8,
    quality: u8,
};

const LmtFretPos = extern struct {
    string: u8,
    fret: u8,
};

const LmtGuideDot = extern struct {
    position: LmtFretPos,
    pitch_class: u8,
    opacity: f32,
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
extern fn lmt_fret_to_midi_n(string: u32, fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32) callconv(.c) u8;
extern fn lmt_midi_to_fret_positions(note: u8, tuning_ptr: [*c]const u8, out: [*c]LmtFretPos) callconv(.c) u8;
extern fn lmt_midi_to_fret_positions_n(note: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtFretPos, out_cap: u32) callconv(.c) u32;
extern fn lmt_generate_voicings_n(chord_set: u16, tuning_ptr: [*c]const u8, tuning_count: u32, max_fret: u8, max_span: u8, out_frets: [*c]i8, out_voicing_cap: u32) callconv(.c) u32;
extern fn lmt_pitch_class_guide_n(selected_ptr: [*c]const LmtFretPos, selected_count: u32, min_fret: u8, max_fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtGuideDot, out_cap: u32) callconv(.c) u32;
extern fn lmt_frets_to_url_n(frets_ptr: [*c]const i8, fret_count: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_url_to_frets_n(url_ptr: [*c]const u8, out: [*c]i8, out_cap: u32) callconv(.c) u32;

extern fn lmt_svg_clock_optc(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_optic_k_group(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_evenness_chart(buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_evenness_field(set: u16, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_fret(frets_ptr: [*c]const i8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_fret_n(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_chord_staff(chord_kind: u8, root: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_key_staff(tonic: u8, quality: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_keyboard(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_svg_piano_staff(notes_ptr: [*c]const u8, note_count: u32, tonic: u8, quality: u8, buf: [*c]u8, buf_size: u32) callconv(.c) u32;
extern fn lmt_raster_is_enabled() callconv(.c) u32;
extern fn lmt_raster_demo_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_clock_optc_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_optic_k_group_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_evenness_chart_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_evenness_field_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_fret_rgba(frets_ptr: [*c]const i8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_fret_n_rgba(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_chord_staff_rgba(chord_kind: u8, root: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_key_staff_rgba(tonic: u8, quality: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_keyboard_rgba(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
extern fn lmt_bitmap_piano_staff_rgba(notes_ptr: [*c]const u8, note_count: u32, tonic: u8, quality: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.c) u32;
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
    try testing.expectEqual(@as(usize, 8), @sizeOf(c.lmt_guide_dot));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_key_context, "tonic"));
    try testing.expectEqual(@as(usize, 1), @offsetOf(c.lmt_key_context, "quality"));
    try testing.expectEqual(@as(usize, 0), @offsetOf(c.lmt_guide_dot, "position"));
    try testing.expectEqual(@as(usize, 2), @offsetOf(c.lmt_guide_dot, "pitch_class"));
    try testing.expectEqual(@as(usize, 4), @offsetOf(c.lmt_guide_dot, "opacity"));
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

    const alt_tuning = [_]u8{ 55, 60, 64, 69 };
    try testing.expectEqual(@as(u8, 69), lmt_fret_to_midi_n(3, 0, @ptrCast(&alt_tuning), alt_tuning.len));

    var out_n: [8]LmtFretPos = undefined;
    const count_n = lmt_midi_to_fret_positions_n(69, @ptrCast(&alt_tuning), alt_tuning.len, @ptrCast(&out_n), out_n.len);
    try testing.expectEqual(@as(u32, 4), count_n);
    try testing.expectEqual(@as(u8, 0), out_n[3].fret);
    try testing.expectEqual(@as(u8, 3), out_n[3].string);

    const four_string_voicing_tuning = [_]u8{ 48, 52, 55, 60 };
    var voicing_rows: [64 * 4]i8 = [_]i8{-1} ** (64 * 4);
    const voicing_count = lmt_generate_voicings_n(pcs.C_MAJOR_TRIAD, @ptrCast(&four_string_voicing_tuning), four_string_voicing_tuning.len, 12, 4, @ptrCast(&voicing_rows), 64);
    try testing.expect(voicing_count > 0);

    var found_open = false;
    var row: usize = 0;
    while (row < voicing_count) : (row += 1) {
        const start = row * four_string_voicing_tuning.len;
        if (std.mem.eql(i8, voicing_rows[start .. start + four_string_voicing_tuning.len], &[_]i8{ 0, 0, 0, 0 })) {
            found_open = true;
            break;
        }
    }
    try testing.expect(found_open);

    const selected = [_]LmtFretPos{
        .{ .string = 0, .fret = 0 },
    };
    const guide_tuning = [_]u8{ 55, 60, 64, 67 };
    var guide_out: [32]LmtGuideDot = undefined;
    const guide_count = lmt_pitch_class_guide_n(@ptrCast(&selected), selected.len, 0, 12, @ptrCast(&guide_tuning), guide_tuning.len, @ptrCast(&guide_out), guide_out.len);
    try testing.expect(guide_count > 0);

    var has_open_g = false;
    var has_c_string_g = false;
    var guide_i: usize = 0;
    while (guide_i < @min(guide_count, guide_out.len)) : (guide_i += 1) {
        const dot = guide_out[guide_i];
        if (dot.position.string == 3 and dot.position.fret == 0) has_open_g = true;
        if (dot.position.string == 1 and dot.position.fret == 7) has_c_string_g = true;
    }
    try testing.expect(has_open_g);
    try testing.expect(has_c_string_g);
    try testing.expectApproxEqAbs(@as(f32, 0.35), guide_out[0].opacity, 0.0001);

    const frets = [_]i8{ 0, 2, 3, 2 };
    var url_buf: [64]u8 = [_]u8{0} ** 64;
    const url_len = lmt_frets_to_url_n(@ptrCast(&frets), frets.len, @ptrCast(&url_buf), url_buf.len);
    try testing.expectEqualStrings("0,2,3,2", url_buf[0..url_len]);

    const url_input = "0,2,3,2";
    var parsed_frets: [8]i8 = [_]i8{-1} ** 8;
    const parsed_count = lmt_url_to_frets_n(url_input.ptr, @ptrCast(&parsed_frets), parsed_frets.len);
    try testing.expectEqual(@as(u32, 4), parsed_count);
    try testing.expectEqualSlices(i8, frets[0..], parsed_frets[0..parsed_count]);
}

test "c abi svg generators" {
    var svg_buf: [65536]u8 = [_]u8{0} ** 65536;
    const c_major = lmt_chord(c.LMT_CHORD_MAJOR, 0);

    const len1 = lmt_svg_clock_optc(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len1 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));

    const optic_k_len = lmt_svg_optic_k_group(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(optic_k_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..optic_k_len], "OPTIC/K") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..optic_k_len], "class=\"optic-k-ring\"") >= 2);

    const evenness_len = lmt_svg_evenness_chart(@ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(evenness_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_len], "class=\"ring\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_len], "class=\"dot\"") != null);

    const evenness_field_len = lmt_svg_evenness_field(c_major, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(evenness_field_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_field_len], "class=\"dot-highlight\"") != null);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..evenness_field_len], "focus ") != null);

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    const len2 = lmt_svg_fret(@ptrCast(&frets), @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len2 > 0);
    try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..len2], "marker-open") != null);

    const four_string = [_]i8{ 0, 0, 0, 3 };
    const len2n = lmt_svg_fret_n(@ptrCast(&four_string), four_string.len, 0, 4, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(len2n > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..len2n], "cx=\"80.00\" cy=\"57.50\"") != null);

    const chord_staff_cases = [_]struct {
        chord_kind: u8,
        root: u8,
    }{
        .{ .chord_kind = c.LMT_CHORD_MAJOR, .root = 0 },
        .{ .chord_kind = c.LMT_CHORD_MINOR, .root = 9 },
        .{ .chord_kind = c.LMT_CHORD_DIMINISHED, .root = 11 },
        .{ .chord_kind = c.LMT_CHORD_AUGMENTED, .root = 8 },
    };
    for (chord_staff_cases) |case| {
        const len3 = lmt_svg_chord_staff(case.chord_kind, case.root, @ptrCast(&svg_buf), @intCast(svg_buf.len));
        try testing.expect(len3 > 0);
        try testing.expect(std.mem.startsWith(u8, svg_buf[0..4], "<svg"));
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "shape-rendering=\"geometricPrecision\"") != null);
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "class=\"clef clef-treble\"") != null);
        try testing.expect(std.mem.count(u8, svg_buf[0..len3], "class=\"notehead chord-notehead\"") >= 3);
        try testing.expect(std.mem.indexOf(u8, svg_buf[0..len3], "class=\"stem cluster-stem\"") != null);
    }

    const key_staff_len = lmt_svg_key_staff(0, c.LMT_KEY_MAJOR, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(key_staff_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..key_staff_len], "width=\"520\"") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..key_staff_len], "class=\"staff-barline\"") >= 2);
    try testing.expect(std.mem.count(u8, svg_buf[0..key_staff_len], "class=\"notehead key-notehead\"") >= 8);

    const keyboard_notes = [_]u8{ 60, 64, 67 };
    const keyboard_len = lmt_svg_keyboard(@ptrCast(&keyboard_notes), keyboard_notes.len, 48, 72, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(keyboard_len > 0);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key white-key is-selected\"") >= 3);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key white-key is-echo\"") >= 2);
    try testing.expect(std.mem.count(u8, svg_buf[0..keyboard_len], "class=\"keyboard-key black-key\"") >= 10);

    const piano_notes = [_]u8{ 43, 52, 60, 64 };
    const piano_staff_len = lmt_svg_piano_staff(@ptrCast(&piano_notes), piano_notes.len, 0, c.LMT_KEY_MAJOR, @ptrCast(&svg_buf), @intCast(svg_buf.len));
    try testing.expect(piano_staff_len > 0);
    try testing.expect(std.mem.indexOf(u8, svg_buf[0..piano_staff_len], "class=\"staff-system staff-mode-grand\"") != null);
    try testing.expect(std.mem.count(u8, svg_buf[0..piano_staff_len], "class=\"clef ") >= 2);
}

test "c abi raster generators" {
    const enabled = lmt_raster_is_enabled();
    try testing.expect(enabled == 0 or enabled == 1);
    if (enabled == 0) return error.SkipZigTest;

    var rgba: [64 * 64 * 4]u8 = [_]u8{0} ** (64 * 64 * 4);
    const written = lmt_raster_demo_rgba(64, 64, @ptrCast(&rgba), @intCast(rgba.len));
    try testing.expectEqual(@as(u32, rgba.len), written);

    const clock_set = lmt_chord(c.LMT_CHORD_MAJOR, 0);
    var clock_rgba: [240 * 240 * 4]u8 = [_]u8{0} ** (240 * 240 * 4);
    try testing.expectEqual(@as(u32, clock_rgba.len), lmt_bitmap_clock_optc_rgba(clock_set, 240, 240, @ptrCast(&clock_rgba), @intCast(clock_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &clock_rgba, &[_]u8{255}) != null);

    var optic_k_rgba: [320 * 160 * 4]u8 = [_]u8{0} ** (320 * 160 * 4);
    try testing.expectEqual(@as(u32, optic_k_rgba.len), lmt_bitmap_optic_k_group_rgba(clock_set, 320, 160, @ptrCast(&optic_k_rgba), @intCast(optic_k_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &optic_k_rgba, &[_]u8{255}) != null);

    var evenness_rgba: [240 * 312 * 4]u8 = [_]u8{0} ** (240 * 312 * 4);
    try testing.expectEqual(@as(u32, evenness_rgba.len), lmt_bitmap_evenness_chart_rgba(240, 312, @ptrCast(&evenness_rgba), @intCast(evenness_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &evenness_rgba, &[_]u8{255}) != null);

    var evenness_field_rgba: [240 * 312 * 4]u8 = [_]u8{0} ** (240 * 312 * 4);
    try testing.expectEqual(@as(u32, evenness_field_rgba.len), lmt_bitmap_evenness_field_rgba(clock_set, 240, 312, @ptrCast(&evenness_field_rgba), @intCast(evenness_field_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &evenness_field_rgba, &[_]u8{255}) != null);

    const frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    var fret_rgba: [320 * 320 * 4]u8 = [_]u8{0} ** (320 * 320 * 4);
    try testing.expectEqual(@as(u32, fret_rgba.len), lmt_bitmap_fret_rgba(@ptrCast(&frets), 320, 320, @ptrCast(&fret_rgba), @intCast(fret_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &fret_rgba, &[_]u8{255}) != null);

    const four_string = [_]i8{ 0, 0, 0, 3 };
    var fret_n_rgba: [320 * 320 * 4]u8 = [_]u8{0} ** (320 * 320 * 4);
    try testing.expectEqual(@as(u32, fret_n_rgba.len), lmt_bitmap_fret_n_rgba(@ptrCast(&four_string), four_string.len, 0, 4, 320, 320, @ptrCast(&fret_n_rgba), @intCast(fret_n_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &fret_n_rgba, &[_]u8{255}) != null);

    var staff_rgba: [640 * 240 * 4]u8 = [_]u8{0} ** (640 * 240 * 4);
    try testing.expectEqual(@as(u32, staff_rgba.len), lmt_bitmap_chord_staff_rgba(c.LMT_CHORD_MAJOR, 0, 640, 240, @ptrCast(&staff_rgba), @intCast(staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &staff_rgba, &[_]u8{255}) != null);

    var key_staff_rgba: [960 * 240 * 4]u8 = [_]u8{0} ** (960 * 240 * 4);
    try testing.expectEqual(@as(u32, key_staff_rgba.len), lmt_bitmap_key_staff_rgba(0, c.LMT_KEY_MAJOR, 960, 240, @ptrCast(&key_staff_rgba), @intCast(key_staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &key_staff_rgba, &[_]u8{255}) != null);

    const keyboard_notes = [_]u8{ 60, 64, 67 };
    var keyboard_rgba: [840 * 220 * 4]u8 = [_]u8{0} ** (840 * 220 * 4);
    try testing.expectEqual(@as(u32, keyboard_rgba.len), lmt_bitmap_keyboard_rgba(@ptrCast(&keyboard_notes), keyboard_notes.len, 48, 72, 840, 220, @ptrCast(&keyboard_rgba), @intCast(keyboard_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &keyboard_rgba, &[_]u8{255}) != null);

    const piano_notes = [_]u8{ 43, 52, 60, 64 };
    var piano_staff_rgba: [840 * 869 * 4]u8 = [_]u8{0} ** (840 * 869 * 4);
    try testing.expectEqual(@as(u32, piano_staff_rgba.len), lmt_bitmap_piano_staff_rgba(@ptrCast(&piano_notes), piano_notes.len, 0, c.LMT_KEY_MAJOR, 840, 869, @ptrCast(&piano_staff_rgba), @intCast(piano_staff_rgba.len)));
    try testing.expect(std.mem.indexOfNone(u8, &piano_staff_rgba, &[_]u8{255}) != null);
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
