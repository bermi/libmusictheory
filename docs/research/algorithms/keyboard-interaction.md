# Keyboard Interaction and MIDI Mapping

> References: [Guitar and Keyboard](../guitar-and-keyboard.md)
> Source: `tmp/harmoniousapp.net/js-client/kb.js`, `tmp/harmoniousapp.net/js-client/pitch-class-sets.js`
> Source: `tmp/harmoniousapp.net/p/f2/Chords-for-Keyboard.html`

## Overview

Algorithms for the interactive piano keyboard: key toggling, selection state management, note highlighting with octave equivalence, and URL state persistence.

## Static Data

### Keyboard Layout

```
KEYBOARD_RANGE = (36, 83)  // MIDI C2 to B5, 4 octaves
NUM_KEYS = 48
MIDDLE_C = 60

// One-octave key pattern
// '_' = white key position, ':' = black key position
KEY_PATTERN = "_:_:__:_:_:_"  // C C# D D# E F F# G G# A A# B
WHITE_KEY_PCS = [0, 2, 4, 5, 7, 9, 11]  // C D E F G A B
BLACK_KEY_PCS = [1, 3, 6, 8, 10]  // C# D# F# G# A#
```

## Algorithms

### 1. Toggle Key Selection

**Input**: MIDI note number, current selection set
**Output**: Updated selection set

```
toggle_key(midi_note, selected):
    if midi_note in selected:
        selected.remove(midi_note)
    else:
        selected.add(midi_note)
    return selected
```

### 2. Update Key Visual State

**Input**: Set of selected MIDI notes, accidental preference
**Output**: Visual state for each key (opacity, label)

```
FULL_OPACITY = 1.0
HALF_OPACITY = 0.5  // octave equivalents
NORMAL_OPACITY = 0.0  // unselected

update_key_visuals(selected_notes, accid_pref):
    selected_pcs = {midi % 12 for midi in selected_notes}
    visuals = []
    for midi in KEYBOARD_RANGE[0]..KEYBOARD_RANGE[1]:
        pc = midi % 12
        if midi in selected_notes:
            visuals.append({
                midi: midi,
                opacity: FULL_OPACITY,
                label: spell_with_preference(pc, accid_pref),
            })
        elif pc in selected_pcs:
            visuals.append({
                midi: midi,
                opacity: HALF_OPACITY,
                label: spell_with_preference(pc, accid_pref),
            })
        else:
            visuals.append({
                midi: midi,
                opacity: NORMAL_OPACITY,
                label: null,
            })
    return visuals
```

### 3. MIDI Notes to URL State

**Input**: Set of selected MIDI notes
**Output**: URL-encoded string

```
notes_to_url(selected_notes):
    // Sort ascending
    sorted_notes = sorted(selected_notes)
    // Format as spelled names with octave
    names = [midi_to_name(n) for n in sorted_notes]
    return "-".join(names)

// Example: {60, 64, 67} → "C4-E4-G4"
```

### 4. URL State to MIDI Notes

**Input**: URL-encoded string
**Output**: Set of MIDI notes

```
url_to_notes(url_str):
    notes = set()
    for name in url_str.split("-"):
        midi = name_to_midi(name)
        notes.add(midi)
    return notes
```

### 5. Playback Style Detection

**Input**: Set of MIDI notes
**Output**: Playback mode ("solo" | "sequential" | "simultaneous")

```
playback_style(selected_notes, pcs):
    if len(selected_notes) == 1:
        return "solo"
    if is_scaley(pcs):
        return "sequential"  // play notes one at a time, ascending
    return "simultaneous"  // play all at once as chord
```

### 6. Pitch Class Set from Keyboard Selection

**Input**: Set of selected MIDI notes
**Output**: 12-bit PCS (octave-collapsed)

```
selection_to_pcs(selected_notes):
    result = 0
    for midi in selected_notes:
        result |= (1 << (midi % 12))
    return result
```

### 7. Sustain-Aware Sounding State

For live browser MIDI input the displayed sounding state is not just the currently depressed keys. Sustain pedal (`CC64`) keeps released notes sounding until the pedal comes back up.

```
state = {
    held: set(),        // notes physically down
    sustained: set(),   // released while CC64 is down
    sustain_down: false,
}

note_on(midi):
    held.add(midi)
    sustained.remove(midi)

note_off(midi):
    held.remove(midi)
    if sustain_down:
        sustained.add(midi)
    else:
        sustained.remove(midi)

cc64(value):
    if value >= 64:
        sustain_down = true
    else:
        sustain_down = false
        sustained = sustained ∩ held

sounding_notes():
    return held ∪ sustained
```

### 8. Middle Pedal Snapshot Capture

The interactive gallery uses middle pedal / sostenuto (`CC66`) as a composer snapshot command rather than as a playback-state modifier. On the rising edge of the pedal, save the current sounding notes together with the currently selected tonic/mode context so the UI can restore the same interpretation later.

```
cc66(value):
    if value >= 64 and not sostenuto_down:
        save_snapshot(
            notes = sounding_notes(),
            tonic = selected_tonic,
            mode = selected_mode,
        )
        sostenuto_down = true
    elif value < 64:
        sostenuto_down = false
```

### 9. Compatible Next-Step Suggestions

Given the current sounding PCS and an explicit selected tonic/mode, rank single pitch-class additions by:

- whether the added tone stays inside the selected context orbit
- how much overlap with the selected context increases or decreases
- how many tones in the expanded set fall outside the selected context
- whether the result remains cluster-free
- whether the expanded set reads as a named chord
- evenness distance
- step distance from the last played tone
- root distance from the selected tonic

This ranking now lives in the experimental library helper `lmt_rank_context_suggestions`. The gallery no longer scores candidate additions in JS. It asks the library for the ranked rows, then only formats the returned facts into user-facing copy. The user-facing result is intentionally deterministic: if the tonic/mode changes, spelling, summary text, suggestion ordering, and snapshot recall all change with it.

### 9.1. Mode Spelling Quality

The live gallery also no longer infers “major-like vs minor-like” mode spelling in JS. It uses the experimental helper `lmt_mode_spelling_quality`, which classifies the selected tonic/mode lens by checking whether the active mode orbit contains a minor third without a major third above the tonic. This keeps note spelling policy aligned between the browser gallery and any other host using the same live-context surface.

### 10. Compact Guitar Preview Selection

The live MIDI scene also shows compact `EADGBE` previews for the current sounding set and for ranked next-step suggestions. The gallery no longer generates every candidate voicing in JS and scores them there. It calls the experimental library helper `lmt_preferred_voicing_n`, which:

- generates the playable candidate rows for the requested PCS and tuning
- scores the rows inside Zig with the deterministic compact-voicing heuristic from `guitar-voicing.md`
- writes only the chosen voicing back to the caller

This keeps the preview policy consistent across the browser gallery and any future embedded host that needs the same “best compact fretboard” suggestion without running JS.

### 11. Explainable Keyboard Playability Assessment

The keyboard playability layer is intentionally local and explainable. It does not expose opaque HMM state ids or claim to solve full polyphonic piano fingering globally. Instead it turns the strongest paper-backed local facts into explicit assessment rows:

- reachable versus blocked one-hand shapes
- comfortable versus hard span limits
- thumb on black key under stretch
- awkward thumb crossing
- repeated weak adjacent-finger sequences
- fluency degradation from recent motion

This matches the direction of the piano fingering literature without pretending to reproduce an entire merged-output HMM or Variable Neighborhood Search solver at the ABI boundary. The public helpers answer questions that an app or LLM can explain directly:

- `lmt_assess_keyboard_realization_n`
- `lmt_assess_keyboard_transition_n`
- `lmt_rank_keyboard_fingerings_n`

The implementation uses a bounded local ranking model:

- static one-hand note groups are sorted and matched against monotonic finger assignments
- the ranking compares keyboard-distance gaps to finger-gap distribution so wide note gaps prefer wider finger coverage while compact clusters prefer compact assignments
- monophonic transitions check whether the chosen finger order follows the natural hand direction or requires a thumb crossing
- recent motion is carried through the temporal load state so repeated large shifts can trigger a fluency warning instead of being judged in isolation

This is the same product stance described in the cited piano papers:

### 12. Gallery Phrase Blackboard Boundary

The live gallery now separates preview state from committed musical memory.

- `Pin for preview`
  - host-only UI state
  - keeps a candidate visible for inspection
  - does not mutate library memory
  - must not bias later ranking
- `Commit to phrase`
  - appends a realized event into caller-owned library memory
  - does affect later phrase audits and committed-phrase ranking helpers
  - is the action a host should use when a user accepts a voicing as part of the phrase

This boundary matters because the library is meant to answer musical questions, not to absorb browser state. Hover, pin, local persistence, MIDI permissions, and other transient controls remain host-owned. Accepted musical choices that should influence later analysis belong in explicit caller-owned structs such as `lmt_keyboard_committed_phrase_memory`.

### 13. No-MIDI Fallback And Virtual Keyboard Input

The gallery is no longer blocked on hardware MIDI. When Web MIDI is unavailable or when no device inputs are connected, the host presents a `virtual keyboard` that toggles notes into the same current-input path used by live MIDI events.

That fallback intentionally preserves the same semantic split:

- toggling notes on the virtual keyboard changes the current displayed input state
- it does not automatically commit anything into phrase memory
- phrase bias only begins after the host explicitly chooses `Commit to phrase`

This keeps the no-hardware path explainable:

- "No MIDI device is connected, so the virtual keyboard is driving the current input state."
- "This move is pinned for preview only."
- "This move was committed to phrase memory, so later suggestions are now judged relative to it."

- HMM and Viterbi models are useful internally, but public results still need named reasons rather than hidden state numbers
- Variable Neighborhood Search highlights that vertical span, thumb use on black keys, and weak-finger stress are meaningful local constraints
- Checklist Models emphasize recent-context fluency, which is why the temporal load state remains part of the playability surface

In practice, `libmusictheory` should be able to say:

- "This right-hand chord exceeds the configured comfortable span."
- "This fingering keeps the thumb off the black key in the stretched version of the shape."
- "This move is theoretically valid, but it keeps adding large shifts to an already strained recent history."

## Data Structures Used

- `KeyboardState`: struct { selected_notes: bounded set of MIDI notes, accid_pref: AccidentalPreference }
- `KeyVisual`: struct { midi: u8, opacity: f32, label: ?NoteName }

## Dependencies

- [Note Spelling](note-spelling.md)
- [Scale, Mode, and Key](scale-mode-key.md) (for `is_scaley`)
