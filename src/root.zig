// keep-sorted start
pub const Day = @import("day.zig").Day;
pub const day01 = @import("day01.zig");
pub const day02 = @import("day02.zig");
pub const utils = @import("utils.zig");
// keep-sorted end

test {
    @import("std").testing.refAllDecls(@This());
}
