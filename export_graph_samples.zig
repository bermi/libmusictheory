const std = @import("std");

const pitch = @import("src/pitch.zig");
const pcs = @import("src/pitch_class_set.zig");
const compat = @import("src/harmonious_svg_compat.zig");
const svg_clock = @import("src/svg/clock.zig");
const svg_mode_icon = @import("src/svg/mode_icon.zig");
const svg_evenness = @import("src/svg/evenness_chart.zig");
const svg_tessellation = @import("src/svg/tessellation.zig");
const svg_orbifold = @import("src/svg/orbifold.zig");
const svg_cof = @import("src/svg/circle_of_fifths.zig");

const OUT_DIR = "docs/architecture/graphs/samples";

fn writeSample(name: []const u8, data: []const u8) !void {
    var path_buf: [256]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buf, "{s}/{s}", .{ OUT_DIR, name });
    try std.fs.cwd().writeFile(.{ .sub_path = path, .data = data });
}

fn kindIndexByName(kind_name: []const u8) ?usize {
    var i: usize = 0;
    while (i < compat.kindCount()) : (i += 1) {
        const name = compat.kindName(i) orelse continue;
        if (std.mem.eql(u8, name, kind_name)) return i;
    }
    return null;
}

fn exportCompat(kind_name: []const u8, image_index: usize, out_name: []const u8, svg_buf: []u8) !void {
    const kind_idx = kindIndexByName(kind_name) orelse return error.UnknownKind;
    if (image_index >= compat.imageCount(kind_idx)) return error.ImageIndexOutOfRange;
    const svg = compat.generateByIndex(kind_idx, image_index, svg_buf);
    try writeSample(out_name, svg);
}

fn exportCompatByName(kind_name: []const u8, image_name: []const u8, out_name: []const u8, svg_buf: []u8) !void {
    const kind_idx = kindIndexByName(kind_name) orelse return error.UnknownKind;
    const count = compat.imageCount(kind_idx);
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const current = compat.imageName(kind_idx, i) orelse continue;
        if (!std.mem.eql(u8, current, image_name)) continue;
        const svg = compat.generateByIndex(kind_idx, i, svg_buf);
        try writeSample(out_name, svg);
        return;
    }
    return error.UnknownImageName;
}

pub fn main() !void {
    try std.fs.cwd().makePath(OUT_DIR);

    var compat_buf: [4 * 1024 * 1024]u8 = undefined;
    var core_buf: [512 * 1024]u8 = undefined;

    // Compatibility sample families (index-based to stay stable with manifest order).
    try exportCompat("opc", 0, "compat-opc.svg", &compat_buf);
    try exportCompat("optc", 0, "compat-optc.svg", &compat_buf);
    try exportCompat("oc", 0, "compat-oc.svg", &compat_buf);
    try exportCompat("even", 0, "compat-even.svg", &compat_buf);
    try exportCompat("scale", 0, "compat-scale.svg", &compat_buf);
    try exportCompat("eadgbe", 0, "compat-eadgbe.svg", &compat_buf);
    // Use a mid-register chord sample to avoid the clipped low-register quirk
    // in the first manifest entry (which is still preserved in compat parity tests).
    try exportCompatByName("chord", "C_3,E_3,G_3.svg", "compat-chord.svg", &compat_buf);
    try exportCompat("grand-chord", 0, "compat-grand-chord.svg", &compat_buf);

    // Core algorithmic graph renderers (non-compat wrappers).
    const major_triad = pcs.fromList(&[_]pitch.PitchClass{ 0, 4, 7 });
    try writeSample("core-opc.svg", svg_clock.renderOPC(major_triad, &core_buf));
    try writeSample("core-optc.svg", svg_clock.renderOPTC(major_triad, "037", &core_buf));

    const icon_spec = svg_mode_icon.ModeIconSpec{ .family = .diatonic, .transposition = 0, .degree = 1 };
    try writeSample("core-mode-icon.svg", svg_mode_icon.renderModeIcon(icon_spec, &core_buf));
    try writeSample("core-evenness.svg", svg_evenness.renderEvennessChart(&core_buf));
    try writeSample("core-tessellation.svg", svg_tessellation.renderScaleTessellation(&core_buf));
    try writeSample("core-orbifold.svg", svg_orbifold.renderTriadOrbifold(&core_buf));
    try writeSample("core-circle-of-fifths.svg", svg_cof.renderCircleOfFifths(&core_buf));

    std.debug.print("exported graph samples to {s}\n", .{OUT_DIR});
}
