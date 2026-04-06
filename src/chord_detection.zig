const chord = @import("chord_construction.zig");
const pcs = @import("pitch_class_set.zig");
const pitch = @import("pitch.zig");

pub const PatternId = enum(u8) {
    maj13,
    dominant13,
    min13,
    maj9_sharp11,
    dominant11,
    min11,
    six_nine,
    maj9,
    dominant9,
    min9,
    dominant7_flat9,
    dominant7_sharp9,
    dominant7_sharp11,
    dominant7_flat13,
    dominant7_alt,
    maj6,
    min6,
    add9,
    min_add9,
    add11,
    maj7,
    dominant7,
    min7,
    dim7,
    min7_flat5,
    min_maj7,
    aug7,
    aug_maj7,
    dominant7_sus4,
    dominant7_sus2,
    maj,
    min,
    dim,
    aug,
    sus4,
    sus2,
    power5,
};

pub const Pattern = struct {
    id: PatternId,
    name: []const u8,
    formula: []const u8,
    pcs: pcs.PitchClassSet,
    interval_count: u8,
};

pub const Match = struct {
    root: pitch.PitchClass,
    bass: pitch.PitchClass,
    bass_known: bool,
    root_is_bass: bool,
    bass_degree: u8,
    pattern: PatternId,
    interval_count: u8,
};

pub const MAX_MATCHES: usize = ALL_PATTERNS.len * 12;

pub const ALL_PATTERNS = [_]Pattern{
    makePattern(.maj13, "maj13", "1 3 5 7 9 13"),
    makePattern(.dominant13, "13", "1 3 5 b7 9 13"),
    makePattern(.min13, "min13", "1 b3 5 b7 9 13"),
    makePattern(.maj9_sharp11, "maj9#11", "1 3 5 7 9 #11"),
    makePattern(.dominant11, "11", "1 3 5 b7 9 11"),
    makePattern(.min11, "min11", "1 b3 5 b7 9 11"),
    makePattern(.six_nine, "6/9", "1 3 5 6 9"),
    makePattern(.maj9, "maj9", "1 3 5 7 9"),
    makePattern(.dominant9, "9", "1 3 5 b7 9"),
    makePattern(.min9, "min9", "1 b3 5 b7 9"),
    makePattern(.dominant7_flat9, "7b9", "1 3 5 b7 b9"),
    makePattern(.dominant7_sharp9, "7#9", "1 3 5 b7 #9"),
    makePattern(.dominant7_sharp11, "7#11", "1 3 5 b7 #11"),
    makePattern(.dominant7_flat13, "7b13", "1 3 5 b7 b13"),
    makePattern(.dominant7_alt, "7alt", "1 3 #5 b7 b9"),
    makePattern(.maj6, "maj6", "1 3 5 6"),
    makePattern(.min6, "min6", "1 b3 5 6"),
    makePattern(.add9, "add9", "1 3 5 9"),
    makePattern(.min_add9, "madd9", "1 b3 5 9"),
    makePattern(.add11, "add11", "1 3 5 11"),
    makePattern(.maj7, "maj7", "1 3 5 7"),
    makePattern(.dominant7, "7", "1 3 5 b7"),
    makePattern(.min7, "min7", "1 b3 5 b7"),
    makePattern(.dim7, "dim7", "1 b3 b5 6"),
    makePattern(.min7_flat5, "m7b5", "1 b3 b5 b7"),
    makePattern(.min_maj7, "minmaj7", "1 b3 5 7"),
    makePattern(.aug7, "aug7", "1 3 #5 b7"),
    makePattern(.aug_maj7, "augmaj7", "1 3 #5 7"),
    makePattern(.dominant7_sus4, "7sus4", "1 4 5 b7"),
    makePattern(.dominant7_sus2, "7sus2", "1 2 5 b7"),
    makePattern(.maj, "maj", "1 3 5"),
    makePattern(.min, "min", "1 b3 5"),
    makePattern(.dim, "dim", "1 b3 b5"),
    makePattern(.aug, "aug", "1 3 #5"),
    makePattern(.sus4, "sus4", "1 4 5"),
    makePattern(.sus2, "sus2", "1 2 5"),
    makePattern(.power5, "5", "1 5"),
};

pub fn count() usize {
    return ALL_PATTERNS.len;
}

pub fn pattern(id: PatternId) *const Pattern {
    return &ALL_PATTERNS[@intFromEnum(id)];
}

pub fn fromInt(raw: u8) ?PatternId {
    if (@as(usize, @intCast(raw)) >= ALL_PATTERNS.len) return null;
    return @enumFromInt(raw);
}

pub fn detectMatches(
    set: pcs.PitchClassSet,
    bass_known: bool,
    bass: pitch.PitchClass,
    out: []Match,
) u16 {
    if (set == 0) return 0;

    var roots_buf: [12]pitch.PitchClass = undefined;
    const roots = pcs.toList(set, &roots_buf);
    var scratch: [MAX_MATCHES]Match = undefined;
    var total: usize = 0;

    for (roots) |root| {
        const normalized = pcs.transposeDown(set, root);
        for (ALL_PATTERNS) |candidate| {
            if (candidate.pcs != normalized) continue;
            const bass_degree = if (bass_known) degreeForBass(candidate, root, bass) else 0;
            scratch[total] = .{
                .root = root,
                .bass = bass,
                .bass_known = bass_known,
                .root_is_bass = bass_known and bass == root,
                .bass_degree = bass_degree,
                .pattern = candidate.id,
                .interval_count = candidate.interval_count,
            };
            total += 1;
        }
    }

    sortMatches(scratch[0..total]);
    const write_count = @min(total, out.len);
    @memcpy(out[0..write_count], scratch[0..write_count]);
    return @as(u16, @intCast(total));
}

fn makePattern(comptime id: PatternId, comptime name: []const u8, comptime formula: []const u8) Pattern {
    @setEvalBranchQuota(10_000);
    return .{
        .id = id,
        .name = name,
        .formula = formula,
        .pcs = chord.formulaToPCS(formula),
        .interval_count = @as(u8, @intCast(pcs.cardinality(chord.formulaToPCS(formula)))),
    };
}

fn degreeForBass(candidate: Pattern, root: pitch.PitchClass, bass: pitch.PitchClass) u8 {
    const relative = pitch.wrapPitchClass(@as(i16, @intCast(bass)) - @as(i16, @intCast(root)));
    var intervals: [12]pitch.PitchClass = undefined;
    const interval_list = pcs.toList(candidate.pcs, &intervals);
    for (interval_list, 0..) |interval_pc, index| {
        if (interval_pc == relative) return @as(u8, @intCast(index + 1));
    }
    return 0;
}

fn sortMatches(matches: []Match) void {
    var i: usize = 1;
    while (i < matches.len) : (i += 1) {
        const current = matches[i];
        var j = i;
        while (j > 0 and comesBefore(current, matches[j - 1])) : (j -= 1) {
            matches[j] = matches[j - 1];
        }
        matches[j] = current;
    }
}

fn comesBefore(a: Match, b: Match) bool {
    if (a.interval_count != b.interval_count) return a.interval_count > b.interval_count;
    if (a.root_is_bass != b.root_is_bass) return a.root_is_bass;
    if (a.root != b.root) return a.root < b.root;
    return @intFromEnum(a.pattern) < @intFromEnum(b.pattern);
}

comptime {
    for (ALL_PATTERNS, 0..) |one, index| {
        if (@intFromEnum(one.id) != index) {
            @compileError("PatternId enum order must match ALL_PATTERNS order");
        }
    }
}
