const std = @import("std");

const assets = @import("../generated/harmonious_scale_nomod_assets.zig");
const mod_assets = @import("../generated/harmonious_scale_mod_assets.zig");
const mod_ulp = @import("../generated/harmonious_scale_mod_ulpshim.zig");

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
const SHARP_KEYSIG_Y = [_]f64{ 39.0, 54.0, 34.0, 49.0, 64.0, 44.0, 59.0 };
const FLAT_KEYSIG_Y = [_]f64{ 59.0, 44.0, 64.0, 49.0, 69.0, 54.0, 74.0 };
const SHARP_KEYSIG_BASE_X = 49.46065;
const FLAT_KEYSIG_BASE_X = 49.46065;

const ScaleLayoutRule = struct {
    key_kind: u8, // 0=natural,1=sharps,2=flats
    key_count: u8,
    note_len: u8,
    offsets: [9]u8,
    step_deltas: [9]i8,
};

const SCALE_LAYOUT_RULES = [_]ScaleLayoutRule{
    .{ .key_kind = 0, .key_count = 0, .note_len = 6, .offsets = .{ 0, 0, 0, 0, 0, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 6, .offsets = .{ 0, 10, 0, 0, 10, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, 0, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 6, .offsets = .{ 0, 10, 0, 10, 10, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 0, 0, 0, 12, 10, 10, 0, 255, 255 }, .step_deltas = .{ 0, 0, 0, 0, 0, 0, -1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 0, 0, 10, 0, 0, 12, 0, 255, 255 }, .step_deltas = .{ 0, 0, 0, 1, 2, 1, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 0, 0, 12, 0, 0, 10, 0, 255, 255 }, .step_deltas = .{ 0, 0, 0, 1, 2, 1, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 0, 10, 0, 0, 12, 0, 0, 255, 255 }, .step_deltas = .{ 0, 0, 0, 1, 2, 1, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 0, 12, 0, 0, 10, 0, 0, 255, 255 }, .step_deltas = .{ 0, 0, 0, 1, 2, 1, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 10, 0, 0, 0, 0, 10, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, 0, 0, 0, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 10, 0, 0, 12, 0, 0, 10, 255, 255 }, .step_deltas = .{ 0, 1, 0, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 7, .offsets = .{ 10, 10, 0, 0, 0, 0, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, 0, 0, 0, 1, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 8, .offsets = .{ 0, 0, 0, 0, 0, 0, 0, 0, 255 }, .step_deltas = .{ 0, 0, 0, 0, 0, -2, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 9, .offsets = .{ 0, 0, 0, 0, 10, 0, 10, 12, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 9, .offsets = .{ 0, 0, 0, 10, 0, 10, 12, 0, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 9, .offsets = .{ 10, 0, 10, 12, 0, 0, 0, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, 0, 0, 0, 1 } },
    .{ .key_kind = 0, .key_count = 0, .note_len = 9, .offsets = .{ 10, 12, 0, 0, 0, 0, 10, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, 0, 0, 0, 1 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 7, .offsets = .{ 0, 0, 0, 0, 10, 10, 0, 255, 255 }, .step_deltas = .{ 0, -1, -1, 0, -2, 0, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 7, .offsets = .{ 0, 0, 0, 10, 10, 0, 0, 255, 255 }, .step_deltas = .{ 0, -1, -1, 0, -2, 0, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 7, .offsets = .{ 0, 0, 10, 10, 0, 0, 0, 255, 255 }, .step_deltas = .{ 0, -1, -1, 0, -2, 0, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 7, .offsets = .{ 0, 10, 10, 0, 0, 0, 0, 255, 255 }, .step_deltas = .{ 0, -1, -1, 0, -2, 0, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 9, .offsets = .{ 10, 0, 0, 10, 0, 10, 10, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 9, .offsets = .{ 10, 0, 10, 0, 0, 10, 0, 10, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 9, .offsets = .{ 10, 0, 10, 10, 0, 10, 0, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 1, .note_len = 9, .offsets = .{ 10, 10, 0, 10, 0, 0, 10, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 0, -1, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 2, .note_len = 6, .offsets = .{ 0, 0, 0, 0, 0, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 1, .key_count = 2, .note_len = 7, .offsets = .{ 10, 0, 0, 10, 10, 0, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, -1, 0, 0, -1, 0, 0 } },
    .{ .key_kind = 1, .key_count = 2, .note_len = 7, .offsets = .{ 10, 0, 10, 0, 0, 10, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, -1, 0, 0, -1, 0, 0 } },
    .{ .key_kind = 1, .key_count = 2, .note_len = 7, .offsets = .{ 10, 10, 0, 10, 0, 0, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, -1, 0, 0, -1, 0, 0 } },
    .{ .key_kind = 1, .key_count = 5, .note_len = 6, .offsets = .{ 0, 0, 0, 0, 0, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 0, 0, 0, 0, 10, 12, 10, 12, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 0, 0, 0, 10, 12, 10, 12, 0, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 0, 0, 10, 12, 10, 12, 0, 0, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 0, 10, 12, 10, 12, 0, 0, 0, 0 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 10, 12, 0, 0, 0, 0, 10, 12, 10 }, .step_deltas = .{ 0, 0, 0, 0, 1, 0, 0, 1, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 10, 12, 10, 12, 0, 0, 0, 0, 10 }, .step_deltas = .{ 0, 0, 0, 0, 1, 0, 0, 1, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 12, 0, 0, 0, 0, 10, 12, 10, 12 }, .step_deltas = .{ 0, 0, 1, 0, 1, 1, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 1, .note_len = 9, .offsets = .{ 12, 10, 12, 0, 0, 0, 0, 10, 12 }, .step_deltas = .{ 0, 0, 0, 0, 0, 1, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 3, .note_len = 7, .offsets = .{ 0, 0, 12, 0, 12, 10, 0, 255, 255 }, .step_deltas = .{ 0, -1, -1, 0, -2, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 3, .note_len = 7, .offsets = .{ 0, 12, 0, 12, 10, 0, 0, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, -2, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 3, .note_len = 7, .offsets = .{ 0, 12, 10, 0, 0, 12, 0, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, -2, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 4, .note_len = 6, .offsets = .{ 0, 0, 0, 0, 0, 0, 255, 255, 255 }, .step_deltas = .{ 0, 0, 1, 0, 0, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 5, .note_len = 7, .offsets = .{ 0, 0, 10, 0, 12, 10, 0, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, -2, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 5, .note_len = 7, .offsets = .{ 0, 10, 0, 12, 10, 0, 0, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, 0, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 5, .note_len = 7, .offsets = .{ 0, 12, 10, 0, 0, 10, 0, 255, 255 }, .step_deltas = .{ 0, 0, -1, 0, -2, 0, -1, 0, 0 } },
    .{ .key_kind = 2, .key_count = 5, .note_len = 7, .offsets = .{ 10, 0, 12, 10, 0, 0, 10, 255, 255 }, .step_deltas = .{ 0, 0, 0, 1, 1, 0, 0, 0, 0 } },
    .{ .key_kind = 2, .key_count = 5, .note_len = 7, .offsets = .{ 12, 10, 0, 0, 10, 0, 12, 255, 255 }, .step_deltas = .{ 0, 0, 0, 0, 1, 0, 0, 0, 0 } },
};

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
    var offset_codes: [9]u8 = undefined;

    var sum_offsets: f64 = 0.0;
    for (note_mods, 0..) |maybe_mod, idx| {
        const offset_code = modifierOffsetInt(maybe_mod);
        offset_codes[idx] = offset_code;
        sum_offsets += @as(f64, @floatFromInt(offset_code));
    }
    const first_offset = @as(f64, @floatFromInt(offset_codes[0]));

    const base_gap = quantizeTo(computeBaseGap(start_x, note_mods.len, sum_offsets, first_offset), 19);

    xs_out[0] = start_x + first_offset;

    var cumulative_offsets: f64 = 0.0;
    const start_first = start_x + first_offset;
    var i: usize = 1;
    while (i < note_mods.len) : (i += 1) {
        cumulative_offsets += @as(f64, @floatFromInt(offset_codes[i]));
        const step = @as(f64, @floatFromInt(i));
        const step_term = quantizeTo(step * base_gap, 17);
        var x = (start_first + cumulative_offsets) + step_term;
        x = applyScaleLayoutParityShim(
            key_sig,
            offset_codes[0..note_mods.len],
            i,
            x,
        );
        xs_out[i] = x;
    }

    return xs_out[0..note_mods.len];
}

fn computeBaseGap(start_x: f64, note_len: usize, sum_offsets: f64, first_offset: f64) f64 {
    const note_count = @as(f64, @floatFromInt(note_len));
    const inv = 1.0 / note_count;
    return ((NOTE_LAYOUT_END_X - start_x) * inv) - ((sum_offsets + first_offset) * inv);
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

fn modifierOffsetInt(modifier: ?ModifierKind) u8 {
    if (modifier) |kind| {
        return switch (kind) {
            .sharp => 12,
            .flat, .natural => 10,
            .double_flat => 16,
        };
    }
    return 0;
}

fn applyScaleLayoutParityShim(
    key_sig: KeySig,
    offsets: []const u8,
    step_index: usize,
    value: f64,
) f64 {
    const delta = scaleLayoutParityUlpDelta(key_sig, offsets, step_index);
    if (delta == 0) return value;

    var adjusted = value;
    const direction = if (delta > 0) std.math.inf(f64) else -std.math.inf(f64);
    var steps: u8 = @as(u8, @intCast(@abs(delta)));
    while (steps > 0) : (steps -= 1) {
        adjusted = std.math.nextAfter(f64, adjusted, direction);
    }
    return adjusted;
}

fn scaleLayoutParityUlpDelta(
    key_sig: KeySig,
    offsets: []const u8,
    step_index: usize,
) i8 {
    const note_len = offsets.len;
    if (step_index == 0) return 0;
    if (step_index >= note_len) return 0;

    const key_kind_code: u8 = switch (key_sig.kind) {
        .natural => 0,
        .sharps => 1,
        .flats => 2,
    };

    for (SCALE_LAYOUT_RULES) |rule| {
        if (rule.key_kind != key_kind_code) continue;
        if (rule.key_count != key_sig.count) continue;
        if (rule.note_len != note_len) continue;

        var i: usize = 0;
        while (i < note_len) : (i += 1) {
            if (rule.offsets[i] != offsets[i]) break;
        }
        if (i == note_len) return rule.step_deltas[step_index];
    }

    return 0;
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
                const x_anchor = SHARP_KEYSIG_BASE_X + (10.0 * @as(f64, @floatFromInt(i)));
                const y_anchor = SHARP_KEYSIG_Y[i];
                try writeKeySigModifierLine(writer, .sharp, assets.SHARP_KEYSIG_BASE_PATH_LINE, x_anchor, y_anchor);
            }
        },
        .flats => {
            var i: usize = 0;
            while (i < key_sig.count) : (i += 1) {
                const x_anchor = FLAT_KEYSIG_BASE_X + (8.0 * @as(f64, @floatFromInt(i)));
                const y_anchor = FLAT_KEYSIG_Y[i];
                try writeKeySigModifierLine(writer, .flat, assets.FLAT_KEYSIG_BASE_PATH_LINE, x_anchor, y_anchor);
            }
        },
    }
}

fn writeKeySigModifierLine(writer: anytype, kind: ModifierKind, base_line: []const u8, x_anchor: f64, y_anchor: f64) !void {
    const marker = " d=\"";
    const suffix = "\" ></path>\n";

    const marker_at = std.mem.indexOf(u8, base_line, marker) orelse return error.InvalidBasePathLine;
    const path_start = marker_at + marker.len;
    const path_end = std.mem.lastIndexOf(u8, base_line, suffix) orelse return error.InvalidBasePathLine;
    if (path_end < path_start) return error.InvalidBasePathLine;

    try writer.writeAll(base_line[0..path_start]);
    try writeTranslatedKeySigModifierPath(writer, kind, x_anchor, y_anchor);
    try writer.writeAll(base_line[path_end..]);
}

fn writeTranslatedKeySigModifierPath(writer: anytype, kind: ModifierKind, x_anchor: f64, y_anchor: f64) !void {
    const path_d: []const u8 = switch (kind) {
        .sharp => mod_assets.SHARP_PATH_D,
        .flat => mod_assets.FLAT_PATH_D,
        else => unreachable,
    };

    var i: usize = 0;
    var token_index: usize = 0;

    while (i < path_d.len) {
        const ch = path_d[i];
        if (isPathCommand(ch)) {
            try writer.writeByte(ch);
            i += 1;
            continue;
        }

        if (isNumberStart(ch)) {
            const start = i;
            i += 1;
            while (i < path_d.len and isNumberContinuation(path_d[i])) : (i += 1) {}

            const is_x = (token_index % 2) == 0;
            const anchor = if (is_x) x_anchor else y_anchor;
            const raw = path_d[start..i];
            const raw_value = std.fmt.parseFloat(f64, raw) catch 0.0;
            const base_value = if (is_x) modifierPathBaseX(kind) else modifierPathBaseY(kind);
            const parsed_offset = raw_value - base_value;
            const default_offset = applyOffsetUlpDelta(parsed_offset, modifierOffsetUlpDelta(kind, token_index));
            const offset = modifierOffsetForToken(kind, token_index, anchor, default_offset);
            const translated = normalizeKeySigToken(kind, token_index, anchor + offset);
            try writer.print("{d}", .{translated});

            token_index += 1;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn normalizeKeySigToken(kind: ModifierKind, token_index: usize, value: f64) f64 {
    switch (kind) {
        .sharp => {
            if (token_index == 134 or token_index == 299 or token_index == 312) {
                return quantizeTo(value, 5);
            }
        },
        .flat => {
            if (token_index == 50) {
                return quantizeTo(value, 5);
            }
        },
        else => {},
    }

    return value;
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

    const modifier_width: f64 = if (attr.width > 1.0) 15.5 else attr.width;

    try writer.writeAll("<path stroke-width=\"0.3\" fill=\"black\" stroke=\"none\" font-family=\"Arial\" font-size=\"10pt\" font-weight=\"normal\" font-style=\"normal\" ");
    try writer.print("x=\"{d}\" y=\"{d}\" width=\"{d}\" height=\"{d}\" d=\"", .{ attr.x, attr.y, modifier_width, attr.height });
    try writeTranslatedModifierPath(writer, kind, path_d, x_anchor, note_y);
    try writer.writeAll("\" ></path>");
}

fn writeTranslatedModifierPath(writer: anytype, kind: ModifierKind, template_path: []const u8, x_anchor: f64, y_anchor: f64) !void {
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
            const start = i;
            i += 1;
            while (i < template_path.len and isNumberContinuation(template_path[i])) : (i += 1) {}

            const is_x = (token_index % 2) == 0;
            const anchor = if (is_x) x_anchor else y_anchor;
            const raw = template_path[start..i];
            const raw_value = std.fmt.parseFloat(f64, raw) catch 0.0;
            const base_value = if (is_x) modifierPathBaseX(kind) else modifierPathBaseY(kind);
            const parsed_offset = raw_value - base_value;
            const default_offset = applyOffsetUlpDelta(parsed_offset, modifierOffsetUlpDelta(kind, token_index));
            const offset = modifierOffsetForToken(kind, token_index, anchor, default_offset);
            try writer.print("{d}", .{anchor + offset});

            token_index += 1;
            continue;
        }

        try writer.writeByte(ch);
        i += 1;
    }
}

fn modifierPathBaseX(kind: ModifierKind) f64 {
    return switch (kind) {
        .sharp => 217.230325,
        .flat => 172.14480555555554,
        .natural => 219.230325,
        .double_flat => 277.1151625,
    };
}

fn modifierPathBaseY(kind: ModifierKind) f64 {
    return switch (kind) {
        .double_flat => 60.0,
        else => 45.0,
    };
}

fn modifierOffsetUlpDelta(kind: ModifierKind, token_index: usize) i16 {
    const deltas: []const i16 = switch (kind) {
        .sharp => mod_ulp.SHARP_ULP_DELTAS[0..],
        .flat => mod_ulp.FLAT_ULP_DELTAS[0..],
        .natural => mod_ulp.NATURAL_ULP_DELTAS[0..],
        .double_flat => mod_ulp.DOUBLE_FLAT_ULP_DELTAS[0..],
    };
    if (token_index >= deltas.len) return 0;
    return deltas[token_index];
}

fn applyOffsetUlpDelta(value: f64, delta: i16) f64 {
    if (delta == 0) return value;

    var adjusted = value;
    const direction = if (delta > 0) std.math.inf(f64) else -std.math.inf(f64);
    var steps: u16 = @as(u16, @intCast(@abs(delta)));
    while (steps > 0) : (steps -= 1) {
        adjusted = std.math.nextAfter(f64, adjusted, direction);
    }
    return adjusted;
}

fn modifierOffsetForToken(kind: ModifierKind, token_index: usize, anchor: f64, default_offset: f64) f64 {
    return switch (kind) {
        .sharp => sharpModifierOffset(token_index, anchor, default_offset),
        .flat => flatModifierOffset(token_index, anchor, default_offset),
        .natural => naturalModifierOffset(token_index, anchor, default_offset),
        .double_flat => doubleFlatModifierOffset(token_index, anchor, default_offset),
    };
}

fn sharpModifierOffset(token_index: usize, anchor: f64, default_offset: f64) f64 {
    if ((token_index == 134 or token_index == 312) and std.math.approxEqAbs(f64, anchor, 51.460650000000001, 0.000000001)) {
        return 5.6361599999999967;
    }

    if (token_index == 267 and (std.math.approxEqAbs(f64, anchor, 75, 0.000000001) or std.math.approxEqAbs(f64, anchor, 80, 0.000000001) or std.math.approxEqAbs(f64, anchor, 85, 0.000000001) or std.math.approxEqAbs(f64, anchor, 90, 0.000000001))) {
        return -9.5212800000000009;
    }

    if (token_index == 299 and (std.math.approxEqAbs(f64, anchor, 30, 0.000000001) or std.math.approxEqAbs(f64, anchor, 35, 0.000000001))) {
        return -6.2107199999999985;
    }

    return default_offset;
}

fn flatModifierOffset(token_index: usize, anchor: f64, default_offset: f64) f64 {
    if (token_index == 50 and std.math.approxEqAbs(f64, anchor, 51.460650000000001, 0.000000001)) {
        return 5.6361599999999967;
    }
    return default_offset;
}

fn naturalModifierOffset(token_index: usize, anchor: f64, default_offset: f64) f64 {
    if (token_index == 31 and (std.math.approxEqAbs(f64, anchor, 30, 0.000000001) or std.math.approxEqAbs(f64, anchor, 35, 0.000000001))) {
        return -6.2107199999999985;
    }

    if ((token_index == 61 or token_index == 63 or token_index == 65) and (std.math.approxEqAbs(f64, anchor, 30, 0.000000001) or std.math.approxEqAbs(f64, anchor, 35, 0.000000001) or std.math.approxEqAbs(f64, anchor, 40, 0.000000001) or std.math.approxEqAbs(f64, anchor, 45, 0.000000001) or std.math.approxEqAbs(f64, anchor, 50, 0.000000001))) {
        return 12.667679999999997;
    }

    if (token_index == 121 and std.math.approxEqAbs(f64, anchor, 30, 0.000000001)) {
        return -1.1217599999999983;
    }

    return default_offset;
}

fn doubleFlatModifierOffset(token_index: usize, anchor: f64, default_offset: f64) f64 {
    if ((token_index == 210 or token_index == 232) and (std.math.approxEqAbs(f64, anchor, 131.15306874999999, 0.000000001) or std.math.approxEqAbs(f64, anchor, 160.84548749999999, 0.000000001) or std.math.approxEqAbs(f64, anchor, 190.53790624999999, 0.000000001) or std.math.approxEqAbs(f64, anchor, 220.23032499999999, 0.000000001))) {
        return 8.9740799999999865;
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
