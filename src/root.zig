//! libmusictheory — Music theory computation library.
//!
//! Implements pitch class set theory, scale/mode/key analysis, chord construction,
//! voice leading, instrument interfaces, and SVG visualization generation.
//! Exposes a C ABI for embedding in any language.

pub const pitch = @import("pitch.zig");
pub const note_name = @import("note_name.zig");
pub const interval = @import("interval.zig");

test {
    _ = @import("tests/pitch_test.zig");
}
