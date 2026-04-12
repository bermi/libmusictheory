const std = @import("std");
const pitch = @import("../pitch.zig");
const phrase = @import("../playability/phrase.zig");
const types = @import("../playability/types.zig");
const keyboard_assessment = @import("../playability/keyboard_assessment.zig");
const fret_assessment = @import("../playability/fret_assessment.zig");

const testing = std.testing;

test "phrase accumulator ignores out-of-range issues" {
    const issues = [_]phrase.PhraseIssue{
        phrase.PhraseIssue.eventIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.shift_required), 4, 2),
        phrase.PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.open_string_relief), 1, 0),
    };

    const summary = phrase.summarizeIssues(2, issues[0..]);
    try testing.expectEqual(@as(u16, 1), summary.issue_count);
    try testing.expectEqual(@as(u16, 0), summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)]);
    try testing.expectEqual(@as(u8, @intFromEnum(types.ReasonKind.open_string_relief)), summary.dominant_reason_family);
}

test "phrase summary becomes neutral when only advisory reasons remain" {
    const issues = [_]phrase.PhraseIssue{
        phrase.PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.reuses_current_anchor), 0, 0),
        phrase.PhraseIssue.transitionIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.bottleneck_reduced), 0, 1, 0),
    };

    const summary = phrase.summarizeIssues(2, issues[0..]);
    try testing.expectEqual(phrase.StrainBucket.neutral, summary.strain_bucket);
    try testing.expectEqual(@as(u16, 0), summary.longest_recovery_deficit_run);
}

test "keyboard phrase event clips notes to fingering capacity" {
    const event = phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 64, 67, 71, 74, 77 }, .right);
    try testing.expectEqual(@as(u8, keyboard_assessment.MAX_FINGERING_NOTES), event.note_count);
    try testing.expectEqual(@as(u8, 74), event.notes[4]);
}

test "fret phrase event fills unused strings with sentinel" {
    const event = phrase.FretPhraseEvent.init(&[_]i8{ 3, 2, 0, 0 });
    try testing.expectEqual(@as(u8, 4), event.fret_count);
    try testing.expectEqual(@as(i8, -1), event.frets[6]);
}

test "keyboard committed phrase memory resets and appends explicit events" {
    var memory = phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expectEqual(@as(usize, 0), memory.len());
    try testing.expect(memory.current() == null);

    try testing.expect(memory.push(phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{60}, .right)));
    try testing.expect(memory.push(phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{67}, .right)));
    try testing.expectEqual(@as(usize, 2), memory.len());
    try testing.expectEqual(@as(u8, 67), memory.current().?.notes[0]);
    try testing.expectEqual(@as(u8, 60), memory.previous().?.notes[0]);

    memory.reset();
    try testing.expectEqual(@as(usize, 0), memory.len());
    try testing.expect(memory.current() == null);
}

test "fret committed phrase memory resets and appends explicit events" {
    var memory = phrase.FretCommittedPhraseMemory.init();
    try testing.expectEqual(@as(usize, 0), memory.len());

    try testing.expect(memory.push(phrase.FretPhraseEvent.init(&[_]i8{ 3, -1, -1, -1 })));
    try testing.expect(memory.push(phrase.FretPhraseEvent.init(&[_]i8{ 5, -1, -1, -1 })));
    try testing.expectEqual(@as(usize, 2), memory.len());
    try testing.expectEqual(@as(i8, 5), memory.current().?.frets[0]);
    try testing.expectEqual(@as(i8, 3), memory.previous().?.frets[0]);

    memory.reset();
    try testing.expectEqual(@as(usize, 0), memory.len());
}

test "phrase summary tracks blocked transitions and recovery deficit runs" {
    const issues = [_]phrase.PhraseIssue{
        phrase.PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.reachable_in_current_window), 0, 0),
        phrase.PhraseIssue.eventIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.shift_required), 1, 3),
        phrase.PhraseIssue.transitionIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.excessive_longitudinal_shift), 1, 2, 5),
        phrase.PhraseIssue.transitionIssue(.blocked, .keyboard_blocker, @intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit), 2, 3, 8),
        phrase.PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.open_string_relief), 4, 0),
    };

    const summary = phrase.summarizeIssues(5, issues[0..]);
    try testing.expectEqual(@as(u16, 5), summary.event_count);
    try testing.expectEqual(@as(u16, 5), summary.issue_count);
    try testing.expectEqual(phrase.NONE_EVENT_INDEX, summary.first_blocked_event_index);
    try testing.expectEqual(@as(u16, 2), summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 3), summary.first_blocked_transition_to_index);
    try testing.expectEqual(phrase.IssueSeverity.blocked, summary.bottleneck_severity);
    try testing.expectEqual(phrase.FamilyDomain.keyboard_blocker, summary.bottleneck_domain);
    try testing.expectEqual(@as(u8, @intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit)), summary.bottleneck_family_index);
    try testing.expectEqual(phrase.StrainBucket.blocked, summary.strain_bucket);
    try testing.expectEqual(@as(u8, @intFromEnum(types.ReasonKind.reachable_in_current_window)), summary.dominant_reason_family);
    try testing.expectEqual(@as(u8, @intFromEnum(types.WarningKind.shift_required)), summary.dominant_warning_family);
    try testing.expectEqual(@as(u16, 2), summary.severity_counts[@intFromEnum(phrase.IssueSeverity.advisory)]);
    try testing.expectEqual(@as(u16, 2), summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)]);
    try testing.expectEqual(@as(u16, 1), summary.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)]);
    try testing.expectEqual(@as(u16, 1), summary.recovery_deficit_start_index);
    try testing.expectEqual(@as(u16, 3), summary.recovery_deficit_end_index);
    try testing.expectEqual(@as(u16, 3), summary.longest_recovery_deficit_run);
}

test "keyboard phrase audit emits hand continuity reset and resets recovery on hand change" {
    const events = [_]phrase.KeyboardPhraseEvent{
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{60}, .right),
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right),
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{84}, .left),
    };
    const profile = types.HandProfile.init(5, 12, 14, 2, 4, true);

    var issues: [64]phrase.PhraseIssue = undefined;
    const result = phrase.auditKeyboardPhrase(events[0..], profile, issues[0..]);

    try testing.expect(result.logical_issue_count >= result.written_issue_count);

    var found_reset = false;
    for (issues[0..result.written_issue_count]) |issue| {
        if (issue.scope == .event and
            issue.family_domain == .playability_reason and
            issue.family_index == @intFromEnum(types.ReasonKind.hand_continuity_reset) and
            issue.event_index == 2)
        {
            found_reset = true;
        }
        try testing.expect(!(issue.scope == .transition and
            issue.event_index == 1 and
            issue.related_event_index == 2 and
            issue.severity == .blocked));
    }
    try testing.expect(found_reset);
}

test "fixed-realization keyboard phrase audit appends warning cluster and recovery deficit issues" {
    const events = [_]phrase.KeyboardPhraseEvent{
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right),
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right),
        phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right),
    };
    const profile = types.HandProfile.init(5, 4, 12, 12, 12, true);

    var issues: [128]phrase.PhraseIssue = undefined;
    const result = phrase.auditKeyboardPhrase(events[0..], profile, issues[0..]);
    try testing.expectEqual(@as(u16, 3), result.summary.longest_recovery_deficit_run);

    var found_cluster = false;
    var found_recovery = false;
    for (issues[0..result.written_issue_count]) |issue| {
        if (issue.family_domain != .playability_warning or issue.severity != .warning) continue;
        if (issue.scope == .transition and issue.event_index == 1 and issue.related_event_index == 2) {
            found_cluster = true;
        }
        if (issue.scope == .transition and issue.event_index == 0 and issue.related_event_index == 2) {
            found_recovery = true;
        }
    }
    try testing.expect(found_cluster);
    try testing.expect(found_recovery);
}

test "fixed-realization fret phrase audit emits shift blockers and recovery deficit run" {
    const events = [_]phrase.FretPhraseEvent{
        phrase.FretPhraseEvent.init(&[_]i8{ 1, -1, -1, -1 }),
        phrase.FretPhraseEvent.init(&[_]i8{ 8, -1, -1, -1 }),
        phrase.FretPhraseEvent.init(&[_]i8{ 12, -1, -1, -1 }),
    };
    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const profile = types.HandProfile.init(4, 3, 5, 2, 3, true);

    var issues: [128]phrase.PhraseIssue = undefined;
    const result = phrase.auditFretPhrase(
        events[0..],
        tuning[0..],
        .generic_guitar,
        profile,
        issues[0..],
    );

    try testing.expectEqual(phrase.StrainBucket.blocked, result.summary.strain_bucket);
    try testing.expectEqual(@as(u16, 0), result.summary.first_blocked_transition_from_index);
    try testing.expectEqual(@as(u16, 1), result.summary.first_blocked_transition_to_index);
    try testing.expect(result.summary.longest_recovery_deficit_run >= 1);

    var found_shift_blocker = false;
    for (issues[0..result.written_issue_count]) |issue| {
        if (issue.scope == .transition and
            issue.family_domain == .fret_blocker and
            issue.family_index == @intFromEnum(fret_assessment.BlockerKind.shift_hard_limit))
        {
            found_shift_blocker = true;
        }
    }
    try testing.expect(found_shift_blocker);
}

test "committed keyboard phrase audit delegates to fixed realization audit" {
    var memory = phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(memory.push(phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));
    try testing.expect(memory.push(phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));
    try testing.expect(memory.push(phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));

    const profile = types.HandProfile.init(5, 4, 12, 12, 12, true);
    var issues: [128]phrase.PhraseIssue = undefined;
    const result = phrase.auditCommittedKeyboardPhrase(&memory, profile, issues[0..]);

    try testing.expectEqual(@as(u16, 3), result.summary.event_count);
    try testing.expectEqual(@as(u16, 3), result.summary.longest_recovery_deficit_run);
}

test "committed fret phrase audit delegates to fixed realization audit" {
    var memory = phrase.FretCommittedPhraseMemory.init();
    try testing.expect(memory.push(phrase.FretPhraseEvent.init(&[_]i8{ 1, -1, -1, -1 })));
    try testing.expect(memory.push(phrase.FretPhraseEvent.init(&[_]i8{ 8, -1, -1, -1 })));
    try testing.expect(memory.push(phrase.FretPhraseEvent.init(&[_]i8{ 12, -1, -1, -1 })));

    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const profile = types.HandProfile.init(4, 3, 5, 2, 3, true);
    var issues: [128]phrase.PhraseIssue = undefined;
    const result = phrase.auditCommittedFretPhrase(
        &memory,
        tuning[0..],
        .generic_guitar,
        profile,
        issues[0..],
    );

    try testing.expectEqual(phrase.StrainBucket.blocked, result.summary.strain_bucket);
    try testing.expectEqual(@as(u16, 3), result.summary.event_count);
}
