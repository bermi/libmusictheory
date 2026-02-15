pub const FormulaToken = enum {
    root,
    flat2,
    nat2,
    sharp2,
    flat3,
    nat3,
    sharp3,
    flat4,
    nat4,
    sharp4,
    flat5,
    nat5,
    sharp5,
    flat6,
    nat6,
    sharp6,
    flat7,
    nat7,
    sharp7,
    flat9,
    nat9,
    sharp9,
    flat11,
    nat11,
    sharp11,
    flat13,
    nat13,
    sharp13,
};

pub const BASE_INTERVALS = [14]i16{ -999, 0, 2, 4, 5, 7, 9, 11, -999, 14, -999, 17, -999, 21 };

pub const FORMULA_SEMITONES = buildFormulaSemitones();

pub fn semitones(token: FormulaToken) u8 {
    return FORMULA_SEMITONES[@intFromEnum(token)];
}

fn buildFormulaSemitones() [@typeInfo(FormulaToken).@"enum".fields.len]u8 {
    var values: [@typeInfo(FormulaToken).@"enum".fields.len]u8 = undefined;
    for (@typeInfo(FormulaToken).@"enum".fields) |field| {
        const token: FormulaToken = @enumFromInt(field.value);
        values[field.value] = switch (token) {
            .root => 0,
            .flat2 => 1,
            .nat2 => 2,
            .sharp2 => 3,
            .flat3 => 3,
            .nat3 => 4,
            .sharp3 => 5,
            .flat4 => 4,
            .nat4 => 5,
            .sharp4 => 6,
            .flat5 => 6,
            .nat5 => 7,
            .sharp5 => 8,
            .flat6 => 8,
            .nat6 => 9,
            .sharp6 => 10,
            .flat7 => 10,
            .nat7 => 11,
            .sharp7 => 12,
            .flat9 => 13,
            .nat9 => 14,
            .sharp9 => 15,
            .flat11 => 16,
            .nat11 => 17,
            .sharp11 => 18,
            .flat13 => 20,
            .nat13 => 21,
            .sharp13 => 22,
        };
    }
    return values;
}
