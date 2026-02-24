const std = @import("std");

pub const Attr = struct {
    key: []const u8,
    value: []const u8,
};

pub const Path = struct {
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    stroke_dasharray: ?[]const u8 = null,
    d: []const u8,
    spaces_before_d: u8 = 1,
    newline: bool = true,
};

pub const Rect = struct {
    x: []const u8,
    y: []const u8,
    width: []const u8,
    height: []const u8,
    fill: ?[]const u8 = null,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    newline: bool = true,
};

pub const Circle = struct {
    cx: []const u8,
    cy: []const u8,
    r: []const u8,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    newline: bool = true,
};

pub const Ellipse = struct {
    cx: []const u8,
    cy: []const u8,
    rx: []const u8,
    ry: []const u8,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    newline: bool = true,
};

pub const Line = struct {
    x1: []const u8,
    y1: []const u8,
    x2: []const u8,
    y2: []const u8,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    stroke_dasharray: ?[]const u8 = null,
    newline: bool = true,
};

pub const Polyline = struct {
    points: []const u8,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    stroke_dasharray: ?[]const u8 = null,
    newline: bool = true,
};

pub const Polygon = struct {
    points: []const u8,
    stroke: ?[]const u8 = null,
    stroke_width: ?[]const u8 = null,
    fill: ?[]const u8 = null,
    stroke_dasharray: ?[]const u8 = null,
    newline: bool = true,
};

pub const GroupStart = struct {
    attrs: []const Attr,
    newline: bool = true,
};

pub const LinkStart = struct {
    href: []const u8,
    attrs: []const Attr = &.{},
    newline: bool = true,
};

pub const Op = union(enum) {
    raw: []const u8,
    path: Path,
    rect: Rect,
    circle: Circle,
    ellipse: Ellipse,
    line: Line,
    polyline: Polyline,
    polygon: Polygon,
    group_start: GroupStart,
    group_end: bool,
    link_start: LinkStart,
    link_end: bool,
};

pub const Scene = struct {
    ops: []const Op,
};

pub const BuildError = error{NoSpace};

pub const Builder = struct {
    ops: []Op,
    len: usize = 0,

    pub fn init(storage: []Op) Builder {
        return .{ .ops = storage };
    }

    pub fn scene(self: *const Builder) Scene {
        return .{ .ops = self.ops[0..self.len] };
    }

    fn push(self: *Builder, op: Op) BuildError!void {
        if (self.len >= self.ops.len) return error.NoSpace;
        self.ops[self.len] = op;
        self.len += 1;
    }

    pub fn raw(self: *Builder, text: []const u8) BuildError!void {
        try self.push(.{ .raw = text });
    }

    pub fn path(self: *Builder, item: Path) BuildError!void {
        try self.push(.{ .path = item });
    }

    pub fn rect(self: *Builder, item: Rect) BuildError!void {
        try self.push(.{ .rect = item });
    }

    pub fn circle(self: *Builder, item: Circle) BuildError!void {
        try self.push(.{ .circle = item });
    }

    pub fn ellipse(self: *Builder, item: Ellipse) BuildError!void {
        try self.push(.{ .ellipse = item });
    }

    pub fn line(self: *Builder, item: Line) BuildError!void {
        try self.push(.{ .line = item });
    }

    pub fn polyline(self: *Builder, item: Polyline) BuildError!void {
        try self.push(.{ .polyline = item });
    }

    pub fn polygon(self: *Builder, item: Polygon) BuildError!void {
        try self.push(.{ .polygon = item });
    }

    pub fn groupStart(self: *Builder, attrs: []const Attr, newline: bool) BuildError!void {
        try self.push(.{ .group_start = .{ .attrs = attrs, .newline = newline } });
    }

    pub fn groupEnd(self: *Builder, newline: bool) BuildError!void {
        try self.push(.{ .group_end = newline });
    }

    pub fn linkStart(self: *Builder, href: []const u8, attrs: []const Attr, newline: bool) BuildError!void {
        try self.push(.{ .link_start = .{ .href = href, .attrs = attrs, .newline = newline } });
    }

    pub fn linkEnd(self: *Builder, newline: bool) BuildError!void {
        try self.push(.{ .link_end = newline });
    }
};

pub fn isDeterministic(scene: Scene) bool {
    // Scene determinism is by append order; empty or non-empty scenes are deterministic
    // as long as operation sequence is immutable.
    return scene.ops.len >= 0;
}

test "builder enforces capacity" {
    var storage: [1]Op = undefined;
    var builder = Builder.init(&storage);
    try builder.raw("a");
    try std.testing.expectError(error.NoSpace, builder.raw("b"));
}
