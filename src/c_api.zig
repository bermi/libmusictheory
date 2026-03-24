const std = @import("std");
const build_options = @import("build_options");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const set_class = @import("set_class.zig");
const cluster = @import("cluster.zig");
const evenness = @import("evenness.zig");
const scale = @import("scale.zig");
const mode = @import("mode.zig");
const key = @import("key.zig");
const note_spelling = @import("note_spelling.zig");
const chord_type = @import("chord_type.zig");
const chord = @import("chord_construction.zig");
const harmony = @import("harmony.zig");
const guitar = @import("guitar.zig");
const svg_clock = @import("svg/clock.zig");
const svg_evenness_chart = @import("svg/evenness_chart.zig");
const svg_fret = @import("svg/fret.zig");
const svg_keyboard = @import("svg/keyboard_svg.zig");
const svg_staff = @import("svg/staff.zig");
const svg_compat = @import("harmonious_svg_compat.zig");
const raster = @import("render/raster.zig");
const bitmap_compat = @import("bitmap_compat.zig");

pub const LmtKeyContext = extern struct {
    tonic: u8,
    quality: u8,
};

pub const LmtFretPos = extern struct {
    string: u8,
    fret: u8,
};

pub const LmtGuideDot = extern struct {
    position: LmtFretPos,
    pitch_class: u8,
    opacity: f32,
};

const SCALE_DIATONIC: u8 = 0;
const SCALE_ACOUSTIC: u8 = 1;
const SCALE_DIMINISHED: u8 = 2;
const SCALE_WHOLE_TONE: u8 = 3;
const SCALE_HARMONIC_MINOR: u8 = 4;
const SCALE_HARMONIC_MAJOR: u8 = 5;
const SCALE_DOUBLE_AUGMENTED_HEXATONIC: u8 = 6;

const MODE_IONIAN: u8 = 0;
const MODE_DORIAN: u8 = 1;
const MODE_PHRYGIAN: u8 = 2;
const MODE_LYDIAN: u8 = 3;
const MODE_MIXOLYDIAN: u8 = 4;
const MODE_AEOLIAN: u8 = 5;
const MODE_LOCRIAN: u8 = 6;
const MODE_MELODIC_MINOR: u8 = 7;
const MODE_DORIAN_B2: u8 = 8;
const MODE_LYDIAN_AUG: u8 = 9;
const MODE_LYDIAN_DOM: u8 = 10;
const MODE_MIXOLYDIAN_B6: u8 = 11;
const MODE_LOCRIAN_NAT2: u8 = 12;
const MODE_SUPER_LOCRIAN: u8 = 13;
const MODE_HALF_WHOLE: u8 = 14;
const MODE_WHOLE_HALF: u8 = 15;
const MODE_WHOLE_TONE: u8 = 16;

const CHORD_MAJOR: u8 = 0;
const CHORD_MINOR: u8 = 1;
const CHORD_DIMINISHED: u8 = 2;
const CHORD_AUGMENTED: u8 = 3;

const KEY_MAJOR: u8 = 0;
const KEY_MINOR: u8 = 1;

const MAJOR_TRIAD = pcs.C_MAJOR_TRIAD;
const MINOR_TRIAD = pcs.C_MINOR_TRIAD;
const DIMINISHED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6 });
const AUGMENTED_TRIAD = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 8 });
const MAJOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 11 });
const DOMINANT_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7, 10 });
const MINOR_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 7, 10 });
const HALF_DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 10 });
const DIMINISHED_SEVENTH = pcs.fromList(&[_]pitch.PitchClass{ 0, 3, 6, 9 });

var c_string_slots: [8][32]u8 = [_][32]u8{[_]u8{0} ** 32} ** 8;
var c_string_slot_index: usize = 0;
var compat_svg_buf: [4 * 1024 * 1024]u8 = undefined;
var wasm_client_scratch: [8 * 1024 * 1024]u8 = undefined;
const MAX_PARAMETRIC_FRET_STRINGS: usize = 64;
const MAX_KEYBOARD_RENDER_NOTES: usize = 128;
const MAX_C_API_GENERIC_VOICINGS: usize = MAX_PARAMETRIC_FRET_STRINGS * MAX_PARAMETRIC_FRET_STRINGS;
var generic_voicing_meta_buf: [MAX_C_API_GENERIC_VOICINGS]guitar.GenericVoicing = undefined;
var generic_voicing_fret_buf: [MAX_C_API_GENERIC_VOICINGS * MAX_PARAMETRIC_FRET_STRINGS]i8 = undefined;

fn maskPitchClassSet(raw: u16) pcs.PitchClassSet {
    return @as(pcs.PitchClassSet, @intCast(raw & 0x0fff));
}

fn toCSet(set: pcs.PitchClassSet) u16 {
    return @as(u16, set);
}

fn decodeKeyContext(ctx: LmtKeyContext) key.Key {
    const tonic = @as(pitch.PitchClass, @intCast(ctx.tonic % 12));
    const quality: key.KeyQuality = if (ctx.quality == KEY_MINOR) .minor else .major;
    return key.Key.init(tonic, quality);
}

fn buildKeyStaffNotes(tonic: pitch.PitchClass, quality: key.KeyQuality, out: *[8]pitch.MidiNote) []const pitch.MidiNote {
    const base_root: u8 = @as(u8, tonic);
    const root_midi: u8 = if (base_root <= 5) 60 + base_root else 48 + base_root;
    const intervals = switch (quality) {
        .major => [_]u8{ 0, 2, 4, 5, 7, 9, 11, 12 },
        .minor => [_]u8{ 0, 2, 3, 5, 7, 8, 10, 12 },
    };

    for (intervals, 0..) |interval, index| {
        out[index] = @as(pitch.MidiNote, @intCast(root_midi + interval));
    }
    return out[0..intervals.len];
}

fn decodeScaleType(scale_type: u8) ?scale.ScaleType {
    return switch (scale_type) {
        SCALE_DIATONIC => .diatonic,
        SCALE_ACOUSTIC => .acoustic,
        SCALE_DIMINISHED => .diminished,
        SCALE_WHOLE_TONE => .whole_tone,
        SCALE_HARMONIC_MINOR => .harmonic_minor,
        SCALE_HARMONIC_MAJOR => .harmonic_major,
        SCALE_DOUBLE_AUGMENTED_HEXATONIC => .double_augmented_hexatonic,
        else => null,
    };
}

fn decodeModeType(mode_type: u8) ?mode.ModeType {
    return switch (mode_type) {
        MODE_IONIAN => .ionian,
        MODE_DORIAN => .dorian,
        MODE_PHRYGIAN => .phrygian,
        MODE_LYDIAN => .lydian,
        MODE_MIXOLYDIAN => .mixolydian,
        MODE_AEOLIAN => .aeolian,
        MODE_LOCRIAN => .locrian,
        MODE_MELODIC_MINOR => .melodic_minor,
        MODE_DORIAN_B2 => .dorian_b2,
        MODE_LYDIAN_AUG => .lydian_aug,
        MODE_LYDIAN_DOM => .lydian_dom,
        MODE_MIXOLYDIAN_B6 => .mixolydian_b6,
        MODE_LOCRIAN_NAT2 => .locrian_nat2,
        MODE_SUPER_LOCRIAN => .super_locrian,
        MODE_HALF_WHOLE => .half_whole,
        MODE_WHOLE_HALF => .whole_half,
        MODE_WHOLE_TONE => .whole_tone,
        else => null,
    };
}

fn modeSet(mode_type: mode.ModeType) pcs.PitchClassSet {
    for (mode.ALL_MODES) |one| {
        if (one.id == mode_type) return one.pcs;
    }
    return mode.ALL_MODES[0].pcs;
}

fn chordTemplate(chord_kind: u8) pcs.PitchClassSet {
    return switch (chord_kind) {
        CHORD_MINOR => chord_type.MINOR.pcs,
        CHORD_DIMINISHED => chord_type.DIMINISHED.pcs,
        CHORD_AUGMENTED => chord_type.AUGMENTED.pcs,
        else => chord_type.MAJOR.pcs,
    };
}

fn firstPitchClass(set: pcs.PitchClassSet) pitch.PitchClass {
    var pc: u4 = 0;
    while (pc < 12) : (pc += 1) {
        if ((set & (@as(pcs.PitchClassSet, 1) << pc)) != 0) {
            return @as(pitch.PitchClass, @intCast(pc));
        }
    }
    return 0;
}

fn classifyChordQuality(root_pc: pitch.PitchClass, chord_set: pcs.PitchClassSet) harmony.ChordQuality {
    const normalized = pcs.transposeDown(chord_set, root_pc);

    if (normalized == MAJOR_TRIAD) return .major;
    if (normalized == MINOR_TRIAD) return .minor;
    if (normalized == DIMINISHED_TRIAD) return .diminished;
    if (normalized == AUGMENTED_TRIAD) return .augmented;

    if (normalized == MAJOR_SEVENTH) return .major;
    if (normalized == DOMINANT_SEVENTH) return .dominant;
    if (normalized == MINOR_SEVENTH) return .minor;
    if (normalized == HALF_DIMINISHED_SEVENTH) return .half_diminished;
    if (normalized == DIMINISHED_SEVENTH) return .diminished_seventh;

    return .unknown;
}

fn decodeTuning(ptr: [*c]const u8) guitar.Tuning {
    if (ptr == null) return guitar.tunings.STANDARD;

    var out: guitar.Tuning = undefined;
    var i: usize = 0;
    while (i < guitar.NUM_STRINGS) : (i += 1) {
        const raw = ptr[i];
        out[i] = @as(pitch.MidiNote, @intCast(@min(raw, @as(u8, 127))));
    }
    return out;
}

fn decodeTuningGeneric(ptr: [*c]const u8, tuning_count: u32, out: *[MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote) []const pitch.MidiNote {
    const len = @min(@as(usize, @intCast(tuning_count)), out.len);
    if (ptr == null or len == 0) return out[0..0];

    var i: usize = 0;
    while (i < len) : (i += 1) {
        const raw = ptr[i];
        out[i] = @as(pitch.MidiNote, @intCast(@min(raw, @as(u8, 127))));
    }
    return out[0..len];
}

fn decodeMidiNotes(ptr: [*c]const u8, note_count: u32, out: *[MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote) []const pitch.MidiNote {
    const len = @min(@as(usize, @intCast(note_count)), out.len);
    if (ptr == null or len == 0) return out[0..0];

    var i: usize = 0;
    while (i < len) : (i += 1) {
        out[i] = @as(pitch.MidiNote, @intCast(@min(ptr[i], @as(u8, 127))));
    }
    return out[0..len];
}

const KeyboardRange = struct {
    low: pitch.MidiNote,
    high: pitch.MidiNote,
};

fn sanitizeKeyboardRange(low_raw: u8, high_raw: u8) KeyboardRange {
    const clamped_low = @as(pitch.MidiNote, @intCast(@min(low_raw, @as(u8, 127))));
    const clamped_high = @as(pitch.MidiNote, @intCast(@min(high_raw, @as(u8, 127))));
    return if (clamped_low <= clamped_high)
        .{ .low = clamped_low, .high = clamped_high }
    else
        .{ .low = clamped_high, .high = clamped_low };
}

fn isSelectedGuidePosition(selected_ptr: [*c]const LmtFretPos, selected_count: usize, string: usize, fret: u8) bool {
    if (selected_ptr == null) return false;

    var i: usize = 0;
    while (i < selected_count) : (i += 1) {
        const pos = selected_ptr[i];
        if (pos.string == @as(u8, @intCast(@min(string, @as(usize, 255)))) and pos.fret == fret) {
            return true;
        }
    }

    return false;
}

fn selectedGuidePitchClasses(selected_ptr: [*c]const LmtFretPos, selected_count: usize, tuning: []const pitch.MidiNote) pcs.PitchClassSet {
    if (selected_ptr == null or selected_count == 0 or tuning.len == 0) return 0;

    var out: pcs.PitchClassSet = 0;
    var i: usize = 0;
    while (i < selected_count) : (i += 1) {
        const pos = selected_ptr[i];
        const midi = guitar.fretToMidiGeneric(pos.string, pos.fret, tuning) orelse continue;
        const pc = @as(pitch.PitchClass, @intCast(midi % 12));
        out |= @as(pcs.PitchClassSet, 1) << pc;
    }

    return out;
}

fn parseUrlFretToken(raw_token: []const u8) ?i8 {
    const token = std.mem.trim(u8, raw_token, " \t\r\n");
    if (token.len == 0) return null;

    const parsed = std.fmt.parseInt(i16, token, 10) catch return null;
    if (parsed < -1 or parsed > std.math.maxInt(i8)) return null;
    return @as(i8, @intCast(parsed));
}

fn writeCString(text: []const u8) [*c]const u8 {
    const slot = &c_string_slots[c_string_slot_index % c_string_slots.len];
    c_string_slot_index += 1;

    const n = @min(text.len, slot.len - 1);
    std.mem.copyForwards(u8, slot[0..n], text[0..n]);
    slot[n] = 0;

    return &slot[0];
}

fn copySvgOut(svg: []const u8, buf: [*c]u8, buf_size: u32) u32 {
    const total = @as(u32, @intCast(svg.len));
    if (buf == null or buf_size == 0) return total;

    const cap = @as(usize, @intCast(buf_size));
    const copy_len = @min(svg.len, cap - 1);
    if (copy_len > 0) {
        std.mem.copyForwards(u8, buf[0..copy_len], svg[0..copy_len]);
    }
    buf[copy_len] = 0;

    return total;
}

fn requiredRgbaBytes(width: u32, height: u32) ?u32 {
    const required: u64 = @as(u64, width) * @as(u64, height) * 4;
    if (width == 0 or height == 0 or required == 0 or required > std.math.maxInt(u32)) return null;
    return @as(u32, @intCast(required));
}

fn renderPublicSvgBitmap(svg: []const u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;

    const required = requiredRgbaBytes(width, height) orelse return 0;
    if (required > out_rgba_size) return 0;

    const out = out_rgba[0..@as(usize, required)];
    const written = bitmap_compat.renderSvgMarkupRgba(width, height, svg, out) catch return 0;
    return @as(u32, @intCast(written));
}

export fn lmt_wasm_scratch_ptr() callconv(.C) [*c]u8 {
    return &wasm_client_scratch[0];
}

export fn lmt_wasm_scratch_size() callconv(.C) u32 {
    return @as(u32, @intCast(wasm_client_scratch.len));
}

export fn lmt_pcs_from_list(pcs_ptr: [*c]const u8, count: u8) callconv(.C) u16 {
    if (pcs_ptr == null or count == 0) return 0;

    var list_buf: [12]pitch.PitchClass = undefined;
    const len = @min(@as(usize, count), list_buf.len);

    var i: usize = 0;
    while (i < len) : (i += 1) {
        list_buf[i] = @as(pitch.PitchClass, @intCast(pcs_ptr[i] % 12));
    }

    return toCSet(pcs.fromList(list_buf[0..len]));
}

export fn lmt_pcs_to_list(set: u16, out: [*c]u8) callconv(.C) u8 {
    var tmp: [12]pitch.PitchClass = undefined;
    const list = pcs.toList(maskPitchClassSet(set), &tmp);

    if (out != null) {
        for (list, 0..) |pc, i| {
            out[i] = @as(u8, pc);
        }
    }

    return @as(u8, @intCast(list.len));
}

export fn lmt_pcs_cardinality(set: u16) callconv(.C) u8 {
    return @as(u8, pcs.cardinality(maskPitchClassSet(set)));
}

export fn lmt_pcs_transpose(set: u16, semitones: u8) callconv(.C) u16 {
    const value = pcs.transpose(maskPitchClassSet(set), @as(u4, @intCast(semitones % 12)));
    return toCSet(value);
}

export fn lmt_pcs_invert(set: u16) callconv(.C) u16 {
    return toCSet(pcs.invert(maskPitchClassSet(set)));
}

export fn lmt_pcs_complement(set: u16) callconv(.C) u16 {
    return toCSet(pcs.complement(maskPitchClassSet(set)));
}

export fn lmt_pcs_is_subset(small: u16, big: u16) callconv(.C) bool {
    return pcs.isSubsetOf(maskPitchClassSet(small), maskPitchClassSet(big));
}

export fn lmt_prime_form(set: u16) callconv(.C) u16 {
    return toCSet(set_class.primeForm(maskPitchClassSet(set)));
}

export fn lmt_forte_prime(set: u16) callconv(.C) u16 {
    return toCSet(set_class.fortePrime(maskPitchClassSet(set)));
}

export fn lmt_is_cluster_free(set: u16) callconv(.C) bool {
    return !cluster.hasCluster(maskPitchClassSet(set));
}

export fn lmt_evenness_distance(set: u16) callconv(.C) f32 {
    return evenness.evennessDistance(maskPitchClassSet(set));
}

export fn lmt_scale(scale_type: u8, tonic: u8) callconv(.C) u16 {
    const st = decodeScaleType(scale_type) orelse return 0;
    const root = @as(pitch.PitchClass, @intCast(tonic % 12));
    return toCSet(pcs.transpose(scale.pcsForType(st), root));
}

export fn lmt_mode(mode_type: u8, root: u8) callconv(.C) u16 {
    const mt = decodeModeType(mode_type) orelse return 0;
    const base = modeSet(mt);
    const tonic = @as(pitch.PitchClass, @intCast(root % 12));
    return toCSet(pcs.transpose(base, tonic));
}

export fn lmt_spell_note(pc: u8, key_ctx: LmtKeyContext) callconv(.C) [*c]const u8 {
    var note_buf: [4]u8 = undefined;
    const k = decodeKeyContext(key_ctx);
    const note = note_spelling.spellNote(@as(pitch.PitchClass, @intCast(pc % 12)), k);
    const text = note.format(&note_buf);
    return writeCString(text);
}

// WASM-friendly helper to avoid JS struct-by-value ABI marshalling.
export fn lmt_spell_note_parts(pc: u8, tonic: u8, quality: u8) callconv(.C) [*c]const u8 {
    return lmt_spell_note(pc, .{ .tonic = tonic, .quality = quality });
}

export fn lmt_chord(chord_kind: u8, root: u8) callconv(.C) u16 {
    const root_pc = @as(pitch.PitchClass, @intCast(root % 12));
    return toCSet(pcs.transpose(chordTemplate(chord_kind), root_pc));
}

export fn lmt_chord_name(set: u16) callconv(.C) [*c]const u8 {
    const name = chord.pcsToChordName(maskPitchClassSet(set)) orelse "Unknown";
    return writeCString(name);
}

export fn lmt_roman_numeral(chord_set: u16, key_ctx: LmtKeyContext) callconv(.C) [*c]const u8 {
    var buf: [16]u8 = undefined;

    const set = maskPitchClassSet(chord_set);
    const root_pc = firstPitchClass(set);
    const chord_instance = harmony.ChordInstance{
        .root = root_pc,
        .pcs = set,
        .quality = classifyChordQuality(root_pc, set),
        .degree = 0,
    };

    const numeral = harmony.romanNumeral(chord_instance, decodeKeyContext(key_ctx));
    const text = numeral.format(&buf);
    return writeCString(text);
}

// WASM-friendly helper to avoid JS struct-by-value ABI marshalling.
export fn lmt_roman_numeral_parts(chord_set: u16, tonic: u8, quality: u8) callconv(.C) [*c]const u8 {
    return lmt_roman_numeral(chord_set, .{ .tonic = tonic, .quality = quality });
}

export fn lmt_fret_to_midi(string: u8, fret: u8, tuning_ptr: [*c]const u8) callconv(.C) u8 {
    if (string >= guitar.NUM_STRINGS) return 0;

    const tuning = decodeTuning(tuning_ptr);
    const clamped_fret: u5 = @intCast(@min(fret, @as(u8, guitar.MAX_FRET)));
    const midi = guitar.fretToMidi(@as(u3, @intCast(string)), clamped_fret, tuning);
    return @as(u8, midi);
}

export fn lmt_fret_to_midi_n(string: u32, fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32) callconv(.C) u8 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    const midi = guitar.fretToMidiGeneric(@as(usize, @intCast(string)), fret, tuning) orelse return 0;
    return @as(u8, midi);
}

export fn lmt_midi_to_fret_positions(note: u8, tuning_ptr: [*c]const u8, out: [*c]LmtFretPos) callconv(.C) u8 {
    var tmp: [guitar.NUM_STRINGS]guitar.FretPosition = undefined;
    const tuning = decodeTuning(tuning_ptr);

    const midi = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const positions = guitar.midiToFretPositions(midi, tuning, &tmp);

    if (out != null) {
        for (positions, 0..) |pos, i| {
            out[i] = .{
                .string = @as(u8, pos.string),
                .fret = @as(u8, pos.fret),
            };
        }
    }

    return @as(u8, @intCast(positions.len));
}

export fn lmt_midi_to_fret_positions_n(note: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtFretPos, out_cap: u32) callconv(.C) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    var tmp: [MAX_PARAMETRIC_FRET_STRINGS]guitar.GenericFretPosition = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);

    const midi = @as(pitch.MidiNote, @intCast(@min(note, @as(u8, 127))));
    const positions = guitar.midiToFretPositionsGeneric(midi, tuning, tmp[0..tuning.len]);

    if (out != null) {
        const write_len = @min(positions.len, @as(usize, @intCast(out_cap)));
        for (positions[0..write_len], 0..) |pos, i| {
            out[i] = .{
                .string = @as(u8, @intCast(@min(pos.string, @as(usize, 255)))),
                .fret = pos.fret,
            };
        }
    }

    return @as(u32, @intCast(positions.len));
}

export fn lmt_generate_voicings_n(chord_set: u16, tuning_ptr: [*c]const u8, tuning_count: u32, max_fret: u8, max_span: u8, out_frets: [*c]i8, out_voicing_cap: u32) callconv(.C) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or out_frets == null or out_voicing_cap == 0) return 0;

    const row_cap = @as(usize, @intCast(out_voicing_cap));
    if (row_cap > MAX_C_API_GENERIC_VOICINGS) return 0;

    const generated = guitar.generateVoicingsGeneric(
        maskPitchClassSet(chord_set),
        tuning,
        max_fret,
        max_span,
        generic_voicing_meta_buf[0..row_cap],
        generic_voicing_fret_buf[0 .. row_cap * tuning.len],
    );

    for (generated, 0..) |voicing, row| {
        const row_start = row * tuning.len;
        @memcpy(out_frets[row_start .. row_start + tuning.len], voicing.frets);
    }

    return @as(u32, @intCast(generated.len));
}

export fn lmt_pitch_class_guide_n(selected_ptr: [*c]const LmtFretPos, selected_count: u32, min_fret: u8, max_fret: u8, tuning_ptr: [*c]const u8, tuning_count: u32, out: [*c]LmtGuideDot, out_cap: u32) callconv(.C) u32 {
    var tuning_buf: [MAX_PARAMETRIC_FRET_STRINGS]pitch.MidiNote = undefined;
    const tuning = decodeTuningGeneric(tuning_ptr, tuning_count, &tuning_buf);
    if (tuning.len == 0 or max_fret < min_fret) return 0;

    const selected_len = @as(usize, @intCast(selected_count));
    const selected_pcs = selectedGuidePitchClasses(selected_ptr, selected_len, tuning);
    if (selected_pcs == 0) return 0;

    const write_cap = @as(usize, @intCast(out_cap));
    var total: usize = 0;

    for (tuning, 0..) |_, string| {
        var fret = min_fret;
        while (true) : (fret += 1) {
            if (isSelectedGuidePosition(selected_ptr, selected_len, string, fret)) {
                if (fret == max_fret or fret == std.math.maxInt(u8)) break;
                continue;
            }

            const midi = guitar.fretToMidiGeneric(string, fret, tuning) orelse {
                if (fret == max_fret or fret == std.math.maxInt(u8)) break;
                continue;
            };
            const pc = @as(pitch.PitchClass, @intCast(midi % 12));
            const bit = @as(pcs.PitchClassSet, 1) << pc;
            if ((selected_pcs & bit) != 0) {
                if (out != null and total < write_cap) {
                    out[total] = .{
                        .position = .{
                            .string = @as(u8, @intCast(@min(string, @as(usize, 255)))),
                            .fret = fret,
                        },
                        .pitch_class = pc,
                        .opacity = guitar.GUIDE_OPACITY,
                    };
                }
                total += 1;
            }

            if (fret == max_fret or fret == std.math.maxInt(u8)) break;
        }
    }

    return @as(u32, @intCast(total));
}

export fn lmt_frets_to_url_n(frets_ptr: [*c]const i8, fret_count: u32, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    if (buf == null or buf_size == 0) return 0;

    const out = buf[0..@as(usize, @intCast(buf_size))];
    var stream = std.io.fixedBufferStream(out);
    const writer = stream.writer();
    const count = @as(usize, @intCast(fret_count));

    if (count > 0 and frets_ptr == null) return 0;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (i > 0) writer.writeByte(',') catch return 0;

        const fret = frets_ptr[i];
        if (fret < -1) return 0;
        if (fret == -1) {
            writer.writeAll("-1") catch return 0;
        } else {
            writer.print("{d}", .{fret}) catch return 0;
        }
    }

    if (stream.pos >= out.len) return 0;
    out[stream.pos] = 0;
    return @as(u32, @intCast(stream.pos));
}

export fn lmt_url_to_frets_n(url_ptr: [*c]const u8, out: [*c]i8, out_cap: u32) callconv(.C) u32 {
    if (url_ptr == null) return 0;

    const url = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(url_ptr)), 0);
    const write_cap = @as(usize, @intCast(out_cap));
    var count: usize = 0;

    var it = std.mem.splitScalar(u8, url, ',');
    while (it.next()) |raw_token| {
        const fret = parseUrlFretToken(raw_token) orelse return 0;
        if (out != null and count < write_cap) {
            out[count] = fret;
        }
        count += 1;
    }

    return @as(u32, @intCast(count));
}

export fn lmt_svg_clock_optc(set: u16, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var svg_buf: [16384]u8 = undefined;
    var label_buf: [12]u8 = undefined;

    const safe_set = maskPitchClassSet(set);
    const label = pcs.format(safe_set, &label_buf);
    const svg = svg_clock.renderOPTC(safe_set, label, &svg_buf);

    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_optic_k_group(set: u16, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var svg_buf: [24576]u8 = undefined;
    const safe_set = maskPitchClassSet(set);
    const svg = svg_clock.renderOpticKGroup(safe_set, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_evenness_chart(buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var svg_buf: [65536]u8 = undefined;
    const svg = svg_evenness_chart.renderEvennessChart(&svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_fret(frets_ptr: [*c]const i8, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var frets: [guitar.NUM_STRINGS]i8 = [_]i8{-1} ** guitar.NUM_STRINGS;
    if (frets_ptr != null) {
        var i: usize = 0;
        while (i < guitar.NUM_STRINGS) : (i += 1) {
            const raw = frets_ptr[i];
            frets[i] = if (raw < -1) -1 else if (raw > guitar.MAX_FRET) @as(i8, @intCast(guitar.MAX_FRET)) else raw;
        }
    }

    const voicing = guitar.GuitarVoicing{
        .frets = frets,
        .tuning = guitar.tunings.STANDARD,
    };

    var svg_buf: [4096]u8 = undefined;
    const svg = svg_fret.renderFretDiagram(voicing, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_fret_n(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    if (frets_ptr == null or string_count == 0) {
        var empty_svg_buf: [256]u8 = undefined;
        const svg = svg_fret.renderDiagram(.{ .frets = &[_]i8{} }, &empty_svg_buf);
        return copySvgOut(svg, buf, buf_size);
    }

    const count = @as(usize, @intCast(string_count));
    const raw_frets = frets_ptr[0..count];

    var svg_buf: [8192]u8 = undefined;
    const svg = svg_fret.renderDiagram(.{
        .frets = raw_frets,
        .window_start = if (window_start == 0 and visible_frets == 0) null else window_start,
        .visible_frets = visible_frets,
    }, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_chord_staff(chord_kind: u8, root: u8, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    const root_pc = @as(pitch.PitchClass, @intCast(root % 12));
    const root_midi: pitch.MidiNote = @as(pitch.MidiNote, @intCast(60 + @as(u8, root_pc)));

    var notes: [4]pitch.MidiNote = undefined;
    const count: usize = switch (chord_kind) {
        CHORD_MINOR => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 3));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 7));
            break :blk 3;
        },
        CHORD_DIMINISHED => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 3));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 6));
            break :blk 3;
        },
        CHORD_AUGMENTED => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 4));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 8));
            break :blk 3;
        },
        else => blk: {
            notes[0] = root_midi;
            notes[1] = @as(pitch.MidiNote, @intCast(root_midi + 4));
            notes[2] = @as(pitch.MidiNote, @intCast(root_midi + 7));
            break :blk 3;
        },
    };

    const k = key.Key.init(root_pc, .major);

    var svg_buf: [16384]u8 = undefined;
    const svg = svg_staff.renderChordStaff(notes[0..count], k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_key_staff(tonic: u8, quality_raw: u8, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    const tonic_pc = @as(pitch.PitchClass, @intCast(tonic % 12));
    const quality: key.KeyQuality = if (quality_raw == KEY_MINOR) .minor else .major;
    const k = key.Key.init(tonic_pc, quality);

    var notes: [8]pitch.MidiNote = undefined;
    const key_notes = buildKeyStaffNotes(tonic_pc, quality, &notes);

    var svg_buf: [24576]u8 = undefined;
    const svg = svg_staff.renderKeyStaff(key_notes, k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_svg_keyboard(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var notes_buf: [MAX_KEYBOARD_RENDER_NOTES]pitch.MidiNote = undefined;
    const notes = decodeMidiNotes(notes_ptr, note_count, &notes_buf);
    const range = sanitizeKeyboardRange(range_low, range_high);

    var svg_buf: [128 * 1024]u8 = undefined;
    const svg = svg_keyboard.renderKeyboard(notes, range.low, range.high, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
}

export fn lmt_raster_is_enabled() callconv(.C) u32 {
    return if (build_options.enable_raster_backend) 1 else 0;
}

export fn lmt_raster_demo_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null or width == 0 or height == 0) return 0;

    const required: u64 = @as(u64, width) * @as(u64, height) * 4;
    if (required == 0 or required > std.math.maxInt(u32)) return 0;
    if (required > @as(u64, out_rgba_size)) return 0;

    const expected_stride = width * 4;
    const out_slice = out_rgba[0..@as(usize, @intCast(required))];
    var surface = raster.Surface{
        .pixels = out_slice,
        .width = width,
        .height = height,
        .stride = expected_stride,
    };
    raster.renderDemoScene(&surface);
    return @as(u32, @intCast(required));
}

export fn lmt_bitmap_clock_optc_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_clock_optc(set, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_clock_optc(set, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_optic_k_group_rgba(set: u16, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend or out_rgba == null) return 0;
    const required = requiredRgbaBytes(width, height) orelse return 0;
    if (required > out_rgba_size) return 0;
    const out = out_rgba[0..@as(usize, required)];
    const written = bitmap_compat.renderPublicOpticKGroupRgba(width, height, maskPitchClassSet(set), out) catch return 0;
    return @as(u32, @intCast(written));
}

export fn lmt_bitmap_evenness_chart_rgba(width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_evenness_chart(null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_evenness_chart(@ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_fret_rgba(frets_ptr: [*c]const i8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_fret(frets_ptr, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_fret(frets_ptr, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_fret_n_rgba(frets_ptr: [*c]const i8, string_count: u32, window_start: u32, visible_frets: u32, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_fret_n(frets_ptr, string_count, window_start, visible_frets, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_fret_n(frets_ptr, string_count, window_start, visible_frets, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_chord_staff_rgba(chord_kind: u8, root: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_chord_staff(chord_kind, root, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_chord_staff(chord_kind, root, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_key_staff_rgba(tonic: u8, quality_raw: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_key_staff(tonic, quality_raw, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_key_staff(tonic, quality_raw, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_keyboard_rgba(notes_ptr: [*c]const u8, note_count: u32, range_low: u8, range_high: u8, width: u32, height: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    const total = lmt_svg_keyboard(notes_ptr, note_count, range_low, range_high, null, 0);
    if (total == 0 or total >= compat_svg_buf.len) return 0;
    const written_total = lmt_svg_keyboard(notes_ptr, note_count, range_low, range_high, @ptrCast(&compat_svg_buf), @intCast(compat_svg_buf.len));
    if (written_total != total) return 0;
    return renderPublicSvgBitmap(compat_svg_buf[0..@as(usize, total)], width, height, out_rgba, out_rgba_size);
}

export fn lmt_bitmap_proof_scale_numerator() callconv(.C) u32 {
    return bitmap_compat.SCALE_NUMERATOR;
}

export fn lmt_bitmap_proof_scale_denominator() callconv(.C) u32 {
    return bitmap_compat.SCALE_DENOMINATOR;
}

export fn lmt_bitmap_compat_kind_supported(kind_index: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return if (bitmap_compat.kindSupported(@as(usize, kind_index))) 1 else 0;
}

export fn lmt_bitmap_compat_candidate_backend_name(kind_index: u32) callconv(.C) [*:0]const u8 {
    if (!build_options.enable_raster_backend) return "".ptr;
    return (bitmap_compat.candidateBackendName(@as(usize, kind_index)) orelse "").ptr;
}

export fn lmt_bitmap_compat_target_width_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetWidthScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

export fn lmt_bitmap_compat_target_width(kind_index: u32, image_index: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetWidth(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_target_height_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetHeightScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

export fn lmt_bitmap_compat_target_height(kind_index: u32, image_index: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.targetHeight(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_required_rgba_bytes_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.requiredRgbaBytesScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator);
}

export fn lmt_bitmap_compat_required_rgba_bytes(kind_index: u32, image_index: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    return bitmap_compat.requiredRgbaBytes(@as(usize, kind_index), @as(usize, image_index));
}

export fn lmt_bitmap_compat_render_candidate_rgba_scaled(kind_index: u32, image_index: u32, scale_numerator: u32, scale_denominator: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderCandidateRgbaScaled(@as(usize, kind_index), @as(usize, image_index), scale_numerator, scale_denominator, out) catch return 0;
    return @as(u32, @intCast(len));
}

export fn lmt_bitmap_compat_render_candidate_rgba(kind_index: u32, image_index: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (out_rgba == null) return 0;
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderCandidateRgba(@as(usize, kind_index), @as(usize, image_index), out) catch return 0;
    return @as(u32, @intCast(len));
}

export fn lmt_bitmap_compat_render_reference_svg_rgba_scaled(kind_index: u32, scale_numerator: u32, scale_denominator: u32, svg_ptr: [*c]const u8, svg_len: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (svg_ptr == null or out_rgba == null or svg_len == 0) return 0;
    const svg = svg_ptr[0..@as(usize, svg_len)];
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderReferenceSvgRgbaScaled(@as(usize, kind_index), svg, scale_numerator, scale_denominator, out) catch return 0;
    return @as(u32, @intCast(len));
}

export fn lmt_bitmap_compat_render_reference_svg_rgba(kind_index: u32, svg_ptr: [*c]const u8, svg_len: u32, out_rgba: [*c]u8, out_rgba_size: u32) callconv(.C) u32 {
    if (!build_options.enable_raster_backend) return 0;
    if (svg_ptr == null or out_rgba == null or svg_len == 0) return 0;
    const svg = svg_ptr[0..@as(usize, svg_len)];
    const out = out_rgba[0..@as(usize, out_rgba_size)];
    const len = bitmap_compat.renderReferenceSvgRgba(@as(usize, kind_index), svg, out) catch return 0;
    return @as(u32, @intCast(len));
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
    return copySvgOut(name, buf, buf_size);
}

export fn lmt_svg_compat_generate(kind_index: u32, image_index: u32, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    const svg = svg_compat.generateByIndex(@as(usize, kind_index), @as(usize, image_index), &compat_svg_buf);
    if (svg.len == 0) return 0;
    return copySvgOut(svg, buf, buf_size);
}
