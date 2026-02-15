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

test {
    _ = @import("tests/pitch_test.zig");
    _ = @import("tests/pitch_class_set_test.zig");
    _ = @import("tests/set_class_test.zig");
    _ = @import("tests/interval_analysis_test.zig");
    _ = @import("tests/cluster_evenness_test.zig");
    _ = @import("tests/scales_modes_test.zig");
}
