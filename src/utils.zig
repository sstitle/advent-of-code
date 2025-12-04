const std = @import("std");

/// Builds a path to a day's input file using a stack buffer (no allocation).
pub fn getInputPathForDay(buf: []u8, day_number: u32) ![]const u8 {
    return std.fmt.bufPrint(buf, "data/day_{d}.txt", .{day_number});
}
