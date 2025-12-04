pub const day01 = @import("day01.zig");
pub const utils = @import("utils.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
