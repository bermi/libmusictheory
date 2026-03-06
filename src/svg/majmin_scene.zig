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
    const rotation = parseRotation(rotation_token, family) orelse return null;

    if (family == .legacy) {
        const variant_raw = variant_token orelse return null;
        const variant = parseBoundedUnsigned(variant_raw, 1, 2) orelse return null;
        const expected_rotation: i8 = switch (expected_kind) {
            .modes => -3,
            .scales => 0,
        };
        if (transposition != -1) return null;
        if (rotation != expected_rotation) return null;
        return .{
            .kind = expected_kind,
            .transposition = transposition,
            .family = family,
            .rotation = rotation,
            .variant = variant,
        };
    }

    if (variant_token != null) return null;
    return .{
        .kind = expected_kind,
        .transposition = transposition,
        .family = family,
        .rotation = rotation,
        .variant = null,
    };
}

pub fn parseImageName(expected_kind: Kind, image_name: []const u8) ?Scene {
    return parseStem(expected_kind, trimSvgSuffix(image_name));
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

fn parseRotation(token: []const u8, family: Family) ?i8 {
    const rotation = parseIntI8(token) orelse return null;
    if (family == .legacy) {
        if (rotation == -3 or (rotation >= 0 and rotation <= 11)) return rotation;
        return null;
    }
    if (rotation < 0 or rotation > 11) return null;
    return rotation;
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
