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
    "lmt_counterpoint_max_voices",
    "lmt_counterpoint_history_capacity",
    "lmt_counterpoint_rule_profile_count",
    "lmt_counterpoint_rule_profile_name",
    "lmt_sizeof_voiced_state",
    "lmt_sizeof_voiced_history",
    "lmt_sizeof_next_step_suggestion",
    "lmt_voiced_history_reset",
    "lmt_build_voiced_state",
    "lmt_voiced_history_push",
    "lmt_classify_motion",
    "lmt_evaluate_motion_profile",
    "lmt_rank_next_steps",
    "lmt_next_step_reason_count",
    "lmt_next_step_reason_name",
    "lmt_next_step_warning_count",
    "lmt_next_step_warning_name",
    "lmt_mode_spelling_quality",
    "lmt_spell_note",
    "lmt_spell_note_parts",
    "lmt_chord",
    "lmt_chord_name",
    "lmt_roman_numeral",
    "lmt_roman_numeral_parts",
    "lmt_fret_to_midi",
    "lmt_fret_to_midi_n",
    "lmt_midi_to_fret_positions",
    "lmt_midi_to_fret_positions_n",
    "lmt_generate_voicings_n",
    "lmt_rank_context_suggestions",
    "lmt_preferred_voicing_n",
    "lmt_pitch_class_guide_n",
    "lmt_frets_to_url_n",
    "lmt_url_to_frets_n",
    "lmt_svg_clock_optc",
    "lmt_svg_optic_k_group",
    "lmt_svg_evenness_chart",
    "lmt_svg_evenness_field",
    "lmt_svg_fret",
    "lmt_svg_fret_n",
    "lmt_svg_fret_tuned_n",
    "lmt_svg_chord_staff",
    "lmt_svg_key_staff",
    "lmt_svg_keyboard",
    "lmt_svg_piano_staff",
    "lmt_raster_is_enabled",
    "lmt_bitmap_clock_optc_rgba",
    "lmt_bitmap_optic_k_group_rgba",
    "lmt_bitmap_evenness_chart_rgba",
    "lmt_bitmap_evenness_field_rgba",
    "lmt_bitmap_fret_rgba",
    "lmt_bitmap_fret_n_rgba",
    "lmt_bitmap_fret_tuned_n_rgba",
    "lmt_bitmap_chord_staff_rgba",
    "lmt_bitmap_key_staff_rgba",
    "lmt_bitmap_keyboard_rgba",
    "lmt_bitmap_piano_staff_rgba",
    "lmt_wasm_scratch_ptr",
    "lmt_wasm_scratch_size",
    "lmt_svg_compat_kind_count",
    "lmt_svg_compat_kind_name",
    "lmt_svg_compat_kind_directory",
    "lmt_svg_compat_image_count",
    "lmt_svg_compat_image_name",
    "lmt_svg_compat_generate",
};

const gallery_export_symbols = [_][]const u8{
    "lmt_pcs_from_list",
    "lmt_pcs_to_list",
    "lmt_pcs_cardinality",
    "lmt_pcs_transpose",
    "lmt_pcs_invert",
    "lmt_pcs_complement",
    "lmt_prime_form",
    "lmt_forte_prime",
    "lmt_is_cluster_free",
    "lmt_evenness_distance",
    "lmt_scale",
    "lmt_mode",
    "lmt_counterpoint_max_voices",
    "lmt_counterpoint_history_capacity",
    "lmt_counterpoint_rule_profile_count",
    "lmt_counterpoint_rule_profile_name",
    "lmt_sizeof_voiced_state",
    "lmt_sizeof_voiced_history",
    "lmt_sizeof_next_step_suggestion",
    "lmt_voiced_history_reset",
    "lmt_build_voiced_state",
    "lmt_voiced_history_push",
    "lmt_classify_motion",
    "lmt_evaluate_motion_profile",
    "lmt_rank_next_steps",
    "lmt_next_step_reason_count",
    "lmt_next_step_reason_name",
    "lmt_next_step_warning_count",
    "lmt_next_step_warning_name",
    "lmt_mode_spelling_quality",
    "lmt_spell_note",
    "lmt_spell_note_parts",
    "lmt_chord",
    "lmt_chord_name",
    "lmt_roman_numeral",
    "lmt_roman_numeral_parts",
    "lmt_fret_to_midi_n",
    "lmt_midi_to_fret_positions_n",
    "lmt_generate_voicings_n",
    "lmt_rank_context_suggestions",
    "lmt_preferred_voicing_n",
    "lmt_pitch_class_guide_n",
    "lmt_frets_to_url_n",
    "lmt_url_to_frets_n",
    "lmt_svg_clock_optc",
    "lmt_svg_optic_k_group",
    "lmt_svg_evenness_chart",
    "lmt_svg_evenness_field",
    "lmt_svg_fret",
    "lmt_svg_fret_n",
    "lmt_svg_fret_tuned_n",
    "lmt_svg_chord_staff",
    "lmt_svg_key_staff",
    "lmt_svg_keyboard",
    "lmt_svg_piano_staff",
    "lmt_bitmap_clock_optc_rgba",
    "lmt_bitmap_optic_k_group_rgba",
    "lmt_bitmap_evenness_chart_rgba",
    "lmt_bitmap_evenness_field_rgba",
    "lmt_bitmap_fret_rgba",
    "lmt_bitmap_fret_n_rgba",
    "lmt_bitmap_fret_tuned_n_rgba",
    "lmt_bitmap_chord_staff_rgba",
    "lmt_bitmap_key_staff_rgba",
    "lmt_bitmap_keyboard_rgba",
    "lmt_bitmap_piano_staff_rgba",
};

const render_compare_export_symbols = [_][]const u8{
    "lmt_wasm_scratch_ptr",
    "lmt_wasm_scratch_size",
    "lmt_svg_compat_kind_count",
    "lmt_svg_compat_kind_name",
    "lmt_svg_compat_kind_directory",
    "lmt_svg_compat_image_count",
    "lmt_svg_compat_image_name",
    "lmt_svg_compat_generate",
    "lmt_bitmap_proof_scale_numerator",
    "lmt_bitmap_proof_scale_denominator",
    "lmt_bitmap_compat_kind_supported",
    "lmt_bitmap_compat_candidate_backend_name",
    "lmt_bitmap_compat_target_width_scaled",
    "lmt_bitmap_compat_target_width",
    "lmt_bitmap_compat_target_height_scaled",
    "lmt_bitmap_compat_target_height",
    "lmt_bitmap_compat_required_rgba_bytes_scaled",
    "lmt_bitmap_compat_required_rgba_bytes",
    "lmt_bitmap_compat_render_candidate_rgba_scaled",
    "lmt_bitmap_compat_render_candidate_rgba",
    "lmt_bitmap_compat_render_reference_svg_rgba_scaled",
    "lmt_bitmap_compat_render_reference_svg_rgba",
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

fn createEmptyRootModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
}

fn createAbiRootModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path("src/c_api.zig"),
        .target = target,
        .optimize = optimize,
    });
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
    native_build_options.addOption(bool, "enable_harmonious_generic_fallbacks", true);
    lib_mod.addOptions("build_options", native_build_options);

    // ── Static library (C ABI) ──────────────────────────────────
    const static_mod = createAbiRootModule(b, target, optimize);
    static_mod.addOptions("build_options", native_build_options);

    const static_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = static_mod,
        .linkage = .static,
    });

    b.installArtifact(static_lib);

    // ── Shared library (C ABI) ──────────────────────────────────
    const shared_mod = createAbiRootModule(b, target, optimize);
    shared_mod.addOptions("build_options", native_build_options);

    const shared_lib = b.addLibrary(.{
        .name = "musictheory",
        .root_module = shared_mod,
        .linkage = .dynamic,
    });

    b.installArtifact(shared_lib);
    static_lib.installHeader(b.path("include/libmusictheory.h"), "libmusictheory.h");
    static_lib.installHeader(b.path("include/libmusictheory_compat.h"), "libmusictheory_compat.h");

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
    const wasm_validation_build_options = b.addOptions();
    wasm_validation_build_options.addOption(bool, "enable_harmonious_generic_fallbacks", false);
    wasm_mod.addOptions("build_options", wasm_validation_build_options);
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

    const wasm_demo_step = b.step("wasm-demo", "Build internal exact SVG parity validation bundle");
    wasm_demo_step.dependOn(&wasm_exe.step);
    wasm_demo_step.dependOn(&install_wasm.step);
    wasm_demo_step.dependOn(&install_validation_html.step);
    wasm_demo_step.dependOn(&install_validation_js.step);
    wasm_demo_step.dependOn(&install_validation_css.step);
    wasm_demo_step.dependOn(&install_index_stub.step);
    wasm_demo_step.dependOn(&install_app_stub.step);
    maybeInstallDirectory(b, wasm_demo_step, "tmp/harmoniousapp.net", "wasm-demo/tmp/harmoniousapp.net");

    const wasm_docs_mod = createAbiRootModule(b, wasm_target, .ReleaseSmall);
    const wasm_docs_build_options = b.addOptions();
    wasm_docs_build_options.addOption(bool, "enable_raster_backend", true);
    wasm_docs_build_options.addOption(bool, "enable_harmonious_generic_fallbacks", true);
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
    const install_docs_qa_atlas_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/qa-atlas.html"),
        .prefix,
        "wasm-docs/qa-atlas.html",
    );
    const install_docs_qa_atlas_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/qa-atlas.js"),
        .prefix,
        "wasm-docs/qa-atlas.js",
    );
    const install_docs_qa_atlas_css = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/qa-atlas.css"),
        .prefix,
        "wasm-docs/qa-atlas.css",
    );

    const wasm_docs_step = b.step("wasm-docs", "Build WebAssembly standalone interactive docs bundle");
    wasm_docs_step.dependOn(&wasm_docs_exe.step);
    wasm_docs_step.dependOn(&install_docs_wasm.step);
    wasm_docs_step.dependOn(&install_docs_index.step);
    wasm_docs_step.dependOn(&install_docs_app.step);
    wasm_docs_step.dependOn(&install_docs_styles.step);
    wasm_docs_step.dependOn(&install_docs_validation_html.step);
    wasm_docs_step.dependOn(&install_docs_validation_js.step);
    wasm_docs_step.dependOn(&install_docs_qa_atlas_html.step);
    wasm_docs_step.dependOn(&install_docs_qa_atlas_js.step);
    wasm_docs_step.dependOn(&install_docs_qa_atlas_css.step);
    maybeInstallDirectory(b, wasm_docs_step, "tmp/harmoniousapp.net", "wasm-docs/tmp/harmoniousapp.net");

    const wasm_gallery_mod = createAbiRootModule(b, wasm_target, .ReleaseSmall);
    const wasm_gallery_build_options = b.addOptions();
    wasm_gallery_build_options.addOption(bool, "enable_raster_backend", true);
    wasm_gallery_build_options.addOption(bool, "enable_harmonious_generic_fallbacks", false);
    wasm_gallery_mod.addOptions("build_options", wasm_gallery_build_options);
    wasm_gallery_mod.export_symbol_names = &gallery_export_symbols;

    const wasm_gallery_exe = b.addExecutable(.{
        .name = "libmusictheory_gallery",
        .root_module = wasm_gallery_mod,
    });
    configureWasmExe(wasm_gallery_exe);

    const install_gallery_wasm = b.addInstallFileWithDir(
        wasm_gallery_exe.getEmittedBin(),
        .prefix,
        "wasm-gallery/libmusictheory.wasm",
    );
    const install_gallery_index = b.addInstallFileWithDir(
        b.path("examples/wasm-gallery/index.html"),
        .prefix,
        "wasm-gallery/index.html",
    );
    const install_gallery_js = b.addInstallFileWithDir(
        b.path("examples/wasm-gallery/gallery.js"),
        .prefix,
        "wasm-gallery/gallery.js",
    );
    const install_gallery_styles = b.addInstallFileWithDir(
        b.path("examples/wasm-gallery/styles.css"),
        .prefix,
        "wasm-gallery/styles.css",
    );
    const install_gallery_presets = b.addInstallFileWithDir(
        b.path("examples/wasm-gallery/gallery-presets.json"),
        .prefix,
        "wasm-gallery/gallery-presets.json",
    );

    const wasm_gallery_step = b.step("wasm-gallery", "Build WebAssembly standalone gallery bundle");
    wasm_gallery_step.dependOn(&wasm_gallery_exe.step);
    wasm_gallery_step.dependOn(&install_gallery_wasm.step);
    wasm_gallery_step.dependOn(&install_gallery_index.step);
    wasm_gallery_step.dependOn(&install_gallery_js.step);
    wasm_gallery_step.dependOn(&install_gallery_styles.step);
    wasm_gallery_step.dependOn(&install_gallery_presets.step);

    const install_harmonious_spa_wasm = b.addInstallFileWithDir(
        wasm_docs_exe.getEmittedBin(),
        .prefix,
        "wasm-harmonious-spa/libmusictheory.wasm",
    );
    const install_harmonious_spa_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/harmonious-spa.html"),
        .prefix,
        "wasm-harmonious-spa/index.html",
    );
    const install_harmonious_spa_fallback_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/harmonious-spa-fallback.html"),
        .prefix,
        "wasm-harmonious-spa/404.html",
    );
    const install_harmonious_spa_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/harmonious-spa.js"),
        .prefix,
        "wasm-harmonious-spa/harmonious-spa.js",
    );

    const wasm_harmonious_spa_step = b.step("wasm-harmonious-spa", "Build internal harmoniousapp.net SPA verification shell");
    wasm_harmonious_spa_step.dependOn(&wasm_docs_exe.step);
    wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_wasm.step);
    wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_html.step);
    wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_fallback_html.step);
    wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_js.step);

    if (localDirExists("tmp/harmoniousapp.net")) {
        const spa_manifest_cmd = b.addSystemCommand(&.{"python3"});
        spa_manifest_cmd.addFileArg(b.path("scripts/generate_harmonious_spa_manifest.py"));
        spa_manifest_cmd.addArgs(&.{ "--root", "tmp/harmoniousapp.net", "--out" });
        const spa_manifest_out = spa_manifest_cmd.addOutputFileArg("harmonious-spa-manifest.js");
        const install_harmonious_spa_manifest = b.addInstallFileWithDir(
            spa_manifest_out,
            .prefix,
            "wasm-harmonious-spa/harmonious-spa-manifest.js",
        );
        const install_harmonious_spa_home = b.addInstallFileWithDir(
            b.path("tmp/harmoniousapp.net/index.html"),
            .prefix,
            "wasm-harmonious-spa/spa-content/index.html",
        );

        wasm_harmonious_spa_step.dependOn(&spa_manifest_cmd.step);
        wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_manifest.step);
        wasm_harmonious_spa_step.dependOn(&install_harmonious_spa_home.step);
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/p", "wasm-harmonious-spa/spa-content/p");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/keyboard", "wasm-harmonious-spa/spa-content/keyboard");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/eadgbe-frets", "wasm-harmonious-spa/spa-content/eadgbe-frets");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/css", "wasm-harmonious-spa/css");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/js-client", "wasm-harmonious-spa/js-client");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/svg", "wasm-harmonious-spa/svg");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/assets", "wasm-harmonious-spa/assets");
        maybeInstallDirectory(b, wasm_harmonious_spa_step, "tmp/harmoniousapp.net/woff", "wasm-harmonious-spa/woff");
    }

    const wasm_render_compare_mod = b.createModule(.{
        .root_source_file = b.path("src/wasm_scaled_render_api.zig"),
        .target = wasm_target,
        .optimize = .ReleaseSmall,
    });
    const wasm_render_compare_build_options = b.addOptions();
    wasm_render_compare_build_options.addOption(bool, "enable_harmonious_generic_fallbacks", false);
    wasm_render_compare_mod.addOptions("build_options", wasm_render_compare_build_options);
    wasm_render_compare_mod.export_symbol_names = &render_compare_export_symbols;

    const wasm_render_compare_exe = b.addExecutable(.{
        .name = "libmusictheory_render_compare",
        .root_module = wasm_render_compare_mod,
    });
    configureWasmExe(wasm_render_compare_exe);

    const install_scaled_render_parity_wasm = b.addInstallFileWithDir(
        wasm_render_compare_exe.getEmittedBin(),
        .prefix,
        "wasm-scaled-render-parity/libmusictheory.wasm",
    );
    const install_scaled_render_parity_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/scaled-render-parity.html"),
        .prefix,
        "wasm-scaled-render-parity/index.html",
    );
    const install_scaled_render_parity_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/scaled-render-parity.js"),
        .prefix,
        "wasm-scaled-render-parity/scaled-render-parity.js",
    );
    const install_scaled_render_parity_common_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/render-compare-common.js"),
        .prefix,
        "wasm-scaled-render-parity/render-compare-common.js",
    );
    const install_scaled_render_parity_css = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/styles.css"),
        .prefix,
        "wasm-scaled-render-parity/styles.css",
    );

    const wasm_scaled_render_parity_step = b.step("wasm-scaled-render-parity", "Build internal scaled render parity verification bundle");
    wasm_scaled_render_parity_step.dependOn(&wasm_render_compare_exe.step);
    wasm_scaled_render_parity_step.dependOn(&install_scaled_render_parity_wasm.step);
    wasm_scaled_render_parity_step.dependOn(&install_scaled_render_parity_html.step);
    wasm_scaled_render_parity_step.dependOn(&install_scaled_render_parity_js.step);
    wasm_scaled_render_parity_step.dependOn(&install_scaled_render_parity_common_js.step);
    wasm_scaled_render_parity_step.dependOn(&install_scaled_render_parity_css.step);
    maybeInstallDirectory(b, wasm_scaled_render_parity_step, "tmp/harmoniousapp.net", "wasm-scaled-render-parity/tmp/harmoniousapp.net");

    const install_native_rgba_proof_wasm = b.addInstallFileWithDir(
        wasm_render_compare_exe.getEmittedBin(),
        .prefix,
        "wasm-native-rgba-proof/libmusictheory.wasm",
    );
    const install_native_rgba_proof_html = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/native-rgba-proof.html"),
        .prefix,
        "wasm-native-rgba-proof/index.html",
    );
    const install_native_rgba_proof_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/native-rgba-proof.js"),
        .prefix,
        "wasm-native-rgba-proof/native-rgba-proof.js",
    );
    const install_native_rgba_proof_common_js = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/render-compare-common.js"),
        .prefix,
        "wasm-native-rgba-proof/render-compare-common.js",
    );
    const install_native_rgba_proof_css = b.addInstallFileWithDir(
        b.path("examples/wasm-demo/styles.css"),
        .prefix,
        "wasm-native-rgba-proof/styles.css",
    );

    const wasm_native_rgba_proof_step = b.step("wasm-native-rgba-proof", "Build internal native RGBA proof verification bundle");
    wasm_native_rgba_proof_step.dependOn(&wasm_render_compare_exe.step);
    wasm_native_rgba_proof_step.dependOn(&install_native_rgba_proof_wasm.step);
    wasm_native_rgba_proof_step.dependOn(&install_native_rgba_proof_html.step);
    wasm_native_rgba_proof_step.dependOn(&install_native_rgba_proof_js.step);
    wasm_native_rgba_proof_step.dependOn(&install_native_rgba_proof_common_js.step);
    wasm_native_rgba_proof_step.dependOn(&install_native_rgba_proof_css.step);
    maybeInstallDirectory(b, wasm_native_rgba_proof_step, "tmp/harmoniousapp.net", "wasm-native-rgba-proof/tmp/harmoniousapp.net");

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
        .root_module = createEmptyRootModule(b, target, optimize),
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
        .root_module = createEmptyRootModule(b, target, optimize),
    });
    c_smoke_shared.linkLibC();
    c_smoke_shared.addIncludePath(b.path("include"));
    c_smoke_shared.addCSourceFile(.{
        .file = b.path("examples/c/smoke.c"),
    });
    c_smoke_shared.linkLibrary(shared_lib);

    const run_c_smoke_shared = b.addRunArtifact(c_smoke_shared);

    const c_compat_smoke_static = b.addExecutable(.{
        .name = "c_api_compat_smoke_static",
        .root_module = createEmptyRootModule(b, target, optimize),
    });
    c_compat_smoke_static.linkLibC();
    c_compat_smoke_static.addIncludePath(b.path("include"));
    c_compat_smoke_static.addCSourceFile(.{
        .file = b.path("examples/c/compat_smoke.c"),
    });
    c_compat_smoke_static.linkLibrary(static_lib);

    const run_c_compat_smoke_static = b.addRunArtifact(c_compat_smoke_static);

    const c_compat_smoke_shared = b.addExecutable(.{
        .name = "c_api_compat_smoke_shared",
        .root_module = createEmptyRootModule(b, target, optimize),
    });
    c_compat_smoke_shared.linkLibC();
    c_compat_smoke_shared.addIncludePath(b.path("include"));
    c_compat_smoke_shared.addCSourceFile(.{
        .file = b.path("examples/c/compat_smoke.c"),
    });
    c_compat_smoke_shared.linkLibrary(shared_lib);

    const run_c_compat_smoke_shared = b.addRunArtifact(c_compat_smoke_shared);

    const c_smoke_step = b.step("c-smoke", "Run C ABI smoke tests");
    c_smoke_step.dependOn(&run_c_smoke_static.step);
    c_smoke_step.dependOn(&run_c_smoke_shared.step);
    c_smoke_step.dependOn(&run_c_compat_smoke_static.step);
    c_smoke_step.dependOn(&run_c_compat_smoke_shared.step);

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
    verify_step.dependOn(&run_c_compat_smoke_static.step);
    verify_step.dependOn(&run_c_compat_smoke_shared.step);
    verify_step.dependOn(&fmt.step);
}
