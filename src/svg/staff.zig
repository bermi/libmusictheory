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
const staff_top_line_y: f32 = 42.0;
const staff_bottom_line_y: f32 = staff_top_line_y + 4.0 * staff_line_gap;
const notehead_rx: f32 = 5.8;
const notehead_ry: f32 = 4.1;
const notehead_shift: f32 = 8.8;
const accidental_column_gap: f32 = 9.0;
const stem_length: f32 = 31.0;
const stem_overlap: f32 = 0.9;
const stem_to_head: f32 = notehead_rx - stem_overlap;
const vertical_collision_step: i16 = 1;

const TREBLE_CLEF_PATH_D =
    \\M25 69M39.0544 25.8288C39.112 25.800000000000004,39.1696 25.800000000000004,39.256 25.800000000000004C39.6016 25.800000000000004,40.0048 26.088,40.580799999999996 26.808C42.9136 29.486400000000003,44.5552 34.152,44.5552 37.9536C44.5552 38.241600000000005,44.4976 38.472,44.4976 38.760000000000005C44.2384 43.2816,42.3952 46.9968,38.7376 50.510400000000004L37.7584 51.4608L37.4128 51.8352L37.4128 51.9504L37.6144 52.8144L37.931200000000004 54.3696L38.248 55.8096C38.68 57.768,38.8528 58.775999999999996,38.8528 58.775999999999996C38.8528 58.775999999999996,38.8528 58.775999999999996,38.8528 58.775999999999996C38.8528 58.775999999999996,38.968 58.775999999999996,39.112 58.7472C39.256 58.7472,39.7168 58.6896,40.2064 58.6896C40.552 58.6896,40.8976 58.7472,41.0704 58.7472C45.1312 59.2656,48.270399999999995 62.1744,49.1632 66.264C49.336 66.9264,49.3936 67.6464,49.3936 68.3664C49.3936 72.2544,47.0608 75.9696,43.172799999999995 77.7264C42.9424 77.8704,42.855999999999995 77.89920000000001,42.855999999999995 77.89920000000001L42.855999999999995 77.928C42.855999999999995 77.928,43.028800000000004 78.5904,43.172799999999995 79.3392L43.6048 81.528L44.007999999999996 83.2848C44.2384 84.408,44.3536 85.2144,44.3536 85.9344C44.3536 86.568,44.2672 87.144,44.1232 87.8064C43.144 91.8096,39.6592 94.2,36.0304 94.2C34.2448 94.2,32.4016 93.624,30.788800000000002 92.328C29.3488 91.11840000000001,28.7152 90.024,28.7152 88.584C28.7152 86.0496,30.759999999999998 84.264,32.8912 84.264C33.64 84.264,34.3888 84.4944,35.1088 84.9264C36.3184 85.7616,36.8656 87.0288,36.8656 88.2672C36.8656 90.168,35.5408 92.03999999999999,33.2656 92.184L33.0352 92.184L33.208 92.2992C34.1584 92.7024,35.1088 92.904,36.0304 92.904C38.3632 92.904,40.552 91.72319999999999,41.8768 89.6784C42.6256 88.5264,43.028800000000004 87.1728,43.028800000000004 85.8192C43.028800000000004 85.3008,42.9424 84.7824,42.827200000000005 84.2064C42.827200000000005 84.1488,42.7408 83.688,42.6256 83.256C41.992000000000004 80.1456,41.617599999999996 78.3312,41.617599999999996 78.3312C41.617599999999996 78.3312,41.617599999999996 78.3312,41.617599999999996 78.3312C41.56 78.3312,41.4448 78.3312,41.3584 78.3888C41.0704 78.4464,40.4656 78.5904,40.2064 78.6192C39.5728 78.7056,38.968 78.7344,38.391999999999996 78.7344C32.7472 78.7344,27.5056 74.9328,25.6912 69.3168C25.2304 67.8192,24.9712 66.3216,24.9712 64.824C24.9712 61.8288,25.9216 58.8912,27.7648 56.2704C29.7808 53.419200000000004,31.7968 50.971199999999996,34.2736 48.436800000000005L35.1376 47.544L34.936 46.4784L34.5616 44.7216L34.072 42.4752C33.928 41.64,33.7552 40.833600000000004,33.7264 40.6608C33.5824 39.7104,33.496 38.7888,33.496 37.8384C33.496 34.2096,34.6768 30.724800000000002,36.8944 27.931200000000004C37.556799999999996 27.0672,38.7376 25.9152,39.0544 25.8288M40.8112 31.5312C40.7536 31.5312,40.6672 31.5312,40.580799999999996 31.5312C39.4 31.5312,37.873599999999996 32.6256,36.8368 34.2384C35.7712 35.8224,35.224000000000004 37.924800000000005,35.224000000000004 40.0848C35.224000000000004 40.6608,35.2528 41.2656,35.3392 41.870400000000004C35.4256 42.302400000000006,35.4544 42.5904,35.684799999999996 43.6272L36.088 45.4416C36.203199999999995 45.9888,36.2896 46.4208,36.2896 46.4784L36.2896 46.4784C36.3184 46.4784,37.2112 45.4992,37.4992 45.1536C40.3792 41.8992,42.1072 38.472,42.4816 35.448C42.510400000000004 35.160000000000004,42.510400000000004 34.9296,42.510400000000004 34.641600000000004C42.510400000000004 33.7488,42.3952 32.8848,42.1936 32.424C41.9632 31.9632,41.4448 31.5888,40.8112 31.5312M36.4624 53.7936C36.4048 53.3904,36.3184 53.0736,36.3184 53.016C36.3184 53.016,36.3184 53.016,36.2896 53.016C36.232 53.016,34.9936 54.456,34.129599999999996 55.464C32.6608 57.2496,31.1056 59.3808,30.472 60.4176C29.2624 62.4624,28.6576 64.7376,28.6576 66.984C28.6576 68.4528,28.9456 69.864,29.464 71.2176C31.019199999999998 75.2208,34.5904 77.7264,38.4784 77.7264C38.9392 77.7264,39.4576 77.6976,39.947199999999995 77.6112C40.580799999999996 77.496,41.3584 77.2656,41.3584 77.1792L41.3584 77.1792C41.3584 77.1792,41.300799999999995 76.8912,41.2144 76.5744L40.3792 72.456L39.7168 69.3744L39.2848 67.2432L38.824 65.1696C38.5936 63.931200000000004,38.5072 63.6144,38.5072 63.6144C38.5072 63.6144,38.5072 63.5856,38.4784 63.5856C38.3056 63.5856,37.384 64.0464,36.9808 64.3344C35.4832 65.3712,34.705600000000004 67.0128,34.705600000000004 68.6256C34.705600000000004 70.152,35.4544 71.6784,36.8944 72.5712C37.2112 72.7728,37.3264 72.9456,37.3264 73.1472C37.3264 73.176,37.3264 73.2624,37.3264 73.2912C37.2688 73.6368,37.0672 73.7808,36.7792 73.7808C36.664 73.7808,36.519999999999996 73.752,36.3472 73.6656C33.6976 72.5136,31.912 69.7776,31.912 66.7824L31.912 66.7824C31.912 63.3264,34.072 60.3312,37.384 59.1504L37.556799999999996 59.0928L37.2688 57.6528L36.4624 53.7936M40.782399999999996 63.4128C40.552 63.384,40.321600000000004 63.384,40.1488 63.384C40.0912 63.384,40.0048 63.384,39.947199999999995 63.384L39.803200000000004 63.384L39.9184 63.9024L40.5232 66.7248L40.8976 68.568L41.300799999999995 70.3824L42.1072 74.3856L42.424 75.912C42.5392 76.3152,42.5968 76.6608,42.6256 76.6608C42.6256 76.6608,42.6256 76.6608,42.6256 76.6608C42.654399999999995 76.6608,43.144 76.3728,43.4608 76.1424C44.9296 75.1056,46.024 73.4928,46.4272 71.8224C46.571200000000005 71.2752,46.6288 70.6992,46.6288 70.152C46.6288 66.8112,44.152 63.7872,40.782399999999996 63.4128
;

const BASS_CLEF_PATH_D =
    \\M25 144M33.8416 133.9488C34.072 133.8912,34.3024 133.8912,34.5616 133.8912C35.5696 133.8912,36.7504 134.0064,37.7584 134.208C42.4816 135.1872,45.736000000000004 138.38400000000001,46.3408 142.6464C46.398399999999995 143.1072,46.4272 143.5392,46.4272 144C46.4272 146.592,45.5344 149.9328,44.007999999999996 152.7264C40.3792 159.2928,33.7552 164.016,25.8064 165.744C25.6624 165.744,25.5472 165.7728,25.4032 165.7728C25.1152 165.7728,24.9712 165.6,24.9712 165.3408C24.9712 165.0528,25.0288 164.9664,25.6048 164.736C34.705600000000004 161.3088,40.782399999999996 153.9072,41.3296 145.6128C41.3584 145.1808,41.3584 144.6912,41.3584 144.3168C41.3584 140.2848,40.12 137.2896,37.7296 135.792C36.6928 135.1296,35.5696 134.8128,34.36 134.8128C31.6816 134.8128,28.9456 136.3392,27.6784 138.9024C27.6208 139.104,27.4192 139.536,27.4192 139.5648C27.4192 139.5648,27.4192 139.5648,27.4192 139.5648C27.4192 139.5648,27.448 139.536,27.534399999999998 139.5072C28.168 139.104,28.8592 138.9024,29.5792 138.9024C30.5872 138.9024,31.6528 139.3344,32.4016 140.1408C33.0928 140.8896,33.4672 141.8976,33.4672 142.8192C33.4672 144.6912,32.0848 146.592,29.9248 146.7936C29.7808 146.7936,29.6368 146.8224,29.4928 146.8224C27.1024 146.8224,25.1728 144.6336,25.1728 141.8688C25.1728 141.8112,25.1728 141.7248,25.1728 141.696C25.288 137.5776,29.0608 134.208,33.8416 133.9488M49.1632 137.808C49.2208 137.7792,49.2496 137.7792,49.336 137.7792C49.5376 137.7792,49.768 137.808,49.825599999999994 137.8656C50.5456 138.0672,50.8912 138.7008,50.8912 139.3056C50.8912 139.824,50.632 140.3424,50.1136 140.6304C49.912 140.7744,49.6528 140.8032,49.3936 140.8032C48.9904 140.8032,48.5584 140.6304,48.270399999999995 140.256C48.04 139.968,47.9248 139.6512,47.9248 139.3344C47.9248 138.6144,48.3856 137.8944,49.1632 137.808M49.1632 147.2256C49.2208 147.2256,49.2496 147.2256,49.336 147.2256C49.5376 147.2256,49.768 147.2544,49.825599999999994 147.312C50.5456 147.5136,50.8912 148.1472,50.8912 148.752C50.8912 149.2704,50.632 149.7888,50.1136 150.048C49.912 150.192,49.6528 150.2496,49.3936 150.2496C48.9904 150.2496,48.5584 150.048,48.270399999999995 149.7024C48.04 149.4144,47.9248 149.0976,47.9248 148.752C47.9248 148.032,48.3856 147.3408,49.1632 147.2256
;

const compat_treble_clef_ref_x: f32 = 25.0;
const compat_treble_clef_ref_top_y: f32 = 39.0;
const compat_bass_clef_ref_x: f32 = 25.0;
const compat_bass_clef_ref_top_y: f32 = 134.0;

pub fn clefForGrandStaff(note: pitch.MidiNote) Clef {
    return if (note >= 60) .treble else .bass;
}

pub fn midiToStaffPosition(note: pitch.MidiNote, clef: Clef) StaffPosition {
    const ref_midi: i16 = switch (clef) {
        .treble => 64, // E4 on bottom line
        .bass => 43, // G2 on bottom line
    };

    const semitones = @as(i16, @intCast(note)) - ref_midi;
    const y = staff_bottom_line_y - @as(f32, @floatFromInt(semitones)) * 2.5;
    const diatonic_step = @as(i16, @intFromFloat(std.math.round((staff_bottom_line_y - y) / staff_step_gap)));

    const ledger_above: u8 = if (y < staff_top_line_y)
        @as(u8, @intFromFloat(std.math.ceil((staff_top_line_y - y) / staff_line_gap)))
    else
        0;
    const ledger_below: u8 = if (y > staff_bottom_line_y)
        @as(u8, @intFromFloat(std.math.ceil((y - staff_bottom_line_y) / staff_line_gap)))
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
    drawClef(w, .treble, staff_x0 + 5.0, top_y);
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
    drawClef(w, .treble, staff_x0 + 5.0, top_top_y);
    drawClef(w, .bass, staff_x0 + 5.0, bottom_top_y);
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
    drawClef(w, .treble, staff_x0 + 5.0, top_y);
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
        drawLedgerLines(writer, note.note_x, note.note.position);
    }

    for (cluster.notes[0..cluster.count]) |note| {
        drawNotehead(writer, note.note_x, note.note.position.y, "chord-notehead");
    }

    writer.print(
        "<line class=\"stem cluster-stem\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#111\" stroke-width=\"1.5\" stroke-linecap=\"round\" />\n",
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
    drawLedgerLines(writer, x, note.position);
    drawNotehead(writer, x, y, notehead_class);

    const stem_up = y >= 60.0;
    if (stem_up) {
        writer.print("<line class=\"stem {s}\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#111\" stroke-width=\"1.4\" stroke-linecap=\"round\" />\n", .{ stem_class, x + stem_to_head, y - 0.6, x + stem_to_head, y - 29.0 }) catch unreachable;
    } else {
        writer.print("<line class=\"stem {s}\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#111\" stroke-width=\"1.4\" stroke-linecap=\"round\" />\n", .{ stem_class, x - stem_to_head, y + 0.6, x - stem_to_head, y + 29.0 }) catch unreachable;
    }
}

fn drawStaffLines(writer: anytype, x0: f32, x1: f32, top_y: f32) void {
    var i: u3 = 0;
    while (i < 5) : (i += 1) {
        const y = top_y + @as(f32, @floatFromInt(i)) * staff_line_gap;
        writer.print("<line class=\"staff-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#171717\" stroke-width=\"1.2\" stroke-linecap=\"round\" />\n", .{ x0, y, x1, y }) catch unreachable;
    }
}

fn drawEndBarline(writer: anytype, x: f32, top_y: f32) void {
    writer.print("<line class=\"staff-barline\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#171717\" stroke-width=\"1.2\" stroke-linecap=\"round\" />\n", .{ x, top_y, x, top_y + 4.0 * staff_line_gap }) catch unreachable;
}

fn drawStaffConnector(writer: anytype, x: f32, top_y: f32, bottom_top_y: f32) void {
    writer.print("<line class=\"staff-connector\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#171717\" stroke-width=\"1.2\" stroke-linecap=\"round\" />\n", .{ x, top_y, x, bottom_top_y + 4.0 * staff_line_gap }) catch unreachable;
}

fn drawGrandBrace(writer: anytype, x: f32, top_y: f32, bottom_y: f32) void {
    const mid = (top_y + bottom_y) / 2.0;
    writer.print(
        "<path class=\"staff-brace\" d=\"M {d:.2} {d:.2} C {d:.2} {d:.2}, {d:.2} {d:.2}, {d:.2} {d:.2}\" fill=\"none\" stroke=\"#111\" stroke-width=\"1.7\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />\n",
        .{
            x + 10.0, top_y,
            x - 2.0,  top_y + 10.0,
            x - 2.0,  mid - 12.0,
            x + 10.0, mid,
        },
    ) catch unreachable;
    writer.print(
        "<path class=\"staff-brace\" d=\"M {d:.2} {d:.2} C {d:.2} {d:.2}, {d:.2} {d:.2}, {d:.2} {d:.2}\" fill=\"none\" stroke=\"#111\" stroke-width=\"1.7\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />\n",
        .{
            x + 10.0, mid,
            x - 2.0,  mid + 12.0,
            x - 2.0,  bottom_y - 10.0,
            x + 10.0, bottom_y,
        },
    ) catch unreachable;
}

fn drawClef(writer: anytype, clef: Clef, x: f32, top_y: f32) void {
    const ref_x = switch (clef) {
        .treble => compat_treble_clef_ref_x,
        .bass => compat_bass_clef_ref_x,
    };
    const ref_top_y = switch (clef) {
        .treble => compat_treble_clef_ref_top_y,
        .bass => compat_bass_clef_ref_top_y,
    };
    const path_d = switch (clef) {
        .treble => TREBLE_CLEF_PATH_D,
        .bass => BASS_CLEF_PATH_D,
    };

    writer.print(
        "<g class=\"clef clef-{s}\" transform=\"translate({d:.2},{d:.2})\"><path class=\"clef-glyph\" d=\"{s}\" fill=\"#111\" stroke=\"none\" /></g>\n",
        .{ @tagName(clef), x - ref_x, top_y - ref_top_y, path_d },
    ) catch unreachable;
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
            writer.writeAll("<line x1=\"1\" y1=\"-10\" x2=\"-1\" y2=\"10\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"7\" y1=\"-10\" x2=\"5\" y2=\"10\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"-2\" y1=\"-3\" x2=\"8\" y2=\"-5\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"-1\" y1=\"4\" x2=\"9\" y2=\"2\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />") catch unreachable;
        },
        .flat => {
            writer.writeAll("<path d=\"M0 -10 L0 9 C0 9 5.5 5.5 5.5 1.2 C5.5 -3.6 1.6 -5.2 0 -3.4\" fill=\"none\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />") catch unreachable;
        },
        .natural => {
            writer.writeAll("<line x1=\"0\" y1=\"-10\" x2=\"0\" y2=\"8\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"6\" y1=\"-7\" x2=\"6\" y2=\"11\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"0\" y1=\"-1\" x2=\"6\" y2=\"-3\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" /><line x1=\"0\" y1=\"6\" x2=\"6\" y2=\"4\" stroke=\"#111\" stroke-width=\"1.25\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />") catch unreachable;
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

fn drawLedgerLines(writer: anytype, x: f32, position: StaffPosition) void {
    var ledger_step: i16 = 10;
    while (ledger_step <= position.diatonic_step) : (ledger_step += 2) {
        const ly = staff_bottom_line_y - @as(f32, @floatFromInt(ledger_step)) * staff_step_gap;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#171717\" stroke-width=\"1.4\" stroke-linecap=\"round\" />\n", .{ x - 8.8, ly, x + 8.8, ly }) catch unreachable;
    }
    ledger_step = -2;
    while (ledger_step >= position.diatonic_step) : (ledger_step -= 2) {
        const ly = staff_bottom_line_y - @as(f32, @floatFromInt(ledger_step)) * staff_step_gap;
        writer.print("<line class=\"ledger-line\" x1=\"{d:.2}\" y1=\"{d:.2}\" x2=\"{d:.2}\" y2=\"{d:.2}\" stroke=\"#171717\" stroke-width=\"1.4\" stroke-linecap=\"round\" />\n", .{ x - 8.8, ly, x + 8.8, ly }) catch unreachable;
    }
}

fn drawNotehead(writer: anytype, x: f32, y: f32, extra_class: []const u8) void {
    writer.print("<ellipse class=\"notehead {s}\" cx=\"{d:.2}\" cy=\"{d:.2}\" rx=\"{d:.2}\" ry=\"{d:.2}\" fill=\"#111\" stroke=\"none\" />\n", .{ extra_class, x, y, notehead_rx, notehead_ry }) catch unreachable;
}

fn writeSvgPrelude(writer: anytype, width: comptime_int, height: []const u8, view_box: []const u8) void {
    var width_buf: [16]u8 = undefined;
    const width_text = std.fmt.bufPrint(&width_buf, "{d}", .{width}) catch unreachable;
    svg_quality.writeSvgPrelude(writer, width_text, height, view_box,
        \\.staff-line,.ledger-line,.stem,.accidental path,.accidental line,.staff-barline,.staff-connector,.staff-brace,.clef-glyph{vector-effect:non-scaling-stroke}
        \\.staff-line,.ledger-line,.staff-barline,.staff-connector{stroke:#171717;stroke-width:1.2;stroke-linecap:round}
        \\.ledger-line{stroke-width:1.4}
        \\.staff-brace{stroke:#111;fill:none;stroke-width:1.55;stroke-linecap:round;stroke-linejoin:round}
        \\.staff-brace{stroke-width:1.7}
        \\.clef-glyph{fill:#111;stroke:none}
        \\.notehead{fill:#111;stroke:none}
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
    const y = staff_bottom_line_y - @as(f32, @floatFromInt(steps)) * staff_step_gap;
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
