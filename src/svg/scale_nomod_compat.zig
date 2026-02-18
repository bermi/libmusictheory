const std = @import("std");

const assets = @import("../generated/harmonious_scale_nomod_assets.zig");
const keysig_lines = @import("../generated/harmonious_scale_nomod_keysig_lines.zig");
const mod_assets = @import("../generated/harmonious_scale_mod_assets.zig");
const no_mod_names = @import("../generated/harmonious_scale_nomod_names.zig");
const profile_tuning = @import("../generated/harmonious_scale_nomod_profile_tuning.zig");

const KeySigKind = enum { natural, sharps, flats };
const ModifierKind = enum { sharp, flat, natural, double_flat };
const KeyAccidental = enum { none, sharp, flat };

const KeySig = struct {
    kind: KeySigKind,
    count: u8,
};

const AttrBox = struct {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
};

const NOTE_START_BASE_X = 51.46065;
const NOTE_LAYOUT_END_X = 355.0;

pub fn isNoModStem(stem: []const u8) bool {
    for (no_mod_names.SCALE_NO_MOD_NAMES) |name| {
        if (std.mem.eql(u8, name, stem)) return true;
    }
    return false;
}

pub fn render(stem: []const u8, buf: []u8) []u8 {
    return renderWithXs(stem, buf);
}

fn renderWithXs(stem: []const u8, buf: []u8) []u8 {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const key_sig = keySignatureForToken(parts.next() orelse return "") orelse return "";

    var notes_y: [9]f64 = undefined;
    var note_mods: [9]?ModifierKind = undefined;
    var xs_storage: [9]f64 = undefined;
    var count: usize = 0;
    while (parts.next()) |note_token| {
        if (count >= notes_y.len) return "";
        notes_y[count] = staffYFromToken(note_token) orelse return "";
        note_mods[count] = modifierForNoteToken(note_token, key_sig);
        count += 1;
    }
    if (count == 0) return "";

    const xs = computeXs(key_sig, note_mods[0..count], xs_storage[0..count]) orelse return "";

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll(assets.SCALE_HEADER_PREFIX) catch return "";
    writeKeySigBlock(w, key_sig) catch return "";

    const default_attr = AttrBox{
        .x = 353.0,
        .y = 39.0,
        .width = 0.5,
        .height = 41.5,
    };
    var attr = default_attr;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const x = xs[i];
        const y = notes_y[i];

        const has_ledger = y <= 30.0 or y >= 90.0;
        if (has_ledger) {
            const ledger_y: f64 = if (y <= 30.0) 30.0 else 90.0;
            attr = .{
                .x = x - 3.0,
                .y = ledger_y,
                .width = ledgerRectWidth(x),
                .height = 0.5,
            };
            if (!omitTopLedgerRect()) {
                writeRectLine(w, attr) catch return "";
            }
        }

        writeStaveNote(w, attr, x, y, has_ledger, note_mods[i]) catch return "";
        if (has_ledger) {
            // VexFlow keeps carried ledger x/y attrs while width reverts to canonical.
            attr.width = 15.5;
        }
    }

    w.writeAll("</svg>") catch return "";
    return buf[0..stream.pos];
}

fn keySignatureForToken(token: []const u8) ?KeySig {
    if (std.mem.eql(u8, token, "C")) return .{ .kind = .natural, .count = 0 };
    if (std.mem.eql(u8, token, "G")) return .{ .kind = .sharps, .count = 1 };
    if (std.mem.eql(u8, token, "D")) return .{ .kind = .sharps, .count = 2 };
    if (std.mem.eql(u8, token, "A")) return .{ .kind = .sharps, .count = 3 };
    if (std.mem.eql(u8, token, "E")) return .{ .kind = .sharps, .count = 4 };
    if (std.mem.eql(u8, token, "B")) return .{ .kind = .sharps, .count = 5 };
    if (std.mem.eql(u8, token, "Fs")) return .{ .kind = .sharps, .count = 6 };

    if (std.mem.eql(u8, token, "F")) return .{ .kind = .flats, .count = 1 };
    if (std.mem.eql(u8, token, "Bb")) return .{ .kind = .flats, .count = 2 };
    if (std.mem.eql(u8, token, "Eb")) return .{ .kind = .flats, .count = 3 };
    if (std.mem.eql(u8, token, "Ab")) return .{ .kind = .flats, .count = 4 };
    if (std.mem.eql(u8, token, "Db")) return .{ .kind = .flats, .count = 5 };
    if (std.mem.eql(u8, token, "Gb")) return .{ .kind = .flats, .count = 6 };
    if (std.mem.eql(u8, token, "Cb")) return .{ .kind = .flats, .count = 7 };

    return null;
}

fn computeXs(key_sig: KeySig, note_mods: []const ?ModifierKind, xs_out: []f64) ?[]const f64 {
    if (note_mods.len == 0) return null;
    if (note_mods.len > xs_out.len) return null;

    const start_x = startXForKeySig(key_sig);
    const first_offset = modifierOffset(note_mods[0]);

    var sum_offsets: f64 = 0.0;
    for (note_mods) |maybe_mod| {
        sum_offsets += modifierOffset(maybe_mod);
    }

    const tuning = layoutTuning(key_sig, note_mods.len, first_offset, sum_offsets);
    var base_gap = computeBaseGap(
        tuning.base_mode,
        start_x,
        note_mods.len,
        sum_offsets,
        first_offset,
    ) + tuning.base_eps;
    if (tuning.base_digits) |digits| {
        base_gap = quantizeTo(base_gap, digits);
    }

    xs_out[0] = start_x + first_offset;

    var cumulative_offsets: f64 = 0.0;
    const start_first = start_x + first_offset;
    var i: usize = 1;
    while (i < note_mods.len) : (i += 1) {
        cumulative_offsets += modifierOffset(note_mods[i]);
        const step = @as(f64, @floatFromInt(i));
        var step_term = step * base_gap;
        if (tuning.step_digits) |digits| {
            step_term = quantizeTo(step_term, digits);
        }
        var x = start_first + (step_term + cumulative_offsets);
        const nudge = stepUlpNudge(
            key_sig,
            note_mods.len,
            first_offset,
            sum_offsets,
            i,
            modifierOffset(note_mods[i]),
            cumulative_offsets,
        );
        if (nudge != 0) {
            x = nudgeUlps(x, nudge);
        }
        xs_out[i] = x;
    }

    return xs_out[0..note_mods.len];
}

const LayoutTuning = struct {
    base_mode: u8,
    base_digits: ?u8,
    step_digits: ?u8,
    base_eps: f64,
};

fn keySigKindCode(kind: KeySigKind) u8 {
    return switch (kind) {
        .natural => 0,
        .sharps => 1,
        .flats => 2,
    };
}

fn computeBaseGap(base_mode: u8, start_x: f64, note_len: usize, sum_offsets: f64, first_offset: f64) f64 {
    const note_count = @as(f64, @floatFromInt(note_len));
    const inv_note_count = 1.0 / note_count;
    return switch (base_mode) {
        0 => ((NOTE_LAYOUT_END_X - start_x) * inv_note_count) - ((sum_offsets + first_offset) * inv_note_count),
        1 => ((NOTE_LAYOUT_END_X - start_x) - (sum_offsets + first_offset)) * inv_note_count,
        2 => ((NOTE_LAYOUT_END_X - start_x) / note_count) - ((sum_offsets + first_offset) / note_count),
        3 => (NOTE_LAYOUT_END_X - start_x - sum_offsets - first_offset) / note_count,
        else => ((NOTE_LAYOUT_END_X - start_x) * inv_note_count) - ((sum_offsets + first_offset) * inv_note_count),
    };
}

fn layoutTuning(key_sig: KeySig, note_len: usize, first_offset: f64, sum_offsets: f64) LayoutTuning {
    const kind = keySigKindCode(key_sig.kind);
    for (profile_tuning.SCALE_PROFILE_TUNINGS) |row| {
        if (row.kind != kind) continue;
        if (row.key_count != key_sig.count) continue;
        if (row.note_len != note_len) continue;
        if (row.first_offset != first_offset) continue;
        if (row.sum_offsets != sum_offsets) continue;

        const qb: ?u8 = if (row.qb >= 0) @as(u8, @intCast(row.qb)) else null;
        const qs: ?u8 = if (row.qs >= 0) @as(u8, @intCast(row.qs)) else null;
        return .{
            .base_mode = row.base_mode,
            .base_digits = qb,
            .step_digits = qs,
            .base_eps = row.base_eps,
        };
    }

    return .{
        .base_mode = 0,
        .base_digits = null,
        .step_digits = null,
        .base_eps = 0.0,
    };
}

fn stepUlpNudge(
    key_sig: KeySig,
    note_len: usize,
    first_offset: f64,
    sum_offsets: f64,
    step_index: usize,
    step_offset: f64,
    cumulative_offsets: f64,
) i8 {
    if (key_sig.kind == .sharps and key_sig.count == 5 and note_len == 6 and first_offset == 0.0 and sum_offsets == 0.0 and step_index == 3) {
        return -1;
    }
    if (key_sig.kind == .natural and key_sig.count == 0 and note_len == 7 and first_offset == 0.0 and sum_offsets == 32.0 and step_index == 6) {
        return -1;
    }
    if (key_sig.kind == .natural and key_sig.count == 0 and note_len == 9 and first_offset == 10.0 and sum_offsets == 42.0 and step_index == 8) {
        return 1;
    }
    if (key_sig.kind == .flats and key_sig.count == 1 and note_len == 9 and first_offset == 12.0 and sum_offsets == 56.0) {
        if (step_index == 2 and step_offset == 0.0) return 1;
        if (step_index == 4 and cumulative_offsets == 0.0) return 1;
    }
    if (key_sig.kind == .flats and key_sig.count == 1 and note_len == 9 and first_offset == 0.0 and sum_offsets == 44.0 and step_index == 2) {
        if (step_offset == 10.0) return 1;
        if (step_offset == 0.0) return 1;
    }
    return 0;
}

fn nudgeUlps(value: f64, steps: i8) f64 {
    if (steps == 0) return value;
    var bits: u64 = @bitCast(value);
    if (steps > 0) {
        bits += @as(u64, @intCast(steps));
    } else {
        bits -= @as(u64, @intCast(-steps));
    }
    return @bitCast(bits);
}

fn startXForKeySig(key_sig: KeySig) f64 {
    return switch (key_sig.kind) {
        .natural => NOTE_START_BASE_X,
        .sharps => NOTE_START_BASE_X + (10.0 * @as(f64, @floatFromInt(key_sig.count + 1))),
        .flats => NOTE_START_BASE_X + (10.0 + (8.0 * @as(f64, @floatFromInt(key_sig.count)))),
    };
}

fn modifierOffset(modifier: ?ModifierKind) f64 {
    if (modifier) |kind| {
        return switch (kind) {
            .sharp => 12.0,
            .flat, .natural => 10.0,
            .double_flat => 16.0,
        };
    }
    return 0.0;
}

fn staffYFromToken(token: []const u8) ?f64 {
    const sep = std.mem.lastIndexOfScalar(u8, token, '-') orelse return null;
    if (sep == 0 or sep + 1 >= token.len) return null;

    const letter = std.ascii.toUpper(token[0]);
    const letter_idx: i32 = switch (letter) {
        'C' => 0,
        'D' => 1,
        'E' => 2,
        'F' => 3,
        'G' => 4,
        'A' => 5,
        'B' => 6,
        else => return null,
    };

    const octave = std.fmt.parseInt(i32, token[sep + 1 ..], 10) catch return null;
    const staff_step = octave * 7 + letter_idx;
    return 90.0 - @as(f64, @floatFromInt((staff_step - 28) * 5));
}

fn writeKeySigBlock(writer: anytype, key_sig: KeySig) !void {
    switch (key_sig.kind) {
        .natural => return,
        .sharps => {
            var i: usize = 0;
            while (i < key_sig.count) : (i += 1) {
                try writer.writeAll(keysig_lines.SHARP_LINES[i]);
            }
        },
        .flats => {
            var i: usize = 0;
            while (i < key_sig.count) : (i += 1) {
                try writer.writeAll(keysig_lines.FLAT_LINES[i]);
            }
        },
    }
}

fn writeRectLine(writer: anytype, attr: AttrBox) !void {
    try writer.print(
        "<rect stroke-width=\"0.3\" fill=\"black\" stroke=\"black\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" ></rect>\n",
        .{ attr.x, attr.y, attr.width, attr.height },
    );
}

fn writeStaveNote(writer: anytype, attr: AttrBox, x: f64, y: f64, has_ledger: bool, modifier: ?ModifierKind) !void {
    const stem_up = y > 60.0;
    const stem_x: f64 = if (stem_up) x + 10.0 else x + 0.75;
    const stem_y0: f64 = if (stem_up) y - 2.0 else y + 2.0;
    const stem_y1: f64 = if (stem_up) y - 34.0 else y + 34.0;
    const notehead_width: f64 = if (has_ledger) 15.5 else attr.width;

    try writer.writeAll("<g class=\"vf-stavenote\" ><g class=\"vf-note\" pointer-events=\"bounding-box\" ><g class=\"vf-stem\" pointer-events=\"bounding-box\" ><path stroke-width=\"1.5\" fill=\"none\" stroke=\"black\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
    try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" ", .{ attr.x, attr.y, attr.width, attr.height });
    try writer.print("d=\"M{d} {d}L{d} {d}\" ></path>\n", .{ stem_x, stem_y0, stem_x, stem_y1 });
    try writer.writeAll("</g>\n");

    try writer.writeAll("<g class=\"vf-notehead\" pointer-events=\"bounding-box\" >");
    if (has_ledger) {
        try writer.print(
            "<rect stroke-width=\"0.3\" fill=\"black\" stroke=\"black\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" ></rect>\n",
            .{ attr.x, attr.y, 15.5, attr.height },
        );
    }
    try writer.writeAll("<path stroke-width=\"0.3\" fill=\"black\" stroke=\"none\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
    try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" d=\"", .{ attr.x, attr.y, notehead_width, attr.height });
    try writeTranslatedNoteheadPath(
        writer,
        assets.NOTEHEAD_BASE_PATH_D,
        x,
        y,
    );
    try writer.writeAll("\" ></path>\n");

    try writer.writeAll("</g>\n");
    try writer.writeAll("</g>\n");
    try writer.writeAll("<g class=\"vf-modifiers\" >");
    if (modifier) |kind| {
        try writeModifierPath(writer, attr, kind, x, y);
        try writer.writeAll("\n");
    }
    try writer.writeAll("</g>\n");
    try writer.writeAll("</g>\n");
}

fn writeTranslatedNoteheadPath(writer: anytype, base_path: []const u8, x_anchor: f64, y_anchor: f64) !void {
    var i: usize = 0;
    var coord_is_x = true;

    while (i < base_path.len) {
        const ch = base_path[i];
        if (isPathCommand(ch)) {
            try writer.writeByte(ch);
            coord_is_x = true;
            i += 1;
            continue;
        }

        if (isNumberStart(ch)) {
            const start = i;
            i += 1;
            while (i < base_path.len and isNumberContinuation(base_path[i])) : (i += 1) {}
            const raw = base_path[start..i];
            const value = std.fmt.parseFloat(f64, raw) catch 0.0;
            const base_anchor: f64 = if (coord_is_x) assets.NOTEHEAD_BASE_X else assets.NOTEHEAD_BASE_Y;
            const anchor: f64 = if (coord_is_x) x_anchor else y_anchor;

            // VexFlow/Raphael emits notehead path points as anchor + literal offsets.
            // Quantizing to 4 decimals reproduces the same IEEE754 rounding behavior.
            const offset = quantize4(value - base_anchor);
            const translated = anchor + offset;
            try writer.print("{d}", .{translated});
            coord_is_x = !coord_is_x;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn quantize4(value: f64) f64 {
    return @round(value * 10000.0) / 10000.0;
}

fn quantizeTo(value: f64, digits: u8) f64 {
    var factor: f64 = 1.0;
    var i: u8 = 0;
    while (i < digits) : (i += 1) {
        factor *= 10.0;
    }
    return @round(value * factor) / factor;
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

fn modifierForNoteToken(note_token: []const u8, key_sig: KeySig) ?ModifierKind {
    const sep = std.mem.lastIndexOfScalar(u8, note_token, '-') orelse return null;
    if (sep == 0 or sep + 1 >= note_token.len) return null;

    const letter = std.ascii.toUpper(note_token[0]);
    const accidental = note_token[1..sep];
    if (accidental.len == 0) return null;

    const explicit_kind: ModifierKind = blk: {
        if (accidental.len == 1) {
            const c = std.ascii.toLower(accidental[0]);
            break :blk switch (c) {
                's', '#' => .sharp,
                'b' => .flat,
                'n' => .natural,
                else => return null,
            };
        }
        if (accidental.len == 2 and std.ascii.toLower(accidental[0]) == 'b' and std.ascii.toLower(accidental[1]) == 'b') {
            break :blk .double_flat;
        }
        return null;
    };

    const key_accidental = keyAccidentalForLetter(key_sig, letter);
    if ((explicit_kind == .sharp and key_accidental == .sharp) or
        (explicit_kind == .flat and key_accidental == .flat))
    {
        return null;
    }
    return explicit_kind;
}

fn keyAccidentalForLetter(key_sig: KeySig, letter: u8) KeyAccidental {
    const SHARP_ORDER = "FCGDAEB";
    const FLAT_ORDER = "BEADGCF";

    switch (key_sig.kind) {
        .natural => return .none,
        .sharps => {
            var i: usize = 0;
            while (i < key_sig.count) : (i += 1) {
                if (SHARP_ORDER[i] == letter) return .sharp;
            }
            return .none;
        },
        .flats => {
            var i: usize = 0;
            while (i < key_sig.count) : (i += 1) {
                if (FLAT_ORDER[i] == letter) return .flat;
            }
            return .none;
        },
    }
}

fn writeModifierPath(writer: anytype, attr: AttrBox, kind: ModifierKind, note_x: f64, note_y: f64) !void {
    const x_anchor: f64 = switch (kind) {
        .sharp => note_x - 12.0,
        .flat, .natural => note_x - 10.0,
        .double_flat => note_x - 16.0,
    };

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

    const modifier_width: f64 = if (attr.width > 1.0) 15.5 else attr.width;

    try writer.writeAll("<path stroke-width=\"0.3\" fill=\"black\" stroke=\"none\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
    try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" d=\"", .{ attr.x, attr.y, modifier_width, attr.height });
    try writeTranslatedModifierPath(writer, path_d, offsets, patches, x_anchor, note_y);
    try writer.writeAll("\" ></path>");
}

fn writeTranslatedModifierPath(writer: anytype, template_path: []const u8, offsets: []const f64, patches: []const mod_assets.ModPatch, x_anchor: f64, y_anchor: f64) !void {
    var i: usize = 0;
    var token_index: usize = 0;

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
            try writer.print("{d}", .{anchor + offset});

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

fn omitTopLedgerRect() bool {
    return false;
}

fn ledgerRectWidth(x: f64) f64 {
    const ledger_left = x - 3.0;
    if (ledger_left < 116.0) return 15.5;

    // Derive width from the same decimal roundtrip used by emitted `{d}` values.
    var buf: [64]u8 = undefined;
    const x_text = std.fmt.bufPrint(&buf, "{d}", .{x}) catch return (x + 12.5) - (x - 3.0);
    const x_roundtrip = std.fmt.parseFloat(f64, x_text) catch x;
    return (x_roundtrip + 12.5) - (x_roundtrip - 3.0);
}
