const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Library module ──────────────────────────────────────────
    const lib_mod = b.addModule("libmusictheory", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── Static library ──────────────────────────────────────────
    const static_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    b.installArtifact(static_lib);

    // ── Unit tests ──────────────────────────────────────────────
    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // ── Format check ────────────────────────────────────────────
    const fmt = b.addFmt(.{
        .paths = &.{ "build.zig", "src" },
        .check = true,
    });

    const fmt_step = b.step("fmt", "Check formatting");
    fmt_step.dependOn(&fmt.step);

    // ── Verify (test + fmt) ─────────────────────────────────────
    const verify_step = b.step("verify", "Run tests and check formatting");
    verify_step.dependOn(&run_tests.step);
    verify_step.dependOn(&fmt.step);
}
