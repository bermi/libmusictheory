const std = @import("std");
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
const svg_fret = @import("svg/fret.zig");
const svg_staff = @import("svg/staff.zig");
const svg_compat = @import("harmonious_svg_compat.zig");

pub const LmtKeyContext = extern struct {
    tonic: u8,
    quality: u8,
};

pub const LmtFretPos = extern struct {
    string: u8,
    fret: u8,
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

export fn lmt_svg_clock_optc(set: u16, buf: [*c]u8, buf_size: u32) callconv(.C) u32 {
    var svg_buf: [8192]u8 = undefined;
    var label_buf: [12]u8 = undefined;

    const safe_set = maskPitchClassSet(set);
    const label = pcs.format(safe_set, &label_buf);
    const svg = svg_clock.renderOPTC(safe_set, label, &svg_buf);

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

    var svg_buf: [8192]u8 = undefined;
    const svg = svg_staff.renderChordStaff(notes[0..count], k, &svg_buf);
    return copySvgOut(svg, buf, buf_size);
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
