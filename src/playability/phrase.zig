const std = @import("std");
const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const fret_assessment = @import("fret_assessment.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");
const types = @import("types.zig");

pub const MAX_PHRASE_EVENTS: usize = 64;
pub const NONE_EVENT_INDEX: u16 = std.math.maxInt(u16);
pub const NONE_FAMILY_INDEX: u8 = std.math.maxInt(u8);

pub const KeyboardPhraseEvent = struct {
    note_count: u8,
    hand: keyboard_assessment.HandRole,
    reserved0: u8,
    reserved1: u8,
    notes: [keyboard_assessment.MAX_FINGERING_NOTES]pitch.MidiNote,

    pub fn init(notes: []const pitch.MidiNote, hand: keyboard_assessment.HandRole) KeyboardPhraseEvent {
        var out = KeyboardPhraseEvent{
            .note_count = @as(u8, @intCast(@min(notes.len, keyboard_assessment.MAX_FINGERING_NOTES))),
            .hand = hand,
            .reserved0 = 0,
            .reserved1 = 0,
            .notes = [_]pitch.MidiNote{0} ** keyboard_assessment.MAX_FINGERING_NOTES,
        };
        @memcpy(out.notes[0..out.note_count], notes[0..out.note_count]);
        return out;
    }
};

pub const FretPhraseEvent = struct {
    fret_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    frets: [guitar.MAX_GENERIC_STRINGS]i8,

    pub fn init(frets: []const i8) FretPhraseEvent {
        var out = FretPhraseEvent{
            .fret_count = @as(u8, @intCast(@min(frets.len, guitar.MAX_GENERIC_STRINGS))),
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .frets = [_]i8{-1} ** guitar.MAX_GENERIC_STRINGS,
        };
        @memcpy(out.frets[0..out.fret_count], frets[0..out.fret_count]);
        return out;
    }
};

pub const IssueScope = enum(u8) {
    event = 0,
    transition = 1,
};

pub const ISSUE_SCOPE_NAMES = [_][]const u8{
    "event",
    "transition",
};

pub const IssueSeverity = enum(u8) {
    advisory = 0,
    warning = 1,
    blocked = 2,
};

pub const ISSUE_SEVERITY_NAMES = [_][]const u8{
    "advisory",
    "warning",
    "blocked",
};

pub const FamilyDomain = enum(u8) {
    none = 0,
    playability_reason = 1,
    playability_warning = 2,
    fret_blocker = 3,
    keyboard_blocker = 4,
};

pub const FAMILY_DOMAIN_NAMES = [_][]const u8{
    "none",
    "playability reason",
    "playability warning",
    "fret blocker",
    "keyboard blocker",
};

pub const StrainBucket = enum(u8) {
    neutral = 0,
    elevated = 1,
    high = 2,
    blocked = 3,
};

pub const STRAIN_BUCKET_NAMES = [_][]const u8{
    "neutral",
    "elevated",
    "high",
    "blocked",
};

pub const PhraseIssue = struct {
    scope: IssueScope,
    severity: IssueSeverity,
    family_domain: FamilyDomain,
    family_index: u8,
    event_index: u16,
    related_event_index: u16,
    magnitude: u16,
    reserved0: u16,

    pub fn eventIssue(
        severity: IssueSeverity,
        family_domain: FamilyDomain,
        family_index: u8,
        event_index: u16,
        magnitude: u16,
    ) PhraseIssue {
        return .{
            .scope = .event,
            .severity = severity,
            .family_domain = family_domain,
            .family_index = family_index,
            .event_index = event_index,
            .related_event_index = NONE_EVENT_INDEX,
            .magnitude = magnitude,
            .reserved0 = 0,
        };
    }

    pub fn transitionIssue(
        severity: IssueSeverity,
        family_domain: FamilyDomain,
        family_index: u8,
        from_event_index: u16,
        to_event_index: u16,
        magnitude: u16,
    ) PhraseIssue {
        return .{
            .scope = .transition,
            .severity = severity,
            .family_domain = family_domain,
            .family_index = family_index,
            .event_index = from_event_index,
            .related_event_index = to_event_index,
            .magnitude = magnitude,
            .reserved0 = 0,
        };
    }
};

pub const PhraseSummary = struct {
    event_count: u16,
    issue_count: u16,
    first_blocked_event_index: u16,
    first_blocked_transition_from_index: u16,
    first_blocked_transition_to_index: u16,
    bottleneck_issue_index: u16,
    bottleneck_magnitude: u16,
    bottleneck_severity: IssueSeverity,
    bottleneck_domain: FamilyDomain,
    bottleneck_family_index: u8,
    strain_bucket: StrainBucket,
    dominant_reason_family: u8,
    dominant_warning_family: u8,
    reserved0: u8,
    severity_counts: [3]u16,
    reason_family_counts: [types.REASON_NAMES.len]u16,
    warning_family_counts: [types.WARNING_NAMES.len]u16,
    recovery_deficit_start_index: u16,
    recovery_deficit_end_index: u16,
    longest_recovery_deficit_run: u16,

    pub fn empty(event_count: usize) PhraseSummary {
        return .{
            .event_count = @as(u16, @intCast(@min(event_count, MAX_PHRASE_EVENTS))),
            .issue_count = 0,
            .first_blocked_event_index = NONE_EVENT_INDEX,
            .first_blocked_transition_from_index = NONE_EVENT_INDEX,
            .first_blocked_transition_to_index = NONE_EVENT_INDEX,
            .bottleneck_issue_index = NONE_EVENT_INDEX,
            .bottleneck_magnitude = 0,
            .bottleneck_severity = .advisory,
            .bottleneck_domain = .none,
            .bottleneck_family_index = NONE_FAMILY_INDEX,
            .strain_bucket = .neutral,
            .dominant_reason_family = NONE_FAMILY_INDEX,
            .dominant_warning_family = NONE_FAMILY_INDEX,
            .reserved0 = 0,
            .severity_counts = [_]u16{0} ** 3,
            .reason_family_counts = [_]u16{0} ** types.REASON_NAMES.len,
            .warning_family_counts = [_]u16{0} ** types.WARNING_NAMES.len,
            .recovery_deficit_start_index = NONE_EVENT_INDEX,
            .recovery_deficit_end_index = NONE_EVENT_INDEX,
            .longest_recovery_deficit_run = 0,
        };
    }
};

pub const SummaryAccumulator = struct {
    summary: PhraseSummary,
    strain_mask: u64,
    relief_mask: u64,

    pub fn init(event_count: usize) SummaryAccumulator {
        return .{
            .summary = PhraseSummary.empty(event_count),
            .strain_mask = 0,
            .relief_mask = 0,
        };
    }

    pub fn observeIssue(self: *SummaryAccumulator, issue: PhraseIssue, issue_index: usize) void {
        const bounded_event_count = self.summary.event_count;
        if (bounded_event_count == 0) return;

        const target_index = issueTargetIndex(issue);
        if (target_index == NONE_EVENT_INDEX or target_index >= bounded_event_count) return;
        if (issue.scope == .transition and (issue.event_index >= bounded_event_count or issue.related_event_index >= bounded_event_count)) return;

        self.summary.issue_count +|= 1;
        self.summary.severity_counts[@intFromEnum(issue.severity)] +|= 1;

        switch (issue.family_domain) {
            .playability_reason => {
                if (issue.family_index < types.REASON_NAMES.len) {
                    self.summary.reason_family_counts[issue.family_index] +|= 1;
                }
                markEvent(&self.relief_mask, target_index);
            },
            .playability_warning => {
                if (issue.family_index < types.WARNING_NAMES.len) {
                    self.summary.warning_family_counts[issue.family_index] +|= 1;
                }
            },
            .fret_blocker, .keyboard_blocker, .none => {},
        }

        if (issue.severity != .advisory) {
            markEvent(&self.strain_mask, target_index);
        }

        if (issue.severity == .blocked) {
            if (issue.scope == .event and self.summary.first_blocked_event_index == NONE_EVENT_INDEX) {
                self.summary.first_blocked_event_index = issue.event_index;
            }
            if (issue.scope == .transition and self.summary.first_blocked_transition_from_index == NONE_EVENT_INDEX) {
                self.summary.first_blocked_transition_from_index = issue.event_index;
                self.summary.first_blocked_transition_to_index = issue.related_event_index;
            }
        }

        if (self.summary.bottleneck_issue_index == NONE_EVENT_INDEX or shouldPromoteBottleneck(issue, issue_index, self.summary)) {
            self.summary.bottleneck_issue_index = @as(u16, @intCast(@min(issue_index, std.math.maxInt(u16))));
            self.summary.bottleneck_magnitude = issue.magnitude;
            self.summary.bottleneck_severity = issue.severity;
            self.summary.bottleneck_domain = issue.family_domain;
            self.summary.bottleneck_family_index = issue.family_index;
        }
    }

    pub fn finish(self: *SummaryAccumulator) PhraseSummary {
        self.summary.dominant_reason_family = dominantFamily(self.summary.reason_family_counts[0..]);
        self.summary.dominant_warning_family = dominantFamily(self.summary.warning_family_counts[0..]);

        const bounded_mask = eventMask(self.summary.event_count);
        const deficit_mask = (self.strain_mask & ~self.relief_mask) & bounded_mask;
        const run = longestRun(deficit_mask, self.summary.event_count);
        self.summary.recovery_deficit_start_index = run.start_index;
        self.summary.recovery_deficit_end_index = run.end_index;
        self.summary.longest_recovery_deficit_run = run.length;
        self.summary.strain_bucket = deriveStrainBucket(self.summary);
        return self.summary;
    }
};

pub fn summarizeIssues(event_count: usize, issues: []const PhraseIssue) PhraseSummary {
    var accumulator = SummaryAccumulator.init(event_count);
    for (issues, 0..) |issue, issue_index| {
        accumulator.observeIssue(issue, issue_index);
    }
    return accumulator.finish();
}

fn issueTargetIndex(issue: PhraseIssue) u16 {
    return switch (issue.scope) {
        .event => issue.event_index,
        .transition => issue.related_event_index,
    };
}

fn shouldPromoteBottleneck(issue: PhraseIssue, issue_index: usize, summary: PhraseSummary) bool {
    const current_rank = severityRank(summary.bottleneck_severity);
    const incoming_rank = severityRank(issue.severity);
    if (incoming_rank != current_rank) return incoming_rank > current_rank;
    if (issue.magnitude != summary.bottleneck_magnitude) return issue.magnitude > summary.bottleneck_magnitude;
    return issue_index < summary.bottleneck_issue_index;
}

fn severityRank(severity: IssueSeverity) u8 {
    return switch (severity) {
        .advisory => 0,
        .warning => 1,
        .blocked => 2,
    };
}

fn markEvent(mask: *u64, event_index: u16) void {
    if (event_index >= MAX_PHRASE_EVENTS) return;
    mask.* |= (@as(u64, 1) << @as(u6, @intCast(event_index)));
}

fn dominantFamily(counts: []const u16) u8 {
    var best_index: u8 = NONE_FAMILY_INDEX;
    var best_count: u16 = 0;
    for (counts, 0..) |count, index| {
        if (count == 0) continue;
        if (count > best_count) {
            best_count = count;
            best_index = @as(u8, @intCast(index));
        }
    }
    return best_index;
}

const RunSummary = struct {
    start_index: u16,
    end_index: u16,
    length: u16,
};

fn longestRun(mask: u64, event_count: u16) RunSummary {
    var best = RunSummary{
        .start_index = NONE_EVENT_INDEX,
        .end_index = NONE_EVENT_INDEX,
        .length = 0,
    };
    var current_start: u16 = NONE_EVENT_INDEX;
    var current_length: u16 = 0;

    var index: u16 = 0;
    while (index < event_count) : (index += 1) {
        const active = (mask & (@as(u64, 1) << @as(u6, @intCast(index)))) != 0;
        if (active) {
            if (current_length == 0) current_start = index;
            current_length += 1;
            if (current_length > best.length) {
                best = .{
                    .start_index = current_start,
                    .end_index = index,
                    .length = current_length,
                };
            }
        } else {
            current_start = NONE_EVENT_INDEX;
            current_length = 0;
        }
    }

    return best;
}

fn eventMask(event_count: u16) u64 {
    if (event_count == 0) return 0;
    if (event_count >= 64) return std.math.maxInt(u64);
    return (@as(u64, 1) << @as(u6, @intCast(event_count))) - 1;
}

fn deriveStrainBucket(summary: PhraseSummary) StrainBucket {
    if (summary.severity_counts[@intFromEnum(IssueSeverity.blocked)] > 0) return .blocked;
    if (summary.longest_recovery_deficit_run >= 3 or summary.severity_counts[@intFromEnum(IssueSeverity.warning)] >= 3) return .high;
    if (summary.severity_counts[@intFromEnum(IssueSeverity.warning)] > 0) return .elevated;
    return .neutral;
}

test "keyboard phrase event clips notes to fingering capacity" {
    const event = KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 64, 67, 71, 74, 77 }, .right);
    try std.testing.expectEqual(@as(u8, keyboard_assessment.MAX_FINGERING_NOTES), event.note_count);
    try std.testing.expectEqual(@as(pitch.MidiNote, 74), event.notes[4]);
}

test "fret phrase event fills unused strings with sentinel" {
    const event = FretPhraseEvent.init(&[_]i8{ 3, 2, 0, 0 });
    try std.testing.expectEqual(@as(u8, 4), event.fret_count);
    try std.testing.expectEqual(@as(i8, -1), event.frets[6]);
}

test "phrase summary tracks blocked transitions and recovery deficit runs" {
    const issues = [_]PhraseIssue{
        PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.reachable_in_current_window), 0, 0),
        PhraseIssue.eventIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.shift_required), 1, 3),
        PhraseIssue.transitionIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.excessive_longitudinal_shift), 1, 2, 5),
        PhraseIssue.transitionIssue(.blocked, .keyboard_blocker, @intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit), 2, 3, 8),
        PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.open_string_relief), 4, 0),
    };

    const summary = summarizeIssues(5, issues[0..]);
    try std.testing.expectEqual(@as(u16, 5), summary.event_count);
    try std.testing.expectEqual(@as(u16, 5), summary.issue_count);
    try std.testing.expectEqual(NONE_EVENT_INDEX, summary.first_blocked_event_index);
    try std.testing.expectEqual(@as(u16, 2), summary.first_blocked_transition_from_index);
    try std.testing.expectEqual(@as(u16, 3), summary.first_blocked_transition_to_index);
    try std.testing.expectEqual(IssueSeverity.blocked, summary.bottleneck_severity);
    try std.testing.expectEqual(FamilyDomain.keyboard_blocker, summary.bottleneck_domain);
    try std.testing.expectEqual(@as(u8, @intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit)), summary.bottleneck_family_index);
    try std.testing.expectEqual(StrainBucket.blocked, summary.strain_bucket);
    try std.testing.expectEqual(@as(u8, @intFromEnum(types.ReasonKind.reachable_in_current_window)), summary.dominant_reason_family);
    try std.testing.expectEqual(@as(u8, @intFromEnum(types.WarningKind.shift_required)), summary.dominant_warning_family);
    try std.testing.expectEqual(@as(u16, 2), summary.severity_counts[@intFromEnum(IssueSeverity.advisory)]);
    try std.testing.expectEqual(@as(u16, 2), summary.severity_counts[@intFromEnum(IssueSeverity.warning)]);
    try std.testing.expectEqual(@as(u16, 1), summary.severity_counts[@intFromEnum(IssueSeverity.blocked)]);
    try std.testing.expectEqual(@as(u16, 1), summary.recovery_deficit_start_index);
    try std.testing.expectEqual(@as(u16, 3), summary.recovery_deficit_end_index);
    try std.testing.expectEqual(@as(u16, 3), summary.longest_recovery_deficit_run);
}

test "phrase summary prefers first blocked event over later warnings for first blocked point" {
    const issues = [_]PhraseIssue{
        PhraseIssue.eventIssue(.blocked, .fret_blocker, @intFromEnum(fret_assessment.BlockerKind.span_hard_limit), 0, 6),
        PhraseIssue.transitionIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.repeated_maximal_stretch), 0, 1, 4),
    };

    const summary = summarizeIssues(2, issues[0..]);
    try std.testing.expectEqual(@as(u16, 0), summary.first_blocked_event_index);
    try std.testing.expectEqual(NONE_EVENT_INDEX, summary.first_blocked_transition_from_index);
    try std.testing.expectEqual(StrainBucket.blocked, summary.strain_bucket);
}

test "phrase summary marks warning-only phrases as elevated" {
    const issues = [_]PhraseIssue{
        PhraseIssue.eventIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.weak_finger_stress), 0, 2),
        PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.technique_profile_applied), 1, 0),
    };

    const summary = summarizeIssues(2, issues[0..]);
    try std.testing.expectEqual(StrainBucket.elevated, summary.strain_bucket);
    try std.testing.expectEqual(@as(u16, 1), summary.longest_recovery_deficit_run);
}
