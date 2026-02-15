const pitch = @import("pitch.zig");
const key_signature = @import("key_signature.zig");

pub const KeyQuality = key_signature.KeyQuality;

pub const Key = struct {
    tonic: pitch.PitchClass,
    quality: KeyQuality,
    signature: key_signature.KeySignature,

    pub fn init(tonic: pitch.PitchClass, quality: KeyQuality) Key {
        return .{
            .tonic = tonic,
            .quality = quality,
            .signature = key_signature.fromTonic(tonic, quality),
        };
    }

    pub fn relativeMajor(self: Key) Key {
        return switch (self.quality) {
            .major => self,
            .minor => {
                const tonic = @as(u8, self.tonic);
                return Key.init(@as(pitch.PitchClass, @intCast((tonic + 3) % 12)), .major);
            },
        };
    }

    pub fn relativeMinor(self: Key) Key {
        return switch (self.quality) {
            .minor => self,
            .major => {
                const tonic = @as(u8, self.tonic);
                return Key.init(@as(pitch.PitchClass, @intCast((tonic + 9) % 12)), .minor);
            },
        };
    }

    pub fn parallelKey(self: Key) Key {
        return Key.init(self.tonic, switch (self.quality) {
            .major => .minor,
            .minor => .major,
        });
    }

    pub fn nextKeySharp(self: Key) Key {
        const tonic = @as(u8, self.tonic);
        return Key.init(@as(pitch.PitchClass, @intCast((tonic + 7) % 12)), self.quality);
    }

    pub fn nextKeyFlat(self: Key) Key {
        const tonic = @as(u8, self.tonic);
        return Key.init(@as(pitch.PitchClass, @intCast((tonic + 5) % 12)), self.quality);
    }
};
