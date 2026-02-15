const std = @import("std");
const pitch = @import("../pitch.zig");
const key = @import("../key.zig");
const key_signature = @import("../key_signature.zig");
const pcs = @import("../pitch_class_set.zig");
const harmony = @import("../harmony.zig");

pub const Clef = enum {
    treble,
    bass,
};

pub const StaffPosition = struct {
    y: f32,
    ledger_lines: i8,
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

    const ledger = if (y < 40.0)
        @as(i8, @intFromFloat(std.math.ceil((40.0 - y) / 10.0)))
    else if (y > 80.0)
        @as(i8, @intFromFloat(std.math.ceil((y - 80.0) / 10.0)))
    else
        0;

    return .{ .y = y, .ledger_lines = ledger };
}

pub fn needsAccidental(note_pc: pitch.PitchClass, k: key.Key) bool {
    const scale_set = harmony.keyScaleSet(k);
    const bit = @as(pcs.PitchClassSet, 1) << note_pc;
    return (scale_set & bit) == 0;
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

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"170\" height=\"110.77\" viewBox=\"0 0 170 110.77\">\n") catch unreachable;
    drawStaffLines(w, 20.0, 150.0, 40.0);
    drawKeySignature(w, k, 30.0, 45.0);

    for (notes, 0..) |note, i| {
        const pos = midiToStaffPosition(note, .treble);
        const x = 95.0 + @as(f32, @floatFromInt(i)) * 8.0;
        drawNote(w, x, pos.y, pos.ledger_lines, needsAccidental(@as(pitch.PitchClass, @intCast(note % 12)), k));
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderGrandChordStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"170\" height=\"216\" viewBox=\"0 0 170 216\">\n") catch unreachable;
    drawStaffLines(w, 20.0, 150.0, 40.0);
    drawStaffLines(w, 20.0, 150.0, 140.0);
    drawKeySignature(w, k, 30.0, 45.0);
    drawKeySignature(w, k, 30.0, 145.0);

    for (notes, 0..) |note, i| {
        const clef = clefForGrandStaff(note);
        const pos = midiToStaffPosition(note, clef);
        const x = 95.0 + @as(f32, @floatFromInt(i)) * 8.0;
        const y = if (clef == .treble) pos.y else pos.y + 100.0;
        drawNote(w, x, y, pos.ledger_lines, needsAccidental(@as(pitch.PitchClass, @intCast(note % 12)), k));
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderScaleStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"363\" height=\"113\" viewBox=\"0 0 363 113\">\n") catch unreachable;
    drawStaffLines(w, 20.0, 343.0, 40.0);
    drawKeySignature(w, k, 30.0, 45.0);

    for (notes, 0..) |note, i| {
        const pos = midiToStaffPosition(note, .treble);
        const x = 70.0 + @as(f32, @floatFromInt(i)) * 36.0;
        drawNote(w, x, pos.y, pos.ledger_lines, needsAccidental(@as(pitch.PitchClass, @intCast(note % 12)), k));
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn drawStaffLines(writer: anytype, x0: f32, x1: f32, top_y: f32) void {
    var i: u3 = 0;
    while (i < 5) : (i += 1) {
        const y = top_y + @as(f32, @floatFromInt(i)) * 10.0;
        writer.print("<line x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"black\" stroke-width=\"1\" />\n", .{ x0, y, x1, y }) catch unreachable;
    }
}

fn drawKeySignature(writer: anytype, k: key.Key, start_x: f32, line_y: f32) void {
    const count_signed = keySignatureSymbolCount(k);
    if (count_signed == 0) return;

    const sym: []const u8 = if (count_signed > 0) "#" else "b";
    const count = @as(u8, @intCast(@abs(count_signed)));

    var i: u8 = 0;
    while (i < count) : (i += 1) {
        const x = start_x + @as(f32, @floatFromInt(i)) * 8.0;
        const y = line_y + @as(f32, @floatFromInt(i % 2)) * 5.0;
        writer.print("<text class=\"keysig\" x=\"{d:.2}\" y=\"{d:.2}\" font-size=\"12\">{s}</text>\n", .{ x, y, sym }) catch unreachable;
    }
}

fn drawNote(writer: anytype, x: f32, y: f32, ledger_lines: i8, accidental: bool) void {
    writer.print("<circle class=\"notehead\" cx=\"{d:.2}\" cy=\"{d:.2}\" r=\"4\" fill=\"black\" />\n", .{ x, y }) catch unreachable;

    if (accidental) {
        writer.print("<text class=\"accidental\" x=\"{d:.2}\" y=\"{d:.2}\" font-size=\"10\">n</text>\n", .{ x - 10.0, y + 3.0 }) catch unreachable;
    }

    if (ledger_lines <= 0) return;

    var i: i8 = 0;
    while (i < ledger_lines) : (i += 1) {
        const dy = @as(f32, @floatFromInt(i + 1)) * 10.0;
        const ly = if (y < 40.0) 40.0 - dy else 80.0 + dy;
        writer.print("<line x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"black\" stroke-width=\"1\" />\n", .{ x - 7.0, ly, x + 7.0, ly }) catch unreachable;
    }
}
