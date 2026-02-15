const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── Zig module ──────────────────────────────────────────────
    const lib_mod = b.addModule("libmusictheory", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ── Static library (C ABI) ──────────────────────────────────
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

    // ── Shared library (C ABI) ──────────────────────────────────
    const shared_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .dynamic,
    });

    b.installArtifact(shared_lib);
    static_lib.installHeader(b.path("include/libmusictheory.h"), "libmusictheory.h");

    // ── Unit tests ──────────────────────────────────────────────
    const lib_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    lib_tests.root_module.addIncludePath(b.path("include"));

    const run_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);

    // ── C ABI smoke tests (static/shared link) ──────────────────
    const c_smoke_static = b.addExecutable(.{
        .name = "c_api_smoke_static",
        .target = target,
        .optimize = optimize,
    });
    c_smoke_static.linkLibC();
    c_smoke_static.addIncludePath(b.path("include"));
    c_smoke_static.addCSourceFile(.{
        .file = b.path("examples/c/smoke.c"),
    });
    c_smoke_static.linkLibrary(static_lib);

    const run_c_smoke_static = b.addRunArtifact(c_smoke_static);

    const c_smoke_shared = b.addExecutable(.{
        .name = "c_api_smoke_shared",
        .target = target,
        .optimize = optimize,
    });
    c_smoke_shared.linkLibC();
    c_smoke_shared.addIncludePath(b.path("include"));
    c_smoke_shared.addCSourceFile(.{
        .file = b.path("examples/c/smoke.c"),
    });
    c_smoke_shared.linkLibrary(shared_lib);

    const run_c_smoke_shared = b.addRunArtifact(c_smoke_shared);

    const c_smoke_step = b.step("c-smoke", "Run C ABI smoke tests");
    c_smoke_step.dependOn(&run_c_smoke_static.step);
    c_smoke_step.dependOn(&run_c_smoke_shared.step);

    // ── Format check ────────────────────────────────────────────
    const fmt = b.addFmt(.{
        .paths = &.{ "build.zig", "src", "include", "examples" },
        .check = true,
    });

    const fmt_step = b.step("fmt", "Check formatting");
    fmt_step.dependOn(&fmt.step);

    // ── Verify (test + c smoke + fmt) ───────────────────────────
    const verify_step = b.step("verify", "Run tests, C ABI smoke tests, and check formatting");
    verify_step.dependOn(&run_tests.step);
    verify_step.dependOn(&run_c_smoke_static.step);
    verify_step.dependOn(&run_c_smoke_shared.step);
    verify_step.dependOn(&fmt.step);
}
