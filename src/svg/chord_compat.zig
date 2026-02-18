const std = @import("std");

const assets = @import("../generated/harmonious_chord_compat_assets.zig");
const mod_assets = @import("../generated/harmonious_scale_mod_assets.zig");
const mod_ulpshim = @import("../generated/harmonious_chord_mod_ulpshim.zig");
const whole_note_ulpshim = @import("../generated/harmonious_whole_note_ulpshim.zig");

pub const Kind = enum {
    chord,
    chord_clipped,
    grand_chord,
    wide_chord,
};

const MAX_KEYS = 16;

const ModifierKind = enum {
    sharp,
    flat,
    natural,
    double_flat,
};

const ClefKind = enum {
    treble,
    bass,
};

const AttrBox = struct {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
};

const TokenParts = struct {
    separator: u8,
    letter: u8,
    octave: i32,
    accidental: ?ModifierKind,
};

const KeyProp = struct {
    line: f64,
    y: f64,
    accidental: ?ModifierKind,
    displaced_prop: bool,
};

const ModifierPlacement = struct {
    kind: ModifierKind,
    key_index: usize,
    width: f64,
    x_shift: f64,
};

const HeadKind = enum {
    whole_note,
    whole_rest,
};

const NoteLayout = struct {
    keys: [MAX_KEYS]KeyProp = undefined,
    key_count: usize = 0,

    notehead_displaced: [MAX_KEYS]bool = [_]bool{false} ** MAX_KEYS,
    use_default_head_x: bool = false,

    stem_direction: i8 = 1,
    note_displaced: bool = false,
    extra_left_px: f64 = 0.0,
    extra_right_px: f64 = 0.0,

    modifiers: [MAX_KEYS]ModifierPlacement = undefined,
    modifier_count: usize = 0,
    modifier_left_shift: f64 = 0.0,

    left_px: f64 = 0.0,
    x_begin: f64 = 0.0,

    line_y_zero: f64 = 90.0,
    head_kind: HeadKind = .whole_note,

    fn isRest(self: *const NoteLayout) bool {
        return self.head_kind == .whole_rest;
    }
};

const SINGLE_BASE_X = 52.950599999999994;
const GRAND_BASE_X = 62.950599999999994;
const WHOLE_NOTE_HEAD_WIDTH = 16.0;
const WHOLE_NOTE_LEDGER_WIDTH = 21.5;
const ACCIDENTAL_SPACING = 2.0;

const AccidentalPattern = enum {
    a,
    b,
    second_on_bottom,
    spaced_out_tetrachord,
    spaced_out_pentachord,
    very_spaced_out_pentachord,
    spaced_out_hexachord,
    very_spaced_out_hexachord,
};

const LineMetric = struct {
    line: f64,
    flat_line: bool = true,
    dbl_sharp_line: bool = true,
    num_acc: usize = 0,
    width: f64 = 0.0,
    column: usize = 0,
};

const COL_1_A = [_]usize{1};
const COL_2_A = [_]usize{ 1, 2 };
const COL_3_A = [_]usize{ 1, 3, 2 };
const COL_3_B = [_]usize{ 1, 2, 1 };
const COL_3_SECOND_ON_BOTTOM = [_]usize{ 1, 2, 3 };
const COL_4_A = [_]usize{ 1, 3, 4, 2 };
const COL_4_B = [_]usize{ 1, 2, 3, 1 };
const COL_4_SPACED = [_]usize{ 1, 2, 1, 2 };
const COL_5_A = [_]usize{ 1, 3, 5, 4, 2 };
const COL_5_B = [_]usize{ 1, 2, 4, 3, 1 };
const COL_5_SPACED = [_]usize{ 1, 2, 3, 2, 1 };
const COL_5_VERY_SPACED = [_]usize{ 1, 2, 1, 2, 1 };
const COL_6_A = [_]usize{ 1, 3, 5, 6, 4, 2 };
const COL_6_B = [_]usize{ 1, 2, 4, 5, 3, 1 };
const COL_6_SPACED = [_]usize{ 1, 3, 2, 1, 3, 2 };
const COL_6_VERY_SPACED = [_]usize{ 1, 2, 1, 2, 1, 2 };

pub fn render(stem: []const u8, kind: Kind, buf: []u8) []u8 {
    return switch (kind) {
        .chord => renderSingleStaff(stem, assets.CHORD_PREFIX, .{ .x = 160.0, .y = 39.0, .width = 0.5, .height = 41.5 }, SINGLE_BASE_X, 90.0, buf),
        .chord_clipped => renderSingleStaff(stem, assets.CHORD_CLIPPED_PREFIX, .{ .x = 160.0, .y = 39.0, .width = 0.5, .height = 41.5 }, SINGLE_BASE_X, 90.0, buf),
        .grand_chord => renderGrandStaff(stem, assets.GRAND_PREFIX, .{ .x = 168.0, .y = 39.0, .width = 2.5, .height = 136.5 }, GRAND_BASE_X, buf),
        .wide_chord => renderGrandStaff(stem, assets.WIDE_PREFIX, .{ .x = 218.0, .y = 39.0, .width = 2.5, .height = 136.5 }, GRAND_BASE_X, buf),
    };
}

fn renderSingleStaff(stem: []const u8, prefix: []const u8, default_attr: AttrBox, base_x: f64, line_y_zero: f64, buf: []u8) []u8 {
    var note = NoteLayout{ .line_y_zero = line_y_zero, .head_kind = .whole_note };
    if (!parseSingleStaffNote(stem, .bass, line_y_zero, &note)) return "";
    finalizeNoteLayout(&note);
    note.x_begin = base_x + note.left_px;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll(prefix) catch return "";

    var attr = default_attr;
    writeStaveNote(w, &note, &attr) catch return "";

    w.writeAll(assets.SVG_SUFFIX) catch return "";
    return buf[0..stream.pos];
}

fn renderGrandStaff(stem: []const u8, prefix: []const u8, default_attr: AttrBox, base_x: f64, buf: []u8) []u8 {
    var top = NoteLayout{ .line_y_zero = 90.0, .head_kind = .whole_note };
    var bottom = NoteLayout{ .line_y_zero = 185.0, .head_kind = .whole_note };

    if (!parseGrandStaffNotes(stem, &top, &bottom)) return "";

    if (top.key_count == 0) {
        initWholeRest(&top, 90.0);
    } else {
        finalizeNoteLayout(&top);
    }

    finalizeNoteLayout(&bottom);

    const shared_left = @max(top.left_px, bottom.left_px);
    top.x_begin = base_x + shared_left;
    bottom.x_begin = base_x + shared_left;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll(prefix) catch return "";

    var attr = default_attr;
    writeStaveNote(w, &top, &attr) catch return "";
    writeStaveNote(w, &bottom, &attr) catch return "";

    w.writeAll(assets.SVG_SUFFIX) catch return "";
    return buf[0..stream.pos];
}

fn parseSingleStaffNote(stem: []const u8, clef: ClefKind, line_y_zero: f64, out: *NoteLayout) bool {
    var parts = std.mem.splitScalar(u8, stem, ',');
    var previous_line: ?f64 = null;

    while (parts.next()) |token| {
        const parsed = parseTokenParts(token) orelse return false;
        const key = keyPropFromToken(parsed, clef, line_y_zero) orelse return false;

        if (out.key_count >= out.keys.len) return false;

        out.keys[out.key_count] = key;
        if (previous_line) |prev_line| {
            if (lineDiffIsHalf(prev_line, key.line)) {
                out.note_displaced = true;
                out.keys[out.key_count].displaced_prop = true;
                if (out.key_count > 0) {
                    out.keys[out.key_count - 1].displaced_prop = true;
                }
            }
        }

        previous_line = key.line;
        out.key_count += 1;
    }

    return out.key_count > 0;
}

fn parseGrandStaffNotes(stem: []const u8, out_top: *NoteLayout, out_bottom: *NoteLayout) bool {
    var parts = std.mem.splitScalar(u8, stem, ',');
    var prev_top: ?f64 = null;
    var prev_bottom: ?f64 = null;

    while (parts.next()) |token| {
        const parsed = parseTokenParts(token) orelse return false;

        if (parsed.separator == '-') {
            const key = keyPropFromToken(parsed, .treble, out_top.line_y_zero) orelse return false;
            if (out_top.key_count >= out_top.keys.len) return false;

            out_top.keys[out_top.key_count] = key;
            if (prev_top) |prev_line| {
                if (lineDiffIsHalf(prev_line, key.line)) {
                    out_top.note_displaced = true;
                    out_top.keys[out_top.key_count].displaced_prop = true;
                    if (out_top.key_count > 0) {
                        out_top.keys[out_top.key_count - 1].displaced_prop = true;
                    }
                }
            }

            prev_top = key.line;
            out_top.key_count += 1;
            continue;
        }

        if (parsed.separator != '_') return false;

        const key = keyPropFromToken(parsed, .bass, out_bottom.line_y_zero) orelse return false;
        if (out_bottom.key_count >= out_bottom.keys.len) return false;

        out_bottom.keys[out_bottom.key_count] = key;
        if (prev_bottom) |prev_line| {
            if (lineDiffIsHalf(prev_line, key.line)) {
                out_bottom.note_displaced = true;
                out_bottom.keys[out_bottom.key_count].displaced_prop = true;
                if (out_bottom.key_count > 0) {
                    out_bottom.keys[out_bottom.key_count - 1].displaced_prop = true;
                }
            }
        }

        prev_bottom = key.line;
        out_bottom.key_count += 1;
    }

    return out_bottom.key_count > 0;
}

fn initWholeRest(out: *NoteLayout, line_y_zero: f64) void {
    out.* = NoteLayout{
        .line_y_zero = line_y_zero,
        .head_kind = .whole_rest,
    };

    out.keys[0] = .{
        .line = 4.0,
        .y = line_y_zero - 40.0,
        .accidental = null,
        .displaced_prop = false,
    };
    out.key_count = 1;
    finalizeNoteLayout(out);
}

fn finalizeNoteLayout(note: *NoteLayout) void {
    if (note.key_count == 0) return;

    sortKeysByLine(note.keys[0..note.key_count]);

    const min_line = note.keys[0].line;
    const max_line = note.keys[note.key_count - 1].line;
    note.stem_direction = if (((min_line + max_line) / 2.0) < 3.0) 1 else -1;

    note.use_default_head_x = false;
    var last_line: ?f64 = null;
    var displaced = false;

    var i: isize = if (note.stem_direction == -1)
        @as(isize, @intCast(note.key_count)) - 1
    else
        0;

    while (if (note.stem_direction == -1)
        i >= 0
    else
        i < @as(isize, @intCast(note.key_count))) : (i += if (note.stem_direction == -1) -1 else 1)
    {
        const idx: usize = @intCast(i);
        const line = note.keys[idx].line;

        if (last_line) |prev_line| {
            const diff = @abs(prev_line - line);
            if (diff == 0.0 or diff == 0.5) {
                displaced = !displaced;
            } else {
                displaced = false;
                note.use_default_head_x = true;
            }
        }

        note.notehead_displaced[idx] = displaced;
        last_line = line;
    }

    note.extra_left_px = if (note.note_displaced and note.stem_direction == -1) WHOLE_NOTE_HEAD_WIDTH else 0.0;
    note.extra_right_px = if (note.note_displaced and note.stem_direction == 1) WHOLE_NOTE_HEAD_WIDTH else 0.0;

    note.modifier_count = 0;
    var k: usize = 0;
    while (k < note.key_count) : (k += 1) {
        const kind = note.keys[k].accidental orelse continue;
        note.modifiers[note.modifier_count] = .{
            .kind = kind,
            .key_index = k,
            .width = modifierWidth(kind),
            .x_shift = 0.0,
        };
        note.modifier_count += 1;
    }

    note.modifier_left_shift = 0.0;
    if (note.modifier_count > 0 and !note.isRest()) {
        formatAccidentals(note);
    }

    note.left_px = note.extra_left_px + note.modifier_left_shift;
}

fn formatAccidentals(note: *NoteLayout) void {
    var order: [MAX_KEYS]usize = undefined;
    var idx: usize = 0;
    while (idx < note.modifier_count) : (idx += 1) {
        order[idx] = idx;
    }

    // VexFlow orders accidental layout by descending stave line.
    var i: usize = 1;
    while (i < note.modifier_count) : (i += 1) {
        const mod_idx = order[i];
        const line = note.keys[note.modifiers[mod_idx].key_index].line;
        var j = i;
        while (j > 0) {
            const prev_mod_idx = order[j - 1];
            const prev_line = note.keys[note.modifiers[prev_mod_idx].key_index].line;
            if (prev_line >= line) break;
            order[j] = prev_mod_idx;
            j -= 1;
        }
        order[j] = mod_idx;
    }

    var lines: [MAX_KEYS]LineMetric = undefined;
    var line_count: usize = 0;

    var sorted_index: usize = 0;
    while (sorted_index < note.modifier_count) : (sorted_index += 1) {
        const mod_idx = order[sorted_index];
        const mod = note.modifiers[mod_idx];
        const line = note.keys[mod.key_index].line;

        var line_metric: *LineMetric = undefined;
        if (line_count == 0 or lines[line_count - 1].line != line) {
            lines[line_count] = .{
                .line = line,
            };
            line_metric = &lines[line_count];
            line_count += 1;
        } else {
            line_metric = &lines[line_count - 1];
        }

        if (!isFlatFamily(mod.kind)) line_metric.flat_line = false;
        if (!isDoubleSharp(mod.kind)) line_metric.dbl_sharp_line = false;
        line_metric.num_acc += 1;
        line_metric.width += mod.width + ACCIDENTAL_SPACING;
    }

    var total_columns: usize = 0;
    i = 0;
    while (i < line_count) {
        const group_start = i;
        var group_end = i;

        while (group_end + 1 < line_count and checkAccidentalCollision(lines[group_end], lines[group_end + 1])) : (group_end += 1) {}

        const group_length = group_end - group_start + 1;
        var pattern: AccidentalPattern = if (checkAccidentalCollision(lines[group_start], lines[group_end])) .a else .b;

        switch (group_length) {
            3 => {
                const line_1_2_diff = lines[group_start + 1].line - lines[group_start + 2].line;
                const line_0_1_diff = lines[group_start + 0].line - lines[group_start + 1].line;
                if (pattern == .a and line_1_2_diff == 0.5 and line_0_1_diff != 0.5) {
                    pattern = .second_on_bottom;
                }
            },
            4 => {
                if (!checkAccidentalCollision(lines[group_start + 0], lines[group_start + 2]) and
                    !checkAccidentalCollision(lines[group_start + 1], lines[group_start + 3]))
                {
                    pattern = .spaced_out_tetrachord;
                }
            },
            5 => {
                if (pattern == .b and !checkAccidentalCollision(lines[group_start + 1], lines[group_start + 3])) {
                    pattern = .spaced_out_pentachord;
                    if (!checkAccidentalCollision(lines[group_start + 0], lines[group_start + 2]) and
                        !checkAccidentalCollision(lines[group_start + 2], lines[group_start + 4]))
                    {
                        pattern = .very_spaced_out_pentachord;
                    }
                }
            },
            6 => {
                if (!checkAccidentalCollision(lines[group_start + 0], lines[group_start + 3]) and
                    !checkAccidentalCollision(lines[group_start + 1], lines[group_start + 4]) and
                    !checkAccidentalCollision(lines[group_start + 2], lines[group_start + 5]))
                {
                    pattern = .spaced_out_hexachord;
                }
                if (!checkAccidentalCollision(lines[group_start + 0], lines[group_start + 2]) and
                    !checkAccidentalCollision(lines[group_start + 2], lines[group_start + 4]) and
                    !checkAccidentalCollision(lines[group_start + 1], lines[group_start + 3]) and
                    !checkAccidentalCollision(lines[group_start + 3], lines[group_start + 5]))
                {
                    pattern = .very_spaced_out_hexachord;
                }
            },
            else => {},
        }

        if (group_length >= 7) {
            var pattern_length: usize = 2;
            var collision_detected = true;
            while (collision_detected) {
                collision_detected = false;
                var line_cursor: usize = group_start;
                while (line_cursor + pattern_length <= group_end) : (line_cursor += 1) {
                    if (checkAccidentalCollision(lines[line_cursor], lines[line_cursor + pattern_length])) {
                        collision_detected = true;
                        pattern_length += 1;
                        break;
                    }
                }
            }

            var line_cursor: usize = group_start;
            while (line_cursor <= group_end) : (line_cursor += 1) {
                const column = ((line_cursor - group_start) % pattern_length) + 1;
                lines[line_cursor].column = column;
                if (column > total_columns) total_columns = column;
            }
        } else {
            const columns = accidentalColumns(group_length, pattern);
            var line_cursor: usize = group_start;
            while (line_cursor <= group_end) : (line_cursor += 1) {
                const column = columns[line_cursor - group_start];
                lines[line_cursor].column = column;
                if (column > total_columns) total_columns = column;
            }
        }

        i = group_end + 1;
    }

    if (total_columns == 0) {
        note.modifier_left_shift = 0.0;
        return;
    }

    // Mirror columns so final placement grows leftward from the notehead.
    i = 0;
    while (i < line_count) : (i += 1) {
        lines[i].column = (total_columns - lines[i].column) + 1;
    }

    var column_widths: [MAX_KEYS + 1]f64 = [_]f64{0.0} ** (MAX_KEYS + 1);
    i = 0;
    while (i < line_count) : (i += 1) {
        const col = lines[i].column;
        if (lines[i].width > column_widths[col]) {
            column_widths[col] = lines[i].width;
        }
    }

    var column_offsets: [MAX_KEYS + 1]f64 = [_]f64{0.0} ** (MAX_KEYS + 1);
    var col: usize = 2;
    while (col <= total_columns) : (col += 1) {
        column_offsets[col] = column_offsets[col - 1] + column_widths[col - 1];
    }

    const total_shift = column_offsets[total_columns] + column_widths[total_columns];
    note.modifier_left_shift = total_shift;

    var acc_cursor: usize = 0;
    i = 0;
    while (i < line_count) : (i += 1) {
        const line = lines[i];
        const col_base_shift = column_offsets[line.column] + column_widths[line.column] - total_shift;
        var line_width: f64 = 0.0;
        var on_line: usize = 0;
        while (on_line < line.num_acc) : (on_line += 1) {
            const mod_idx = order[acc_cursor];
            note.modifiers[mod_idx].x_shift = col_base_shift - line_width;
            line_width += note.modifiers[mod_idx].width + ACCIDENTAL_SPACING;
            acc_cursor += 1;
        }
    }

    // For displaced whole-note stacks with downward stems, VexFlow keeps
    // modifier anchors fixed and pushes the notehead column right by one
    // notehead width.
    if (note.note_displaced and note.stem_direction == -1) {
        note.modifier_left_shift += WHOLE_NOTE_HEAD_WIDTH;
        var m: usize = 0;
        while (m < note.modifier_count) : (m += 1) {
            note.modifiers[m].x_shift -= WHOLE_NOTE_HEAD_WIDTH;
        }
    }
}

fn accidentalColumns(group_length: usize, pattern: AccidentalPattern) []const usize {
    return switch (group_length) {
        1 => switch (pattern) {
            .a, .b => COL_1_A[0..],
            else => COL_1_A[0..],
        },
        2 => COL_2_A[0..],
        3 => switch (pattern) {
            .a => COL_3_A[0..],
            .b => COL_3_B[0..],
            .second_on_bottom => COL_3_SECOND_ON_BOTTOM[0..],
            else => COL_3_A[0..],
        },
        4 => switch (pattern) {
            .a => COL_4_A[0..],
            .b => COL_4_B[0..],
            .spaced_out_tetrachord => COL_4_SPACED[0..],
            else => COL_4_A[0..],
        },
        5 => switch (pattern) {
            .a => COL_5_A[0..],
            .b => COL_5_B[0..],
            .spaced_out_pentachord => COL_5_SPACED[0..],
            .very_spaced_out_pentachord => COL_5_VERY_SPACED[0..],
            else => COL_5_A[0..],
        },
        6 => switch (pattern) {
            .a => COL_6_A[0..],
            .b => COL_6_B[0..],
            .spaced_out_hexachord => COL_6_SPACED[0..],
            .very_spaced_out_hexachord => COL_6_VERY_SPACED[0..],
            else => COL_6_A[0..],
        },
        else => COL_1_A[0..],
    };
}

fn checkAccidentalCollision(line_1: LineMetric, line_2: LineMetric) bool {
    var clearance = line_2.line - line_1.line;
    var clearance_required: f64 = 3.0;

    if (clearance > 0.0) {
        clearance_required = if (line_2.flat_line or line_2.dbl_sharp_line) 2.5 else 3.0;
        if (line_1.dbl_sharp_line) clearance -= 0.5;
    } else {
        clearance_required = if (line_1.flat_line or line_1.dbl_sharp_line) 2.5 else 3.0;
        if (line_2.dbl_sharp_line) clearance -= 0.5;
    }

    return @abs(clearance) < clearance_required;
}

fn isFlatFamily(kind: ModifierKind) bool {
    return switch (kind) {
        .flat, .double_flat => true,
        else => false,
    };
}

fn isDoubleSharp(kind: ModifierKind) bool {
    _ = kind;
    return false;
}

fn sortKeysByLine(keys: []KeyProp) void {
    var i: usize = 1;
    while (i < keys.len) : (i += 1) {
        const key = keys[i];
        var j = i;
        while (j > 0 and keys[j - 1].line > key.line) : (j -= 1) {
            keys[j] = keys[j - 1];
        }
        keys[j] = key;
    }
}

fn lineDiffIsHalf(a: f64, b: f64) bool {
    return @abs(a - b) == 0.5;
}

fn parseTokenParts(token: []const u8) ?TokenParts {
    if (token.len < 3) return null;

    const underscore_idx = std.mem.lastIndexOfScalar(u8, token, '_');
    const dash_idx = std.mem.lastIndexOfScalar(u8, token, '-');

    const sep_idx: usize = blk: {
        if (underscore_idx == null and dash_idx == null) return null;
        if (underscore_idx == null) break :blk dash_idx.?;
        if (dash_idx == null) break :blk underscore_idx.?;
        break :blk @max(underscore_idx.?, dash_idx.?);
    };

    if (sep_idx == 0 or sep_idx + 1 >= token.len) return null;

    const separator = token[sep_idx];
    const note_token = token[0..sep_idx];
    if (note_token.len == 0) return null;

    const letter = std.ascii.toUpper(note_token[0]);
    _ = letterIndex(letter) orelse return null;

    const accidental_text = note_token[1..];
    const accidental: ?ModifierKind = if (accidental_text.len == 0)
        null
    else
        (parseExplicitAccidental(accidental_text) orelse return null);

    const octave = std.fmt.parseInt(i32, token[sep_idx + 1 ..], 10) catch return null;

    return .{
        .separator = separator,
        .letter = letter,
        .octave = octave,
        .accidental = accidental,
    };
}

fn parseExplicitAccidental(text: []const u8) ?ModifierKind {
    if (text.len == 1) {
        const c = std.ascii.toLower(text[0]);
        return switch (c) {
            'b' => ModifierKind.flat,
            's', '#' => ModifierKind.sharp,
            'n' => ModifierKind.natural,
            else => null,
        };
    }

    if (text.len == 2) {
        const c0 = std.ascii.toLower(text[0]);
        const c1 = std.ascii.toLower(text[1]);
        if (c0 == 'b' and c1 == 'b') return ModifierKind.double_flat;
    }

    return null;
}

fn keyPropFromToken(token: TokenParts, clef: ClefKind, line_y_zero: f64) ?KeyProp {
    const letter_idx = letterIndex(token.letter) orelse return null;
    const step = token.octave * 7 + letter_idx;

    const line = switch (clef) {
        .treble => @as(f64, @floatFromInt(step - 28)) / 2.0,
        .bass => @as(f64, @floatFromInt(step - 16)) / 2.0,
    };

    const y = line_y_zero - (line * 10.0);

    return .{
        .line = line,
        .y = y,
        .accidental = token.accidental,
        .displaced_prop = false,
    };
}

fn letterIndex(letter: u8) ?i32 {
    return switch (letter) {
        'C' => 0,
        'D' => 1,
        'E' => 2,
        'F' => 3,
        'G' => 4,
        'A' => 5,
        'B' => 6,
        else => null,
    };
}

fn modifierWidth(kind: ModifierKind) f64 {
    return switch (kind) {
        .sharp => 10.0,
        .flat => 8.0,
        .natural => 8.0,
        .double_flat => 14.0,
    };
}

fn noteheadX(note: *const NoteLayout, key_index: usize) f64 {
    const displaced = note.notehead_displaced[key_index];
    if (!displaced) return note.x_begin;
    return note.x_begin + (WHOLE_NOTE_HEAD_WIDTH * @as(f64, @floatFromInt(note.stem_direction)));
}

fn writeStaveNote(writer: anytype, note: *const NoteLayout, attr: *AttrBox) !void {
    if (!note.isRest()) {
        try writeOuterLedgerLines(writer, note, attr);
    }

    try writer.writeAll("<g class=\"vf-stavenote\" ><g class=\"vf-note\" pointer-events=\"bounding-box\" >");

    var key_index: usize = 0;
    while (key_index < note.key_count) : (key_index += 1) {
        const key = note.keys[key_index];
        const head_x = noteheadX(note, key_index);

        try writer.writeAll("<g class=\"vf-notehead\" pointer-events=\"bounding-box\" >");

        if (!note.isRest() and hasLedgerLine(key.line)) {
            const ledger_y = adjustedLedgerY(key.line, key.y);
            attr.* = .{
                .x = head_x - 3.0,
                .y = ledger_y,
                .width = WHOLE_NOTE_LEDGER_WIDTH,
                .height = 0.5,
            };
            try writeRectLine(writer, attr.*);
        }

        try writer.writeAll("<path stroke-width=\"0.3\" fill=\"black\" stroke=\"none\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
        try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" d=\"", .{ attr.x, attr.y, attr.width, attr.height });

        switch (note.head_kind) {
            .whole_note => try writeTranslatedWholeNotePath(writer, head_x, key.y),
            .whole_rest => try writeTranslatedPath(
                writer,
                assets.WHOLE_REST_BASE_PATH_D,
                assets.WHOLE_REST_BASE_X,
                assets.WHOLE_REST_BASE_Y,
                head_x,
                key.y,
            ),
        }

        try writer.writeAll("\" ></path>\n");
        try writer.writeAll("</g>\n");
    }

    try writer.writeAll("</g>\n");
    try writer.writeAll("<g class=\"vf-modifiers\" >");

    if (!note.isRest()) {
        var mod_index: usize = 0;
        while (mod_index < note.modifier_count) : (mod_index += 1) {
            const mod = note.modifiers[mod_index];
            const key = note.keys[mod.key_index];
            const x_anchor = (note.x_begin - 2.0 + mod.x_shift) - mod.width;
            try writeModifierPath(writer, attr.*, mod.kind, x_anchor, key.y);
            try writer.writeAll("\n");
        }
    }

    try writer.writeAll("</g>\n");
    try writer.writeAll("</g>\n");
}

fn writeOuterLedgerLines(writer: anytype, note: *const NoteLayout, attr: *AttrBox) !void {
    if (note.key_count == 0) return;

    const highest_line = note.keys[note.key_count - 1].line;
    const lowest_line = note.keys[0].line;

    var head_x = noteheadX(note, 0);
    if (note.use_default_head_x) {
        head_x = note.x_begin;
    }

    var line: i32 = 6;
    while (@as(f64, @floatFromInt(line)) <= highest_line) : (line += 1) {
        const y = note.line_y_zero - (@as(f64, @floatFromInt(line)) * 10.0);
        attr.* = .{
            .x = head_x - 3.0,
            .y = y,
            .width = ledgerLineWidth(head_x),
            .height = 0.5,
        };
        try writeRectLine(writer, attr.*);
    }

    line = 0;
    while (@as(f64, @floatFromInt(line)) >= lowest_line) : (line -= 1) {
        const y = note.line_y_zero - (@as(f64, @floatFromInt(line)) * 10.0);
        attr.* = .{
            .x = head_x - 3.0,
            .y = y,
            .width = ledgerLineWidth(head_x),
            .height = 0.5,
        };
        try writeRectLine(writer, attr.*);
    }
}

fn ledgerLineWidth(head_x: f64) f64 {
    if (std.math.approxEqAbs(f64, head_x, 110.9506, 0.000000001)) {
        return WHOLE_NOTE_LEDGER_WIDTH;
    }
    const left = head_x - 3.0;
    const right = head_x + 18.5;
    return right - left;
}

fn hasLedgerLine(line: f64) bool {
    return line <= 0.0 or line >= 6.0;
}

fn adjustedLedgerY(line: f64, y: f64) f64 {
    var ledger_y = y;
    const floor_line = @floor(line);

    if (line < 0.0 and std.math.approxEqAbs(f64, floor_line - line, -0.5, 0.000000001)) {
        ledger_y -= 5.0;
    } else if (line > 6.0 and std.math.approxEqAbs(f64, floor_line - line, -0.5, 0.000000001)) {
        ledger_y += 5.0;
    }

    return ledger_y;
}

fn writeRectLine(writer: anytype, attr: AttrBox) !void {
    try writer.print(
        "<rect stroke-width=\"0.3\" fill=\"black\" stroke=\"black\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" ></rect>\n",
        .{ attr.x, attr.y, attr.width, attr.height },
    );
}

fn writeTranslatedWholeNotePath(writer: anytype, x_anchor: f64, y_anchor: f64) !void {
    const template_path = assets.WHOLE_NOTE_BASE_PATH_D;

    var i: usize = 0;
    var coord_is_x = true;
    var x_token_index: usize = 0;
    var y_token_index: usize = 0;

    while (i < template_path.len) {
        const ch = template_path[i];
        if (isPathCommand(ch)) {
            try writer.writeByte(ch);
            coord_is_x = true;
            i += 1;
            continue;
        }

        if (isNumberStart(ch)) {
            const start = i;
            i += 1;
            while (i < template_path.len and isNumberContinuation(template_path[i])) : (i += 1) {}

            if (coord_is_x) {
                const raw = template_path[start..i];
                const value = std.fmt.parseFloat(f64, raw) catch 0.0;
                const offset = value - assets.WHOLE_NOTE_BASE_X;
                const translated = applyWholeNoteUlpShim(true, x_anchor, x_token_index, x_anchor + offset);
                try writer.print("{d}", .{translated});
                x_token_index += 1;
            } else {
                const raw = template_path[start..i];
                const value = std.fmt.parseFloat(f64, raw) catch 0.0;
                const offset = quantize4(value - assets.WHOLE_NOTE_BASE_Y);
                const translated = applyWholeNoteUlpShim(false, y_anchor, y_token_index, y_anchor + offset);
                try writer.print("{d}", .{translated});
                y_token_index += 1;
            }
            coord_is_x = !coord_is_x;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn writeTranslatedPath(writer: anytype, template_path: []const u8, base_x: f64, base_y: f64, x_anchor: f64, y_anchor: f64) !void {
    var i: usize = 0;
    var coord_is_x = true;

    while (i < template_path.len) {
        const ch = template_path[i];
        if (isPathCommand(ch)) {
            try writer.writeByte(ch);
            coord_is_x = true;
            i += 1;
            continue;
        }

        if (isNumberStart(ch)) {
            const start = i;
            i += 1;
            while (i < template_path.len and isNumberContinuation(template_path[i])) : (i += 1) {}

            const raw = template_path[start..i];
            const value = std.fmt.parseFloat(f64, raw) catch 0.0;
            const base_anchor = if (coord_is_x) base_x else base_y;
            const target_anchor = if (coord_is_x) x_anchor else y_anchor;
            const offset = quantize4(value - base_anchor);
            try writer.print("{d}", .{target_anchor + offset});
            coord_is_x = !coord_is_x;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn writeModifierPath(writer: anytype, attr: AttrBox, kind: ModifierKind, x_anchor: f64, y_anchor: f64) !void {
    const path_d: []const u8 = switch (kind) {
        .sharp => mod_assets.SHARP_PATH_D,
        .flat => mod_assets.FLAT_PATH_D,
        .natural => mod_assets.NATURAL_PATH_D,
        .double_flat => mod_assets.DOUBLE_FLAT_PATH_D,
    };

    const offsets: []const f64 = switch (kind) {
        .sharp => mod_assets.SHARP_OFFSETS[0..],
        .flat => mod_assets.FLAT_OFFSETS[0..],
        .natural => mod_assets.NATURAL_OFFSETS[0..],
        .double_flat => mod_assets.DOUBLE_FLAT_OFFSETS[0..],
    };

    const patches: []const mod_assets.ModPatch = switch (kind) {
        .sharp => mod_assets.SHARP_PATCHES[0..],
        .flat => mod_assets.FLAT_PATCHES[0..],
        .natural => mod_assets.NATURAL_PATCHES[0..],
        .double_flat => mod_assets.DOUBLE_FLAT_PATCHES[0..],
    };

    try writer.writeAll("<path stroke-width=\"0.3\" fill=\"black\" stroke=\"none\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
    try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" d=\"", .{ attr.x, attr.y, attr.width, attr.height });
    try writeTranslatedModifierPath(writer, kind, path_d, offsets, patches, x_anchor, y_anchor);
    try writer.writeAll("\" ></path>");
}

fn quantize4(value: f64) f64 {
    return @round(value * 10000.0) / 10000.0;
}

fn applyWholeNoteUlpShim(is_x: bool, anchor: f64, axis_token_index: usize, value: f64) f64 {
    const delta = wholeNoteUlpDelta(is_x, anchor, axis_token_index);
    if (delta == 0) return value;

    var adjusted = value;
    const direction = if (delta > 0) std.math.inf(f64) else -std.math.inf(f64);
    var steps: u16 = @intCast(@abs(delta));
    while (steps > 0) : (steps -= 1) {
        adjusted = std.math.nextAfter(f64, adjusted, direction);
    }
    return adjusted;
}

fn wholeNoteUlpDelta(is_x: bool, anchor: f64, axis_token_index: usize) i16 {
    if (axis_token_index > std.math.maxInt(u8)) return 0;
    const axis_idx: u8 = @intCast(axis_token_index);
    const anchor_bits: u64 = @bitCast(anchor);

    const table: []const whole_note_ulpshim.WholeNoteUlpEntry = if (is_x)
        whole_note_ulpshim.WHOLE_NOTE_X_ULP[0..]
    else
        whole_note_ulpshim.WHOLE_NOTE_Y_ULP[0..];

    for (table) |entry| {
        if (entry.axis_token_index != axis_idx) continue;
        if (entry.anchor_bits != anchor_bits) continue;
        return entry.delta;
    }
    return 0;
}

fn writeTranslatedModifierPath(writer: anytype, kind: ModifierKind, template_path: []const u8, offsets: []const f64, patches: []const mod_assets.ModPatch, x_anchor: f64, y_anchor: f64) !void {
    var i: usize = 0;
    var token_index: usize = 0;
    var x_token_index: usize = 0;
    var y_token_index: usize = 0;

    while (i < template_path.len) {
        const ch = template_path[i];
        if (isPathCommand(ch)) {
            try writer.writeByte(ch);
            i += 1;
            continue;
        }

        if (isNumberStart(ch)) {
            i += 1;
            while (i < template_path.len and isNumberContinuation(template_path[i])) : (i += 1) {}

            if (token_index >= offsets.len) return;

            const is_x = (token_index % 2) == 0;
            const anchor = if (is_x) x_anchor else y_anchor;
            const offset = resolveModifierOffset(token_index, anchor, offsets[token_index], patches);
            const axis_token_index = if (is_x) x_token_index else y_token_index;
            const translated = applyModifierUlpShim(kind, is_x, anchor, axis_token_index, anchor + offset);
            try writer.print("{d}", .{translated});

            if (is_x) {
                x_token_index += 1;
            } else {
                y_token_index += 1;
            }
            token_index += 1;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn resolveModifierOffset(token_index: usize, anchor: f64, default_offset: f64, patches: []const mod_assets.ModPatch) f64 {
    for (patches) |patch| {
        if (patch.token_index != token_index) continue;
        for (patch.anchors) |patch_anchor| {
            if (std.math.approxEqAbs(f64, patch_anchor, anchor, 0.000000001)) {
                return patch.secondary_offset;
            }
        }
        return default_offset;
    }
    return default_offset;
}

fn applyModifierUlpShim(kind: ModifierKind, is_x: bool, anchor: f64, axis_token_index: usize, value: f64) f64 {
    const delta = modifierUlpDelta(kind, is_x, anchor, axis_token_index);
    if (delta == 0) return value;

    var adjusted = value;
    const direction = if (delta > 0) std.math.inf(f64) else -std.math.inf(f64);
    var steps: u8 = @intCast(@abs(delta));
    while (steps > 0) : (steps -= 1) {
        adjusted = std.math.nextAfter(f64, adjusted, direction);
    }
    return adjusted;
}

fn modifierUlpDelta(kind: ModifierKind, is_x: bool, anchor: f64, axis_token_index: usize) i8 {
    if (axis_token_index > std.math.maxInt(u8)) return 0;
    const axis_idx: u8 = @intCast(axis_token_index);
    const anchor_bits: u64 = @bitCast(anchor);

    const table: []const mod_ulpshim.UlpShimEntry = switch (kind) {
        .sharp => if (is_x) mod_ulpshim.SHARP_X_ULP[0..] else mod_ulpshim.SHARP_Y_ULP[0..],
        .flat => if (is_x) mod_ulpshim.FLAT_X_ULP[0..] else mod_ulpshim.FLAT_Y_ULP[0..],
        .natural => return 0,
        .double_flat => if (is_x) mod_ulpshim.DOUBLE_FLAT_X_ULP[0..] else mod_ulpshim.DOUBLE_FLAT_Y_ULP[0..],
    };

    for (table) |entry| {
        if (entry.axis_token_index != axis_idx) continue;
        if (entry.anchor_bits != anchor_bits) continue;
        return entry.delta;
    }
    return 0;
}

fn isPathCommand(ch: u8) bool {
    return switch (ch) {
        'M', 'L', 'C' => true,
        else => false,
    };
}

fn isNumberStart(ch: u8) bool {
    return switch (ch) {
        '-', '+', '0'...'9', '.' => true,
        else => false,
    };
}

fn isNumberContinuation(ch: u8) bool {
    return switch (ch) {
        '0'...'9', '.', 'e', 'E', '-', '+' => true,
        else => false,
    };
}
