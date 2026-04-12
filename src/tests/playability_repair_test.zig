const std = @import("std");
const testing = std.testing;
const pitch = @import("../pitch.zig");
const playability = @import("../playability.zig");

test "keyboard phrase repairs can reassign hand without crossing the music-change boundary" {
    var memory = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(memory.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));
    try testing.expect(memory.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{48}, .right)));

    const profile = playability.types.HandProfile.init(5, 12, 14, 2, 4, true);
    const policy = playability.repair.RepairPolicy.defaultForClass(.realization_only);

    var repairs_buf: [playability.repair.MAX_PHRASE_REPAIRS]playability.repair.RankedKeyboardPhraseRepair = undefined;
    const repairs = playability.repair.rankKeyboardPhraseRepairs(&memory, profile, policy, repairs_buf[0..]);

    try testing.expect(repairs.len > 0);
    try testing.expectEqual(playability.repair.RepairClass.realization_only, repairs[0].repair_class);
    try testing.expect(!repairs[0].crossed_musical_change_boundary);
    try testing.expectEqual(playability.keyboard_assessment.HandRole.left, repairs[0].replacement_event.hand);
    try testing.expect((repairs[0].change_mask & (@as(u32, 1) << @intFromEnum(playability.repair.ChangeFlag.hand_reassigned))) != 0);
    try testing.expect((repairs[0].preserved_mask & (@as(u32, 1) << @intFromEnum(playability.repair.PreservationFlag.exact_pitches_preserved))) != 0);
}

test "keyboard repair class boundary keeps texture-reduced repairs out when policy stops at register adjustment" {
    var memory = playability.phrase.KeyboardCommittedPhraseMemory.init();
    try testing.expect(memory.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{72}, .right)));
    try testing.expect(memory.push(playability.phrase.KeyboardPhraseEvent.init(&[_]pitch.MidiNote{ 60, 72 }, .right)));

    const profile = playability.types.HandProfile.init(5, 4, 6, 2, 4, true);

    var register_policy = playability.repair.RepairPolicy.defaultForClass(.register_adjusted);
    register_policy.allow_hand_reassignment = false;
    register_policy.preserve_bass = false;

    var register_buf: [playability.repair.MAX_PHRASE_REPAIRS]playability.repair.RankedKeyboardPhraseRepair = undefined;
    const register_repairs = playability.repair.rankKeyboardPhraseRepairs(&memory, profile, register_policy, register_buf[0..]);
    try testing.expect(register_repairs.len > 0);
    for (register_repairs) |repair| {
        try testing.expect(@intFromEnum(repair.repair_class) <= @intFromEnum(playability.repair.RepairClass.register_adjusted));
    }

    var texture_policy = playability.repair.RepairPolicy.defaultForClass(.texture_reduced);
    texture_policy.allow_hand_reassignment = false;
    texture_policy.preserve_bass = false;

    var texture_buf: [playability.repair.MAX_PHRASE_REPAIRS]playability.repair.RankedKeyboardPhraseRepair = undefined;
    const texture_repairs = playability.repair.rankKeyboardPhraseRepairs(&memory, profile, texture_policy, texture_buf[0..]);
    var found_texture_reduced = false;
    for (texture_repairs) |repair| {
        if (repair.repair_class == .texture_reduced) found_texture_reduced = true;
    }
    try testing.expect(found_texture_reduced);
}

test "fret phrase repairs can relocate a pitch without crossing the music-change boundary" {
    var memory = playability.phrase.FretCommittedPhraseMemory.init();
    try testing.expect(memory.push(playability.phrase.FretPhraseEvent.init(&[_]i8{ 3, -1, -1, -1 })));
    try testing.expect(memory.push(playability.phrase.FretPhraseEvent.init(&[_]i8{ 10, -1, -1, -1 })));

    const tuning = [_]pitch.MidiNote{ 40, 45, 50, 55 };
    const hand = playability.types.HandProfile.init(4, 4, 5, 1, 3, true);
    const policy = playability.repair.RepairPolicy.defaultForClass(.realization_only);

    var repairs_buf: [playability.repair.MAX_PHRASE_REPAIRS]playability.repair.RankedFretPhraseRepair = undefined;
    const repairs = playability.repair.rankFretPhraseRepairs(
        &memory,
        tuning[0..],
        .generic_guitar,
        hand,
        policy,
        repairs_buf[0..],
    );

    try testing.expect(repairs.len > 0);
    try testing.expectEqual(playability.repair.RepairClass.realization_only, repairs[0].repair_class);
    try testing.expect(!repairs[0].crossed_musical_change_boundary);
    try testing.expectEqual(@as(i8, 5), repairs[0].replacement_event.frets[1]);
    try testing.expectEqual(@as(i8, -1), repairs[0].replacement_event.frets[0]);
    try testing.expect((repairs[0].change_mask & (@as(u32, 1) << @intFromEnum(playability.repair.ChangeFlag.fret_location_changed))) != 0);
    try testing.expect((repairs[0].preserved_mask & (@as(u32, 1) << @intFromEnum(playability.repair.PreservationFlag.exact_pitches_preserved))) != 0);
}
