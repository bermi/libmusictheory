const pitch = @import("pitch.zig");

pub const KeyQuality = enum {
    major,
    minor,
};

pub const SignatureType = enum {
    natural,
    sharps,
    flats,
};

pub const KeySignature = struct {
    kind: SignatureType,
    count: u4,
};

pub const SignatureInfo = struct {
    tonic: pitch.PitchClass,
    quality: KeyQuality,
    signature: KeySignature,
};

pub const MAJOR_SIGNATURES = [_]SignatureInfo{
    .{ .tonic = pitch.pc.C, .quality = .major, .signature = .{ .kind = .natural, .count = 0 } },
    .{ .tonic = pitch.pc.G, .quality = .major, .signature = .{ .kind = .sharps, .count = 1 } },
    .{ .tonic = pitch.pc.D, .quality = .major, .signature = .{ .kind = .sharps, .count = 2 } },
    .{ .tonic = pitch.pc.A, .quality = .major, .signature = .{ .kind = .sharps, .count = 3 } },
    .{ .tonic = pitch.pc.E, .quality = .major, .signature = .{ .kind = .sharps, .count = 4 } },
    .{ .tonic = pitch.pc.B, .quality = .major, .signature = .{ .kind = .sharps, .count = 5 } },
    .{ .tonic = pitch.pc.Fs, .quality = .major, .signature = .{ .kind = .sharps, .count = 6 } },
    .{ .tonic = pitch.pc.Cs, .quality = .major, .signature = .{ .kind = .sharps, .count = 7 } },
    .{ .tonic = pitch.pc.F, .quality = .major, .signature = .{ .kind = .flats, .count = 1 } },
    .{ .tonic = pitch.pc.As, .quality = .major, .signature = .{ .kind = .flats, .count = 2 } },
    .{ .tonic = pitch.pc.Ds, .quality = .major, .signature = .{ .kind = .flats, .count = 3 } },
    .{ .tonic = pitch.pc.Gs, .quality = .major, .signature = .{ .kind = .flats, .count = 4 } },
    .{ .tonic = pitch.pc.Cs, .quality = .major, .signature = .{ .kind = .flats, .count = 5 } },
    .{ .tonic = pitch.pc.Fs, .quality = .major, .signature = .{ .kind = .flats, .count = 6 } },
    .{ .tonic = pitch.pc.B, .quality = .major, .signature = .{ .kind = .flats, .count = 7 } },
};

pub fn fromTonic(tonic: pitch.PitchClass, quality: KeyQuality) KeySignature {
    const major_tonic = switch (quality) {
        .major => tonic,
        .minor => @as(pitch.PitchClass, @intCast((tonic + 3) % 12)),
    };

    return switch (major_tonic) {
        pitch.pc.C => .{ .kind = .natural, .count = 0 },
        pitch.pc.G => .{ .kind = .sharps, .count = 1 },
        pitch.pc.D => .{ .kind = .sharps, .count = 2 },
        pitch.pc.A => .{ .kind = .sharps, .count = 3 },
        pitch.pc.E => .{ .kind = .sharps, .count = 4 },
        pitch.pc.B => .{ .kind = .sharps, .count = 5 },
        pitch.pc.Fs => .{ .kind = .sharps, .count = 6 },
        pitch.pc.Cs => .{ .kind = .flats, .count = 5 },
        pitch.pc.Gs => .{ .kind = .flats, .count = 4 },
        pitch.pc.Ds => .{ .kind = .flats, .count = 3 },
        pitch.pc.As => .{ .kind = .flats, .count = 2 },
        pitch.pc.F => .{ .kind = .flats, .count = 1 },
        else => .{ .kind = .natural, .count = 0 },
    };
}
