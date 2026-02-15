//! libmusictheory — Music theory computation library.
//!
//! Implements pitch class set theory, scale/mode/key analysis, chord construction,
//! voice leading, instrument interfaces, and SVG visualization generation.
//! Exposes a C ABI for embedding in any language.

pub const pitch = @import("pitch.zig");
pub const note_name = @import("note_name.zig");
pub const interval = @import("interval.zig");
pub const pitch_class_set = @import("pitch_class_set.zig");

test {
    _ = @import("tests/pitch_test.zig");
    _ = @import("tests/pitch_class_set_test.zig");
}
