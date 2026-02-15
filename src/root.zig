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

test {
    _ = @import("tests/pitch_test.zig");
    _ = @import("tests/pitch_class_set_test.zig");
    _ = @import("tests/set_class_test.zig");
}
