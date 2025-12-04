const std = @import("std");
const day01 = @import("day01.zig");
const day02 = @import("day02.zig");

const allocator = std.heap.page_allocator;

pub fn main() !void {
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    // Skip program name
    _ = args.next();

    var day: ?u32 = null;
    var use_example = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--example")) {
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

    const selected_day = day orelse 1;

    std.debug.print("Running day {d}{s}\n", .{ selected_day, if (use_example) " (example)" else "" });

    switch (selected_day) {
        1 => try runDay01(use_example),
        2 => try runDay02(use_example),
        else => std.debug.print("Day {d} not implemented yet\n", .{selected_day}),
    }
}

fn runDay01(use_example: bool) !void {
    const actions = if (use_example)
        day01.getExampleActions()
    else
        try day01.loadActions(allocator);

    const part_one = day01.solvePartOne(actions);
    std.debug.print("Day One - Part One: {d}\n", .{part_one});

    const part_two = day01.solvePartTwo(actions);
    std.debug.print("Day One - Part Two: {d}\n", .{part_two});
}

fn runDay02(use_example: bool) !void {
    const result = day02.solve();
    std.debug.print("Use example: {any}\n", .{use_example});
    std.debug.print("Day Two: {any}\n", .{result});
}
