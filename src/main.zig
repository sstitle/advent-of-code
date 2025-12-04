const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");
const utils = @import("utils.zig");

const allocator = std.heap.page_allocator;

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
        1 => try runDay01(use_example),
        2 => try runDay02(use_example),
        else => std.debug.print("Day {d} not implemented yet\n", .{selected_day}),
    }
}

fn runDay01(use_example: bool) !void {
    var owned_actions: ?[][]const u8 = null;
    defer if (owned_actions) |actions| utils.freeLines(allocator, actions);

    const actions: []const []const u8 = if (use_example)
        day01.getExampleActions()
    else blk: {
        owned_actions = try day01.loadActions(allocator);
        break :blk owned_actions.?;
    };

    const part_one = try day01.solvePartOne(actions);
    std.debug.print("Day One - Part One: {d}\n", .{part_one});

    const part_two = try day01.solvePartTwo(actions);
    std.debug.print("Day One - Part Two: {d}\n", .{part_two});
}

fn runDay02(use_example: bool) !void {
    var owned_pairs: ?std.ArrayList(day02.Pair) = null;
    defer if (owned_pairs) |*list| list.deinit(allocator);

    const pairs: []const day02.Pair = if (use_example)
        day02.getExamplePairs()
    else blk: {
        owned_pairs = try day02.loadPairs(allocator);
        break :blk owned_pairs.?.items;
    };

    const result = try day02.solve(allocator, pairs);
    std.debug.print("Day Two: {d}\n", .{result});
}
