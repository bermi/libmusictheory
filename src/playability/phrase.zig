const std = @import("std");
const pitch = @import("../pitch.zig");
const guitar = @import("../guitar.zig");
const fret_assessment = @import("fret_assessment.zig");
const keyboard_assessment = @import("keyboard_assessment.zig");
const types = @import("types.zig");

pub const MAX_PHRASE_EVENTS: usize = 64;
pub const MAX_PHRASE_AUDIT_ISSUES: usize = 4096;
pub const MAX_PHRASE_BRANCH_STEPS: usize = 8;
pub const MAX_BRANCH_STEP_CANDIDATES: usize = 8;
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
        for (notes[0..out.note_count], 0..) |note, index| {
            out.notes[index] = note;
        }
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

pub const KeyboardPhraseBranch = struct {
    step_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    steps: [MAX_PHRASE_BRANCH_STEPS]KeyboardPhraseEvent,

    pub fn init() KeyboardPhraseBranch {
        return .{
            .step_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .steps = [_]KeyboardPhraseEvent{KeyboardPhraseEvent.init(&[_]pitch.MidiNote{}, .right)} ** MAX_PHRASE_BRANCH_STEPS,
        };
    }

    pub fn reset(self: *KeyboardPhraseBranch) void {
        self.* = init();
    }

    pub fn len(self: *const KeyboardPhraseBranch) usize {
        return @min(@as(usize, self.step_count), MAX_PHRASE_BRANCH_STEPS);
    }

    pub fn slice(self: *const KeyboardPhraseBranch) []const KeyboardPhraseEvent {
        return self.steps[0..self.len()];
    }

    pub fn push(self: *KeyboardPhraseBranch, event: KeyboardPhraseEvent) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_BRANCH_STEPS) return false;
        self.steps[count] = event;
        self.step_count = @as(u8, @intCast(count + 1));
        return true;
    }
};

pub const FretPhraseBranch = struct {
    step_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    steps: [MAX_PHRASE_BRANCH_STEPS]FretPhraseEvent,

    pub fn init() FretPhraseBranch {
        return .{
            .step_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .steps = [_]FretPhraseEvent{FretPhraseEvent.init(&[_]i8{})} ** MAX_PHRASE_BRANCH_STEPS,
        };
    }

    pub fn reset(self: *FretPhraseBranch) void {
        self.* = init();
    }

    pub fn len(self: *const FretPhraseBranch) usize {
        return @min(@as(usize, self.step_count), MAX_PHRASE_BRANCH_STEPS);
    }

    pub fn slice(self: *const FretPhraseBranch) []const FretPhraseEvent {
        return self.steps[0..self.len()];
    }

    pub fn push(self: *FretPhraseBranch, event: FretPhraseEvent) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_BRANCH_STEPS) return false;
        self.steps[count] = event;
        self.step_count = @as(u8, @intCast(count + 1));
        return true;
    }
};

pub const KeyboardPhraseStepCandidates = struct {
    candidate_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    candidates: [MAX_BRANCH_STEP_CANDIDATES]KeyboardPhraseEvent,

    pub fn init(candidates: []const KeyboardPhraseEvent) KeyboardPhraseStepCandidates {
        var out = KeyboardPhraseStepCandidates{
            .candidate_count = @as(u8, @intCast(@min(candidates.len, MAX_BRANCH_STEP_CANDIDATES))),
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .candidates = [_]KeyboardPhraseEvent{KeyboardPhraseEvent.init(&[_]pitch.MidiNote{}, .right)} ** MAX_BRANCH_STEP_CANDIDATES,
        };
        for (candidates[0..out.candidate_count], 0..) |candidate, index| {
            out.candidates[index] = candidate;
        }
        return out;
    }

    pub fn len(self: *const KeyboardPhraseStepCandidates) usize {
        return @min(@as(usize, self.candidate_count), MAX_BRANCH_STEP_CANDIDATES);
    }

    pub fn slice(self: *const KeyboardPhraseStepCandidates) []const KeyboardPhraseEvent {
        return self.candidates[0..self.len()];
    }
};

pub const FretPhraseStepCandidates = struct {
    candidate_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    candidates: [MAX_BRANCH_STEP_CANDIDATES]FretPhraseEvent,

    pub fn init(candidates: []const FretPhraseEvent) FretPhraseStepCandidates {
        var out = FretPhraseStepCandidates{
            .candidate_count = @as(u8, @intCast(@min(candidates.len, MAX_BRANCH_STEP_CANDIDATES))),
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .candidates = [_]FretPhraseEvent{FretPhraseEvent.init(&[_]i8{})} ** MAX_BRANCH_STEP_CANDIDATES,
        };
        for (candidates[0..out.candidate_count], 0..) |candidate, index| {
            out.candidates[index] = candidate;
        }
        return out;
    }

    pub fn len(self: *const FretPhraseStepCandidates) usize {
        return @min(@as(usize, self.candidate_count), MAX_BRANCH_STEP_CANDIDATES);
    }

    pub fn slice(self: *const FretPhraseStepCandidates) []const FretPhraseEvent {
        return self.candidates[0..self.len()];
    }
};

pub const KeyboardPhraseCandidateWindow = struct {
    step_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    steps: [MAX_PHRASE_BRANCH_STEPS]KeyboardPhraseStepCandidates,

    pub fn init() KeyboardPhraseCandidateWindow {
        return .{
            .step_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .steps = [_]KeyboardPhraseStepCandidates{KeyboardPhraseStepCandidates.init(&[_]KeyboardPhraseEvent{})} ** MAX_PHRASE_BRANCH_STEPS,
        };
    }

    pub fn reset(self: *KeyboardPhraseCandidateWindow) void {
        self.* = init();
    }

    pub fn len(self: *const KeyboardPhraseCandidateWindow) usize {
        return @min(@as(usize, self.step_count), MAX_PHRASE_BRANCH_STEPS);
    }

    pub fn slice(self: *const KeyboardPhraseCandidateWindow) []const KeyboardPhraseStepCandidates {
        return self.steps[0..self.len()];
    }

    pub fn push(self: *KeyboardPhraseCandidateWindow, step: KeyboardPhraseStepCandidates) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_BRANCH_STEPS) return false;
        self.steps[count] = step;
        self.step_count = @as(u8, @intCast(count + 1));
        return true;
    }
};

pub const FretPhraseCandidateWindow = struct {
    step_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    steps: [MAX_PHRASE_BRANCH_STEPS]FretPhraseStepCandidates,

    pub fn init() FretPhraseCandidateWindow {
        return .{
            .step_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .steps = [_]FretPhraseStepCandidates{FretPhraseStepCandidates.init(&[_]FretPhraseEvent{})} ** MAX_PHRASE_BRANCH_STEPS,
        };
    }

    pub fn reset(self: *FretPhraseCandidateWindow) void {
        self.* = init();
    }

    pub fn len(self: *const FretPhraseCandidateWindow) usize {
        return @min(@as(usize, self.step_count), MAX_PHRASE_BRANCH_STEPS);
    }

    pub fn slice(self: *const FretPhraseCandidateWindow) []const FretPhraseStepCandidates {
        return self.steps[0..self.len()];
    }

    pub fn push(self: *FretPhraseCandidateWindow, step: FretPhraseStepCandidates) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_BRANCH_STEPS) return false;
        self.steps[count] = step;
        self.step_count = @as(u8, @intCast(count + 1));
        return true;
    }
};

pub const KeyboardCommittedPhraseMemory = struct {
    event_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    events: [MAX_PHRASE_EVENTS]KeyboardPhraseEvent,

    pub fn init() KeyboardCommittedPhraseMemory {
        return .{
            .event_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .events = [_]KeyboardPhraseEvent{KeyboardPhraseEvent.init(&[_]pitch.MidiNote{}, .right)} ** MAX_PHRASE_EVENTS,
        };
    }

    pub fn reset(self: *KeyboardCommittedPhraseMemory) void {
        self.* = init();
    }

    pub fn len(self: *const KeyboardCommittedPhraseMemory) usize {
        return @min(@as(usize, self.event_count), MAX_PHRASE_EVENTS);
    }

    pub fn slice(self: *const KeyboardCommittedPhraseMemory) []const KeyboardPhraseEvent {
        return self.events[0..self.len()];
    }

    pub fn current(self: *const KeyboardCommittedPhraseMemory) ?*const KeyboardPhraseEvent {
        const count = self.len();
        if (count == 0) return null;
        return &self.events[count - 1];
    }

    pub fn previous(self: *const KeyboardCommittedPhraseMemory) ?*const KeyboardPhraseEvent {
        const count = self.len();
        if (count < 2) return null;
        return &self.events[count - 2];
    }

    pub fn push(self: *KeyboardCommittedPhraseMemory, event: KeyboardPhraseEvent) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_EVENTS) return false;
        self.events[count] = event;
        self.event_count = @as(u8, @intCast(count + 1));
        return true;
    }

    pub fn loadBeforeCurrent(self: *const KeyboardCommittedPhraseMemory, profile: types.HandProfile) ?types.TemporalLoadState {
        const count = self.len();
        if (count < 2) return null;

        var maybe_load: ?types.TemporalLoadState = null;
        var index: usize = 0;
        while (index + 1 < count) : (index += 1) {
            const event = self.events[index];
            const realization = keyboard_assessment.assessRealization(
                keyboardPhraseNotes(&event),
                event.hand,
                profile,
                maybe_load,
            );
            maybe_load = realization.state.load;
        }
        return maybe_load;
    }
};

pub const FretCommittedPhraseMemory = struct {
    event_count: u8,
    reserved0: u8,
    reserved1: u8,
    reserved2: u8,
    events: [MAX_PHRASE_EVENTS]FretPhraseEvent,

    pub fn init() FretCommittedPhraseMemory {
        return .{
            .event_count = 0,
            .reserved0 = 0,
            .reserved1 = 0,
            .reserved2 = 0,
            .events = [_]FretPhraseEvent{FretPhraseEvent.init(&[_]i8{})} ** MAX_PHRASE_EVENTS,
        };
    }

    pub fn reset(self: *FretCommittedPhraseMemory) void {
        self.* = init();
    }

    pub fn len(self: *const FretCommittedPhraseMemory) usize {
        return @min(@as(usize, self.event_count), MAX_PHRASE_EVENTS);
    }

    pub fn slice(self: *const FretCommittedPhraseMemory) []const FretPhraseEvent {
        return self.events[0..self.len()];
    }

    pub fn current(self: *const FretCommittedPhraseMemory) ?*const FretPhraseEvent {
        const count = self.len();
        if (count == 0) return null;
        return &self.events[count - 1];
    }

    pub fn previous(self: *const FretCommittedPhraseMemory) ?*const FretPhraseEvent {
        const count = self.len();
        if (count < 2) return null;
        return &self.events[count - 2];
    }

    pub fn push(self: *FretCommittedPhraseMemory, event: FretPhraseEvent) bool {
        const count = self.len();
        if (count >= MAX_PHRASE_EVENTS) return false;
        self.events[count] = event;
        self.event_count = @as(u8, @intCast(count + 1));
        return true;
    }

    pub fn loadBeforeCurrent(
        self: *const FretCommittedPhraseMemory,
        tuning: []const pitch.MidiNote,
        technique: fret_assessment.TechniqueProfile,
        hand_override: ?types.HandProfile,
    ) ?types.TemporalLoadState {
        const count = self.len();
        if (count < 2) return null;

        var maybe_load: ?types.TemporalLoadState = null;
        var index: usize = 0;
        while (index + 1 < count) : (index += 1) {
            const realization = fret_assessment.assessRealization(
                fretPhraseFrets(&self.events[index]),
                tuning,
                technique,
                hand_override,
                maybe_load,
            );
            maybe_load = realization.state.load;
        }
        return maybe_load;
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

pub const PhraseBranchSummary = struct {
    step_count: u16,
    first_blocked_step_index: u16,
    first_blocked_transition_from_index: u16,
    first_blocked_transition_to_index: u16,
    peak_strain_step_index: u16,
    peak_strain_magnitude: u16,
    improving_window_count: u16,
    deficit_window_count: u16,
    neutral_window_count: u16,
    strain_bucket: StrainBucket,
    dominant_reason_family: u8,
    dominant_warning_family: u8,
    reserved0: u8,
    reserved1: u8,

    pub fn empty(step_count: usize) PhraseBranchSummary {
        return .{
            .step_count = @as(u16, @intCast(@min(step_count, MAX_PHRASE_BRANCH_STEPS))),
            .first_blocked_step_index = NONE_EVENT_INDEX,
            .first_blocked_transition_from_index = NONE_EVENT_INDEX,
            .first_blocked_transition_to_index = NONE_EVENT_INDEX,
            .peak_strain_step_index = NONE_EVENT_INDEX,
            .peak_strain_magnitude = 0,
            .improving_window_count = 0,
            .deficit_window_count = 0,
            .neutral_window_count = 0,
            .strain_bucket = .neutral,
            .dominant_reason_family = NONE_FAMILY_INDEX,
            .dominant_warning_family = NONE_FAMILY_INDEX,
            .reserved0 = 0,
            .reserved1 = 0,
        };
    }
};

pub const PhraseAuditResult = struct {
    logical_issue_count: usize,
    written_issue_count: usize,
    truncated: bool,
    summary: PhraseSummary,
};

pub fn summarizeBranchIssues(step_count: usize, issues: []const PhraseIssue) PhraseBranchSummary {
    const bounded_step_count = boundedBranchStepCount(step_count);
    var branch_summary = PhraseBranchSummary.empty(bounded_step_count);
    var accumulator = SummaryAccumulator.init(bounded_step_count);

    var best_issue_target = NONE_EVENT_INDEX;
    for (issues, 0..) |issue, issue_index| {
        const target_index = issueTargetIndex(issue);
        if (target_index == NONE_EVENT_INDEX or target_index >= bounded_step_count) continue;
        if (issue.scope == .transition and (issue.event_index >= bounded_step_count or issue.related_event_index >= bounded_step_count)) continue;

        if (branch_summary.peak_strain_step_index == NONE_EVENT_INDEX or shouldPromoteBottleneck(issue, issue_index, accumulator.summary)) {
            best_issue_target = target_index;
        }
        accumulator.observeIssue(issue, issue_index);
    }

    const phrase_summary = accumulator.finish();
    const bounded_mask = eventMask(phrase_summary.event_count);
    const deficit_mask = (accumulator.strain_mask & ~accumulator.relief_mask) & bounded_mask;
    const improving_mask = (accumulator.relief_mask & ~accumulator.strain_mask) & bounded_mask;
    const deficit_count: u16 = @as(u16, @intCast(@popCount(deficit_mask)));
    const improving_count: u16 = @as(u16, @intCast(@popCount(improving_mask)));
    const neutral_count: u16 = phrase_summary.event_count - deficit_count - improving_count;

    branch_summary.step_count = phrase_summary.event_count;
    branch_summary.first_blocked_step_index = if (phrase_summary.first_blocked_event_index != NONE_EVENT_INDEX)
        phrase_summary.first_blocked_event_index
    else
        phrase_summary.first_blocked_transition_to_index;
    branch_summary.first_blocked_transition_from_index = phrase_summary.first_blocked_transition_from_index;
    branch_summary.first_blocked_transition_to_index = phrase_summary.first_blocked_transition_to_index;
    branch_summary.peak_strain_step_index = best_issue_target;
    branch_summary.peak_strain_magnitude = phrase_summary.bottleneck_magnitude;
    branch_summary.improving_window_count = improving_count;
    branch_summary.deficit_window_count = deficit_count;
    branch_summary.neutral_window_count = neutral_count;
    branch_summary.strain_bucket = phrase_summary.strain_bucket;
    branch_summary.dominant_reason_family = phrase_summary.dominant_reason_family;
    branch_summary.dominant_warning_family = phrase_summary.dominant_warning_family;
    return branch_summary;
}

pub fn summarizeKeyboardBranch(branch: *const KeyboardPhraseBranch, profile: types.HandProfile) PhraseBranchSummary {
    var issues: [MAX_PHRASE_AUDIT_ISSUES]PhraseIssue = undefined;
    const result = auditKeyboardPhrase(branch.slice(), profile, issues[0..]);
    return summarizeBranchIssues(branch.len(), issues[0..result.logical_issue_count]);
}

pub fn summarizeKeyboardBranchAgainstCommittedPhrase(
    memory: *const KeyboardCommittedPhraseMemory,
    branch: *const KeyboardPhraseBranch,
    profile: types.HandProfile,
) PhraseBranchSummary {
    var issues: [MAX_PHRASE_AUDIT_ISSUES]PhraseIssue = undefined;
    const result = auditKeyboardBranchAgainstCommittedPhrase(memory, branch, profile, issues[0..]);
    return summarizeBranchIssues(branch.len(), issues[0..result.logical_issue_count]);
}

pub fn summarizeFretBranch(
    branch: *const FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
) PhraseBranchSummary {
    var issues: [MAX_PHRASE_AUDIT_ISSUES]PhraseIssue = undefined;
    const result = auditFretPhrase(branch.slice(), tuning, technique, hand_override, issues[0..]);
    return summarizeBranchIssues(branch.len(), issues[0..result.logical_issue_count]);
}

pub fn summarizeFretBranchAgainstCommittedPhrase(
    memory: *const FretCommittedPhraseMemory,
    branch: *const FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
) PhraseBranchSummary {
    var issues: [MAX_PHRASE_AUDIT_ISSUES]PhraseIssue = undefined;
    const result = auditFretBranchAgainstCommittedPhrase(memory, branch, tuning, technique, hand_override, issues[0..]);
    return summarizeBranchIssues(branch.len(), issues[0..result.logical_issue_count]);
}

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
                if (isReliefReason(issue.family_index)) {
                    markEvent(&self.relief_mask, target_index);
                }
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

const AuditBuilder = struct {
    out: []PhraseIssue,
    accumulator: SummaryAccumulator,
    warning_masks: [MAX_PHRASE_EVENTS]u32,
    continuity_reset_mask: u64,
    logical_issue_count: usize,
    written_issue_count: usize,

    fn init(event_count: usize, out: []PhraseIssue) AuditBuilder {
        return .{
            .out = out,
            .accumulator = SummaryAccumulator.init(event_count),
            .warning_masks = [_]u32{0} ** MAX_PHRASE_EVENTS,
            .continuity_reset_mask = 0,
            .logical_issue_count = 0,
            .written_issue_count = 0,
        };
    }

    fn appendIssue(self: *AuditBuilder, issue: PhraseIssue, track_warning_mask: bool) void {
        self.accumulator.observeIssue(issue, self.logical_issue_count);
        if (track_warning_mask and issue.family_domain == .playability_warning and issue.family_index < 32) {
            const target_index = issueTargetIndex(issue);
            if (target_index < self.accumulator.summary.event_count) {
                self.warning_masks[target_index] |= bitForIndex(issue.family_index);
            }
        }
        if (self.written_issue_count < self.out.len) {
            self.out[self.written_issue_count] = issue;
            self.written_issue_count += 1;
        }
        self.logical_issue_count += 1;
    }

    fn appendLocalIssue(self: *AuditBuilder, issue: PhraseIssue) void {
        self.appendIssue(issue, true);
    }

    fn appendPhraseIssue(self: *AuditBuilder, issue: PhraseIssue) void {
        self.appendIssue(issue, false);
    }

    fn noteContinuityReset(self: *AuditBuilder, event_index: u16) void {
        markEvent(&self.continuity_reset_mask, event_index);
        self.appendPhraseIssue(PhraseIssue.eventIssue(
            .advisory,
            .playability_reason,
            @as(u8, @intFromEnum(types.ReasonKind.hand_continuity_reset)),
            event_index,
            0,
        ));
    }

    fn finish(self: *AuditBuilder) PhraseAuditResult {
        return .{
            .logical_issue_count = self.logical_issue_count,
            .written_issue_count = self.written_issue_count,
            .truncated = self.logical_issue_count > self.written_issue_count,
            .summary = self.accumulator.finish(),
        };
    }
};

const WarningCluster = struct {
    family_index: u8,
    start_index: u16,
    end_index: u16,
    length: u16,
};

pub fn auditKeyboardPhrase(
    events: []const KeyboardPhraseEvent,
    profile: types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    return auditKeyboardPhraseSeeded(events, profile, null, null, null, out);
}

fn auditKeyboardPhraseSeeded(
    events: []const KeyboardPhraseEvent,
    profile: types.HandProfile,
    seed_previous_event: ?KeyboardPhraseEvent,
    seed_previous_input_load: ?types.TemporalLoadState,
    seed_previous_realization: ?keyboard_assessment.RealizationAssessment,
    out: []PhraseIssue,
) PhraseAuditResult {
    const bounded_events = boundedEventCount(events.len);
    var builder = AuditBuilder.init(bounded_events, out);

    var previous_event: ?KeyboardPhraseEvent = seed_previous_event;
    var previous_input_load: ?types.TemporalLoadState = seed_previous_input_load;
    var previous_realization: keyboard_assessment.RealizationAssessment = undefined;
    var has_previous_realization = false;
    if (seed_previous_realization) |realization| {
        previous_realization = realization;
        has_previous_realization = true;
    }

    for (events[0..bounded_events], 0..) |event, raw_index| {
        const event_index = @as(u16, @intCast(raw_index));
        const notes = keyboardPhraseNotes(&event);

        var input_load: ?types.TemporalLoadState = null;
        if (previous_event) |prior| {
            if (prior.hand == event.hand) {
                if (!has_previous_realization) {
                    previous_realization = keyboard_assessment.assessRealization(
                        keyboardPhraseNotes(&prior),
                        prior.hand,
                        profile,
                        previous_input_load,
                    );
                    has_previous_realization = true;
                }
                input_load = previous_realization.state.load;
                const previous_event_index: u16 = if (event_index == 0) 0 else event_index - 1;
                appendKeyboardTransitionIssues(
                    &builder,
                    keyboard_assessment.assessTransition(
                        keyboardPhraseNotes(&prior),
                        notes,
                        event.hand,
                        profile,
                        previous_input_load,
                    ),
                    previous_realization,
                    keyboard_assessment.assessRealization(notes, event.hand, profile, input_load),
                    profile,
                    previous_event_index,
                    event_index,
                );
            } else {
                // hand continuity reset: a hand switch starts a new local segment.
                builder.noteContinuityReset(event_index);
            }
        }

        const realization = keyboard_assessment.assessRealization(notes, event.hand, profile, input_load);
        appendKeyboardEventIssues(&builder, realization, event_index);

        previous_event = event;
        previous_input_load = input_load;
        previous_realization = realization;
        has_previous_realization = true;
    }

    appendRepeatedWarningClusterIssue(&builder);
    appendRecoveryDeficitIssue(&builder);
    return builder.finish();
}

pub fn auditCommittedKeyboardPhrase(
    memory: *const KeyboardCommittedPhraseMemory,
    profile: types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    return auditKeyboardPhrase(memory.slice(), profile, out);
}

pub fn auditKeyboardBranchAgainstCommittedPhrase(
    memory: *const KeyboardCommittedPhraseMemory,
    branch: *const KeyboardPhraseBranch,
    profile: types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    const prior = memory.current() orelse return auditKeyboardPhrase(branch.slice(), profile, out);
    const prior_input_load = memory.loadBeforeCurrent(profile);
    const prior_realization = keyboard_assessment.assessRealization(
        keyboardPhraseNotes(prior),
        prior.hand,
        profile,
        prior_input_load,
    );
    return auditKeyboardPhraseSeeded(branch.slice(), profile, prior.*, prior_input_load, prior_realization, out);
}

pub fn auditFretPhrase(
    events: []const FretPhraseEvent,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    return auditFretPhraseSeeded(events, tuning, technique, hand_override, null, null, null, out);
}

fn auditFretPhraseSeeded(
    events: []const FretPhraseEvent,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    seed_previous_event: ?FretPhraseEvent,
    seed_previous_input_load: ?types.TemporalLoadState,
    seed_previous_realization: ?fret_assessment.RealizationAssessment,
    out: []PhraseIssue,
) PhraseAuditResult {
    const bounded_events = boundedEventCount(events.len);
    var builder = AuditBuilder.init(bounded_events, out);

    var previous_event: ?FretPhraseEvent = seed_previous_event;
    var previous_input_load: ?types.TemporalLoadState = seed_previous_input_load;
    var previous_realization: fret_assessment.RealizationAssessment = undefined;
    var has_previous_realization = false;
    if (seed_previous_realization) |realization| {
        previous_realization = realization;
        has_previous_realization = true;
    }
    const hand = hand_override orelse fret_assessment.defaultHandProfile(technique);

    for (events[0..bounded_events], 0..) |event, raw_index| {
        const event_index = @as(u16, @intCast(raw_index));
        const frets = fretPhraseFrets(&event);
        if (previous_event != null and !has_previous_realization) {
            previous_realization = fret_assessment.assessRealization(
                fretPhraseFrets(&previous_event.?),
                tuning,
                technique,
                hand_override,
                previous_input_load,
            );
            has_previous_realization = true;
        }
        const input_load: ?types.TemporalLoadState = if (previous_event != null and has_previous_realization)
            previous_realization.state.load
        else
            null;

        const realization = fret_assessment.assessRealization(frets, tuning, technique, hand_override, input_load);
        appendFretEventIssues(&builder, realization, event_index);

        if (previous_event) |prior| {
            const previous_event_index: u16 = if (event_index == 0) 0 else event_index - 1;
            appendFretTransitionIssues(
                &builder,
                fret_assessment.assessTransition(
                    fretPhraseFrets(&prior),
                    frets,
                    tuning,
                    technique,
                    hand_override,
                ),
                previous_realization,
                realization,
                hand,
                previous_event_index,
                event_index,
            );
        }

        previous_event = event;
        previous_input_load = input_load;
        previous_realization = realization;
        has_previous_realization = true;
    }

    appendRepeatedWarningClusterIssue(&builder);
    appendRecoveryDeficitIssue(&builder);
    return builder.finish();
}

pub fn auditCommittedFretPhrase(
    memory: *const FretCommittedPhraseMemory,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    return auditFretPhrase(memory.slice(), tuning, technique, hand_override, out);
}

pub fn auditFretBranchAgainstCommittedPhrase(
    memory: *const FretCommittedPhraseMemory,
    branch: *const FretPhraseBranch,
    tuning: []const pitch.MidiNote,
    technique: fret_assessment.TechniqueProfile,
    hand_override: ?types.HandProfile,
    out: []PhraseIssue,
) PhraseAuditResult {
    const prior = memory.current() orelse return auditFretPhrase(branch.slice(), tuning, technique, hand_override, out);
    const prior_input_load = memory.loadBeforeCurrent(tuning, technique, hand_override);
    const prior_realization = fret_assessment.assessRealization(
        fretPhraseFrets(prior),
        tuning,
        technique,
        hand_override,
        prior_input_load,
    );
    return auditFretPhraseSeeded(branch.slice(), tuning, technique, hand_override, prior.*, prior_input_load, prior_realization, out);
}

fn boundedEventCount(raw_len: usize) usize {
    return @min(raw_len, MAX_PHRASE_EVENTS);
}

fn boundedBranchStepCount(raw_len: usize) usize {
    return @min(raw_len, MAX_PHRASE_BRANCH_STEPS);
}

pub fn keyboardPhraseNotes(event: *const KeyboardPhraseEvent) []const pitch.MidiNote {
    const clipped = @min(@as(usize, event.note_count), keyboard_assessment.MAX_FINGERING_NOTES);
    return event.notes[0..clipped];
}

pub fn fretPhraseFrets(event: *const FretPhraseEvent) []const i8 {
    const clipped = @min(@as(usize, event.fret_count), guitar.MAX_GENERIC_STRINGS);
    return event.frets[0..clipped];
}

fn appendKeyboardEventIssues(
    builder: *AuditBuilder,
    realization: keyboard_assessment.RealizationAssessment,
    event_index: u16,
) void {
    appendBitIssues(builder, .event, .advisory, .playability_reason, realization.reason_bits, event_index, NONE_EVENT_INDEX, 0);
    appendBitIssues(builder, .event, .warning, .playability_warning, realization.warning_bits, event_index, NONE_EVENT_INDEX, realization.bottleneck_cost);
    appendBitIssues(builder, .event, .blocked, .keyboard_blocker, realization.blocker_bits, event_index, NONE_EVENT_INDEX, realization.bottleneck_cost);
}

fn appendFretEventIssues(
    builder: *AuditBuilder,
    realization: fret_assessment.RealizationAssessment,
    event_index: u16,
) void {
    appendBitIssues(builder, .event, .advisory, .playability_reason, realization.reason_bits, event_index, NONE_EVENT_INDEX, 0);
    appendBitIssues(builder, .event, .warning, .playability_warning, realization.warning_bits, event_index, NONE_EVENT_INDEX, realization.bottleneck_cost);
    appendBitIssues(builder, .event, .blocked, .fret_blocker, realization.blocker_bits, event_index, NONE_EVENT_INDEX, realization.bottleneck_cost);
}

fn appendKeyboardTransitionIssues(
    builder: *AuditBuilder,
    transition: keyboard_assessment.TransitionAssessment,
    from_realization: keyboard_assessment.RealizationAssessment,
    to_realization: keyboard_assessment.RealizationAssessment,
    profile: types.HandProfile,
    from_index: u16,
    to_index: u16,
) void {
    const anchor_delta_semitones = midiDelta(from_realization.state.anchor_midi, to_realization.state.anchor_midi);

    var warning_bits = transition.warning_bits & keyboardPairWarningMask();
    var blocker_bits = transition.blocker_bits & bitForIndex(@intFromEnum(keyboard_assessment.BlockerKind.impossible_thumb_crossing));
    const reason_bits: u32 = 0;

    if (anchor_delta_semitones > 0) warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.shift_required));
    if (anchor_delta_semitones > profile.comfort_shift_steps) {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.excessive_longitudinal_shift));
    }
    if (anchor_delta_semitones > profile.limit_shift_steps) {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.hard_limit_exceeded));
        blocker_bits |= bitForIndex(@intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit));
    }
    if (from_realization.state.span_semitones >= profile.comfort_span_steps and
        to_realization.state.span_semitones >= profile.comfort_span_steps)
    {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.repeated_maximal_stretch));
    }
    if (from_realization.state.load.event_count > 1 and
        from_realization.state.load.peak_shift_steps >= profile.comfort_shift_steps and
        anchor_delta_semitones > 0)
    {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.fluency_degradation_from_recent_motion));
    }

    appendBitIssues(builder, .transition, .advisory, .playability_reason, reason_bits, from_index, to_index, 0);
    appendBitIssues(builder, .transition, .warning, .playability_warning, warning_bits, from_index, to_index, transition.bottleneck_cost);
    appendBitIssues(builder, .transition, .blocked, .keyboard_blocker, blocker_bits, from_index, to_index, transition.bottleneck_cost);
}

fn appendFretTransitionIssues(
    builder: *AuditBuilder,
    transition: fret_assessment.TransitionAssessment,
    from_realization: fret_assessment.RealizationAssessment,
    to_realization: fret_assessment.RealizationAssessment,
    hand: types.HandProfile,
    from_index: u16,
    to_index: u16,
) void {
    const anchor_delta_steps = absDiffU8(from_realization.state.anchor_fret, to_realization.state.anchor_fret);

    var warning_bits: u32 = 0;
    var blocker_bits: u32 = 0;
    var reason_bits: u32 = 0;

    if (anchor_delta_steps > 0) warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.shift_required));
    if (anchor_delta_steps > hand.comfort_shift_steps) {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.excessive_longitudinal_shift));
    }
    if (anchor_delta_steps > hand.limit_shift_steps) {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.hard_limit_exceeded));
        blocker_bits |= bitForIndex(@intFromEnum(fret_assessment.BlockerKind.shift_hard_limit));
    }
    if (from_realization.state.span_steps >= hand.comfort_span_steps and
        to_realization.state.span_steps >= hand.comfort_span_steps)
    {
        warning_bits |= bitForIndex(@intFromEnum(types.WarningKind.repeated_maximal_stretch));
    }
    if (transition.to_state.open_string_count > transition.from_state.open_string_count) {
        reason_bits |= bitForIndex(@intFromEnum(types.ReasonKind.open_string_relief));
    }
    if (to_realization.bottleneck_cost < from_realization.bottleneck_cost) {
        reason_bits |= bitForIndex(@intFromEnum(types.ReasonKind.bottleneck_reduced));
    }

    appendBitIssues(builder, .transition, .advisory, .playability_reason, reason_bits, from_index, to_index, 0);
    appendBitIssues(builder, .transition, .warning, .playability_warning, warning_bits, from_index, to_index, transition.bottleneck_cost);
    appendBitIssues(builder, .transition, .blocked, .fret_blocker, blocker_bits, from_index, to_index, transition.bottleneck_cost);
}

fn appendBitIssues(
    builder: *AuditBuilder,
    scope: IssueScope,
    severity: IssueSeverity,
    family_domain: FamilyDomain,
    bits: u32,
    event_index: u16,
    related_event_index: u16,
    magnitude: u16,
) void {
    var remaining = bits;
    var family_index: u8 = 0;
    while (remaining != 0) : (family_index += 1) {
        if ((remaining & 1) != 0) {
            const issue = switch (scope) {
                .event => PhraseIssue.eventIssue(severity, family_domain, family_index, event_index, magnitude),
                .transition => PhraseIssue.transitionIssue(severity, family_domain, family_index, event_index, related_event_index, magnitude),
            };
            builder.appendLocalIssue(issue);
        }
        remaining >>= 1;
    }
}

fn appendRepeatedWarningClusterIssue(builder: *AuditBuilder) void {
    // warning cluster: repeated copies of the same warning family inside one continuity segment.
    const cluster = strongestWarningCluster(
        builder.warning_masks[0..builder.accumulator.summary.event_count],
        builder.accumulator.summary.event_count,
        builder.continuity_reset_mask,
    ) orelse return;

    builder.appendPhraseIssue(makeRangeIssue(
        .warning,
        .playability_warning,
        cluster.family_index,
        cluster.start_index,
        cluster.end_index,
        cluster.length,
    ));
}

fn appendRecoveryDeficitIssue(builder: *AuditBuilder) void {
    // recovery deficit: strain survives without enough relief to reset the phrase burden.
    const bounded_mask = eventMask(builder.accumulator.summary.event_count);
    const deficit_mask = (builder.accumulator.strain_mask & ~builder.accumulator.relief_mask) & bounded_mask;
    const run = longestRun(deficit_mask, builder.accumulator.summary.event_count);
    if (run.length == 0) return;

    const family_index = dominantWarningInRange(builder.warning_masks[0..builder.accumulator.summary.event_count], run.start_index, run.end_index) orelse return;
    builder.appendPhraseIssue(makeRangeIssue(
        .warning,
        .playability_warning,
        family_index,
        run.start_index,
        run.end_index,
        run.length,
    ));
}

fn strongestWarningCluster(
    warning_masks: []const u32,
    event_count: u16,
    continuity_reset_mask: u64,
) ?WarningCluster {
    var best: ?WarningCluster = null;

    for (0..types.WARNING_NAMES.len) |raw_family_index| {
        const family_index = @as(u8, @intCast(raw_family_index));
        var current_start: u16 = NONE_EVENT_INDEX;
        var current_length: u16 = 0;

        var event_index: u16 = 0;
        while (event_index < event_count) : (event_index += 1) {
            if (event_index > 0 and hasMaskBit(continuity_reset_mask, event_index)) {
                current_start = NONE_EVENT_INDEX;
                current_length = 0;
            }

            const active = (warning_masks[event_index] & bitForIndex(family_index)) != 0;
            if (active) {
                if (current_length == 0) current_start = event_index;
                current_length += 1;
                if (current_length >= 2) {
                    const candidate = WarningCluster{
                        .family_index = family_index,
                        .start_index = current_start,
                        .end_index = event_index,
                        .length = current_length,
                    };
                    if (best == null or shouldPromoteWarningCluster(candidate, best.?)) {
                        best = candidate;
                    }
                }
            } else {
                current_start = NONE_EVENT_INDEX;
                current_length = 0;
            }
        }
    }

    return best;
}

fn shouldPromoteWarningCluster(candidate: WarningCluster, current: WarningCluster) bool {
    if (candidate.length != current.length) return candidate.length > current.length;
    if (candidate.start_index != current.start_index) return candidate.start_index < current.start_index;
    return candidate.family_index < current.family_index;
}

fn dominantWarningInRange(warning_masks: []const u32, start_index: u16, end_index: u16) ?u8 {
    var counts = [_]u16{0} ** types.WARNING_NAMES.len;
    var event_index = start_index;
    while (event_index <= end_index and event_index < warning_masks.len) : (event_index += 1) {
        for (0..types.WARNING_NAMES.len) |raw_family_index| {
            if ((warning_masks[event_index] & bitForIndex(raw_family_index)) != 0) {
                counts[raw_family_index] +|= 1;
            }
        }
    }
    const dominant = dominantFamily(counts[0..]);
    return if (dominant == NONE_FAMILY_INDEX) null else dominant;
}

fn makeRangeIssue(
    severity: IssueSeverity,
    family_domain: FamilyDomain,
    family_index: u8,
    start_index: u16,
    end_index: u16,
    magnitude: u16,
) PhraseIssue {
    return if (start_index == end_index)
        PhraseIssue.eventIssue(severity, family_domain, family_index, start_index, magnitude)
    else
        PhraseIssue.transitionIssue(severity, family_domain, family_index, start_index, end_index, magnitude);
}

fn bitForIndex(index: anytype) u32 {
    const resolved = @as(u8, @intCast(index));
    if (resolved >= 32) return 0;
    return (@as(u32, 1) << @as(u5, @intCast(resolved)));
}

fn hasMaskBit(mask: u64, event_index: u16) bool {
    if (event_index >= 64) return false;
    return (mask & (@as(u64, 1) << @as(u6, @intCast(event_index)))) != 0;
}

fn keyboardPairWarningMask() u32 {
    return bitForIndex(@intFromEnum(types.WarningKind.thumb_on_black_under_stretch)) |
        bitForIndex(@intFromEnum(types.WarningKind.awkward_thumb_crossing)) |
        bitForIndex(@intFromEnum(types.WarningKind.repeated_weak_adjacent_finger_sequence));
}

fn midiDelta(a: pitch.MidiNote, b: pitch.MidiNote) u8 {
    return absDiffU8(a, b);
}

fn absDiffU8(a: u8, b: u8) u8 {
    return if (a >= b) a - b else b - a;
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

fn isReliefReason(family_index: u8) bool {
    return switch (family_index) {
        @intFromEnum(types.ReasonKind.open_string_relief),
        @intFromEnum(types.ReasonKind.bottleneck_reduced),
        @intFromEnum(types.ReasonKind.hand_continuity_reset),
        => true,
        else => false,
    };
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

test "keyboard phrase branch resets and appends explicit steps" {
    var branch = KeyboardPhraseBranch.init();
    try std.testing.expectEqual(@as(usize, 0), branch.len());
    try std.testing.expect(branch.push(KeyboardPhraseEvent.init(&[_]pitch.MidiNote{60}, .right)));
    try std.testing.expect(branch.push(KeyboardPhraseEvent.init(&[_]pitch.MidiNote{64}, .right)));
    try std.testing.expectEqual(@as(usize, 2), branch.len());
    try std.testing.expectEqual(@as(pitch.MidiNote, 64), branch.slice()[1].notes[0]);
    branch.reset();
    try std.testing.expectEqual(@as(usize, 0), branch.len());
}

test "keyboard phrase candidate window clips candidates to fixed capacity" {
    const event = KeyboardPhraseEvent.init(&[_]pitch.MidiNote{60}, .right);
    const candidates = [_]KeyboardPhraseEvent{event} ** (MAX_BRANCH_STEP_CANDIDATES + 2);
    const step = KeyboardPhraseStepCandidates.init(candidates[0..]);
    try std.testing.expectEqual(@as(usize, MAX_BRANCH_STEP_CANDIDATES), step.len());

    var window = KeyboardPhraseCandidateWindow.init();
    try std.testing.expect(window.push(step));
    try std.testing.expectEqual(@as(usize, 1), window.len());
    try std.testing.expectEqual(@as(usize, MAX_BRANCH_STEP_CANDIDATES), window.slice()[0].len());
}

test "branch summary tracks blocked step peak strain and window trends" {
    const issues = [_]PhraseIssue{
        PhraseIssue.eventIssue(.advisory, .playability_reason, @intFromEnum(types.ReasonKind.open_string_relief), 0, 0),
        PhraseIssue.eventIssue(.warning, .playability_warning, @intFromEnum(types.WarningKind.shift_required), 1, 3),
        PhraseIssue.transitionIssue(.blocked, .keyboard_blocker, @intFromEnum(keyboard_assessment.BlockerKind.shift_hard_limit), 1, 2, 8),
    };

    const summary = summarizeBranchIssues(3, issues[0..]);
    try std.testing.expectEqual(@as(u16, 3), summary.step_count);
    try std.testing.expectEqual(@as(u16, 2), summary.first_blocked_step_index);
    try std.testing.expectEqual(@as(u16, 1), summary.first_blocked_transition_from_index);
    try std.testing.expectEqual(@as(u16, 2), summary.first_blocked_transition_to_index);
    try std.testing.expectEqual(@as(u16, 2), summary.peak_strain_step_index);
    try std.testing.expectEqual(@as(u16, 8), summary.peak_strain_magnitude);
    try std.testing.expectEqual(@as(u16, 1), summary.improving_window_count);
    try std.testing.expectEqual(@as(u16, 2), summary.deficit_window_count);
    try std.testing.expectEqual(@as(u16, 0), summary.neutral_window_count);
    try std.testing.expectEqual(StrainBucket.blocked, summary.strain_bucket);
}

test "keyboard branch summary helper evaluates fixed branch windows" {
    var branch = KeyboardPhraseBranch.init();
    try std.testing.expect(branch.push(KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));
    try std.testing.expect(branch.push(KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));
    try std.testing.expect(branch.push(KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 67 }, .right)));

    const profile = types.HandProfile.init(5, 4, 12, 12, 12, true);
    const summary = summarizeKeyboardBranch(&branch, profile);
    try std.testing.expectEqual(@as(u16, 3), summary.step_count);
    try std.testing.expect(summary.deficit_window_count >= 2);
    try std.testing.expectEqual(StrainBucket.high, summary.strain_bucket);
}
