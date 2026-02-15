//! libmusictheory — Music theory computation library.
//!
//! Implements pitch class set theory, scale/mode/key analysis, chord construction,
//! voice leading, instrument interfaces, and SVG visualization generation.
//! Exposes a C ABI for embedding in any language.

pub const pitch = @import("pitch.zig");
pub const note_name = @import("note_name.zig");
pub const interval = @import("interval.zig");
pub const pitch_class_set = @import("pitch_class_set.zig");
pub const forte = @import("forte.zig");
pub const set_class = @import("set_class.zig");
pub const interval_vector = @import("interval_vector.zig");
pub const fc_components = @import("fc_components.zig");
pub const interval_analysis = @import("interval_analysis.zig");
pub const cluster = @import("cluster.zig");
pub const evenness = @import("evenness.zig");
pub const scale = @import("scale.zig");
pub const mode = @import("mode.zig");
pub const key_signature = @import("key_signature.zig");
pub const key = @import("key.zig");
pub const note_spelling = @import("note_spelling.zig");
pub const chord_type = @import("chord_type.zig");
pub const chord_construction = @import("chord_construction.zig");
pub const harmony = @import("harmony.zig");
pub const voice_leading = @import("voice_leading.zig");
pub const guitar = @import("guitar.zig");
pub const keyboard = @import("keyboard.zig");
pub const svg_clock = @import("svg/clock.zig");
pub const svg_staff = @import("svg/staff.zig");
pub const svg_fret = @import("svg/fret.zig");

test {
    _ = @import("tests/pitch_test.zig");
    _ = @import("tests/pitch_class_set_test.zig");
    _ = @import("tests/set_class_test.zig");
    _ = @import("tests/interval_analysis_test.zig");
    _ = @import("tests/cluster_evenness_test.zig");
    _ = @import("tests/scales_modes_test.zig");
    _ = @import("tests/keys_signatures_test.zig");
    _ = @import("tests/chord_construction_test.zig");
    _ = @import("tests/harmony_analysis_test.zig");
    _ = @import("tests/voice_leading_test.zig");
    _ = @import("tests/guitar_test.zig");
    _ = @import("tests/keyboard_test.zig");
    _ = @import("tests/svg_clock_test.zig");
    _ = @import("tests/svg_staff_test.zig");
    _ = @import("tests/svg_fret_test.zig");
}
