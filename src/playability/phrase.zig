const std = @import("std");
const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const types = @import("types.zig");
const fret_assessment = @import("fret_assessment.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");

pub const MAX_FRET_EVENT_STRINGS: usize = guitar.MAX_GENERIC_STRINGS;
pub const MAX_KEYBOARD_EVENT_NOTES: usize = keyboard_assessment.MAX_FINGERING_NOTES;
pub const MAX_AUDIT_EVENTS: usize = 64;
pub const INVALID_EVENT_INDEX: u32 = std.math.maxInt(u32);

pub const IssueLocationKind = enum(u8) {
    event = 0,
    transition = 1,
};

pub const ISSUE_LOCATION_NAMES = [_][]const u8{
    "event",
    "transition",
};

pub const IssueSeverity = enum(u8) {
    clear = 0,
    warning = 1,
    blocked = 2,
};

pub const ISSUE_SEVERITY_NAMES = [_][]const u8{
    "clear",
    "warning",
    "blocked",
};

pub const FretPhraseEvent = struct {
    fret_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    frets: [MAX_FRET_EVENT_STRINGS]i8,

    pub fn init(frets_in: []const i8) FretPhraseEvent {
        var event = FretPhraseEvent{
            .fret_count = @as(u8, @intCast(@min(frets_in.len, MAX_FRET_EVENT_STRINGS))),
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .frets = [_]i8{-1} ** MAX_FRET_EVENT_STRINGS,
        };
        const count = @as(usize, event.fret_count);
        @memcpy(event.frets[0..count], frets_in[0..count]);
        return event;
    }
};

pub const KeyboardPhraseEvent = struct {
    note_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    notes: [MAX_KEYBOARD_EVENT_NOTES]pitch.MidiNote,

    pub fn init(notes_in: []const pitch.MidiNote) KeyboardPhraseEvent {
        var event = KeyboardPhraseEvent{
            .note_count = @as(u8, @intCast(@min(notes_in.len, MAX_KEYBOARD_EVENT_NOTES))),
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .notes = [_]pitch.MidiNote{0} ** MAX_KEYBOARD_EVENT_NOTES,
        };
        const count = @as(usize, event.note_count);
        @memcpy(event.notes[0..count], notes_in[0..count]);
        return event;
    }
};

pub const PhraseIssue = struct {
    location: IssueLocationKind,
    severity: IssueSeverity,
    event_index: u32,
    next_event_index: u32,
    blocker_count: u8,
    warning_count: u8,
    dominant_reason: u8,
    dominant_warning: u8,
    bottleneck_cost: u16,
    cumulative_cost: u16,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
};

pub const PhraseSummary = struct {
    event_count: u32,
    transition_count: u32,
    issue_count: u32,
    blocked_issue_count: u32,
    warning_issue_count: u32,
    first_blocked_event_index: u32,
    first_blocked_transition_index: u32,
    bottleneck_event_index: u32,
    bottleneck_next_event_index: u32,
    cumulative_cost: u32,
    total_blocker_count: u32,
    total_warning_count: u32,
    total_reason_count: u32,
    max_bottleneck_cost: u16,
    peak_span_steps: u8,
    peak_shift_steps: u8,
    bottleneck_location: IssueLocationKind,
    bottleneck_severity: IssueSeverity,
    dominant_reason: u8,
    dominant_warning: u8,
    reserved0: u8,

    pub fn init(event_count: usize, transition_count: usize) PhraseSummary {
        return .{
            .event_count = clampCount(event_count),
            .transition_count = clampCount(transition_count),
            .issue_count = 0,
            .blocked_issue_count = 0,
            .warning_issue_count = 0,
            .first_blocked_event_index = INVALID_EVENT_INDEX,
            .first_blocked_transition_index = INVALID_EVENT_INDEX,
            .bottleneck_event_index = INVALID_EVENT_INDEX,
            .bottleneck_next_event_index = INVALID_EVENT_INDEX,
            .cumulative_cost = 0,
            .total_blocker_count = 0,
            .total_warning_count = 0,
            .total_reason_count = 0,
            .max_bottleneck_cost = 0,
            .peak_span_steps = 0,
            .peak_shift_steps = 0,
            .bottleneck_location = .event,
            .bottleneck_severity = .clear,
            .dominant_reason = types.INVALID_REASON_INDEX,
            .dominant_warning = types.INVALID_WARNING_INDEX,
            .reserved0 = 0,
        };
    }
};

pub const IssueCollection = struct {
    rows: []PhraseIssue,
    total_count: u32,
};

pub fn collectFretIssues(
    realizations: []const fret_assessment.RealizationAssessment,
    transitions: []const fret_assessment.TransitionAssessment,
    out: []PhraseIssue,
) IssueCollection {
    const result = summarizeFretInternal(realizations, transitions, out);
    return .{
        .rows = out[0..result.write_count],
        .total_count = result.summary.issue_count,
    };
}

pub fn summarizeFretAssessments(
    realizations: []const fret_assessment.RealizationAssessment,
    transitions: []const fret_assessment.TransitionAssessment,
) PhraseSummary {
    return summarizeFretInternal(realizations, transitions, null).summary;
}

pub fn collectKeyboardIssues(
    realizations: []const keyboard_assessment.RealizationAssessment,
    transitions: []const keyboard_assessment.TransitionAssessment,
    out: []PhraseIssue,
) IssueCollection {
    const result = summarizeKeyboardInternal(realizations, transitions, out);
    return .{
        .rows = out[0..result.write_count],
        .total_count = result.summary.issue_count,
    };
}

pub fn summarizeKeyboardAssessments(
    realizations: []const keyboard_assessment.RealizationAssessment,
    transitions: []const keyboard_assessment.TransitionAssessment,
) PhraseSummary {
    return summarizeKeyboardInternal(realizations, transitions, null).summary;
}

const InternalResult = struct {
    summary: PhraseSummary,
    write_count: usize,
};

fn summarizeFretInternal(
    realizations: []const fret_assessment.RealizationAssessment,
    transitions: []const fret_assessment.TransitionAssessment,
    out_opt: ?[]PhraseIssue,
) InternalResult {
    var summary = PhraseSummary.init(realizations.len, transitions.len);
    var reason_counts = [_]u32{0} ** types.REASON_NAMES.len;
    var warning_counts = [_]u32{0} ** types.WARNING_NAMES.len;
    var write_count: usize = 0;

    for (realizations, 0..) |assessment, index| {
        observeAggregateBits(&summary, &reason_counts, &warning_counts, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits);
        summary.cumulative_cost +|= assessment.cumulative_cost;
        if (assessment.state.span_steps > summary.peak_span_steps) summary.peak_span_steps = assessment.state.span_steps;
        if (assessment.state.load.last_shift_steps > summary.peak_shift_steps) summary.peak_shift_steps = assessment.state.load.last_shift_steps;

        const severity = severityForBits(assessment.blocker_bits, assessment.warning_bits);
        observeBottleneck(
            &summary,
            .event,
            severity,
            @as(u32, @intCast(index)),
            INVALID_EVENT_INDEX,
            assessment.bottleneck_cost,
        );

        if (buildIssue(.event, @as(u32, @intCast(index)), INVALID_EVENT_INDEX, severity, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits, assessment.bottleneck_cost, assessment.cumulative_cost)) |issue| {
            recordIssue(&summary, issue, true);
            appendIssue(out_opt, &write_count, issue);
        }
    }

    for (transitions, 0..) |assessment, index| {
        observeAggregateBits(&summary, &reason_counts, &warning_counts, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits);
        summary.cumulative_cost +|= transitionIncrementCost(
            assessment.cumulative_cost,
            if (index < realizations.len) realizations[index].cumulative_cost else null,
            if (index + 1 < realizations.len) realizations[index + 1].cumulative_cost else null,
        );
        if (assessment.to_state.span_steps > summary.peak_span_steps) summary.peak_span_steps = assessment.to_state.span_steps;
        if (assessment.anchor_delta_steps > summary.peak_shift_steps) summary.peak_shift_steps = assessment.anchor_delta_steps;

        const severity = severityForBits(assessment.blocker_bits, assessment.warning_bits);
        observeBottleneck(
            &summary,
            .transition,
            severity,
            @as(u32, @intCast(index)),
            @as(u32, @intCast(index + 1)),
            assessment.bottleneck_cost,
        );

        if (buildIssue(.transition, @as(u32, @intCast(index)), @as(u32, @intCast(index + 1)), severity, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits, assessment.bottleneck_cost, assessment.cumulative_cost)) |issue| {
            recordIssue(&summary, issue, false);
            appendIssue(out_opt, &write_count, issue);
        }
    }

    summary.dominant_reason = dominantIndex(reason_counts[0..], types.INVALID_REASON_INDEX);
    summary.dominant_warning = dominantIndex(warning_counts[0..], types.INVALID_WARNING_INDEX);
    return .{ .summary = summary, .write_count = write_count };
}

fn summarizeKeyboardInternal(
    realizations: []const keyboard_assessment.RealizationAssessment,
    transitions: []const keyboard_assessment.TransitionAssessment,
    out_opt: ?[]PhraseIssue,
) InternalResult {
    var summary = PhraseSummary.init(realizations.len, transitions.len);
    var reason_counts = [_]u32{0} ** types.REASON_NAMES.len;
    var warning_counts = [_]u32{0} ** types.WARNING_NAMES.len;
    var write_count: usize = 0;

    for (realizations, 0..) |assessment, index| {
        observeAggregateBits(&summary, &reason_counts, &warning_counts, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits);
        summary.cumulative_cost +|= assessment.cumulative_cost;
        if (assessment.state.span_semitones > summary.peak_span_steps) summary.peak_span_steps = assessment.state.span_semitones;
        if (assessment.state.load.last_shift_steps > summary.peak_shift_steps) summary.peak_shift_steps = assessment.state.load.last_shift_steps;

        const severity = severityForBits(assessment.blocker_bits, assessment.warning_bits);
        observeBottleneck(
            &summary,
            .event,
            severity,
            @as(u32, @intCast(index)),
            INVALID_EVENT_INDEX,
            assessment.bottleneck_cost,
        );

        if (buildIssue(.event, @as(u32, @intCast(index)), INVALID_EVENT_INDEX, severity, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits, assessment.bottleneck_cost, assessment.cumulative_cost)) |issue| {
            recordIssue(&summary, issue, true);
            appendIssue(out_opt, &write_count, issue);
        }
    }

    for (transitions, 0..) |assessment, index| {
        observeAggregateBits(&summary, &reason_counts, &warning_counts, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits);
        summary.cumulative_cost +|= transitionIncrementCost(
            assessment.cumulative_cost,
            if (index < realizations.len) realizations[index].cumulative_cost else null,
            if (index + 1 < realizations.len) realizations[index + 1].cumulative_cost else null,
        );
        if (assessment.to_state.span_semitones > summary.peak_span_steps) summary.peak_span_steps = assessment.to_state.span_semitones;
        if (assessment.anchor_delta_semitones > summary.peak_shift_steps) summary.peak_shift_steps = assessment.anchor_delta_semitones;

        const severity = severityForBits(assessment.blocker_bits, assessment.warning_bits);
        observeBottleneck(
            &summary,
            .transition,
            severity,
            @as(u32, @intCast(index)),
            @as(u32, @intCast(index + 1)),
            assessment.bottleneck_cost,
        );

        if (buildIssue(.transition, @as(u32, @intCast(index)), @as(u32, @intCast(index + 1)), severity, assessment.blocker_bits, assessment.warning_bits, assessment.reason_bits, assessment.bottleneck_cost, assessment.cumulative_cost)) |issue| {
            recordIssue(&summary, issue, false);
            appendIssue(out_opt, &write_count, issue);
        }
    }

    summary.dominant_reason = dominantIndex(reason_counts[0..], types.INVALID_REASON_INDEX);
    summary.dominant_warning = dominantIndex(warning_counts[0..], types.INVALID_WARNING_INDEX);
    return .{ .summary = summary, .write_count = write_count };
}

fn observeAggregateBits(
    summary: *PhraseSummary,
    reason_counts: *[types.REASON_NAMES.len]u32,
    warning_counts: *[types.WARNING_NAMES.len]u32,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
) void {
    summary.total_blocker_count +|= @as(u32, types.countBits(blocker_bits));
    summary.total_warning_count +|= @as(u32, types.countBits(warning_bits));
    summary.total_reason_count +|= @as(u32, types.countBits(reason_bits));
    observeBitCounts(reason_counts[0..], reason_bits);
    observeBitCounts(warning_counts[0..], warning_bits);
}

fn observeBitCounts(out: []u32, bits: u32) void {
    for (out, 0..) |*count, index| {
        if ((bits & (@as(u32, 1) << @as(u5, @intCast(index)))) != 0) {
            count.* +|= 1;
        }
    }
}

fn severityForBits(blocker_bits: u32, warning_bits: u32) IssueSeverity {
    if (blocker_bits != 0) return .blocked;
    if (warning_bits != 0) return .warning;
    return .clear;
}

fn buildIssue(
    location: IssueLocationKind,
    event_index: u32,
    next_event_index: u32,
    severity: IssueSeverity,
    blocker_bits: u32,
    warning_bits: u32,
    reason_bits: u32,
    bottleneck_cost: u16,
    cumulative_cost: u16,
) ?PhraseIssue {
    if (severity == .clear) return null;
    return .{
        .location = location,
        .severity = severity,
        .event_index = event_index,
        .next_event_index = next_event_index,
        .blocker_count = types.countBits(blocker_bits),
        .warning_count = types.countBits(warning_bits),
        .dominant_reason = types.firstReasonIndex(reason_bits),
        .dominant_warning = types.firstWarningIndex(warning_bits),
        .bottleneck_cost = bottleneck_cost,
        .cumulative_cost = cumulative_cost,
        .blocker_bits = blocker_bits,
        .warning_bits = warning_bits,
        .reason_bits = reason_bits,
    };
}

fn appendIssue(out_opt: ?[]PhraseIssue, write_count: *usize, issue: PhraseIssue) void {
    if (out_opt) |out| {
        if (write_count.* < out.len) {
            out[write_count.*] = issue;
            write_count.* += 1;
        }
    }
}

fn recordIssue(summary: *PhraseSummary, issue: PhraseIssue, is_event: bool) void {
    summary.issue_count +|= 1;
    switch (issue.severity) {
        .warning => summary.warning_issue_count +|= 1,
        .blocked => summary.blocked_issue_count +|= 1,
        .clear => {},
    }

    if (issue.severity == .blocked) {
        if (is_event and summary.first_blocked_event_index == INVALID_EVENT_INDEX) {
            summary.first_blocked_event_index = issue.event_index;
        }
        if (!is_event and summary.first_blocked_transition_index == INVALID_EVENT_INDEX) {
            summary.first_blocked_transition_index = issue.event_index;
        }
    }
}

fn observeBottleneck(
    summary: *PhraseSummary,
    location: IssueLocationKind,
    severity: IssueSeverity,
    event_index: u32,
    next_event_index: u32,
    bottleneck_cost: u16,
) void {
    if (!shouldReplaceBottleneck(summary.*, location, severity, event_index, next_event_index, bottleneck_cost)) return;
    summary.max_bottleneck_cost = bottleneck_cost;
    summary.bottleneck_location = location;
    summary.bottleneck_severity = severity;
    summary.bottleneck_event_index = event_index;
    summary.bottleneck_next_event_index = next_event_index;
}

fn shouldReplaceBottleneck(
    summary: PhraseSummary,
    location: IssueLocationKind,
    severity: IssueSeverity,
    event_index: u32,
    next_event_index: u32,
    bottleneck_cost: u16,
) bool {
    if (summary.bottleneck_event_index == INVALID_EVENT_INDEX) return true;
    if (bottleneck_cost != summary.max_bottleneck_cost) return bottleneck_cost > summary.max_bottleneck_cost;

    const severity_rank = @intFromEnum(severity);
    const current_severity_rank = @intFromEnum(summary.bottleneck_severity);
    if (severity_rank != current_severity_rank) return severity_rank > current_severity_rank;
    if (event_index != summary.bottleneck_event_index) return event_index < summary.bottleneck_event_index;
    if (next_event_index != summary.bottleneck_next_event_index) return next_event_index < summary.bottleneck_next_event_index;
    return @intFromEnum(location) < @intFromEnum(summary.bottleneck_location);
}

fn dominantIndex(counts: []const u32, fallback: u8) u8 {
    var best_index: ?usize = null;
    var best_count: u32 = 0;
    for (counts, 0..) |count, index| {
        if (count == 0) continue;
        if (best_index == null or count > best_count) {
            best_index = index;
            best_count = count;
        }
    }
    return if (best_index) |index| @as(u8, @intCast(index)) else fallback;
}

fn transitionIncrementCost(total_cost: u16, from_cost: ?u16, to_cost: ?u16) u32 {
    if (from_cost) |from| {
        if (to_cost) |to| {
            const raw_delta = @as(i32, total_cost) - @as(i32, from) - @as(i32, to);
            return @as(u32, @intCast(@max(raw_delta, 0)));
        }
    }
    return total_cost;
}

fn clampCount(count: usize) u32 {
    return @as(u32, @intCast(@min(count, std.math.maxInt(u32))));
}
