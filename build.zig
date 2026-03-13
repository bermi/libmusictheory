const std = @import("std");

const validation_export_symbols = [_][]const u8{
    "lmt_wasm_scratch_ptr",
    "lmt_wasm_scratch_size",
    "lmt_svg_compat_kind_count",
    "lmt_svg_compat_kind_name",
    "lmt_svg_compat_kind_directory",
    "lmt_svg_compat_image_count",
    "lmt_svg_compat_image_name",
    "lmt_svg_compat_generate",
};

const full_demo_export_symbols = [_][]const u8{
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

fn localDirExists(rel_path: []const u8) bool {
    std.fs.cwd().access(rel_path, .{}) catch return false;
    return true;
}

fn maybeInstallDirectory(b: *std.Build, step: *std.Build.Step, source_rel_path: []const u8, install_subdir: []const u8) void {
    if (!localDirExists(source_rel_path)) return;

    const install_dir = b.addInstallDirectory(.{
        .source_dir = b.path(source_rel_path),
        .install_dir = .prefix,
        .install_subdir = install_subdir,
    });
    step.dependOn(&install_dir.step);
}

fn configureWasmExe(exe: *std.Build.Step.Compile) void {
    exe.rdynamic = false;
    exe.entry = .disabled;
    exe.export_memory = true;
    exe.initial_memory = 16 * 1024 * 1024;
    exe.max_memory = 64 * 1024 * 1024;
}

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
        .root_source_file = b.path("src/wasm_validation_api.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
    });
    wasm_mod.export_symbol_names = &validation_export_symbols;

    const wasm_exe = b.addExecutable(.{
        .name = "libmusictheory_validation",
        .root_module = wasm_mod,
    });
    configureWasmExe(wasm_exe);

    const install_wasm = b.addInstallFileWithDir(
        wasm_exe.getEmittedBin(),
        .prefix,
        "wasm-demo/libmusictheory.wasm",
    );
    const install_validation_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/validation.html"),
        .prefix,
        "wasm-demo/validation.html",
    );
    const install_validation_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/validation.js"),
        .prefix,
        "wasm-demo/validation.js",
    );
    const install_validation_css = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/styles.css"),
        .prefix,
        "wasm-demo/styles.css",
    );
    const wasm_demo_write = b.addWriteFiles();
    const index_stub = wasm_demo_write.add("index.html", "<!doctype html><meta charset=\"utf-8\"><title>Validation Bundle</title><p>Validation-focused wasm bundle.</p><p>Open <a href=\"validation.html\">validation.html</a>.</p><p>For the full interactive API docs bundle, run <code>zig build wasm-docs</code> and serve <code>zig-out/wasm-docs</code>.</p>\n");
    const app_stub = wasm_demo_write.add("app.js", "// Validation-focused wasm bundle: interactive demo app is not shipped in this profile.\\n");
    const install_index_stub = b.addInstallFileWithDir(
        index_stub,
        .prefix,
        "wasm-demo/index.html",
    );
    const install_app_stub = b.addInstallFileWithDir(
        app_stub,
        .prefix,
        "wasm-demo/app.js",
    );

    const wasm_demo_step = b.step("wasm-demo", "Build WebAssembly interactive demo");
    wasm_demo_step.dependOn(&wasm_exe.step);
    wasm_demo_step.dependOn(&install_wasm.step);
    wasm_demo_step.dependOn(&install_validation_html.step);
    wasm_demo_step.dependOn(&install_validation_js.step);
    wasm_demo_step.dependOn(&install_validation_css.step);
    wasm_demo_step.dependOn(&install_index_stub.step);
    wasm_demo_step.dependOn(&install_app_stub.step);
    maybeInstallDirectory(b, wasm_demo_step, "tmp/harmoniousapp.net", "wasm-demo/tmp/harmoniousapp.net");

    const wasm_docs_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
    });
    const wasm_docs_build_options = b.addOptions();
    wasm_docs_build_options.addOption(bool, "enable_raster_backend", false);
    wasm_docs_mod.addOptions("build_options", wasm_docs_build_options);
    wasm_docs_mod.export_symbol_names = &full_demo_export_symbols;

    const wasm_docs_exe = b.addExecutable(.{
        .name = "libmusictheory_docs",
        .root_module = wasm_docs_mod,
    });
    configureWasmExe(wasm_docs_exe);

    const install_docs_wasm = b.addInstallFileWithDir(
        wasm_docs_exe.getEmittedBin(),
        .prefix,
        "wasm-docs/libmusictheory.wasm",
    );
    const install_docs_index = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/index.html"),
        .prefix,
        "wasm-docs/index.html",
    );
    const install_docs_app = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/app.js"),
        .prefix,
        "wasm-docs/app.js",
    );
    const install_docs_styles = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/styles.css"),
        .prefix,
        "wasm-docs/styles.css",
    );
    const install_docs_validation_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/validation.html"),
        .prefix,
        "wasm-docs/validation.html",
    );
    const install_docs_validation_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/validation.js"),
        .prefix,
        "wasm-docs/validation.js",
    );

    const wasm_docs_step = b.step("wasm-docs", "Build WebAssembly full interactive docs bundle");
    wasm_docs_step.dependOn(&wasm_docs_exe.step);
    wasm_docs_step.dependOn(&install_docs_wasm.step);
    wasm_docs_step.dependOn(&install_docs_index.step);
    wasm_docs_step.dependOn(&install_docs_app.step);
    wasm_docs_step.dependOn(&install_docs_styles.step);
    wasm_docs_step.dependOn(&install_docs_validation_html.step);
    wasm_docs_step.dependOn(&install_docs_validation_js.step);
    maybeInstallDirectory(b, wasm_docs_step, "tmp/harmoniousapp.net", "wasm-docs/tmp/harmoniousapp.net");

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
