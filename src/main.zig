const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const day03 = @import("day03.zig");
const day04 = @import("day04.zig");
const day05 = @import("day05.zig");
const day06 = @import("day06.zig");
const day07 = @import("day07.zig");

fn printHelp() void {
    std.debug.print(
        \\Advent of Code 2025 Solutions
        \\
        \\Usage: aoc [OPTIONS]
        \\
        \\Options:
        \\  --day <N>     Run solution for day N (required)
        \\  --day=<N>     Run solution for day N (alternative syntax)
        \\  --example     Use example input instead of full input
        \\  --help        Show this help message
        \\
        \\Examples:
        \\  aoc --day 1
        \\  aoc --day=2 --example
        \\
    , .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.next();

    var day: ?u32 = null;
    var use_example = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printHelp();
            return;
        } else if (std.mem.eql(u8, arg, "--example")) {
            use_example = true;
        } else if (std.mem.eql(u8, arg, "--day")) {
            if (args.next()) |day_arg| {
                day = std.fmt.parseInt(u32, day_arg, 10) catch {
                    std.debug.print("Invalid day number: {s}\n", .{day_arg});
                    return;
                };
            }
        } else if (std.mem.startsWith(u8, arg, "--day=")) {
            const day_str = arg[6..];
            day = std.fmt.parseInt(u32, day_str, 10) catch {
                std.debug.print("Invalid day number: {s}\n", .{day_str});
                return;
            };
        }
    }

    const selected_day = day orelse {
        std.debug.print("Error: --day is required. Use --help for usage.\n", .{});
        return;
    };

    std.debug.print("Running day {d}{s}\n", .{ selected_day, if (use_example) " (example)" else "" });

    switch (selected_day) {
        1 => try day01.day.run(allocator, use_example),
        2 => try day02.day.run(allocator, use_example),
        3 => try day03.day.run(allocator, use_example),
        4 => try day04.day.run(allocator, use_example),
        5 => try day05.day.run(allocator, use_example),
        6 => try day06.day.run(allocator, use_example),
        7 => try day07.day.run(allocator, use_example),
        else => std.debug.print("Day {d} not implemented yet\n", .{selected_day}),
    }
}
