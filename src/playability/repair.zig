const std = @import("std");
const pitch = @import("../pitch.zig");
const pcs = @import("../pitch_class_set.zig");
const guitar = @import("../guitar.zig");
const phrase = @import("phrase.zig");
const types = @import("types.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");
const fret_assessment = @import("fret_assessment.zig");

pub const MAX_PHRASE_REPAIRS: usize = 32;
pub const NONE_CHANGE_INDEX: u8 = std.math.maxInt(u8);

pub const RepairClass = enum(u8) {
    realization_only = 0,
    register_adjusted = 1,
    texture_reduced = 2,
};

pub const REPAIR_CLASS_NAMES = [_][]const u8{
    "realization-only",
    "register-adjusted",
    "texture-reduced",
};

pub const PreservationFlag = enum(u8) {
    bass_preserved = 0,
    top_voice_preserved = 1,
    pitch_classes_preserved = 2,
    note_count_preserved = 3,
    exact_pitches_preserved = 4,
    exact_frets_preserved = 5,
};

pub const PRESERVATION_FLAG_NAMES = [_][]const u8{
    "bass preserved",
    "top voice preserved",
    "pitch classes preserved",
    "note count preserved",
    "exact pitches preserved",
    "exact frets preserved",
};

pub const ChangeFlag = enum(u8) {
    hand_reassigned = 0,
    fret_location_changed = 1,
    octave_displaced = 2,
    note_removed = 3,
};

pub const CHANGE_FLAG_NAMES = [_][]const u8{
    "hand reassigned",
    "fret location changed",
    "octave displaced",
    "note removed",
};

pub const RepairPolicy = struct {
    max_class: RepairClass,
    preserve_bass: bool,
    preserve_top_voice: bool,
    prefer_inner_changes: bool,
    allow_hand_reassignment: bool,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,

    pub fn defaultForClass(max_class: RepairClass) RepairPolicy {
        return .{
            .max_class = max_class,
            .preserve_bass = true,
            .preserve_top_voice = true,
            .prefer_inner_changes = true,
            .allow_hand_reassignment = true,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
        };
    }
};

pub const RankedKeyboardPhraseRepair = struct {
    repair_class: RepairClass,
    target_event_index: u16,
    // "what changed" records the focused edit that produced the repair candidate.
    changed_from_index: u8,
    changed_to_index: u8,
    changed_from_value: u8,
    changed_to_value: u8,
    // "crossed musical-change boundary" tells hosts whether the repair stayed
    // within realization_only or crossed into register_adjusted/texture_reduced.
    crossed_musical_change_boundary: bool,
    hand: keyboard_assessment.HandRole,
    // "what was preserved" stays explicit so hosts can explain why a repair was accepted.
    preserved_mask: u32,
    change_mask: u32,
    bottleneck_lift: i16,
    issue_lift: i16,
    blocked_issue_lift: i16,
    warning_issue_lift: i16,
    before_summary: phrase.PhraseSummary,
    after_summary: phrase.PhraseSummary,
    replacement_event: phrase.KeyboardPhraseEvent,
};

pub const RankedFretPhraseRepair = struct {
    repair_class: RepairClass,
    target_event_index: u16,
    // "what changed" records the focused edit that produced the repair candidate.
    changed_from_index: u8,
    changed_to_index: u8,
    changed_from_value: i8,
    changed_to_value: i8,
    // "crossed musical-change boundary" tells hosts whether the repair stayed
    // within realization_only or crossed into register_adjusted/texture_reduced.
    crossed_musical_change_boundary: bool,
    technique: fret_assessment.TechniqueProfile,
    // "what was preserved" stays explicit so hosts can explain why a repair was accepted.
    preserved_mask: u32,
    change_mask: u32,
    bottleneck_lift: i16,
    issue_lift: i16,
    blocked_issue_lift: i16,
    warning_issue_lift: i16,
    before_summary: phrase.PhraseSummary,
    after_summary: phrase.PhraseSummary,
    replacement_event: phrase.FretPhraseEvent,
};

pub fn fromInt(raw: u8) ?RepairClass {
    return switch (raw) {
        0 => .realization_only,
        1 => .register_adjusted,
        2 => .texture_reduced,
        else => null,
    };
}

pub fn rankKeyboardPhraseRepairs(
    memory: *const phrase.KeyboardCommittedPhraseMemory,
    hand_profile: types.HandProfile,
    policy: RepairPolicy,
    out: []RankedKeyboardPhraseRepair,
) []RankedKeyboardPhraseRepair {
    if (out.len == 0) return out[0..0];
    const events = memory.slice();
    if (events.len == 0) return out[0..0];

    var before_issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    const before_audit = phrase.auditCommittedKeyboardPhrase(memory, hand_profile, before_issues[0..]);
    const target_index = primaryRepairTarget(before_audit.summary, before_issues[0..before_audit.written_issue_count]) orelse return out[0..0];
    const original = events[target_index];

    var write_len: usize = 0;
    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.realization_only)) {
        if (policy.allow_hand_reassignment) {
            const alternate_hand: keyboard_assessment.HandRole = switch (original.hand) {
                .left => .right,
                .right => .left,
            };
            var replacement = original;
            replacement.hand = alternate_hand;
            write_len = appendKeyboardRepairCandidate(
                out,
                write_len,
                memory,
                hand_profile,
                before_audit.summary,
                target_index,
                original,
                replacement,
                .realization_only,
                NONE_CHANGE_INDEX,
                NONE_CHANGE_INDEX,
                @intFromEnum(original.hand),
                @intFromEnum(alternate_hand),
                bitForIndex(@intFromEnum(ChangeFlag.hand_reassigned)),
                policy,
            );
        }
    }

    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.register_adjusted)) {
        const ordered = orderedKeyboardIndices(original.note_count, policy.prefer_inner_changes);
        for (ordered[0..original.note_count]) |note_index| {
            if (isProtectedKeyboardIndex(&original, note_index, policy)) continue;

            for ([_]i16{ -12, 12 }) |delta| {
                const current_note = original.notes[note_index];
                const shifted = @as(i16, current_note) + delta;
                if (shifted < 0 or shifted > 127) continue;

                var notes_buf: [keyboard_assessment.MAX_FINGERING_NOTES]pitch.MidiNote = original.notes;
                notes_buf[note_index] = @as(pitch.MidiNote, @intCast(shifted));
                sortMidi(notes_buf[0..original.note_count]);
                const replacement = phrase.KeyboardPhraseEvent.init(notes_buf[0..original.note_count], original.hand);
                write_len = appendKeyboardRepairCandidate(
                    out,
                    write_len,
                    memory,
                    hand_profile,
                    before_audit.summary,
                    target_index,
                    original,
                    replacement,
                    .register_adjusted,
                    note_index,
                    note_index,
                    current_note,
                    @as(u8, @intCast(shifted)),
                    bitForIndex(@intFromEnum(ChangeFlag.octave_displaced)),
                    policy,
                );
            }
        }
    }

    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.texture_reduced) and original.note_count > 1) {
        const ordered = orderedKeyboardIndices(original.note_count, policy.prefer_inner_changes);
        for (ordered[0..original.note_count]) |note_index| {
            if (isProtectedKeyboardIndex(&original, note_index, policy)) continue;

            var reduced_notes: [keyboard_assessment.MAX_FINGERING_NOTES]pitch.MidiNote = [_]pitch.MidiNote{0} ** keyboard_assessment.MAX_FINGERING_NOTES;
            var reduced_count: usize = 0;
            for (original.notes[0..original.note_count], 0..) |note, index| {
                if (index == note_index) continue;
                reduced_notes[reduced_count] = note;
                reduced_count += 1;
            }
            const replacement = phrase.KeyboardPhraseEvent.init(reduced_notes[0..reduced_count], original.hand);
            write_len = appendKeyboardRepairCandidate(
                out,
                write_len,
                memory,
                hand_profile,
                before_audit.summary,
                target_index,
                original,
                replacement,
                .texture_reduced,
                note_index,
                NONE_CHANGE_INDEX,
                original.notes[note_index],
                0,
                bitForIndex(@intFromEnum(ChangeFlag.note_removed)),
                policy,
            );
        }
    }

    std.sort.insertion(RankedKeyboardPhraseRepair, out[0..write_len], {}, keyboardRepairLessThan);
    return out[0..write_len];
}

pub fn rankFretPhraseRepairs(
    memory: *const phrase.FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    policy: RepairPolicy,
    out: []RankedFretPhraseRepair,
) []RankedFretPhraseRepair {
    if (out.len == 0) return out[0..0];
    const events = memory.slice();
    if (events.len == 0 or tuning.len == 0) return out[0..0];

    var before_issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    const before_audit = phrase.auditCommittedFretPhrase(memory, tuning, technique, hand_override, before_issues[0..]);
    const target_index = primaryRepairTarget(before_audit.summary, before_issues[0..before_audit.written_issue_count]) orelse return out[0..0];
    const original = events[target_index];
    const target_state = fret_assessment.assessRealization(phrase.fretPhraseFrets(&original), tuning, technique, hand_override, null).state;

    var write_len: usize = 0;
    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.realization_only)) {
        var midi_buf: [guitar.MAX_GENERIC_STRINGS]FretMidiEntry = undefined;
        const midi_notes = activeFretMidiNotes(&original, tuning, &midi_buf);
        for (midi_notes) |entry| {
            const source_string = entry.string_index;
            var ranked_locations: [fret_assessment.MAX_RANKED_LOCATIONS]fret_assessment.RankedLocation = undefined;
            const ranked = fret_assessment.rankLocationsForMidi(entry.note, tuning, target_state.anchor_fret, technique, hand_override, ranked_locations[0..]);
            for (ranked) |location| {
                if (location.location.position.string == source_string and location.location.position.fret == @as(u8, @intCast(original.frets[source_string]))) continue;
                if (original.frets[location.location.position.string] >= 0) continue;

                var replacement_frets = original.frets;
                replacement_frets[source_string] = -1;
                replacement_frets[location.location.position.string] = @as(i8, @intCast(location.location.position.fret));
                const replacement = phrase.FretPhraseEvent.init(replacement_frets[0..original.fret_count]);
                write_len = appendFretRepairCandidate(
                    out,
                    write_len,
                    memory,
                    tuning,
                    technique,
                    hand_override,
                    before_audit.summary,
                    target_index,
                    original,
                    replacement,
                    .realization_only,
                    source_string,
                    @as(u8, @intCast(location.location.position.string)),
                    original.frets[source_string],
                    @as(i8, @intCast(location.location.position.fret)),
                    bitForIndex(@intFromEnum(ChangeFlag.fret_location_changed)),
                    policy,
                );
            }
        }
    }

    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.register_adjusted)) {
        var midi_buf: [guitar.MAX_GENERIC_STRINGS]FretMidiEntry = undefined;
        const midi_notes = activeFretMidiNotes(&original, tuning, &midi_buf);
        for (midi_notes) |entry| {
            if (isProtectedFretString(&original, tuning, entry.string_index, policy)) continue;

            for ([_]i16{ -12, 12 }) |delta| {
                const shifted = @as(i16, entry.note) + delta;
                if (shifted < 0 or shifted > 127) continue;

                var ranked_locations: [fret_assessment.MAX_RANKED_LOCATIONS]fret_assessment.RankedLocation = undefined;
                const ranked = fret_assessment.rankLocationsForMidi(@as(pitch.MidiNote, @intCast(shifted)), tuning, target_state.anchor_fret, technique, hand_override, ranked_locations[0..]);
                for (ranked) |location| {
                    if (location.location.position.string != entry.string_index and original.frets[location.location.position.string] >= 0) continue;

                    var replacement_frets = original.frets;
                    replacement_frets[entry.string_index] = -1;
                    replacement_frets[location.location.position.string] = @as(i8, @intCast(location.location.position.fret));
                    const replacement = phrase.FretPhraseEvent.init(replacement_frets[0..original.fret_count]);
                    var change_mask = bitForIndex(@intFromEnum(ChangeFlag.octave_displaced));
                    if (location.location.position.string != entry.string_index or location.location.position.fret != @as(u8, @intCast(@max(original.frets[entry.string_index], 0)))) {
                        change_mask |= bitForIndex(@intFromEnum(ChangeFlag.fret_location_changed));
                    }
                    write_len = appendFretRepairCandidate(
                        out,
                        write_len,
                        memory,
                        tuning,
                        technique,
                        hand_override,
                        before_audit.summary,
                        target_index,
                        original,
                        replacement,
                        .register_adjusted,
                        entry.string_index,
                        @as(u8, @intCast(location.location.position.string)),
                        original.frets[entry.string_index],
                        @as(i8, @intCast(location.location.position.fret)),
                        change_mask,
                        policy,
                    );
                }
            }
        }
    }

    if (@intFromEnum(policy.max_class) >= @intFromEnum(RepairClass.texture_reduced) and original.fret_count > 1) {
        var active_strings: [guitar.MAX_GENERIC_STRINGS]u8 = [_]u8{NONE_CHANGE_INDEX} ** guitar.MAX_GENERIC_STRINGS;
        const active_string_count = activeFretStringIndices(&original, active_strings[0..]);
        for (active_strings[0..active_string_count]) |string_index| {
            if (isProtectedFretString(&original, tuning, string_index, policy)) continue;

            var replacement_frets = original.frets;
            replacement_frets[string_index] = -1;
            const replacement = phrase.FretPhraseEvent.init(replacement_frets[0..original.fret_count]);
            write_len = appendFretRepairCandidate(
                out,
                write_len,
                memory,
                tuning,
                technique,
                hand_override,
                before_audit.summary,
                target_index,
                original,
                replacement,
                .texture_reduced,
                string_index,
                NONE_CHANGE_INDEX,
                original.frets[string_index],
                -1,
                bitForIndex(@intFromEnum(ChangeFlag.note_removed)),
                policy,
            );
        }
    }

    std.sort.insertion(RankedFretPhraseRepair, out[0..write_len], {}, fretRepairLessThan);
    return out[0..write_len];
}

fn appendKeyboardRepairCandidate(
    out: []RankedKeyboardPhraseRepair,
    write_len: usize,
    memory: *const phrase.KeyboardCommittedPhraseMemory,
    hand_profile: types.HandProfile,
    before_summary: phrase.PhraseSummary,
    target_index: usize,
    original: phrase.KeyboardPhraseEvent,
    replacement: phrase.KeyboardPhraseEvent,
    repair_class: RepairClass,
    changed_from_index: u8,
    changed_to_index: u8,
    changed_from_value: u8,
    changed_to_value: u8,
    change_mask: u32,
    policy: RepairPolicy,
) usize {
    if (write_len >= out.len) return write_len;
    if (keyboardEventsEqual(&original, &replacement)) return write_len;

    var repaired: [phrase.MAX_PHRASE_EVENTS]phrase.KeyboardPhraseEvent = undefined;
    const repaired_events = rewriteKeyboardPhrase(memory, target_index, replacement, &repaired);

    var after_issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    const after_audit = phrase.auditKeyboardPhrase(repaired_events, hand_profile, after_issues[0..]);
    if (!repairImproves(before_summary, after_audit.summary)) return write_len;

    const preserved_mask = keyboardPreservationMask(&original, &replacement);
    if (policy.preserve_bass and !hasBit(preserved_mask, @intFromEnum(PreservationFlag.bass_preserved))) return write_len;
    if (policy.preserve_top_voice and !hasBit(preserved_mask, @intFromEnum(PreservationFlag.top_voice_preserved))) return write_len;

    out[write_len] = .{
        .repair_class = repair_class,
        .target_event_index = @as(u16, @intCast(target_index)),
        .changed_from_index = changed_from_index,
        .changed_to_index = changed_to_index,
        .changed_from_value = changed_from_value,
        .changed_to_value = changed_to_value,
        .crossed_musical_change_boundary = repair_class != .realization_only,
        .hand = replacement.hand,
        .preserved_mask = preserved_mask,
        .change_mask = change_mask,
        .bottleneck_lift = intLift(before_summary.bottleneck_magnitude, after_audit.summary.bottleneck_magnitude),
        .issue_lift = intLift(before_summary.issue_count, after_audit.summary.issue_count),
        .blocked_issue_lift = intLift(before_summary.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)], after_audit.summary.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)]),
        .warning_issue_lift = intLift(before_summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)], after_audit.summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)]),
        .before_summary = before_summary,
        .after_summary = after_audit.summary,
        .replacement_event = replacement,
    };
    return write_len + 1;
}

fn appendFretRepairCandidate(
    out: []RankedFretPhraseRepair,
    write_len: usize,
    memory: *const phrase.FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    before_summary: phrase.PhraseSummary,
    target_index: usize,
    original: phrase.FretPhraseEvent,
    replacement: phrase.FretPhraseEvent,
    repair_class: RepairClass,
    changed_from_index: u8,
    changed_to_index: u8,
    changed_from_value: i8,
    changed_to_value: i8,
    change_mask: u32,
    policy: RepairPolicy,
) usize {
    if (write_len >= out.len) return write_len;
    if (fretEventsEqual(&original, &replacement)) return write_len;

    var repaired: [phrase.MAX_PHRASE_EVENTS]phrase.FretPhraseEvent = undefined;
    const repaired_events = rewriteFretPhrase(memory, target_index, replacement, &repaired);

    var after_issues: [phrase.MAX_PHRASE_AUDIT_ISSUES]phrase.PhraseIssue = undefined;
    const after_audit = phrase.auditFretPhrase(repaired_events, tuning, technique, hand_override, after_issues[0..]);
    if (!repairImproves(before_summary, after_audit.summary)) return write_len;

    const preserved_mask = fretPreservationMask(&original, &replacement, tuning);
    if (policy.preserve_bass and !hasBit(preserved_mask, @intFromEnum(PreservationFlag.bass_preserved))) return write_len;
    if (policy.preserve_top_voice and !hasBit(preserved_mask, @intFromEnum(PreservationFlag.top_voice_preserved))) return write_len;

    out[write_len] = .{
        .repair_class = repair_class,
        .target_event_index = @as(u16, @intCast(target_index)),
        .changed_from_index = changed_from_index,
        .changed_to_index = changed_to_index,
        .changed_from_value = changed_from_value,
        .changed_to_value = changed_to_value,
        .crossed_musical_change_boundary = repair_class != .realization_only,
        .technique = technique,
        .preserved_mask = preserved_mask,
        .change_mask = change_mask,
        .bottleneck_lift = intLift(before_summary.bottleneck_magnitude, after_audit.summary.bottleneck_magnitude),
        .issue_lift = intLift(before_summary.issue_count, after_audit.summary.issue_count),
        .blocked_issue_lift = intLift(before_summary.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)], after_audit.summary.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)]),
        .warning_issue_lift = intLift(before_summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)], after_audit.summary.severity_counts[@intFromEnum(phrase.IssueSeverity.warning)]),
        .before_summary = before_summary,
        .after_summary = after_audit.summary,
        .replacement_event = replacement,
    };
    return write_len + 1;
}

fn rewriteKeyboardPhrase(
    memory: *const phrase.KeyboardCommittedPhraseMemory,
    target_index: usize,
    replacement: phrase.KeyboardPhraseEvent,
    out: *[phrase.MAX_PHRASE_EVENTS]phrase.KeyboardPhraseEvent,
) []const phrase.KeyboardPhraseEvent {
    const events = memory.slice();
    for (events, 0..) |event, index| {
        out[index] = if (index == target_index) replacement else event;
    }
    return out[0..events.len];
}

fn rewriteFretPhrase(
    memory: *const phrase.FretCommittedPhraseMemory,
    target_index: usize,
    replacement: phrase.FretPhraseEvent,
    out: *[phrase.MAX_PHRASE_EVENTS]phrase.FretPhraseEvent,
) []const phrase.FretPhraseEvent {
    const events = memory.slice();
    for (events, 0..) |event, index| {
        out[index] = if (index == target_index) replacement else event;
    }
    return out[0..events.len];
}

fn primaryRepairTarget(summary: phrase.PhraseSummary, issues: []const phrase.PhraseIssue) ?usize {
    if (summary.first_blocked_event_index != phrase.NONE_EVENT_INDEX) return summary.first_blocked_event_index;
    if (summary.first_blocked_transition_to_index != phrase.NONE_EVENT_INDEX) return summary.first_blocked_transition_to_index;
    if (summary.bottleneck_issue_index != phrase.NONE_EVENT_INDEX and summary.bottleneck_issue_index < issues.len) {
        const issue = issues[summary.bottleneck_issue_index];
        return switch (issue.scope) {
            .event => issue.event_index,
            .transition => issue.related_event_index,
        };
    }
    if (summary.recovery_deficit_end_index != phrase.NONE_EVENT_INDEX) return summary.recovery_deficit_end_index;
    return null;
}

fn keyboardPreservationMask(before: *const phrase.KeyboardPhraseEvent, after: *const phrase.KeyboardPhraseEvent) u32 {
    return notePreservationMask(
        phrase.keyboardPhraseNotes(before),
        phrase.keyboardPhraseNotes(after),
        true,
    );
}

fn fretPreservationMask(before: *const phrase.FretPhraseEvent, after: *const phrase.FretPhraseEvent, tuning: []const pitch.MidiNote) u32 {
    var before_buf: [guitar.MAX_GENERIC_STRINGS]pitch.MidiNote = undefined;
    var after_buf: [guitar.MAX_GENERIC_STRINGS]pitch.MidiNote = undefined;
    var mask = notePreservationMask(
        fretEventMidiNotes(before, tuning, &before_buf),
        fretEventMidiNotes(after, tuning, &after_buf),
        true,
    );
    if (std.mem.eql(i8, phrase.fretPhraseFrets(before), phrase.fretPhraseFrets(after))) {
        mask |= bitForIndex(@intFromEnum(PreservationFlag.exact_frets_preserved));
    }
    return mask;
}

fn notePreservationMask(before_notes: []const pitch.MidiNote, after_notes: []const pitch.MidiNote, include_exact_pitches: bool) u32 {
    var mask: u32 = 0;
    if (before_notes.len > 0 and after_notes.len > 0) {
        var before_sorted: [guitar.MAX_GENERIC_STRINGS]pitch.MidiNote = [_]pitch.MidiNote{0} ** guitar.MAX_GENERIC_STRINGS;
        var after_sorted: [guitar.MAX_GENERIC_STRINGS]pitch.MidiNote = [_]pitch.MidiNote{0} ** guitar.MAX_GENERIC_STRINGS;
        @memcpy(before_sorted[0..before_notes.len], before_notes);
        @memcpy(after_sorted[0..after_notes.len], after_notes);
        sortMidi(before_sorted[0..before_notes.len]);
        sortMidi(after_sorted[0..after_notes.len]);

        if (before_sorted[0] == after_sorted[0]) {
            mask |= bitForIndex(@intFromEnum(PreservationFlag.bass_preserved));
        }
        if (before_sorted[before_notes.len - 1] == after_sorted[after_notes.len - 1]) {
            mask |= bitForIndex(@intFromEnum(PreservationFlag.top_voice_preserved));
        }
        if (pitchClassSetForNotes(before_notes) == pitchClassSetForNotes(after_notes)) {
            mask |= bitForIndex(@intFromEnum(PreservationFlag.pitch_classes_preserved));
        }
        if (before_notes.len == after_notes.len) {
            mask |= bitForIndex(@intFromEnum(PreservationFlag.note_count_preserved));
            if (include_exact_pitches and std.mem.eql(pitch.MidiNote, before_sorted[0..before_notes.len], after_sorted[0..after_notes.len])) {
                mask |= bitForIndex(@intFromEnum(PreservationFlag.exact_pitches_preserved));
            }
        }
    } else {
        if (before_notes.len == after_notes.len) {
            mask |= bitForIndex(@intFromEnum(PreservationFlag.note_count_preserved));
            mask |= bitForIndex(@intFromEnum(PreservationFlag.pitch_classes_preserved));
            if (include_exact_pitches) {
                mask |= bitForIndex(@intFromEnum(PreservationFlag.exact_pitches_preserved));
            }
        }
    }
    return mask;
}

fn pitchClassSetForNotes(notes: []const pitch.MidiNote) pcs.PitchClassSet {
    var out: pcs.PitchClassSet = 0;
    for (notes) |note| {
        out |= (@as(pcs.PitchClassSet, 1) << @as(pitch.PitchClass, @intCast(note % 12)));
    }
    return out;
}

fn fretEventMidiNotes(
    event: *const phrase.FretPhraseEvent,
    tuning: []const pitch.MidiNote,
    out: *[guitar.MAX_GENERIC_STRINGS]pitch.MidiNote,
) []const pitch.MidiNote {
    var count: usize = 0;
    const fret_count = @min(phrase.fretPhraseFrets(event).len, tuning.len);
    for (phrase.fretPhraseFrets(event)[0..fret_count], 0..) |fret, string_index| {
        if (fret < 0) continue;
        out[count] = tuning[string_index] + @as(pitch.MidiNote, @intCast(fret));
        count += 1;
    }
    return out[0..count];
}

const FretMidiEntry = struct {
    note: pitch.MidiNote,
    string_index: u8,
};

fn activeFretMidiNotes(
    event: *const phrase.FretPhraseEvent,
    tuning: []const pitch.MidiNote,
    out: *[guitar.MAX_GENERIC_STRINGS]FretMidiEntry,
) []const FretMidiEntry {
    var count: usize = 0;
    const fret_count = @min(phrase.fretPhraseFrets(event).len, tuning.len);
    for (phrase.fretPhraseFrets(event)[0..fret_count], 0..) |fret, string_index| {
        if (fret < 0) continue;
        out[count] = .{
            .note = tuning[string_index] + @as(pitch.MidiNote, @intCast(fret)),
            .string_index = @as(u8, @intCast(string_index)),
        };
        count += 1;
    }
    return out[0..count];
}

fn activeFretStringIndices(event: *const phrase.FretPhraseEvent, out: []u8) usize {
    var count: usize = 0;
    for (phrase.fretPhraseFrets(event), 0..) |fret, string_index| {
        if (fret < 0 or count >= out.len) continue;
        out[count] = @as(u8, @intCast(string_index));
        count += 1;
    }
    return count;
}

fn isProtectedKeyboardIndex(event: *const phrase.KeyboardPhraseEvent, note_index: u8, policy: RepairPolicy) bool {
    if (event.note_count == 0) return true;
    if (policy.preserve_bass and note_index == 0) return true;
    if (policy.preserve_top_voice and note_index + 1 == event.note_count) return true;
    return false;
}

fn isProtectedFretString(event: *const phrase.FretPhraseEvent, tuning: []const pitch.MidiNote, string_index: u8, policy: RepairPolicy) bool {
    if (!policy.preserve_bass and !policy.preserve_top_voice) return false;

    var midi_buf: [guitar.MAX_GENERIC_STRINGS]FretMidiEntry = undefined;
    const entries = activeFretMidiNotes(event, tuning, &midi_buf);
    if (entries.len == 0) return false;

    var min_entry = entries[0];
    var max_entry = entries[0];
    for (entries[1..]) |entry| {
        if (entry.note < min_entry.note) min_entry = entry;
        if (entry.note > max_entry.note) max_entry = entry;
    }

    if (policy.preserve_bass and string_index == min_entry.string_index) return true;
    if (policy.preserve_top_voice and string_index == max_entry.string_index) return true;
    return false;
}

fn orderedKeyboardIndices(note_count: u8, prefer_inner: bool) [keyboard_assessment.MAX_FINGERING_NOTES]u8 {
    var out: [keyboard_assessment.MAX_FINGERING_NOTES]u8 = [_]u8{ 0, 1, 2, 3, 4 };
    if (!prefer_inner or note_count <= 2) return out;

    var write_index: usize = 0;
    if (note_count > 2) {
        var left: i8 = @as(i8, @intCast(note_count / 2));
        var right: i8 = left + @as(i8, @intCast((note_count + 1) % 2));
        while (left >= 0 or right < note_count) {
            if (left >= 1 and left < note_count - 1) {
                out[write_index] = @as(u8, @intCast(left));
                write_index += 1;
            }
            if (right >= 1 and right < note_count - 1 and right != left) {
                out[write_index] = @as(u8, @intCast(right));
                write_index += 1;
            }
            left -= 1;
            right += 1;
        }
    }
    var idx: u8 = 0;
    while (idx < note_count) : (idx += 1) {
        var seen = false;
        for (out[0..write_index]) |value| {
            if (value == idx) {
                seen = true;
                break;
            }
        }
        if (!seen) {
            out[write_index] = idx;
            write_index += 1;
        }
    }
    return out;
}

fn keyboardEventsEqual(a: *const phrase.KeyboardPhraseEvent, b: *const phrase.KeyboardPhraseEvent) bool {
    return a.note_count == b.note_count and
        a.hand == b.hand and
        std.mem.eql(pitch.MidiNote, a.notes[0..a.note_count], b.notes[0..b.note_count]);
}

fn fretEventsEqual(a: *const phrase.FretPhraseEvent, b: *const phrase.FretPhraseEvent) bool {
    return a.fret_count == b.fret_count and
        std.mem.eql(i8, a.frets[0..a.fret_count], b.frets[0..b.fret_count]);
}

fn sortMidi(notes: []pitch.MidiNote) void {
    std.sort.insertion(pitch.MidiNote, notes, {}, midiLessThan);
}

fn midiLessThan(_: void, a: pitch.MidiNote, b: pitch.MidiNote) bool {
    return a < b;
}

fn repairImproves(before: phrase.PhraseSummary, after: phrase.PhraseSummary) bool {
    if (@intFromEnum(after.strain_bucket) < @intFromEnum(before.strain_bucket)) return true;
    if (@intFromEnum(after.bottleneck_severity) < @intFromEnum(before.bottleneck_severity)) return true;
    if (after.bottleneck_magnitude < before.bottleneck_magnitude) return true;
    if (after.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)] < before.severity_counts[@intFromEnum(phrase.IssueSeverity.blocked)]) return true;
    if (after.issue_count < before.issue_count) return true;
    return false;
}

fn keyboardRepairLessThan(_: void, a: RankedKeyboardPhraseRepair, b: RankedKeyboardPhraseRepair) bool {
    if (a.crossed_musical_change_boundary != b.crossed_musical_change_boundary) {
        return !a.crossed_musical_change_boundary and b.crossed_musical_change_boundary;
    }
    if (a.after_summary.strain_bucket != b.after_summary.strain_bucket) {
        return @intFromEnum(a.after_summary.strain_bucket) < @intFromEnum(b.after_summary.strain_bucket);
    }
    if (a.after_summary.bottleneck_severity != b.after_summary.bottleneck_severity) {
        return @intFromEnum(a.after_summary.bottleneck_severity) < @intFromEnum(b.after_summary.bottleneck_severity);
    }
    if (a.blocked_issue_lift != b.blocked_issue_lift) return a.blocked_issue_lift > b.blocked_issue_lift;
    if (a.bottleneck_lift != b.bottleneck_lift) return a.bottleneck_lift > b.bottleneck_lift;
    if (a.issue_lift != b.issue_lift) return a.issue_lift > b.issue_lift;
    if (a.repair_class != b.repair_class) return @intFromEnum(a.repair_class) < @intFromEnum(b.repair_class);
    return a.target_event_index < b.target_event_index;
}

fn fretRepairLessThan(_: void, a: RankedFretPhraseRepair, b: RankedFretPhraseRepair) bool {
    if (a.crossed_musical_change_boundary != b.crossed_musical_change_boundary) {
        return !a.crossed_musical_change_boundary and b.crossed_musical_change_boundary;
    }
    if (a.after_summary.strain_bucket != b.after_summary.strain_bucket) {
        return @intFromEnum(a.after_summary.strain_bucket) < @intFromEnum(b.after_summary.strain_bucket);
    }
    if (a.after_summary.bottleneck_severity != b.after_summary.bottleneck_severity) {
        return @intFromEnum(a.after_summary.bottleneck_severity) < @intFromEnum(b.after_summary.bottleneck_severity);
    }
    if (a.blocked_issue_lift != b.blocked_issue_lift) return a.blocked_issue_lift > b.blocked_issue_lift;
    if (a.bottleneck_lift != b.bottleneck_lift) return a.bottleneck_lift > b.bottleneck_lift;
    if (a.issue_lift != b.issue_lift) return a.issue_lift > b.issue_lift;
    if (a.repair_class != b.repair_class) return @intFromEnum(a.repair_class) < @intFromEnum(b.repair_class);
    return a.target_event_index < b.target_event_index;
}

fn intLift(before: anytype, after: anytype) i16 {
    return @as(i16, @intCast(@as(i32, before) - @as(i32, after)));
}

fn bitForIndex(index: usize) u32 {
    if (index >= 32) return 0;
    return @as(u32, 1) << @as(u5, @intCast(index));
}

fn hasBit(mask: u32, index: usize) bool {
    return (mask & bitForIndex(index)) != 0;
}

test "repair policy defaults preserve outer voices and allow hand reassignment" {
    const policy = RepairPolicy.defaultForClass(.texture_reduced);
    try std.testing.expectEqual(RepairClass.texture_reduced, policy.max_class);
    try std.testing.expect(policy.preserve_bass);
    try std.testing.expect(policy.preserve_top_voice);
    try std.testing.expect(policy.allow_hand_reassignment);
}
