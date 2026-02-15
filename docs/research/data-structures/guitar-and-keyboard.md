# Guitar and Keyboard Data Structures

> References: [Guitar and Keyboard](../guitar-and-keyboard.md)
> Used by: guitar-voicing, keyboard-interaction

## Guitar Types

### Tuning

Open string MIDI notes for a guitar tuning.

```zig
pub const NUM_STRINGS = 6;
pub const MAX_FRET = 24;

pub const Tuning = [NUM_STRINGS]MidiNote;

pub const tunings = struct {
    pub const STANDARD: Tuning = .{ 40, 45, 50, 55, 59, 64 };
    pub const DROP_D: Tuning = .{ 38, 45, 50, 55, 59, 64 };
    pub const DADGAD: Tuning = .{ 38, 45, 50, 55, 57, 62 };
    pub const OPEN_G: Tuning = .{ 38, 43, 50, 55, 59, 62 };
    pub const OPEN_D: Tuning = .{ 38, 45, 50, 54, 57, 62 };
};
```

### FretPosition

A single position on the fretboard.

```zig
pub const FretPosition = struct {
    string: u3,    // 0-5 (low E to high E)
    fret: u5,      // 0-24

    pub fn toMidi(self: FretPosition, tuning: Tuning) MidiNote {
        return tuning[self.string] + self.fret;
    }

    pub fn toPitchClass(self: FretPosition, tuning: Tuning) PitchClass {
        return @intCast(self.toMidi(tuning) % 12);
    }
};
```

### GuitarVoicing

A complete chord voicing across all 6 strings.

```zig
pub const StringState = enum(u2) {
    muted = 0,     // string not played
    open = 1,      // open string (fret 0)
    fretted = 2,   // specific fret pressed
};

pub const GuitarVoicing = struct {
    frets: [NUM_STRINGS]i8,   // -1 = muted, 0 = open, 1-24 = fret
    tuning: Tuning,

    pub fn stringState(self: GuitarVoicing, string: u3) StringState {
        if (self.frets[string] < 0) return .muted;
        if (self.frets[string] == 0) return .open;
        return .fretted;
    }

    pub fn toMidiNotes(self: GuitarVoicing, buf: *[NUM_STRINGS]MidiNote) []MidiNote {
        var count: usize = 0;
        for (0..NUM_STRINGS) |i| {
            if (self.frets[i] >= 0) {
                buf[count] = @intCast(self.tuning[i] + @as(u8, @intCast(self.frets[i])));
                count += 1;
            }
        }
        return buf[0..count];
    }

    pub fn toPitchClassSet(self: GuitarVoicing) PitchClassSet {
        var result: PitchClassSet = 0;
        for (0..NUM_STRINGS) |i| {
            if (self.frets[i] >= 0) {
                const midi = self.tuning[i] + @as(u8, @intCast(self.frets[i]));
                result |= @as(PitchClassSet, 1) << @intCast(midi % 12);
            }
        }
        return result;
    }

    pub fn handSpan(self: GuitarVoicing) u5 {
        var min_fret: u5 = MAX_FRET;
        var max_fret: u5 = 0;
        var has_fretted = false;
        for (self.frets) |f| {
            if (f > 0) {
                const uf: u5 = @intCast(f);
                if (uf < min_fret) min_fret = uf;
                if (uf > max_fret) max_fret = uf;
                has_fretted = true;
            }
        }
        if (!has_fretted) return 0;
        return max_fret - min_fret;
    }

    pub fn toUrlString(self: GuitarVoicing, buf: *[32]u8) []u8 {
        // Format: "x,0,2,2,2,0" or "0,3,2,0,1,0"
        var len: usize = 0;
        for (0..NUM_STRINGS) |i| {
            if (i > 0) { buf[len] = ','; len += 1; }
            if (self.frets[i] < 0) {
                buf[len] = 'x'; len += 1;
            } else {
                // write number...
            }
        }
        return buf[0..len];
    }
};
```

### CAGEDPosition

One of the 5 CAGED system positions for a chord.

```zig
pub const CAGEDShape = enum(u3) {
    C = 0, A = 1, G = 2, E = 3, D = 4,
};

pub const CAGEDPosition = struct {
    shape: CAGEDShape,
    voicing: GuitarVoicing,
    position: u5,          // fret position (barre fret)
    root_string: u3,       // which string has the root
};
```

### GuideDot

Visual guide showing octave-equivalent positions on the fretboard.

```zig
pub const GuideDot = struct {
    position: FretPosition,
    pitch_class: PitchClass,
    opacity: f32,           // 0.35 for guide, 0.4 for muted string indication

    pub const GUIDE_OPACITY: f32 = 0.35;
    pub const MUTED_OPACITY: f32 = 0.4;
};
```

## Keyboard Types

### KeyboardState

State of the interactive piano keyboard.

```zig
pub const KeyboardState = struct {
    selected_notes: std.BoundedArray(MidiNote, 48),  // max 48 keys in 4-octave range
    accid_pref: AccidentalPreference,
    range_low: MidiNote,    // default 36 (C2)
    range_high: MidiNote,   // default 83 (B5)

    pub fn pitchClassSet(self: KeyboardState) PitchClassSet {
        var result: PitchClassSet = 0;
        for (self.selected_notes.slice()) |midi| {
            result |= @as(PitchClassSet, 1) << @intCast(midi % 12);
        }
        return result;
    }

    pub fn toggle(self: *KeyboardState, midi: MidiNote) void {
        // Add or remove note from selection
        for (self.selected_notes.slice(), 0..) |n, i| {
            if (n == midi) {
                _ = self.selected_notes.orderedRemove(i);
                return;
            }
        }
        self.selected_notes.append(midi) catch {};
    }
};
```

### KeyVisual

Visual state for one piano key.

```zig
pub const KeyVisual = struct {
    midi: MidiNote,
    is_black: bool,
    opacity: f32,           // 1.0 = selected, 0.5 = octave equiv, 0.0 = normal
    label: ?NoteName,       // spelled note name when selected

    pub const FULL_OPACITY: f32 = 1.0;
    pub const HALF_OPACITY: f32 = 0.5;
    pub const NORMAL_OPACITY: f32 = 0.0;
};
```

## Key Slider Types

### SliderState

State of the interactive key slider canvas.

```zig
pub const SliderState = struct {
    position: f32,          // horizontal scroll position in pixels
    velocity: f32,          // current scroll velocity
    current_key: u4,        // 0-11, index in circle of fifths
    is_dragging: bool,
    canvas_width: f32,
    canvas_height: f32,

    pub const FRICTION: f32 = 0.96;

    pub fn stride(self: SliderState) f32 {
        return self.canvas_width / 9.0;
    }

    pub fn scrollFraction(self: SliderState) f32 {
        const s = self.stride();
        return @mod(self.position, s) / s;
    }
};
```

### GridCoord

Position in the triangular Tonnetz grid.

```zig
pub const GridCoord = struct {
    row: u4,
    col: u4,
    is_down_triangle: bool,
};

pub const TriangleInfo = struct {
    coord: GridCoord,
    color_index: u4,        // 0-11, maps to pitch class via COLOR_INDEX
    // Up triangles = major-type chords
    // Down triangles = minor-type chords
};
```

### Color

RGB color for triangle rendering.

```zig
pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn blend(a: Color, b: Color, t: f32) Color {
        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(a.r)) + (@as(f32, @floatFromInt(b.r)) - @as(f32, @floatFromInt(a.r))) * t),
            .g = @intFromFloat(@as(f32, @floatFromInt(a.g)) + (@as(f32, @floatFromInt(b.g)) - @as(f32, @floatFromInt(a.g))) * t),
            .b = @intFromFloat(@as(f32, @floatFromInt(a.b)) + (@as(f32, @floatFromInt(b.b)) - @as(f32, @floatFromInt(a.b))) * t),
        };
    }

    pub fn toHex(self: Color, buf: *[7]u8) []u8 {
        // "#RRGGBB" format
    }
};

/// 12 pitch-class colors
pub const PC_COLORS = [12]Color{
    .{ .r = 0x00, .g = 0x00, .b = 0xCC }, // C
    .{ .r = 0xAA, .g = 0x44, .b = 0xFF }, // C#
    .{ .r = 0xFF, .g = 0x00, .b = 0xFF }, // D
    .{ .r = 0xAA, .g = 0x11, .b = 0x66 }, // D#
    .{ .r = 0xEE, .g = 0x00, .b = 0x22 }, // E
    .{ .r = 0xFF, .g = 0x99, .b = 0x11 }, // F
    .{ .r = 0xCC, .g = 0x88, .b = 0x11 }, // F#
    .{ .r = 0x00, .g = 0x99, .b = 0x44 }, // G
    .{ .r = 0x11, .g = 0x66, .b = 0x11 }, // G#
    .{ .r = 0x00, .g = 0x77, .b = 0x77 }, // A
    .{ .r = 0x00, .g = 0xBB, .b = 0xBB }, // A#
    .{ .r = 0x22, .g = 0x88, .b = 0xFF }, // B
};

/// Circle-of-fifths color reordering
pub const COLOR_INDEX = [12]u4{ 2, 7, 0, 5, 10, 3, 8, 1, 6, 11, 4, 9 };
```

## Relationships

```
Guitar:
  Tuning [6]MidiNote
    └── FretPosition (string + fret)
          └── GuitarVoicing ([6]i8)
                └── CAGEDPosition (shape + voicing)
          └── GuideDot (position + opacity)

Keyboard:
  KeyboardState (selected notes + preference)
    └── KeyVisual (per-key rendering state)

Slider:
  SliderState (position + velocity + key)
    └── GridCoord (row + col + direction)
          └── TriangleInfo (coord + color)
    └── Color (RGB + blending)
```
