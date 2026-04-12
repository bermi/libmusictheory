const std = @import("std");
const phrase = @import("../playability/phrase.zig");
const types = @import("../playability/types.zig");

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
