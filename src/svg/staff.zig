const std = @import("std");
const pitch = @import("../pitch.zig");
const key = @import("../key.zig");
const note_name = @import("../note_name.zig");
const note_spelling = @import("../note_spelling.zig");
const svg_quality = @import("quality.zig");

pub const Clef = enum {
    treble,
    bass,
};

pub const StaffPosition = struct {
    y: f32,
    diatonic_step: i16,
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

const ClusterNote = struct {
    note: SpelledStaffNote,
    note_x: f32,
    accidental_column: u8 = 0,
    displaced: bool = false,
};

const ChordClusterLayout = struct {
    notes: [12]ClusterNote = undefined,
    count: usize = 0,
    stem_up: bool = true,
    stem_x: f32 = 0,
    stem_start_y: f32 = 0,
    stem_end_y: f32 = 0,
};

const staff_line_gap: f32 = 10.0;
const staff_step_gap: f32 = 5.0;
const notehead_shift: f32 = 8.5;
const accidental_column_gap: f32 = 9.0;
const stem_length: f32 = 31.0;
const stem_to_head: f32 = 5.0;
const vertical_collision_step: i16 = 1;

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
    const diatonic_step = @as(i16, @intFromFloat(std.math.round((80.0 - y) / staff_step_gap)));

    const ledger_above: u8 = if (y < 40.0)
        @as(u8, @intFromFloat(std.math.ceil((40.0 - y) / staff_line_gap)))
    else
        0;
    const ledger_below: u8 = if (y > 80.0)
        @as(u8, @intFromFloat(std.math.ceil((y - 80.0) / staff_line_gap)))
    else
        0;

    return .{ .y = y, .diatonic_step = diatonic_step, .ledger_lines_above = ledger_above, .ledger_lines_below = ledger_below };
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

    const width: comptime_int = 210;
    const top_y = 42.0;
    const staff_x0 = 38.0;
    const staff_x1 = 188.0;
    const key_sig_x = 70.0;
    const cluster_x = 124.0 + keySignatureAdvance(k);

    writeSvgPrelude(w, width, "126", "0 0 210 126");
    drawStaffLines(w, staff_x0, staff_x1, top_y);
    drawEndBarline(w, staff_x1, top_y);
    drawClef(w, .treble, 52.0, top_y);
    drawKeySignature(w, k, .treble, key_sig_x);

    var cluster = layoutChordCluster(notes, k, .treble, cluster_x);
    drawChordCluster(w, &cluster);

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderGrandChordStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const width: comptime_int = 228;
    const top_top_y = 42.0;
    const bottom_top_y = 142.0;
    const staff_x0 = 44.0;
    const staff_x1 = 204.0;
    const key_sig_x = 78.0;
    const cluster_x = 140.0 + keySignatureAdvance(k);

    writeSvgPrelude(w, width, "236", "0 0 228 236");
    drawGrandBrace(w, 24.0, top_top_y - 2.0, bottom_top_y + 42.0);
    drawStaffConnector(w, 44.0, top_top_y, bottom_top_y);
    drawStaffLines(w, staff_x0, staff_x1, top_top_y);
    drawStaffLines(w, staff_x0, staff_x1, bottom_top_y);
    drawEndBarline(w, staff_x1, top_top_y);
    drawEndBarline(w, staff_x1, bottom_top_y);
    drawClef(w, .treble, 56.0, top_top_y);
    drawClef(w, .bass, 58.0, bottom_top_y);
    drawKeySignature(w, k, .treble, key_sig_x);
    drawKeySignature(w, k, .bass, key_sig_x);

    var treble_notes: [12]pitch.MidiNote = undefined;
    var bass_notes: [12]pitch.MidiNote = undefined;
    var treble_count: usize = 0;
    var bass_count: usize = 0;
    for (notes) |note| {
        switch (clefForGrandStaff(note)) {
            .treble => {
                treble_notes[treble_count] = note;
                treble_count += 1;
            },
            .bass => {
                bass_notes[bass_count] = note;
                bass_count += 1;
            },
        }
    }

    var treble_cluster = layoutChordCluster(treble_notes[0..treble_count], k, .treble, cluster_x);
    var bass_cluster = layoutChordCluster(bass_notes[0..bass_count], k, .bass, cluster_x);
    shiftClusterY(&bass_cluster, 100.0);
    drawChordCluster(w, &treble_cluster);
    drawChordCluster(w, &bass_cluster);

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

pub fn renderScaleStaff(notes: []const pitch.MidiNote, k: key.Key, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    const width: comptime_int = 392;
    const top_y = 42.0;
    const staff_x0 = 38.0;
    const staff_x1 = 370.0;
    const key_sig_x = 70.0;
    const start_x = 102.0 + keySignatureAdvance(k);

    writeSvgPrelude(w, width, "126", "0 0 392 126");
    drawStaffLines(w, staff_x0, staff_x1, top_y);
    drawEndBarline(w, staff_x1, top_y);
    drawClef(w, .treble, 52.0, top_y);
    drawKeySignature(w, k, .treble, key_sig_x);

    const spacing: f32 = if (notes.len <= 1) 0.0 else 34.0;
    for (notes, 0..) |note, index| {
        const spelled = spellStaffNote(note, k, .treble);
        const x = start_x + @as(f32, @floatFromInt(index)) * spacing;
        drawSingleStaffNote(w, x, spelled, "scale-notehead", "scale-stem");
    }

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn layoutChordCluster(notes: []const pitch.MidiNote, k: key.Key, clef: Clef, cluster_x: f32) ChordClusterLayout {
    var cluster = ChordClusterLayout{};
    cluster.count = @min(notes.len, cluster.notes.len);

    for (notes[0..cluster.count], 0..) |note, index| {
        cluster.notes[index] = .{
            .note = spellStaffNote(note, k, clef),
            .note_x = cluster_x,
        };
    }

    sortClusterNotes(&cluster);
    cluster.stem_up = stemDirectionForCluster(&cluster);
    assignClusterDisplacement(&cluster, cluster_x);
    assignAccidentalColumns(&cluster);
    computeClusterStem(&cluster);
    return cluster;
}

fn shiftClusterY(cluster: *ChordClusterLayout, offset: f32) void {
    var i: usize = 0;
    while (i < cluster.count) : (i += 1) {
        cluster.notes[i].note.position.y += offset;
    }
    cluster.stem_start_y += offset;
    cluster.stem_end_y += offset;
}

fn sortClusterNotes(cluster: *ChordClusterLayout) void {
    var i: usize = 1;
    while (i < cluster.count) : (i += 1) {
        const value = cluster.notes[i];
        var j = i;
        while (j > 0 and cluster.notes[j - 1].note.position.y > value.note.position.y) : (j -= 1) {
            cluster.notes[j] = cluster.notes[j - 1];
        }
        cluster.notes[j] = value;
    }
}

fn stemDirectionForCluster(cluster: *const ChordClusterLayout) bool {
    if (cluster.count == 0) return true;
    const top = cluster.notes[0].note.position.y;
    const bottom = cluster.notes[cluster.count - 1].note.position.y;
    return ((top + bottom) / 2.0) >= 60.0;
}

fn assignClusterDisplacement(cluster: *ChordClusterLayout, cluster_x: f32) void {
    var run_start: usize = 0;
    while (run_start < cluster.count) {
        var run_end = run_start + 1;
        while (run_end < cluster.count and @abs(cluster.notes[run_end].note.position.diatonic_step - cluster.notes[run_end - 1].note.position.diatonic_step) == vertical_collision_step) : (run_end += 1) {}

        if (run_end - run_start > 1) {
            if (cluster.stem_up) {
                var displace = true;
                var idx = run_start;
                while (idx < run_end) : (idx += 1) {
                    cluster.notes[idx].displaced = displace;
                    displace = !displace;
                }
            } else {
                var displace = true;
                var idx = run_end;
                while (idx > run_start) {
                    idx -= 1;
                    cluster.notes[idx].displaced = displace;
                    displace = !displace;
                }
            }
        }
        run_start = run_end;
    }

    for (cluster.notes[0..cluster.count]) |*note| {
        note.note_x = cluster_x;
        if (note.displaced) {
            note.note_x += if (cluster.stem_up) -notehead_shift else notehead_shift;
        }
    }
}

fn assignAccidentalColumns(cluster: *ChordClusterLayout) void {
    var last_y_by_column: [12]f32 = [_]f32{-1000.0} ** 12;
    for (cluster.notes[0..cluster.count]) |*note| {
        if (note.note.accidental == .none) continue;
        var column: u8 = 0;
        while (column < last_y_by_column.len) : (column += 1) {
            if (note.note.position.y - last_y_by_column[column] >= 16.0) {
                note.accidental_column = column;
                last_y_by_column[column] = note.note.position.y;
                break;
            }
        }
    }
}

fn computeClusterStem(cluster: *ChordClusterLayout) void {
    if (cluster.count == 0) return;
    const top = cluster.notes[0].note.position.y;
    const bottom = cluster.notes[cluster.count - 1].note.position.y;

    var leftmost = cluster.notes[0].note_x;
    var rightmost = cluster.notes[0].note_x;
    for (cluster.notes[1..cluster.count]) |note| {
        leftmost = @min(leftmost, note.note_x);
        rightmost = @max(rightmost, note.note_x);
    }

    if (cluster.stem_up) {
        cluster.stem_x = rightmost + stem_to_head;
        cluster.stem_start_y = bottom - 0.4;
        cluster.stem_end_y = @min(top - 26.0, bottom - stem_length);
    } else {
        cluster.stem_x = leftmost - stem_to_head;
        cluster.stem_start_y = top + 0.4;
        cluster.stem_end_y = @max(bottom + 26.0, top + stem_length);
    }
}

fn drawChordCluster(writer: anytype, cluster: *const ChordClusterLayout) void {
    if (cluster.count == 0) return;

    writer.writeAll("<g class=\"chord-cluster\">\n") catch unreachable;

    for (cluster.notes[0..cluster.count]) |note| {
        if (note.note.accidental != .none) {
            const accidental_x = note.note_x - 14.0 - @as(f32, @floatFromInt(note.accidental_column)) * accidental_column_gap;
            drawAccidentalGlyph(writer, note.note.accidental, accidental_x, note.note.position.y);
        }
    }

    for (cluster.notes[0..cluster.count]) |note| {
        drawLedgerLines(writer, note.note_x, note.note.position.y, note.note.position);
    }

    for (cluster.notes[0..cluster.count]) |note| {
        drawNotehead(writer, note.note_x, note.note.position.y, "chord-notehead");
    }

    writer.print(
        "<line class=\"stem cluster-stem\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n",
        .{ cluster.stem_x, cluster.stem_start_y, cluster.stem_x, cluster.stem_end_y },
    ) catch unreachable;

    writer.writeAll("</g>\n") catch unreachable;
}

fn drawSingleStaffNote(writer: anytype, x: f32, note: SpelledStaffNote, notehead_class: []const u8, stem_class: []const u8) void {
    const y = note.position.y;
    if (note.accidental != .none) {
        const accidental_x: f32 = x - (if (note.accidental == .flat) @as(f32, 11.0) else @as(f32, 13.0));
        drawAccidentalGlyph(writer, note.accidental, accidental_x, y);
    }
    drawLedgerLines(writer, x, y, note.position);
    drawNotehead(writer, x, y, notehead_class);

    const stem_up = y >= 60.0;
    if (stem_up) {
        writer.print("<line class=\"stem {s}\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ stem_class, x + 4.8, y - 0.6, x + 4.8, y - 29.0 }) catch unreachable;
    } else {
        writer.print("<line class=\"stem {s}\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ stem_class, x - 4.8, y + 0.6, x - 4.8, y + 29.0 }) catch unreachable;
    }
}

fn drawStaffLines(writer: anytype, x0: f32, x1: f32, top_y: f32) void {
    var i: u3 = 0;
    while (i < 5) : (i += 1) {
        const y = top_y + @as(f32, @floatFromInt(i)) * staff_line_gap;
        writer.print("<line class=\"staff-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x0, y, x1, y }) catch unreachable;
    }
}

fn drawEndBarline(writer: anytype, x: f32, top_y: f32) void {
    writer.print("<line class=\"staff-barline\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x, top_y, x, top_y + 4.0 * staff_line_gap }) catch unreachable;
}

fn drawStaffConnector(writer: anytype, x: f32, top_y: f32, bottom_top_y: f32) void {
    writer.print("<line class=\"staff-connector\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x, top_y, x, bottom_top_y + 4.0 * staff_line_gap }) catch unreachable;
}

fn drawGrandBrace(writer: anytype, x: f32, top_y: f32, bottom_y: f32) void {
    const mid = (top_y + bottom_y) / 2.0;
    writer.print(
        "<path class=\"staff-brace\" d=\"M {d:.2} {d:.2} C {d:.2} {d:.2}, {d:.2} {d:.2}, {d:.2} {d:.2}\" />\n",
        .{
            x + 10.0, top_y,
            x - 2.0,  top_y + 10.0,
            x - 2.0,  mid - 12.0,
            x + 10.0, mid,
        },
    ) catch unreachable;
    writer.print(
        "<path class=\"staff-brace\" d=\"M {d:.2} {d:.2} C {d:.2} {d:.2}, {d:.2} {d:.2}, {d:.2} {d:.2}\" />\n",
        .{
            x + 10.0, mid,
            x - 2.0,  mid + 12.0,
            x - 2.0,  bottom_y - 10.0,
            x + 10.0, bottom_y,
        },
    ) catch unreachable;
}

fn drawClef(writer: anytype, clef: Clef, x: f32, top_y: f32) void {
    switch (clef) {
        .treble => writer.print(
            "<g class=\"clef clef-treble\" transform=\"translate({d:.2},{d:.2})\"><path class=\"clef-stroke\" d=\"M 12 -52 C 2 -52, -8 -43, -8 -28 C -8 -14, 1 -4, 12 -4 C 22 -4, 29 -12, 29 -21 C 29 -31, 22 -38, 13 -38 C 4 -38, -1 -31, -1 -24 C -1 -16, 4 -10, 11 -10 C 22 -10, 30 -18, 30 -31 C 30 -45, 19 -58, 4 -58 C -14 -58, -27 -41, -27 -18 C -27 3, -14 17, 0 28 C 14 39, 24 50, 24 67 C 24 82, 14 92, 0 92 C -11 92, -20 84, -20 73 C -20 64, -13 57, -4 57 C 5 57, 12 64, 12 73 C 12 80, 8 86, 1 89\" /><path class=\"clef-stroke\" d=\"M 10 -66 L 1 102\" /><circle class=\"clef-hole\" cx=\"3\" cy=\"3\" r=\"7.5\" /></g>\n",
            .{ x, top_y + 18.0 },
        ) catch unreachable,
        .bass => writer.print(
            "<g class=\"clef clef-bass\" transform=\"translate({d:.2},{d:.2})\"><path class=\"clef-stroke\" d=\"M 14 -12 C 5 -15, -5 -9, -10 1 C -15 11, -15 24, -8 33 C -1 42, 11 45, 22 41 C 31 38, 39 30, 42 21 C 44 14, 43 7, 39 1 C 35 -5, 29 -8, 21 -8 C 14 -8, 8 -5, 4 -1\" /><circle class=\"clef-fill\" cx=\"44\" cy=\"-8\" r=\"2.8\" /><circle class=\"clef-fill\" cx=\"44\" cy=\"8\" r=\"2.8\" /></g>\n",
            .{ x, top_y + 19.0 },
        ) catch unreachable,
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
        const ly = y - @as(f32, @floatFromInt((i * 2) + 2)) * staff_step_gap;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 8.8, ly, x + 8.8, ly }) catch unreachable;
    }
    i = 0;
    while (i < position.ledger_lines_below) : (i += 1) {
        const ly = y + @as(f32, @floatFromInt((i * 2) + 2)) * staff_step_gap;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" />\n", .{ x - 8.8, ly, x + 8.8, ly }) catch unreachable;
    }
}

fn drawNotehead(writer: anytype, x: f32, y: f32, extra_class: []const u8) void {
    writer.print("<ellipse class=\"notehead {s}\" cx=\"{d:.2}\" cy=\"{d:.2}\" rx=\"6.0\" ry=\"4.35\" transform=\"rotate(-20 {d:.2} {d:.2})\" />\n", .{ extra_class, x, y, x, y }) catch unreachable;
}

fn writeSvgPrelude(writer: anytype, width: comptime_int, height: []const u8, view_box: []const u8) void {
    var width_buf: [16]u8 = undefined;
    const width_text = std.fmt.bufPrint(&width_buf, "{d}", .{width}) catch unreachable;
    svg_quality.writeSvgPrelude(writer, width_text, height, view_box,
        \\.staff-line,.ledger-line,.stem,.accidental path,.accidental line,.staff-barline,.staff-connector,.staff-brace,.clef-stroke,.clef-hole{vector-effect:non-scaling-stroke}
        \\.staff-line,.ledger-line,.staff-barline,.staff-connector{stroke:#171717;stroke-width:1.2;stroke-linecap:round}
        \\.ledger-line{stroke-width:1.4}
        \\.staff-brace,.clef-stroke,.clef-hole{stroke:#111;fill:none;stroke-width:1.55;stroke-linecap:round;stroke-linejoin:round}
        \\.staff-brace{stroke-width:1.7}
        \\.clef-fill{fill:#111;stroke:none}
        \\.notehead{fill:#111;stroke:#111;stroke-width:0.7}
        \\.stem{stroke:#111;stroke-width:1.4;stroke-linecap:round}
        \\.cluster-stem{stroke-width:1.5}
        \\.accidental{stroke:#111;fill:none;stroke-width:1.25;stroke-linecap:round;stroke-linejoin:round}
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
    const y = 80.0 - @as(f32, @floatFromInt(steps)) * staff_step_gap;
    return .{
        .y = y,
        .diatonic_step = steps,
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
            .sharp => &[_]f32{ 42.0, 57.0, 37.0, 52.0, 67.0, 47.0, 62.0 },
            .flat => &[_]f32{ 62.0, 47.0, 67.0, 52.0, 72.0, 57.0, 77.0 },
            else => unreachable,
        },
        .bass => switch (kind) {
            .sharp => &[_]f32{ 52.0, 67.0, 47.0, 62.0, 77.0, 57.0, 72.0 },
            .flat => &[_]f32{ 72.0, 57.0, 77.0, 62.0, 82.0, 67.0, 87.0 },
            else => unreachable,
        },
    };
}

fn keySignatureAdvance(k: key.Key) f32 {
    const count = @abs(keySignatureSymbolCount(k));
    if (count == 0) return 0.0;
    return @as(f32, @floatFromInt(count)) * 8.0 + 10.0;
}
