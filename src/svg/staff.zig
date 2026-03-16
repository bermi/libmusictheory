const std = @import("std");
const pitch = @import("../pitch.zig");
const key = @import("../key.zig");
const note_name = @import("../note_name.zig");
const note_spelling = @import("../note_spelling.zig");
const pcs = @import("../pitch_class_set.zig");
const harmony = @import("../harmony.zig");

pub const Clef = enum {
    treble,
    bass,
};

pub const StaffPosition = struct {
    y: f32,
    ledger_lines_above: u8,
    ledger_lines_below: u8,
};

pub const AccidentalGlyph = enum {
    none,
    natural,
    sharp,
    flat,
};

const SpelledStaffNote = struct {
    name: note_name.NoteName,
    octave: i8,
    position: StaffPosition,
    accidental: AccidentalGlyph,
};

pub fn clefForGrandStaff(note: pitch.MidiNote) Clef {
    return if (note >= 60) .treble else .bass;
}

pub fn midiToStaffPosition(note: pitch.MidiNote, clef: Clef) StaffPosition {
    const ref_midi: i16 = switch (clef) {
        .treble => 64, // E4 on bottom line
        .bass => 43, // G2 on bottom line
    };

    const semitones = @as(i16, @intCast(note)) - ref_midi;
    const y = 80.0 - @as(f32, @floatFromInt(semitones)) * 2.5;

    const ledger_above: u8 = if (y < 40.0)
        @as(u8, @intFromFloat(std.math.ceil((40.0 - y) / 10.0)))
    else
        0;
    const ledger_below: u8 = if (y > 80.0)
        @as(u8, @intFromFloat(std.math.ceil((y - 80.0) / 10.0)))
    else
        0;

    return .{ .y = y, .ledger_lines_above = ledger_above, .ledger_lines_below = ledger_below };
}

pub fn needsAccidental(note_pc: pitch.PitchClass, k: key.Key) bool {
    const spelled = note_spelling.spellNote(note_pc, k);
    return accidentalForName(spelled, k) != .none;
}

pub fn keySignatureSymbolCount(k: key.Key) i8 {
    return switch (k.signature.kind) {
        .natural => 0,
        .sharps => @as(i8, @intCast(k.signature.count)),
        .flats => -@as(i8, @intCast(k.signature.count)),
    };
}

pub fn renderChordStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    writeSvgPrelude(w, 170, "110.77", "0 0 170 110.77");
    drawStaffLines(w, 20.0, 150.0, 40.0);
    drawKeySignature(w, k, .treble, 30.0);

    for (notes, 0..) |note, i| {
        const spelled = spellStaffNote(note, k, .treble);
        const x = 95.0 + @as(f32, @floatFromInt(i)) * 8.0;
        drawNote(w, x, spelled);
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderGrandChordStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    writeSvgPrelude(w, 170, "216", "0 0 170 216");
    drawStaffLines(w, 20.0, 150.0, 40.0);
    drawStaffLines(w, 20.0, 150.0, 140.0);
    drawKeySignature(w, k, .treble, 30.0);
    drawKeySignature(w, k, .bass, 30.0);

    for (notes, 0..) |note, i| {
        const clef = clefForGrandStaff(note);
        var spelled = spellStaffNote(note, k, clef);
        const x = 95.0 + @as(f32, @floatFromInt(i)) * 8.0;
        if (clef == .bass) {
            spelled.position.y += 100.0;
        }
        drawNote(w, x, spelled);
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderScaleStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    writeSvgPrelude(w, 363, "113", "0 0 363 113");
    drawStaffLines(w, 20.0, 343.0, 40.0);
    drawKeySignature(w, k, .treble, 30.0);

    for (notes, 0..) |note, i| {
        const spelled = spellStaffNote(note, k, .treble);
        const x = 70.0 + @as(f32, @floatFromInt(i)) * 36.0;
        drawNote(w, x, spelled);
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn drawStaffLines(writer: anytype, x0: f32, x1: f32, top_y: f32) void {
    var i: u3 = 0;
    while (i < 5) : (i += 1) {
        const y = top_y + @as(f32, @floatFromInt(i)) * 10.0;
        writer.print("<line class=\"staff-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x0, y, x1, y }) catch unreachable;
    }
}

fn drawKeySignature(writer: anytype, k: key.Key, clef: Clef, start_x: f32) void {
    const count_signed = keySignatureSymbolCount(k);
    if (count_signed == 0) return;

    const kind: AccidentalGlyph = if (count_signed > 0) .sharp else .flat;
    const count = @as(u8, @intCast(@abs(count_signed)));
    const anchors = keySignatureAnchors(clef, kind);

    var i: u8 = 0;
    while (i < count) : (i += 1) {
        const x = start_x + @as(f32, @floatFromInt(i)) * 8.0;
        drawAccidentalGlyph(writer, kind, x, anchors[i]);
    }
}

fn drawNote(writer: anytype, x: f32, note: SpelledStaffNote) void {
    const y = note.position.y;

    if (note.accidental != .none) {
        const accidental_x: f32 = x - (if (note.accidental == .flat) @as(f32, 11.0) else @as(f32, 13.0));
        drawAccidentalGlyph(writer, note.accidental, accidental_x, y);
    }

    drawLedgerLines(writer, x, y, note.position);
    writer.print("<ellipse class=\"notehead\" cx=\"{d:.2}\" cy=\"{d:.2}\" rx=\"5.7\" ry=\"4.1\" transform=\"rotate(-20 {d:.2} {d:.2})\" />\n", .{ x, y, x, y }) catch unreachable;

    const stem_up = y >= 60.0;
    if (stem_up) {
        writer.print("<line class=\"stem\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x + 4.8, y - 0.6, x + 4.8, y - 29.0 }) catch unreachable;
    } else {
        writer.print("<line class=\"stem\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 4.8, y + 0.6, x - 4.8, y + 29.0 }) catch unreachable;
    }
}

fn writeSvgPrelude(writer: anytype, width: comptime_int, height: []const u8, view_box: []const u8) void {
    writer.print("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"{d}\" height=\"{s}\" viewBox=\"{s}\" shape-rendering=\"geometricPrecision\" text-rendering=\"geometricPrecision\">\n", .{ width, height, view_box }) catch unreachable;
    writer.writeAll(
        \\<style>
        \\.staff-line,.ledger-line,.stem,.accidental path,.accidental line{vector-effect:non-scaling-stroke}
        \\.staff-line,.ledger-line{stroke:#171717;stroke-width:1.2;stroke-linecap:round}
        \\.ledger-line{stroke-width:1.4}
        \\.notehead{fill:#111;stroke:#111;stroke-width:0.6}
        \\.stem{stroke:#111;stroke-width:1.35;stroke-linecap:round}
        \\.accidental{stroke:#111;fill:none;stroke-width:1.25;stroke-linecap:round;stroke-linejoin:round}
        \\</style>
        \\
    ) catch unreachable;
}

fn spellStaffNote(note: pitch.MidiNote, k: key.Key, clef: Clef) SpelledStaffNote {
    const pc = @as(pitch.PitchClass, @intCast(note % 12));
    const name = note_spelling.spellNote(pc, k);
    const octave = noteOctaveForName(note, name);
    return .{
        .name = name,
        .octave = octave,
        .position = staffPositionForName(name, octave, clef),
        .accidental = accidentalForName(name, k),
    };
}

fn noteOctaveForName(note: pitch.MidiNote, name: note_name.NoteName) i8 {
    const midi_i: i16 = @intCast(note);
    const pc_i: i16 = @intCast(name.toPitchClass());
    return @as(i8, @intCast(@divTrunc(midi_i - pc_i, 12) - 1));
}

pub fn staffPositionForName(name: note_name.NoteName, octave: i8, clef: Clef) StaffPosition {
    const steps = diatonicIndex(name.letter, octave) - referenceDiatonicIndex(clef);
    const y = 80.0 - @as(f32, @floatFromInt(steps)) * 5.0;
    return .{
        .y = y,
        .ledger_lines_above = if (steps > 8) @as(u8, @intCast(@divTrunc(steps - 8, 2))) else 0,
        .ledger_lines_below = if (steps < 0) @as(u8, @intCast(@divTrunc(-steps, 2))) else 0,
    };
}

fn accidentalForName(name: note_name.NoteName, k: key.Key) AccidentalGlyph {
    const key_accidental = keySignatureAccidentalForLetter(k, name.letter);
    if (name.accidental == key_accidental) return .none;

    return switch (name.accidental) {
        .natural => if (key_accidental == .natural) .none else .natural,
        .sharp => .sharp,
        .flat => .flat,
        else => .none,
    };
}

fn keySignatureAccidentalForLetter(k: key.Key, letter: note_name.Letter) note_name.Accidental {
    return switch (k.signature.kind) {
        .natural => .natural,
        .sharps => if (letterWithinSignature(letter, &[_]note_name.Letter{ .F, .C, .G, .D, .A, .E, .B }, k.signature.count)) .sharp else .natural,
        .flats => if (letterWithinSignature(letter, &[_]note_name.Letter{ .B, .E, .A, .D, .G, .C, .F }, k.signature.count)) .flat else .natural,
    };
}

fn letterWithinSignature(letter: note_name.Letter, order: []const note_name.Letter, count: u4) bool {
    var i: usize = 0;
    while (i < count and i < order.len) : (i += 1) {
        if (order[i] == letter) return true;
    }
    return false;
}

fn diatonicIndex(letter: note_name.Letter, octave: i8) i16 {
    const letter_index: i16 = switch (letter) {
        .C => 0,
        .D => 1,
        .E => 2,
        .F => 3,
        .G => 4,
        .A => 5,
        .B => 6,
    };
    return @as(i16, octave) * 7 + letter_index;
}

fn referenceDiatonicIndex(clef: Clef) i16 {
    return switch (clef) {
        .treble => diatonicIndex(.E, 4),
        .bass => diatonicIndex(.G, 2),
    };
}

fn keySignatureAnchors(clef: Clef, kind: AccidentalGlyph) *const [7]f32 {
    return switch (clef) {
        .treble => switch (kind) {
            .sharp => &[_]f32{ 40.0, 55.0, 35.0, 50.0, 65.0, 45.0, 60.0 },
            .flat => &[_]f32{ 60.0, 45.0, 65.0, 50.0, 70.0, 55.0, 75.0 },
            else => unreachable,
        },
        .bass => switch (kind) {
            .sharp => &[_]f32{ 50.0, 65.0, 45.0, 60.0, 75.0, 55.0, 70.0 },
            .flat => &[_]f32{ 70.0, 55.0, 75.0, 60.0, 80.0, 65.0, 90.0 },
            else => unreachable,
        },
    };
}

fn drawAccidentalGlyph(writer: anytype, kind: AccidentalGlyph, x: f32, y: f32) void {
    if (kind == .none) return;
    writer.print("<g class=\"accidental accidental-{s}\" transform=\"translate({d:.2},{d:.2})\">", .{ accidentalClass(kind), x, y }) catch unreachable;
    switch (kind) {
        .sharp => {
            writer.writeAll("<line x1=\"1\" y1=\"-10\" x2=\"-1\" y2=\"10\" /><line x1=\"7\" y1=\"-10\" x2=\"5\" y2=\"10\" /><line x1=\"-2\" y1=\"-3\" x2=\"8\" y2=\"-5\" /><line x1=\"-1\" y1=\"4\" x2=\"9\" y2=\"2\" />") catch unreachable;
        },
        .flat => {
            writer.writeAll("<path d=\"M0 -10 L0 9 C0 9 5.5 5.5 5.5 1.2 C5.5 -3.6 1.6 -5.2 0 -3.4\" />") catch unreachable;
        },
        .natural => {
            writer.writeAll("<line x1=\"0\" y1=\"-10\" x2=\"0\" y2=\"8\" /><line x1=\"6\" y1=\"-7\" x2=\"6\" y2=\"11\" /><line x1=\"0\" y1=\"-1\" x2=\"6\" y2=\"-3\" /><line x1=\"0\" y1=\"6\" x2=\"6\" y2=\"4\" />") catch unreachable;
        },
        .none => {},
    }
    writer.writeAll("</g>\n") catch unreachable;
}

fn accidentalClass(kind: AccidentalGlyph) []const u8 {
    return switch (kind) {
        .sharp => "sharp",
        .flat => "flat",
        .natural => "natural",
        .none => "none",
    };
}

fn drawLedgerLines(writer: anytype, x: f32, y: f32, position: StaffPosition) void {
    var i: u8 = 0;
    while (i < position.ledger_lines_above) : (i += 1) {
        const ly = y - @as(f32, @floatFromInt((i * 2) + 2)) * 5.0;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 8.0, ly, x + 8.0, ly }) catch unreachable;
    }
    i = 0;
    while (i < position.ledger_lines_below) : (i += 1) {
        const ly = y + @as(f32, @floatFromInt((i * 2) + 2)) * 5.0;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 8.0, ly, x + 8.0, ly }) catch unreachable;
    }
}
