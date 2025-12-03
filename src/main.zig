const std = @import("std");
const advent_of_code = @import("advent_of_code");

// The Day 1 Advent of Code challeng involves a dial with numbers from 0 to 99.
// It starts at 50 and we read in the input file with entries of L or R followed by a number to turn.
// We're going to make a state reducer that will handle input commands and count the number of times we stop
// on 0 after a rotation.
const INITIAL_VALUE = 50;
const MODULO_VALUE = 100;

const State = struct {
    current_position: u8,
    count_of_zeroes: u32,

    pub fn logState(state: State) void {
        std.debug.print("Current position: {d}, Count of zeroes: {d}\n", .{ state.current_position, state.count_of_zeroes });
    }
};

pub fn reduce(state: State, command: []const u8) State {
    std.debug.print("Reducing state with command: {s}\n", .{command});
    // Validate input
    if (command.len < 2) unreachable;

    const direction = command[0];
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch unreachable;
    std.debug.print("Direction: {c}, Amount: {d}\n", .{ direction, amount });
    const new_position = switch (direction) {
        // Take the new position with modulo without overflow
        'L' => @mod(@as(i64, state.current_position) - amount, MODULO_VALUE),
        'R' => @mod(@as(i64, state.current_position) + amount, MODULO_VALUE),
        else => unreachable,
    };
    const new_count_of_zeroes = if (new_position == 0) state.count_of_zeroes + 1 else state.count_of_zeroes;
    return State{ .current_position = @intCast(new_position), .count_of_zeroes = new_count_of_zeroes };
}

pub fn main() !void {
    std.debug.print("Start of main\n", .{});
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const current_dir = std.fs.cwd();
    const cwd_path = try current_dir.realpathAlloc(alloc, ".");
    std.debug.print("Current path: {s}\n", .{cwd_path});

    const data_dir = try std.fs.path.join(alloc, &[_][]const u8{ cwd_path, "data" });
    const day_number = 1;
    // Find path like "data/day_1.txt"
    const day_path_string = try std.fmt.allocPrint(alloc, "day_{d}.txt", .{day_number});
    std.debug.print("Day path string: {s}\n", .{day_path_string});

    const day_path = try std.fs.path.join(alloc, &[_][]const u8{ data_dir, day_path_string });
    std.debug.print("Day path: {s}\n", .{day_path});

    std.debug.print("Initializing state\n", .{});
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    std.debug.print("Starting state:\n", .{});
    initial_state.logState();
    var current_state = initial_state;

    // We can read the file one line at a time and apply the reducer for each line
    var file = try std.fs.openFileAbsolute(day_path, .{ .mode = .read_only });
    defer file.close();

    // Accumulating writer to store each line
    var line = std.Io.Writer.Allocating.init(alloc);
    defer line.deinit();
    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);

    // Get pointer to the Reader interface (don't copy it!)
    const reader = &file_reader.interface;
    // Read line by line
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the newline delimiter

        std.debug.print("{s}\n", .{line.written()});

        std.debug.print("Applying command: '{s}'\n", .{line.written()});
        current_state = reduce(current_state, line.written());

        std.debug.print("Current state:\n", .{});
        current_state.logState();

        std.debug.print("\n", .{});
        line.clearRetainingCapacity();
    }

    std.debug.print("Final state:\n", .{});
    current_state.logState();

    std.debug.print("\n", .{});
    try advent_of_code.bufferedPrint();
}

test "verify state reducer works on simple commands" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    try std.testing.expectEqual(@as(i32, 50), initial_state.current_position);

    var current_state = initial_state;
    current_state = reduce(current_state, "L3");
    try std.testing.expectEqual(@as(i32, 47), current_state.current_position);

    current_state = reduce(current_state, "R10");
    try std.testing.expectEqual(@as(i32, 57), current_state.current_position);
}

test "verify that we handle wraparound" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    try std.testing.expectEqual(@as(i32, 50), initial_state.current_position);

    var current_state = initial_state;
    current_state = reduce(current_state, "L50");
    try std.testing.expectEqual(@as(i32, 0), current_state.current_position);

    current_state = reduce(current_state, "L1");
    try std.testing.expectEqual(@as(i32, 99), current_state.current_position);
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
