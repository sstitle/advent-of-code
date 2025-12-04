const std = @import("std");

/// Generic Day abstraction for Advent of Code solutions.
/// Each day implements this interface by providing input type and solver functions.
pub fn Day(comptime Input: type, comptime Output: type) type {
    return struct {
        load: *const fn (std.mem.Allocator) anyerror![]Input,
        getExample: *const fn () []const Input,
        solvers: []const Solver,

        const Self = @This();

        pub const Solver = struct {
            name: []const u8,
            func: *const fn ([]const Input) anyerror!Output,
        };

        pub fn run(self: Self, allocator: std.mem.Allocator, use_example: bool) !void {
            var arena = std.heap.ArenaAllocator.init(allocator);
            defer arena.deinit();
            const alloc = arena.allocator();

            const input: []const Input = if (use_example)
                self.getExample()
            else
                try self.load(alloc);

            for (self.solvers) |solver| {
                const result = try solver.func(input);
                std.debug.print("{s}: {d}\n", .{ solver.name, result });
            }
        }
    };
}
