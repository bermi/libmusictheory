const std = @import("std");
const testing = std.testing;

const playability = @import("../playability.zig");
const pitch = @import("../pitch.zig");

const phrase = playability.phrase;
const fret_assessment = playability.fret_assessment;
const keyboard_assessment = playability.keyboard_assessment;
const keyboard_topology = playability.keyboard_topology;

fn invalidIndex() u32 {
    return phrase.INVALID_EVENT_INDEX;
}

fn findIssueByLocation(issues: []const phrase.PhraseIssue, location: phrase.IssueLocationKind) ?phrase.PhraseIssue {
    for (issues) |issue| {
        if (issue.location == location) return issue;
    }
    return null;
}

test "phrase events keep compact fixed-size copies of input realizations" {
    const fret_event = phrase.FretPhraseEvent.init(&[_]i8{ 1, 4, -1, -1 });
    try testing.expectEqual(@as(u8, 4), fret_event.fret_count);
    try testing.expectEqual(@as(i8, 1), fret_event.frets[0]);
    try testing.expectEqual(@as(i8, 4), fret_event.frets[1]);
    try testing.expectEqual(@as(i8, -1), fret_event.frets[2]);

    const keyboard_event = phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 64, 67 });
    try testing.expectEqual(@as(u8, 3), keyboard_event.note_count);
    try testing.expectEqual(@as(u8, 60), keyboard_event.notes[0]);
    try testing.expectEqual(@as(u8, 67), keyboard_event.notes[2]);
}

test "keyboard phrase summaries identify the first blocked transition and bottleneck" {
    const profile = keyboard_topology.defaultHandProfile();
    const hand: keyboard_assessment.HandRole = .right;

    const first = keyboard_assessment.assessRealization(&[_]pitch.MidiNote{60}, hand, profile, null);
    const second = keyboard_assessment.assessRealization(&[_]pitch.MidiNote{73}, hand, profile, first.state.load);
    const transition = keyboard_assessment.assessTransition(&[_]pitch.MidiNote{60}, &[_]pitch.MidiNote{73}, hand, profile, null);

    var issue_buf: [4]phrase.PhraseIssue = undefined;
    const issues = phrase.collectKeyboardIssues(&[_]keyboard_assessment.RealizationAssessment{ first, second }, &[_]keyboard_assessment.TransitionAssessment{transition}, issue_buf[0..]);
    const summary = phrase.summarizeKeyboardAssessments(&[_]keyboard_assessment.RealizationAssessment{ first, second }, &[_]keyboard_assessment.TransitionAssessment{transition});

    try testing.expectEqual(summary.issue_count, issues.total_count);
    try testing.expect(issues.rows.len >= 1);
    const transition_issue = findIssueByLocation(issues.rows, .transition) orelse return error.TestExpectedEqual;
    try testing.expectEqual(phrase.IssueSeverity.blocked, transition_issue.severity);
    try testing.expectEqual(@as(u32, 0), transition_issue.event_index);
    try testing.expectEqual(@as(u32, 1), transition_issue.next_event_index);

    try testing.expectEqual(@as(u32, 2), summary.event_count);
    try testing.expectEqual(@as(u32, 1), summary.transition_count);
    try testing.expect(summary.issue_count >= 1);
    try testing.expectEqual(@as(u32, 1), summary.blocked_issue_count);
    try testing.expect(summary.warning_issue_count <= summary.issue_count);
    try testing.expectEqual(invalidIndex(), summary.first_blocked_event_index);
    try testing.expectEqual(@as(u32, 0), summary.first_blocked_transition_index);
    try testing.expectEqual(phrase.IssueLocationKind.transition, summary.bottleneck_location);
    try testing.expectEqual(phrase.IssueSeverity.blocked, summary.bottleneck_severity);
    try testing.expectEqual(@as(u32, 0), summary.bottleneck_event_index);
    try testing.expectEqual(@as(u32, 1), summary.bottleneck_next_event_index);
    try testing.expect(summary.dominant_warning != playability.types.INVALID_WARNING_INDEX);
    try testing.expect(summary.max_bottleneck_cost >= 13);
    try testing.expect(summary.peak_shift_steps >= 13);
    try testing.expect(summary.cumulative_cost >= transition.cumulative_cost);
}

test "fret phrase summaries keep event and transition issues aligned by phrase index" {
    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const technique: fret_assessment.TechniqueProfile = .bass_simandl;

    const first = fret_assessment.assessRealization(&[_]i8{ 1, 4, -1, -1 }, &tuning, technique, null, null);
    const second = fret_assessment.assessRealization(&[_]i8{ 5, 7, -1, -1 }, &tuning, technique, null, first.state.load);
    const transition = fret_assessment.assessTransition(&[_]i8{ 1, 4, -1, -1 }, &[_]i8{ 5, 7, -1, -1 }, &tuning, technique, null);

    var issue_buf: [6]phrase.PhraseIssue = undefined;
    const issues = phrase.collectFretIssues(&[_]fret_assessment.RealizationAssessment{ first, second }, &[_]fret_assessment.TransitionAssessment{transition}, issue_buf[0..]);
    const summary = phrase.summarizeFretAssessments(&[_]fret_assessment.RealizationAssessment{ first, second }, &[_]fret_assessment.TransitionAssessment{transition});

    try testing.expectEqual(summary.issue_count, issues.total_count);
    try testing.expect(issues.rows.len >= 2);
    const event_issue = findIssueByLocation(issues.rows, .event) orelse return error.TestExpectedEqual;
    const transition_issue = findIssueByLocation(issues.rows, .transition) orelse return error.TestExpectedEqual;
    try testing.expectEqual(@as(u32, 0), event_issue.event_index);
    try testing.expectEqual(invalidIndex(), event_issue.next_event_index);
    try testing.expectEqual(@as(u32, 0), transition_issue.event_index);
    try testing.expectEqual(@as(u32, 1), transition_issue.next_event_index);

    try testing.expectEqual(@as(u32, 2), summary.event_count);
    try testing.expectEqual(@as(u32, 1), summary.transition_count);
    try testing.expect(summary.issue_count >= 2);
    try testing.expectEqual(@as(u32, 0), summary.blocked_issue_count);
    try testing.expect(summary.warning_issue_count >= 2);
    try testing.expectEqual(invalidIndex(), summary.first_blocked_event_index);
    try testing.expectEqual(invalidIndex(), summary.first_blocked_transition_index);
    try testing.expectEqual(phrase.IssueLocationKind.transition, summary.bottleneck_location);
    try testing.expectEqual(phrase.IssueSeverity.warning, summary.bottleneck_severity);
    try testing.expectEqual(@as(u8, @intFromEnum(playability.types.ReasonKind.reachable_location)), summary.dominant_reason);
    try testing.expect(summary.dominant_warning != playability.types.INVALID_WARNING_INDEX);
    try testing.expect(summary.total_warning_count > summary.warning_issue_count);
    try testing.expect(summary.cumulative_cost >= first.cumulative_cost + second.cumulative_cost);
}
