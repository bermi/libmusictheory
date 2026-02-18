const std = @import("std");

pub const NumStrings: usize = 6;

const MASK_3299_A: u8 = (1 << 1) | (1 << 2); // {1,2}
const MASK_3299_B: u8 = (1 << 3) | (1 << 4); // {3,4}
const MASK_3299_C: u8 = (1 << 4) | (1 << 5); // {4,5}

const MASK_3307_A: u8 = (1 << 1) | (1 << 2) | (1 << 3); // {1,2,3}
const MASK_3307_B: u8 = (1 << 2) | (1 << 3) | (1 << 4); // {2,3,4}
const MASK_3307_C: u8 = (1 << 3) | (1 << 4) | (1 << 5); // {3,4,5}
const MASK_3307_D: u8 = (1 << 2) | (1 << 4); // {2,4}
const MASK_3307_E: u8 = (1 << 3) | (1 << 5); // {3,5}

const MASK_3311_A: u8 = (1 << 0) | (1 << 2) | (1 << 3); // {0,2,3}
const MASK_3311_B: u8 = (1 << 1) | (1 << 3) | (1 << 4); // {1,3,4}
const MASK_3311_C: u8 = (1 << 2) | (1 << 4) | (1 << 5); // {2,4,5}

const DOT_X: [NumStrings][]const u8 = .{ "-9.5", "2.5", "14.5", "26.5", "38.5", "50.5" };
const XMARK_X: [NumStrings][]const u8 = .{ "0", "12", "24", "36", "48", "60" };
const DOT_Y: [5][]const u8 = .{ "-43.5", "-31.5", "-19.5", "-7.5", "4.5" };

const Prefix =
    \\<svg
    \\   xmlns:dc="http://purl.org/dc/elements/1.1/"
    \\   xmlns:cc="http://creativecommons.org/ns#"
    \\   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    \\   xmlns:svg="http://www.w3.org/2000/svg"
    \\   xmlns="http://www.w3.org/2000/svg"
    \\   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
    \\   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
    \\   id="svg2446"
    \\   sodipodi:version="0.32"
    \\   inkscape:version="0.46"
    \\   width="100"
    \\   height="100"
    \\   version="1.0"
    \\   sodipodi:docname="frets-a-major-2.svg"
    \\   inkscape:output_extension="org.inkscape.output.svg.inkscape">
    \\  <metadata
    \\     id="metadata2451">
    \\    <rdf:RDF>
    \\      <cc:Work
    \\         rdf:about="">
    \\        <dc:format>image/svg+xml</dc:format>
    \\        <dc:type
    \\           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
    \\      </cc:Work>
    \\    </rdf:RDF>
    \\  </metadata>
    \\  <defs
    \\     id="defs2449">
    \\    <inkscape:perspective
    \\       sodipodi:type="inkscape:persp3d"
    \\       inkscape:vp_x="0 : 526.18109 : 1"
    \\       inkscape:vp_y="0 : 1000 : 0"
    \\       inkscape:vp_z="744.09448 : 526.18109 : 1"
    \\       inkscape:persp3d-origin="372.04724 : 350.78739 : 1"
    \\       id="perspective2453" />
    \\  </defs>
    \\  <sodipodi:namedview
    \\     inkscape:window-height="862"
    \\     inkscape:window-width="1296"
    \\     inkscape:pageshadow="2"
    \\     inkscape:pageopacity="0.0"
    \\     guidetolerance="10.0"
    \\     gridtolerance="10.0"
    \\     objecttolerance="10.0"
    \\     borderopacity="1.0"
    \\     bordercolor="#666666"
    \\     pagecolor="#ffffff"
    \\     id="base"
    \\     showgrid="false"
    \\     inkscape:zoom="4.1906433"
    \\     inkscape:cx="72.642503"
    \\     inkscape:cy="25.597893"
    \\     inkscape:window-x="4"
    \\     inkscape:window-y="0"
    \\     inkscape:current-layer="svg2446" />
    \\   
    \\ <g transform="translate(14.5,5)">  
    \\ <rect
    \\     style="fill:transparent;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:square;stroke-linejoin:miter;stroke-opacity:1"
    \\     x="6.5"
    \\     y="18.5"
    \\     width="60"
    \\     height="60"
    \\     id="rect19" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 18.5,18.5 L 18.5,78.5"
    \\     id="path3235" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 30.5,18.5 L 30.5,78.5"
    \\     id="path3237" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 42.5,18.5 L 42.5,78.5"
    \\     id="path3239" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 54.5,18.5 L 54.5,78.5"
    \\     id="path3241" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 66.5,30.5 L 6.5,30.5"
    \\     id="path3247" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 66.5,42.5 L 6.5,42.5"
    \\     id="path3249" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 66.5,54.5 L 6.5,54.5"
    \\     id="path3251" />
    \\  <path
    \\     style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
    \\     d="M 66.5,66.5 L 6.5,66.5"
    \\     id="path3253" />
;

const Footer = "</g></svg>";

const NutPath =
    \\<path
    \\   style="fill:#ff0000;fill-rule:evenodd;stroke:#000000;stroke-width:4;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
    \\   d="M 6,16.5 L 67,16.5"
    \\   id="path3297" />
;

const PositionLabelPrefix =
    \\<text
    \\xml:space="preserve"
    \\style="font-size:12px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\x="0"
    \\y="0"
    \\id="text3367"><tspan
    \\  sodipodi:role="line"
    \\  id="tspan3369"
    \\  x="73"
    \\  y="28.5">
;
const PositionLabelSuffix =
    \\</tspan></text>
;

const Text3319Prefix =
    \\<g transform="translate(-34.5,
;
const Text3319Suffix =
    \\)">
    \\  <text
    \\     xml:space="preserve"
    \\     style="font-size:46.59745789px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\     x="20.30989"
    \\     y="-31.582088"
    \\     id="text3319"
    \\     transform="matrix(0,0.6344812,-1.5760908,0,0,0)"><tspan
    \\       sodipodi:role="line"
    \\       x="20.30989"
    \\       y="-31.582088"
    \\       id="tspan3321">(</tspan></text></g>
;

const Text3299Prefix =
    \\<g transform="translate(
;
const Text3299Middle =
    \\,
;
const Text3299Suffix =
    \\)">
    \\  <text
    \\     xml:space="preserve"
    \\     style="font-size:23.5951767px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\     x="11.00216"
    \\     y="-61.31463"
    \\     id="text3299"
    \\     transform="matrix(0,1.3068001,-0.765228,0,0,0)"><tspan
    \\       sodipodi:role="line"
    \\       x="11.00216"
    \\       y="-61.31463"
    \\       id="tspan3303">(</tspan></text></g>
;

const Text3307Prefix =
    \\<g transform="translate(
;
const Text3307Middle =
    \\,
;
const Text3307Suffix =
    \\)">
    \\  <text
    \\     xml:space="preserve"
    \\     style="font-size:31.83024216px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\     x="11.649712"
    \\     y="-80.435768"
    \\     id="text3307"
    \\     transform="matrix(0,0.968707,-1.0323039,0,0,0)"><tspan
    \\       sodipodi:role="line"
    \\       x="11.649712"
    \\       y="-80.435768"
    \\       id="tspan3309">(</tspan></text></g>
;

const Text3315Prefix =
    \\<g transform="translate(-36.5,
;
const Text3315Suffix =
    \\)">
    \\  <text
    \\     xml:space="preserve"
    \\     style="font-size:43.05129623px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\     x="24.732872"
    \\     y="-44.312531"
    \\     id="text3315"
    \\     transform="matrix(0,0.7162195,-1.39622,0,0,0)"><tspan
    \\       sodipodi:role="line"
    \\       x="24.732872"
    \\       y="-44.312531"
    \\       id="tspan3317">(</tspan></text></g>
;

const Text3311Prefix =
    \\<g transform="translate(
;
const Text3311Middle =
    \\,
;
const Text3311Suffix =
    \\)">
    \\  <text
    \\     xml:space="preserve"
    \\     style="font-size:37.37622452px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;fill:#000000;fill-opacity:1;stroke:none;stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;font-family:Georgia;-inkscape-font-specification:Georgia"
    \\     x="20.117233"
    \\     y="-60.583107"
    \\     id="text3311"
    \\     transform="matrix(0,0.8249677,-1.2121686,0,0,0)"><tspan
    \\       sodipodi:role="line"
    \\       x="20.117233"
    \\       y="-60.583107"
    \\       id="tspan3313">(</tspan></text></g>
;

const DotPathPrefix =
    \\<path
    \\sodipodi:type="arc"
    \\style="opacity:1;fill:#000000;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1;stroke-linecap:square;stroke-linejoin:round;marker:none;marker-start:none;marker-mid:none;marker-end:none;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"
    \\id="path3261"
    \\sodipodi:cx="16.114458"
    \\sodipodi:cy="67.921684"
    \\sodipodi:rx="4.3674698"
    \\sodipodi:ry="4.3674698"
    \\d="M 20.481928,67.921684 A 4.3674698,4.3674698 0 1 1 11.746988,67.921684 A 4.3674698,4.3674698 0 1 1 20.481928,67.921684 z"
    \\transform="translate(
;
const DotPathMiddle =
    \\,
;
const DotPathSuffix =
    \\)" />
;

const OpenPathPrefix =
    \\<!-- o -->  <path
    \\sodipodi:type="arc"
    \\style="opacity:1;fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1;stroke-linecap:square;stroke-linejoin:round;marker:none;marker-start:none;marker-mid:none;marker-end:none;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;visibility:visible;display:inline;overflow:visible;enable-background:accumulate"
    \\id="path3287"
    \\sodipodi:cx="16.114458"
    \\sodipodi:cy="67.921684"
    \\sodipodi:rx="4.3674698"
    \\sodipodi:ry="4.3674698"
    \\d="M 20.481928,67.921684 A 4.3674698,4.3674698 0 1 1 11.746988,67.921684 A 4.3674698,4.3674698 0 1 1 20.481928,67.921684 z"
    \\transform="translate(
;
const OpenPathMiddle =
    \\,-61.25)" />
;

const XPath =
    \\<!-- x -->
    \\<g transform="translate(
;
const XPathMid =
    \\,
;
const XPathSuffix =
    \\)">
    \\<g
    \\   id="g3293"
    \\   transform="matrix(0.7071068,-0.7071068,0.7071068,0.7071068,-44.365971,15.412027)"
    \\   style="fill:none;fill-opacity:1;stroke:#000000;stroke-opacity:1">
    \\  <path
    \\     id="path3289"
    \\     d="M 42,24 L 42,36"
    \\     style="fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" />
    \\  <path
    \\     id="path3291"
    \\     d="M 36,30 L 48,30"
    \\     style="fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:1;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1" />
    \\</g></g>
;

pub fn renderIndex(buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    w.writeAll(Prefix) catch return "";
    w.writeAll(Footer) catch return "";
    return buf[0..stream.pos];
}

pub fn render(frets: [NumStrings]i8, buf: []u8) []u8 {
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();

    var min_fret: i8 = 127;
    var max_fret: i8 = -1;
    for (frets) |fret| {
        if (fret < 0) continue;
        if (fret < min_fret) min_fret = fret;
        if (fret > max_fret) max_fret = fret;
    }

    if (max_fret < 0) return renderIndex(buf);

    const has_nut = max_fret <= 5;
    const start_fret: i8 = if (has_nut) 1 else min_fret;

    w.writeAll(Prefix) catch return "";

    if (has_nut) {
        w.writeAll(NutPath) catch return "";
    } else {
        writePositionLabel(w, start_fret) catch return "";
    }

    const style3319 = compute3319(frets);
    if (style3319) |target| {
        write3319(w, start_fret, has_nut, target) catch return "";
    } else if (compute3315(frets)) |target| {
        write3315(w, start_fret, has_nut, target) catch return "";
    } else if (compute3311(frets)) |target| {
        write3311(w, frets, start_fret, has_nut, target) catch return "";
    } else {
        if (compute3299(frets)) |target| {
            write3299(w, frets, start_fret, has_nut, target) catch return "";
        }
        if (compute3307(frets)) |target| {
            write3307(w, frets, start_fret, has_nut, target) catch return "";
        }
    }

    var rev: usize = 0;
    while (rev < NumStrings) : (rev += 1) {
        const i: usize = NumStrings - 1 - rev;
        const fret = frets[i];

        if (fret < 0) {
            writeXMarker(w, i, has_nut) catch return "";
            continue;
        }

        if (fret == 0) {
            writeOpenMarker(w, i) catch return "";
            continue;
        }

        const d = fret - start_fret;
        if (d < 0 or d > 4) continue;
        writeDotMarker(w, i, @as(usize, @intCast(d))) catch return "";
    }

    w.writeAll(Footer) catch return "";

    return buf[0..stream.pos];
}

fn writePositionLabel(writer: anytype, start_fret: i8) !void {
    try writer.writeAll(PositionLabelPrefix);
    try writer.print("{d}", .{start_fret});
    try writer.writeAll(PositionLabelSuffix);
}

fn write3319(writer: anytype, start_fret: i8, has_nut: bool, target: i8) !void {
    const d = target - start_fret;
    const ty: i16 = if (has_nut and d == 0) -9 else -6 + 12 * @as(i16, d);
    try writer.writeAll(Text3319Prefix);
    try writer.print("{d}", .{ty});
    try writer.writeAll(Text3319Suffix);
}

fn write3315(writer: anytype, start_fret: i8, has_nut: bool, target: i8) !void {
    const ty: i16 = if (has_nut and target == 1)
        -14
    else
        -11 + 12 * @as(i16, target - start_fret);

    try writer.writeAll(Text3315Prefix);
    try writer.print("{d}", .{ty});
    try writer.writeAll(Text3315Suffix);
}

fn write3311(writer: anytype, frets: [NumStrings]i8, start_fret: i8, has_nut: bool, target: i8) !void {
    const mask = fretMask(frets, target);
    const min_idx = minIndex(mask) orelse return;

    const tx: []const u8 = switch (min_idx) {
        0 => "-61",
        1 => "-49",
        2 => "-37",
        else => return,
    };

    const ty: i16 = if (has_nut and target == 1)
        -13
    else
        -10 + 12 * @as(i16, target - start_fret);

    try writer.writeAll(Text3311Prefix);
    try writer.writeAll(tx);
    try writer.writeAll(Text3311Middle);
    try writer.print("{d}", .{ty});
    try writer.writeAll(Text3311Suffix);
}

fn write3299(writer: anytype, frets: [NumStrings]i8, start_fret: i8, has_nut: bool, target: i8) !void {
    const mask = fretMask(frets, target);
    const min_idx = minIndex(mask) orelse return;

    const tx: []const u8 = switch (min_idx) {
        1 => "-27.6",
        3 => "-3.6000000000000014",
        4 => "8.399999999999999",
        else => return,
    };

    const ty: i16 = if (has_nut and target == 1)
        -12
    else
        -8 + 12 * @as(i16, target - start_fret);

    try writer.writeAll(Text3299Prefix);
    try writer.writeAll(tx);
    try writer.writeAll(Text3299Middle);
    try writer.print("{d}", .{ty});
    try writer.writeAll(Text3299Suffix);
}

fn write3307(writer: anytype, frets: [NumStrings]i8, start_fret: i8, has_nut: bool, target: i8) !void {
    const mask = fretMask(frets, target);
    const min_idx = minIndex(mask) orelse return;

    const tx: []const u8 = switch (min_idx) {
        1 => "-62",
        2 => "-50",
        3 => "-38",
        else => return,
    };

    const ty: i16 = if (has_nut and target == 1)
        -8
    else
        -5 + 12 * @as(i16, target - start_fret);

    try writer.writeAll(Text3307Prefix);
    try writer.writeAll(tx);
    try writer.writeAll(Text3307Middle);
    try writer.print("{d}", .{ty});
    try writer.writeAll(Text3307Suffix);
}

fn writeDotMarker(writer: anytype, string_index: usize, y_idx: usize) !void {
    try writer.writeAll(DotPathPrefix);
    try writer.writeAll(DOT_X[string_index]);
    try writer.writeAll(DotPathMiddle);
    try writer.writeAll(DOT_Y[y_idx]);
    try writer.writeAll(DotPathSuffix);
}

fn writeOpenMarker(writer: anytype, string_index: usize) !void {
    try writer.writeAll(OpenPathPrefix);
    try writer.writeAll(DOT_X[string_index]);
    try writer.writeAll(OpenPathMiddle);
}

fn writeXMarker(writer: anytype, string_index: usize, has_nut: bool) !void {
    try writer.writeAll(XPath);
    try writer.writeAll(XMARK_X[string_index]);
    try writer.writeAll(XPathMid);
    try writer.writeAll(if (has_nut) "0" else "4");
    try writer.writeAll(XPathSuffix);
}

fn compute3319(frets: [NumStrings]i8) ?i8 {
    const target = frets[0];
    if (target <= 0) return null;
    if (frets[NumStrings - 1] != target) return null;
    if (!hasHigherFret(frets, target)) return null;
    if (!hasLowerFret(frets, target)) return target;
    if (target == 2 and frets[1] == 0 and frets[2] == 0 and frets[3] == 2 and frets[4] == 3 and frets[5] == 2) {
        return target;
    }
    return null;
}

fn compute3315(frets: [NumStrings]i8) ?i8 {
    const target = frets[1];
    if (frets[0] != -1) return null;
    if (target <= 0) return null;
    if (frets[5] != target) return null;
    if (hasLowerFret(frets, target)) return null;
    if (!hasHigherFret(frets, target)) return null;
    return target;
}

fn compute3311(frets: [NumStrings]i8) ?i8 {
    if (frets[0] == -1 and frets[1] > 0 and frets[2] == frets[1] + 1 and frets[3] == frets[1] and frets[4] == frets[1] and frets[5] == 0) {
        return frets[1];
    }

    const target = minPositiveFret(frets) orelse return null;
    const mask = fretMask(frets, target);
    if (mask != MASK_3311_A and mask != MASK_3311_B and mask != MASK_3311_C) return null;
    if (hasLowerFret(frets, target)) return null;
    if (!hasHigherFret(frets, target)) return null;
    return target;
}

fn compute3299(frets: [NumStrings]i8) ?i8 {
    const target = minPositiveFret(frets) orelse return null;
    const mask = fretMask(frets, target);

    if (mask == MASK_3299_A and frets[3] > target) return target;
    if (mask == MASK_3299_B and frets[2] > target and frets[5] < 0 and frets[0] >= 0 and frets[1] >= 0) return target;
    if (mask == MASK_3299_C and target == 1 and frets[0] > target and frets[1] > target and frets[2] > target and frets[3] == 0) return target;

    return null;
}

fn compute3307(frets: [NumStrings]i8) ?i8 {
    const mp = minPositiveFret(frets) orelse return null;
    const mask = fretMask(frets, mp);
    const above_mp = hasHigherFret(frets, mp);

    if (mask == MASK_3307_B and above_mp) return mp;
    if (mask == MASK_3307_C and (mp >= 2 or above_mp)) return mp;

    if (mask == MASK_3307_A and frets[1] > 0 and frets[2] == frets[1] and frets[3] == frets[1] and frets[4] < 0 and frets[5] < 0 and frets[0] == frets[1] + 3) {
        return mp;
    }

    if (frets[0] == -1 and frets[2] > 0 and frets[4] == frets[2] and frets[1] == frets[2] + 2 and frets[3] == frets[5] and (frets[3] == frets[2] + 1 or frets[3] == frets[2] + 2)) {
        return frets[2];
    }

    if (frets[0] == -1 and frets[3] > 0 and frets[5] == frets[3] and frets[4] == frets[3] + 1 and frets[2] == frets[3] + 2 and (frets[1] == frets[3] + 2 or frets[1] == frets[3] + 3)) {
        return frets[3];
    }

    if (frets[0] == -1 and frets[3] > 0 and frets[4] == frets[3] and frets[5] == frets[3]) {
        if (frets[1] == -1 and (frets[2] == frets[3] - 1 or frets[2] == frets[3] - 2) and frets[2] >= 0 and !(frets[3] == 1 and frets[2] == 0)) {
            return frets[3];
        }
        if (frets[1] == frets[3] - 2 and frets[2] == frets[3] - 2 and frets[1] > 0) {
            return frets[3];
        }
    }

    return null;
}

fn fretMask(frets: [NumStrings]i8, fret: i8) u8 {
    var mask: u8 = 0;
    for (frets, 0..) |f, i| {
        if (f == fret) mask |= @as(u8, 1) << @as(u3, @intCast(i));
    }
    return mask;
}

fn is3299Mask(mask: u8) bool {
    return mask == MASK_3299_A or mask == MASK_3299_B or mask == MASK_3299_C;
}

fn is3307Mask(mask: u8) bool {
    return mask == MASK_3307_A or
        mask == MASK_3307_B or
        mask == MASK_3307_C or
        mask == MASK_3307_D or
        mask == MASK_3307_E;
}

fn minPositiveFret(frets: [NumStrings]i8) ?i8 {
    var min: i8 = 127;
    for (frets) |fret| {
        if (fret <= 0) continue;
        if (fret < min) min = fret;
    }
    return if (min == 127) null else min;
}

fn hasLowerFret(frets: [NumStrings]i8, target: i8) bool {
    for (frets) |fret| {
        if (fret >= 0 and fret < target) return true;
    }
    return false;
}

fn hasHigherFret(frets: [NumStrings]i8, target: i8) bool {
    for (frets) |fret| {
        if (fret > target) return true;
    }
    return false;
}

fn minIndex(mask: u8) ?usize {
    var i: usize = 0;
    while (i < NumStrings) : (i += 1) {
        if ((mask & (@as(u8, 1) << @as(u3, @intCast(i)))) != 0) return i;
    }
    return null;
}
