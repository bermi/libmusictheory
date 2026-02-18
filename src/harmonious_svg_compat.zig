const std = @import("std");

const manifest = @import("generated/harmonious_manifest.zig");
const oc_templates = @import("generated/harmonious_oc_templates.zig");
const pitch = @import("pitch.zig");
const pcs = @import("pitch_class_set.zig");
const cluster = @import("cluster.zig");
const key = @import("key.zig");
const guitar = @import("guitar.zig");

const svg_clock = @import("svg/clock.zig");
const svg_fret_compat = @import("svg/fret_compat.zig");
const svg_staff = @import("svg/staff.zig");
const svg_chord_compat = @import("svg/chord_compat.zig");
const svg_scale_nomod_compat = @import("svg/scale_nomod_compat.zig");
const svg_text_misc = @import("svg/text_misc.zig");
const svg_evenness_chart = @import("svg/evenness_chart.zig");
const svg_majmin_compat = @import("svg/majmin_compat.zig");

pub const KindInfo = manifest.KindInfo;
pub const KindId = manifest.KindId;

pub fn kindCount() usize {
    return manifest.ALL_KINDS.len;
}

pub fn kindName(kind_index: usize) ?[]const u8 {
    const info = kindInfo(kind_index) orelse return null;
    return info.api_name;
}

pub fn kindDirectory(kind_index: usize) ?[]const u8 {
    const info = kindInfo(kind_index) orelse return null;
    return info.directory;
}

pub fn imageCount(kind_index: usize) usize {
    const info = kindInfo(kind_index) orelse return 0;
    return info.names.len;
}

pub fn imageName(kind_index: usize, image_index: usize) ?[]const u8 {
    const info = kindInfo(kind_index) orelse return null;
    if (image_index >= info.names.len) return null;
    return info.names[image_index];
}

pub fn generateByIndex(kind_index: usize, image_index: usize, buf: []u8) []u8 {
    const info = kindInfo(kind_index) orelse return "";
    if (image_index >= info.names.len) return "";
    return generateByName(kind_index, info.names[image_index], buf);
}

pub fn generateByName(kind_index: usize, image_name: []const u8, buf: []u8) []u8 {
    const info = kindInfo(kind_index) orelse return "";
    const stem = trimSvgSuffix(image_name);

    return switch (info.id) {
        .vert_text_black => svg_text_misc.renderVerticalLabel(stem, false, buf),
        .vert_text_b2t_black => svg_text_misc.renderVerticalLabel(stem, true, buf),
        .center_square_text => svg_text_misc.renderCenterSquareGlyph(stem, buf),
        .even => svg_evenness_chart.renderEvennessByName(stem, buf),
        .opc => renderOpcClock(stem, buf),
        .optc => renderOptcClock(stem, buf),
        .oc => renderModeIcon(stem, buf),
        .eadgbe => renderEadgbe(stem, buf),
        .chord => renderChordLike(stem, .chord, buf),
        .chord_clipped => renderChordLike(stem, .chord_clipped, buf),
        .wide_chord => renderChordLike(stem, .wide_chord, buf),
        .grand_chord => renderChordLike(stem, .grand_chord, buf),
        .scale => renderScaleStaff(stem, buf),
        .majmin_modes, .majmin_scales => renderMajmin(info, image_name, stem, buf),
    };
}

const ChordLikeKind = enum {
    chord,
    chord_clipped,
    wide_chord,
    grand_chord,
};

fn kindInfo(kind_index: usize) ?KindInfo {
    if (kind_index >= manifest.ALL_KINDS.len) return null;
    return manifest.ALL_KINDS[kind_index];
}

fn trimSvgSuffix(name: []const u8) []const u8 {
    if (std.mem.endsWith(u8, name, ".svg")) {
        return name[0 .. name.len - 4];
    }
    return name;
}

fn renderMajmin(info: KindInfo, image_name: []const u8, stem: []const u8, buf: []u8) []u8 {
    const image_index = findImageIndex(info.names, image_name, stem) orelse return renderFallback(info.api_name, stem, buf);
    return switch (info.id) {
        .majmin_modes => svg_majmin_compat.render(.modes, image_index, buf),
        .majmin_scales => svg_majmin_compat.render(.scales, image_index, buf),
        else => renderFallback(info.api_name, stem, buf),
    };
}

fn findImageIndex(names: []const []const u8, image_name: []const u8, stem: []const u8) ?usize {
    var i: usize = 0;
    while (i < names.len) : (i += 1) {
        if (std.mem.eql(u8, names[i], image_name)) return i;
    }

    i = 0;
    while (i < names.len) : (i += 1) {
        if (std.mem.eql(u8, trimSvgSuffix(names[i]), stem)) return i;
    }

    return null;
}

fn firstCsvField(text: []const u8) []const u8 {
    const idx = std.mem.indexOfScalar(u8, text, ',') orelse return text;
    return text[0..idx];
}

fn renderOpcClock(stem: []const u8, buf: []u8) []u8 {
    const label = firstCsvField(stem);
    const set = parseSetLabel(label) orelse return renderFallback("opc", stem, buf);
    return svg_clock.renderOPC(set, buf);
}

fn renderOptcClock(stem: []const u8, buf: []u8) []u8 {
    const args = parseOptcImageArgs(stem) orelse return renderFallback("optc", stem, buf);
    return svg_clock.renderOPTCHarmoniousCompat(
        args.set,
        args.label,
        .{
            .cluster_mask = args.cluster_mask,
            .dash_mask = args.dash_mask,
            .black_mask = args.black_mask,
        },
        buf,
    );
}

const OptcImageArgs = struct {
    label: []const u8,
    set: pcs.PitchClassSet,
    cluster_mask: pcs.PitchClassSet,
    dash_mask: pcs.PitchClassSet,
    black_mask: pcs.PitchClassSet,
};

fn parseOptcImageArgs(stem: []const u8) ?OptcImageArgs {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const label = parts.next() orelse return null;
    const set = parseSetLabel(label) orelse return null;

    var cluster_mask = cluster.getClusters(set).cluster_mask;
    var dash_mask: pcs.PitchClassSet = 0;
    var black_mask: pcs.PitchClassSet = 0;

    if (parts.next()) |cluster_mask_token| {
        cluster_mask = parseSetMaskToken(cluster_mask_token) orelse return null;
        const dash_mask_token = parts.next() orelse return null;
        const black_mask_token = parts.next() orelse return null;
        dash_mask = parseSetMaskToken(dash_mask_token) orelse return null;
        black_mask = parseSetMaskToken(black_mask_token) orelse return null;
        if (parts.next() != null) return null;
    }

    return .{
        .label = label,
        .set = set,
        .cluster_mask = cluster_mask,
        .dash_mask = dash_mask,
        .black_mask = black_mask,
    };
}

fn parseSetMaskToken(token: []const u8) ?pcs.PitchClassSet {
    if (token.len == 0) return null;
    const raw = std.fmt.parseInt(u16, token, 10) catch return null;
    if (raw > 0x0fff) return null;
    return @as(pcs.PitchClassSet, @intCast(raw));
}

fn parseSetLabel(label: []const u8) ?pcs.PitchClassSet {
    if (label.len == 0) return null;

    var set: pcs.PitchClassSet = 0;
    for (label) |ch| {
        const pc_opt: ?u4 = switch (ch) {
            '0'...'9' => @as(u4, @intCast(ch - '0')),
            'a', 'A', 't', 'T' => 10,
            'b', 'B', 'e', 'E' => 11,
            else => null,
        };
        const pc = pc_opt orelse return null;
        set |= @as(pcs.PitchClassSet, 1) << pc;
    }

    return set;
}

fn renderModeIcon(stem: []const u8, buf: []u8) []u8 {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const family_token = parts.next() orelse return renderFallback("oc", stem, buf);
    const transposition_token = parts.next() orelse return renderFallback("oc", stem, buf);
    const roman_token = parts.next() orelse return renderFallback("oc", stem, buf);

    const transposition = std.fmt.parseInt(i8, transposition_token, 10) catch return renderFallback("oc", stem, buf);
    const color = ocTranspositionColor(transposition);
    const tint = ocTranspositionTint(transposition);
    const template = findOcTemplate(family_token, roman_token) orelse return renderFallback("oc", stem, buf);

    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.writeAll("<svg id=\"todo1\" class=\"todo2\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0\" y=\"0\" width=\"70\" height=\"70\" viewBox=\"-7 -7 114 114\">\n") catch return "";
    w.writeAll("  <!-- Loaded SVG font from path \"./svg-fonts/Enhanced-CharterRegular.svg\" -->\n") catch return "";
    writeTemplateBody(w, template.body_template, color, tint) catch return "";
    w.writeAll("\n</svg>") catch return "";
    return buf[0..stream.pos];
}

fn ocTranspositionColor(transposition: i8) []const u8 {
    return switch (transposition) {
        -1 => "black",
        0 => "#00c",
        1 => "#a4f",
        2 => "#f0f",
        3 => "#a16",
        4 => "#e02",
        5 => "#f91",
        6 => "#c81",
        7 => "#094",
        8 => "#161",
        9 => "#077",
        10 => "#0bb",
        11 => "#28f",
        else => "black",
    };
}

fn ocTranspositionTint(transposition: i8) []const u8 {
    return switch (transposition) {
        0 => "#bbe",
        1 => "#dcf",
        2 => "#fbf",
        3 => "#dbc",
        4 => "#ebb",
        5 => "#fdb",
        6 => "#ffb",
        7 => "#beb",
        8 => "#bdc",
        9 => "#bee",
        10 => "#bff",
        11 => "#bdf",
        else => "#bbe",
    };
}

fn findOcTemplate(family: []const u8, roman: []const u8) ?oc_templates.OcTemplate {
    for (oc_templates.OC_TEMPLATES) |entry| {
        if (std.mem.eql(u8, entry.family, family) and std.mem.eql(u8, entry.roman, roman)) {
            return entry;
        }
    }
    return null;
}

fn writeTemplateBody(writer: anytype, body_template: []const u8, color: []const u8, tint: []const u8) !void {
    var parts = std.mem.splitSequence(u8, body_template, "__COLOR__");
    var first = true;
    while (parts.next()) |part| {
        if (!first) try writer.writeAll(color);
        first = false;
        var tint_parts = std.mem.splitSequence(u8, part, "#bbe");
        var tint_first = true;
        while (tint_parts.next()) |tint_part| {
            if (!tint_first) try writer.writeAll(tint);
            tint_first = false;
            try writer.writeAll(tint_part);
        }
    }
}

fn renderEadgbe(stem: []const u8, buf: []u8) []u8 {
    if (std.mem.eql(u8, stem, "index")) {
        return svg_fret_compat.renderIndex(buf);
    }

    var frets: [guitar.NUM_STRINGS]i8 = [_]i8{-1} ** guitar.NUM_STRINGS;
    var parts = std.mem.splitScalar(u8, stem, ',');
    var i: usize = 0;
    while (parts.next()) |token| {
        if (i >= guitar.NUM_STRINGS) break;
        frets[i] = std.fmt.parseInt(i8, token, 10) catch -1;
        i += 1;
    }

    if (i != guitar.NUM_STRINGS) {
        frets = [_]i8{ -1, 3, 2, 0, 1, 0 };
    }

    return svg_fret_compat.render(frets, buf);
}

fn renderChordLike(stem: []const u8, kind: ChordLikeKind, buf: []u8) []u8 {
    const compat_kind: svg_chord_compat.Kind = switch (kind) {
        .chord => .chord,
        .chord_clipped => .chord_clipped,
        .wide_chord => .wide_chord,
        .grand_chord => .grand_chord,
    };
    const compat_svg = svg_chord_compat.render(stem, compat_kind, buf);
    if (compat_svg.len > 0) return compat_svg;
    return renderFallback("chord", stem, buf);
}

fn renderScaleStaff(stem: []const u8, buf: []u8) []u8 {
    const compat_svg = svg_scale_nomod_compat.render(stem, buf);
    if (compat_svg.len > 0) return compat_svg;

    var parts = std.mem.splitScalar(u8, stem, ',');
    const key_token = parts.next() orelse return renderFallback("scale", stem, buf);

    var notes_buf: [12]pitch.MidiNote = undefined;
    var count: usize = 0;
    while (parts.next()) |token| {
        if (count >= notes_buf.len) break;
        const midi = parseMidiToken(token) orelse continue;
        notes_buf[count] = midi;
        count += 1;
    }

    if (count == 0) return renderFallback("scale", stem, buf);

    const key_pc = parsePitchClassToken(key_token) orelse @as(pitch.PitchClass, @intCast(notes_buf[0] % 12));
    const k = key.Key.init(key_pc, .major);

    return svg_staff.renderScaleStaff(notes_buf[0..count], k, buf);
}

fn parseMidiList(stem: []const u8, out: *[12]pitch.MidiNote) []pitch.MidiNote {
    var parts = std.mem.splitScalar(u8, stem, ',');
    var count: usize = 0;

    while (parts.next()) |token| {
        if (count >= out.len) break;
        const midi = parseMidiToken(token) orelse continue;
        out[count] = midi;
        count += 1;
    }

    return out[0..count];
}

fn parseMidiToken(token: []const u8) ?pitch.MidiNote {
    const sep = std.mem.lastIndexOfScalar(u8, token, '_') orelse std.mem.lastIndexOfScalar(u8, token, '-') orelse return null;
    if (sep + 1 >= token.len) return null;

    const pc_token = token[0..sep];
    const octave_token = token[sep + 1 ..];

    const class = parsePitchClassToken(pc_token) orelse return null;
    const octave = std.fmt.parseInt(i8, octave_token, 10) catch return null;

    return pitch.pcToMidi(class, octave);
}

fn parsePitchClassToken(token: []const u8) ?pitch.PitchClass {
    if (token.len == 0) return null;

    const letter = std.ascii.toUpper(token[0]);
    const base: i16 = switch (letter) {
        'C' => 0,
        'D' => 2,
        'E' => 4,
        'F' => 5,
        'G' => 7,
        'A' => 9,
        'B' => 11,
        else => return null,
    };

    var offset: i16 = 0;
    for (token[1..]) |ch| {
        switch (ch) {
            'b', 'B' => offset -= 1,
            's', 'S', '#' => offset += 1,
            'n', 'N' => {},
            else => return null,
        }
    }

    return pitch.wrapPitchClass(base + offset);
}

fn renderFallback(kind_name: []const u8, stem: []const u8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    w.writeAll("<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"420\" height=\"56\" viewBox=\"0 0 420 56\">\n") catch return "";
    w.writeAll("<rect x=\"0\" y=\"0\" width=\"420\" height=\"56\" fill=\"#fff\" stroke=\"#bbb\" />\n") catch return "";
    w.print("<text x=\"8\" y=\"34\" font-size=\"12\" fill=\"#444\">{s}:{s}</text>\n", .{ kind_name, stem }) catch return "";
    w.writeAll("</svg>\n") catch return "";

    return buf[0..stream.pos];
}
