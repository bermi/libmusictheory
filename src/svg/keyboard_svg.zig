const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const keyboard = @import("../keyboard.zig");
const svg_quality = @import("quality.zig");

const PaletteColor = struct {
    r: u8,
    g: u8,
    b: u8,
};

const WHITE_KEY_FILL = PaletteColor{ .r = 252, .g = 250, .b = 245 };
const WHITE_KEY_STROKE = PaletteColor{ .r = 53, .g = 55, .b = 61 };
const BLACK_KEY_FILL = PaletteColor{ .r = 20, .g = 23, .b = 30 };
const BLACK_KEY_STROKE = PaletteColor{ .r = 6, .g = 8, .b = 12 };
const BG_FILL = PaletteColor{ .r = 247, .g = 241, .b = 232 };

const OPC_FILL_COLORS = [_]PaletteColor{
    .{ .r = 0x00, .g = 0x00, .b = 0xCC },
    .{ .r = 0xAA, .g = 0x44, .b = 0xFF },
    .{ .r = 0xFF, .g = 0x00, .b = 0xFF },
    .{ .r = 0xAA, .g = 0x11, .b = 0x66 },
    .{ .r = 0xEE, .g = 0x00, .b = 0x22 },
    .{ .r = 0xFF, .g = 0x99, .b = 0x11 },
    .{ .r = 0xFF, .g = 0xEE, .b = 0x00 },
    .{ .r = 0x11, .g = 0xEE, .b = 0x00 },
    .{ .r = 0x00, .g = 0x99, .b = 0x44 },
    .{ .r = 0x00, .g = 0xBB, .b = 0xBB },
    .{ .r = 0x11, .g = 0x66, .b = 0xBB },
    .{ .r = 0x22, .g = 0x88, .b = 0xFF },
};

const margin_x: f32 = 16.0;
const margin_y: f32 = 16.0;
const white_key_width: f32 = 24.0;
const white_key_height: f32 = 124.0;
const black_key_width: f32 = 14.0;
const black_key_height: f32 = 76.0;
const accent_height: f32 = 14.0;
const white_fill_alpha_exact: f32 = 0.34;
const white_fill_alpha_echo: f32 = 0.16;
const black_fill_alpha_echo: f32 = 0.72;

pub fn renderKeyboard(notes: []const pitch.MidiNote, range_low: pitch.MidiNote, range_high: pitch.MidiNote, buf: []u8) []u8 {
    const low = @min(range_low, range_high);
    const high = @max(range_low, range_high);
    const white_count = countWhiteKeys(low, high);
    const width = margin_x * 2.0 + @as(f32, @floatFromInt(white_count)) * white_key_width;
    const height = margin_y * 2.0 + white_key_height;

    var width_buf: [16]u8 = undefined;
    var height_buf: [16]u8 = undefined;
    var view_box_buf: [48]u8 = undefined;
    const width_str = std.fmt.bufPrint(&width_buf, "{d:.0}", .{width}) catch unreachable;
    const height_str = std.fmt.bufPrint(&height_buf, "{d:.0}", .{height}) catch unreachable;
    const view_box = std.fmt.bufPrint(&view_box_buf, "0 0 {d:.0} {d:.0}", .{ width, height }) catch unreachable;

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    svg_quality.writeSvgPrelude(w, width_str, height_str, view_box,
        \\.keyboard-bg{fill:rgb(247,241,232)}
        \\.keyboard-key,.keyboard-accent{vector-effect:non-scaling-stroke}
        \\.keyboard-key{stroke-linejoin:round}
        \\
    ) catch unreachable;

    w.print(
        "<rect class=\"keyboard-bg\" x=\"0\" y=\"0\" width=\"{d:.0}\" height=\"{d:.0}\" rx=\"20\" fill=\"rgb({d},{d},{d})\" />\n",
        .{ width, height, BG_FILL.r, BG_FILL.g, BG_FILL.b },
    ) catch unreachable;

    const selected_pcs: pcs.PitchClassSet = keyboard.notesPitchClassSet(notes);
    drawWhiteKeys(w, notes, selected_pcs, low, high);
    drawBlackKeys(w, notes, selected_pcs, low, high);

    w.writeAll("</svg>\n") catch unreachable;
    return buf[0..stream.pos];
}

fn drawWhiteKeys(w: anytype, notes: []const pitch.MidiNote, selected_pcs: pcs.PitchClassSet, range_low: pitch.MidiNote, range_high: pitch.MidiNote) void {
    var midi: u16 = range_low;
    while (midi <= range_high) : (midi += 1) {
        const note = @as(pitch.MidiNote, @intCast(midi));
        if (isBlackKey(note)) continue;

        const x = margin_x + @as(f32, @floatFromInt(whiteIndexBefore(range_low, note))) * white_key_width;
        const state = noteState(notes, selected_pcs, note);
        const pc = @as(u4, @intCast(note % 12));
        const color = OPC_FILL_COLORS[pc];

        switch (state) {
            .selected => {
                w.print(
                    "<rect class=\"keyboard-key white-key is-selected\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.5\" fill=\"rgba({d},{d},{d},{d:.3})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.5\" />\n",
                    .{ note, pc, x, margin_y, white_key_width, white_key_height, color.r, color.g, color.b, white_fill_alpha_exact, WHITE_KEY_STROKE.r, WHITE_KEY_STROKE.g, WHITE_KEY_STROKE.b },
                ) catch unreachable;
                w.print(
                    "<rect class=\"keyboard-accent white-key-accent is-selected\" data-midi=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" fill=\"rgb({d},{d},{d})\" />\n",
                    .{ note, x + 1.25, margin_y + white_key_height - accent_height - 1.0, white_key_width - 2.5, accent_height, color.r, color.g, color.b },
                ) catch unreachable;
            },
            .echo => {
                w.print(
                    "<rect class=\"keyboard-key white-key is-echo\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.5\" fill=\"rgba({d},{d},{d},{d:.3})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.5\" />\n",
                    .{ note, pc, x, margin_y, white_key_width, white_key_height, color.r, color.g, color.b, white_fill_alpha_echo, WHITE_KEY_STROKE.r, WHITE_KEY_STROKE.g, WHITE_KEY_STROKE.b },
                ) catch unreachable;
                w.print(
                    "<rect class=\"keyboard-accent white-key-accent is-echo\" data-midi=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" fill=\"rgba({d},{d},{d},0.58)\" />\n",
                    .{ note, x + 2.0, margin_y + white_key_height - accent_height + 1.0, white_key_width - 4.0, accent_height - 3.0, color.r, color.g, color.b },
                ) catch unreachable;
            },
            .normal => {
                w.print(
                    "<rect class=\"keyboard-key white-key\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.5\" fill=\"rgb({d},{d},{d})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.5\" />\n",
                    .{ note, pc, x, margin_y, white_key_width, white_key_height, WHITE_KEY_FILL.r, WHITE_KEY_FILL.g, WHITE_KEY_FILL.b, WHITE_KEY_STROKE.r, WHITE_KEY_STROKE.g, WHITE_KEY_STROKE.b },
                ) catch unreachable;
            },
        }
    }
}

fn drawBlackKeys(w: anytype, notes: []const pitch.MidiNote, selected_pcs: pcs.PitchClassSet, range_low: pitch.MidiNote, range_high: pitch.MidiNote) void {
    var midi: u16 = range_low;
    while (midi <= range_high) : (midi += 1) {
        const note = @as(pitch.MidiNote, @intCast(midi));
        if (!isBlackKey(note)) continue;

        const x = margin_x + @as(f32, @floatFromInt(whiteIndexBefore(range_low, note))) * white_key_width - black_key_width / 2.0;
        const state = noteState(notes, selected_pcs, note);
        const pc = @as(u4, @intCast(note % 12));
        const color = OPC_FILL_COLORS[pc];

        switch (state) {
            .selected => {
                w.print(
                    "<rect class=\"keyboard-key black-key is-selected\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.2\" fill=\"rgb({d},{d},{d})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.35\" />\n",
                    .{ note, pc, x, margin_y, black_key_width, black_key_height, color.r, color.g, color.b, BLACK_KEY_STROKE.r, BLACK_KEY_STROKE.g, BLACK_KEY_STROKE.b },
                ) catch unreachable;
            },
            .echo => {
                w.print(
                    "<rect class=\"keyboard-key black-key is-echo\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.2\" fill=\"rgba({d},{d},{d},{d:.3})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.35\" />\n",
                    .{ note, pc, x, margin_y, black_key_width, black_key_height, color.r, color.g, color.b, black_fill_alpha_echo, BLACK_KEY_STROKE.r, BLACK_KEY_STROKE.g, BLACK_KEY_STROKE.b },
                ) catch unreachable;
            },
            .normal => {
                w.print(
                    "<rect class=\"keyboard-key black-key\" data-midi=\"{d}\" data-pc=\"{d}\" x=\"{d:.2}\" y=\"{d:.2}\" width=\"{d:.2}\" height=\"{d:.2}\" rx=\"3.2\" fill=\"rgb({d},{d},{d})\" stroke=\"rgb({d},{d},{d})\" stroke-width=\"1.35\" />\n",
                    .{ note, pc, x, margin_y, black_key_width, black_key_height, BLACK_KEY_FILL.r, BLACK_KEY_FILL.g, BLACK_KEY_FILL.b, BLACK_KEY_STROKE.r, BLACK_KEY_STROKE.g, BLACK_KEY_STROKE.b },
                ) catch unreachable;
            },
        }
    }
}

const NoteState = enum {
    normal,
    echo,
    selected,
};

fn noteState(notes: []const pitch.MidiNote, selected_pcs: pcs.PitchClassSet, midi: pitch.MidiNote) NoteState {
    const opacity = keyboard.visualOpacityForMidi(notes, selected_pcs, midi);
    if (opacity == keyboard.KeyVisual.FULL_OPACITY) return .selected;
    if (opacity == keyboard.KeyVisual.HALF_OPACITY) return .echo;
    return .normal;
}

fn isBlackKey(midi: pitch.MidiNote) bool {
    return switch (midi % 12) {
        1, 3, 6, 8, 10 => true,
        else => false,
    };
}

fn countWhiteKeys(range_low: pitch.MidiNote, range_high: pitch.MidiNote) usize {
    var total: usize = 0;
    var midi: u16 = range_low;
    while (midi <= range_high) : (midi += 1) {
        if (!isBlackKey(@as(pitch.MidiNote, @intCast(midi)))) total += 1;
    }
    return total;
}

fn whiteIndexBefore(range_low: pitch.MidiNote, midi_note: pitch.MidiNote) usize {
    var total: usize = 0;
    var midi: u16 = range_low;
    while (midi < midi_note) : (midi += 1) {
        if (!isBlackKey(@as(pitch.MidiNote, @intCast(midi)))) total += 1;
    }
    return total;
}
