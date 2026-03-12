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
    const native_build_options = b.addOptions();
    native_build_options.addOption(bool, "enable_raster_backend", true);
    lib_mod.addOptions("build_options", native_build_options);

    // ── Static library (C ABI) ──────────────────────────────────
    const static_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    static_mod.addOptions("build_options", native_build_options);

    const static_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = static_mod,
        .linkage = .static,
    });

    b.installArtifact(static_lib);

    // ── Shared library (C ABI) ──────────────────────────────────
    const shared_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    shared_mod.addOptions("build_options", native_build_options);

    const shared_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = shared_mod,
        .linkage = .dynamic,
    });

    b.installArtifact(shared_lib);
    static_lib.installHeader(b.path("include/libmusictheory.h"), "libmusictheory.h");

    // ── WASM demo artifact + assets ─────────────────────────────
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
    });
    wasm_mod.export_symbol_names = &.{
        "lmt_pcs_from_list",
        "lmt_pcs_to_list",
        "lmt_pcs_cardinality",
        "lmt_pcs_transpose",
        "lmt_pcs_invert",
        "lmt_pcs_complement",
        "lmt_pcs_is_subset",
        "lmt_prime_form",
        "lmt_forte_prime",
        "lmt_is_cluster_free",
        "lmt_evenness_distance",
        "lmt_scale",
        "lmt_mode",
        "lmt_spell_note",
        "lmt_spell_note_parts",
        "lmt_chord",
        "lmt_chord_name",
        "lmt_roman_numeral",
        "lmt_roman_numeral_parts",
        "lmt_fret_to_midi",
        "lmt_midi_to_fret_positions",
        "lmt_svg_clock_optc",
        "lmt_svg_fret",
        "lmt_svg_chord_staff",
        "lmt_wasm_scratch_ptr",
        "lmt_wasm_scratch_size",
        "lmt_svg_compat_kind_count",
        "lmt_svg_compat_kind_name",
        "lmt_svg_compat_kind_directory",
        "lmt_svg_compat_image_count",
        "lmt_svg_compat_image_name",
        "lmt_svg_compat_generate",
    };

    const wasm_exe = b.addExecutable(.{
        .name = "libmusictheory",
        .root_module = wasm_mod,
    });
    const wasm_build_options = b.addOptions();
    wasm_build_options.addOption(bool, "enable_raster_backend", false);
    wasm_mod.addOptions("build_options", wasm_build_options);
    wasm_exe.rdynamic = false;
    wasm_exe.entry = .disabled;
    wasm_exe.export_memory = true;
    wasm_exe.initial_memory = 16 * 1024 * 1024;
    wasm_exe.max_memory = 64 * 1024 * 1024;

    const install_wasm = b.addInstallFileWithDir(
        wasm_exe.getEmittedBin(),
        .prefix,
        "wasm-demo/libmusictheory.wasm",
    );
    const install_demo_assets = b.addInstallDirectory(.{
        .source_dir = b.path("examples/wasm-demo"),
        .install_dir = .prefix,
        .install_subdir = "wasm-demo",
    });

    const wasm_demo_step = b.step("wasm-demo", "Build WebAssembly interactive demo");
    wasm_demo_step.dependOn(&wasm_exe.step);
    wasm_demo_step.dependOn(&install_wasm.step);
    wasm_demo_step.dependOn(&install_demo_assets.step);

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
        .paths = &.{ "build.zig", "src", "include", "examples", "scripts" },
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
