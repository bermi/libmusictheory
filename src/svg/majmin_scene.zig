const std = @import("std");

pub const Kind = enum {
    modes,
    scales,
};

pub const Family = enum {
    legacy,
    dntri,
    hex,
    rhomb,
    uptri,
};

pub const Scene = struct {
    kind: Kind,
    transposition: i8,
    family: Family,
    rotation: i8,
    variant: ?u8,
};

pub fn parseStem(expected_kind: Kind, stem: []const u8) ?Scene {
    var parts = std.mem.splitScalar(u8, stem, ',');
    const kind_token = parts.next() orelse return null;
    const transposition_token = parts.next() orelse return null;
    const family_token = parts.next() orelse return null;
    const rotation_token = parts.next() orelse return null;
    const variant_token = parts.next();
    if (parts.next() != null) return null;

    if (!kindTokenMatches(expected_kind, kind_token)) return null;

    const transposition = parseBoundedInt(transposition_token, -1, 11) orelse return null;
    const family = parseFamily(family_token) orelse return null;
    const rotation = parseIntI8(rotation_token) orelse return null;

    if (family == .legacy) {
        const variant_raw = variant_token orelse return null;
        const variant = parseBoundedUnsigned(variant_raw, 1, 2) orelse return null;
        const expected_rotation: i8 = switch (expected_kind) {
            .modes => -3,
            .scales => 0,
        };
        if (transposition != -1) return null;
        if (rotation != expected_rotation) return null;
        const parsed: Scene = .{
            .kind = expected_kind,
            .transposition = transposition,
            .family = family,
            .rotation = rotation,
            .variant = variant,
        };
        if (!isValidScene(parsed)) return null;
        return parsed;
    }

    if (variant_token != null) return null;
    const parsed: Scene = .{
        .kind = expected_kind,
        .transposition = transposition,
        .family = family,
        .rotation = rotation,
        .variant = null,
    };
    if (!isValidScene(parsed)) return null;
    return parsed;
}

pub fn parseImageName(expected_kind: Kind, image_name: []const u8) ?Scene {
    return parseStem(expected_kind, trimSvgSuffix(image_name));
}

pub fn isValidScene(scene: Scene) bool {
    if (scene.transposition < -1 or scene.transposition > 11) return false;

    if (scene.family == .legacy) {
        const expected_rotation: i8 = switch (scene.kind) {
            .modes => -3,
            .scales => 0,
        };
        if (scene.transposition != -1) return false;
        if (scene.rotation != expected_rotation) return false;
        const variant = scene.variant orelse return false;
        return variant >= 1 and variant <= 2;
    }

    if (scene.variant != null) return false;
    if (scene.rotation < 0 or scene.rotation > 11) return false;
    if (scene.kind == .scales and scene.transposition < 0) return false;
    return isAllowedRotation(scene.kind, scene.family, scene.rotation);
}

pub fn formatStem(scene: Scene, out: []u8) ?[]const u8 {
    if (!isValidScene(scene)) return null;
    var stream = std.io.fixedBufferStream(out);
    const w = stream.writer();

    w.writeAll(switch (scene.kind) {
        .modes => "modes,",
        .scales => "scales,",
    }) catch return null;
    w.print("{d},", .{scene.transposition}) catch return null;
    w.writeAll(switch (scene.family) {
        .legacy => "",
        .dntri => "dntri",
        .hex => "hex",
        .rhomb => "rhomb",
        .uptri => "uptri",
    }) catch return null;
    w.print(",{d}", .{scene.rotation}) catch return null;

    if (scene.family == .legacy) {
        const variant = scene.variant orelse return null;
        w.print(",{d}", .{variant}) catch return null;
    }

    return out[0..stream.pos];
}

fn trimSvgSuffix(name: []const u8) []const u8 {
    if (std.mem.endsWith(u8, name, ".svg")) {
        return name[0 .. name.len - 4];
    }
    return name;
}

fn kindTokenMatches(kind: Kind, token: []const u8) bool {
    return switch (kind) {
        .modes => std.mem.eql(u8, token, "modes"),
        .scales => std.mem.eql(u8, token, "scales"),
    };
}

fn parseFamily(token: []const u8) ?Family {
    if (token.len == 0) return .legacy;
    if (std.mem.eql(u8, token, "dntri")) return .dntri;
    if (std.mem.eql(u8, token, "hex")) return .hex;
    if (std.mem.eql(u8, token, "rhomb")) return .rhomb;
    if (std.mem.eql(u8, token, "uptri")) return .uptri;
    return null;
}

fn isAllowedRotation(kind: Kind, family: Family, rotation: i8) bool {
    return switch (kind) {
        .modes => switch (family) {
            .legacy => rotation == -3,
            .dntri => rotation == 0 or rotation == 1 or rotation == 3 or rotation == 4 or rotation == 7 or rotation == 10 or rotation == 11,
            .hex => rotation == 0 or rotation == 1 or rotation == 7 or rotation == 8 or rotation == 9 or rotation == 10 or rotation == 11,
            .rhomb => rotation == 0 or rotation == 1 or rotation == 3 or rotation == 7 or rotation == 9 or rotation == 10 or rotation == 11,
            .uptri => rotation == 0 or rotation == 1 or rotation == 4 or rotation == 7 or rotation == 8 or rotation == 10 or rotation == 11,
        },
        .scales => switch (family) {
            .legacy => rotation == 0,
            .dntri, .hex, .rhomb, .uptri => rotation >= 0 and rotation <= 11,
        },
    };
}

fn parseBoundedInt(token: []const u8, min: i8, max: i8) ?i8 {
    const value = parseIntI8(token) orelse return null;
    if (value < min or value > max) return null;
    return value;
}

fn parseBoundedUnsigned(token: []const u8, min: u8, max: u8) ?u8 {
    if (token.len == 0) return null;
    const value = std.fmt.parseInt(u8, token, 10) catch return null;
    if (value < min or value > max) return null;
    return value;
}

fn parseIntI8(token: []const u8) ?i8 {
    if (token.len == 0) return null;
    return std.fmt.parseInt(i8, token, 10) catch null;
}
