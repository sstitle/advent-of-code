const std = @import("std");
const utils = @import("utils.zig");

const INITIAL_VALUE: u8 = 50;
const MODULO_VALUE: u32 = 100;

pub const State = struct {
    current_position: u8,
    count_of_zeroes: u32,

    pub fn logState(state: State) void {
        std.debug.print("Current position: {d}, Count of zeroes: {d}\n", .{ state.current_position, state.count_of_zeroes });
    }
};

/// Part One reducer: counts only when we stop on 0 after a rotation.
pub fn reducePartOne(state: State, command: []const u8) State {
    if (command.len < 2) unreachable;

    const direction = command[0];
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch unreachable;
    const intermediate_position = switch (direction) {
        'L' => @as(i64, state.current_position) - amount,
        'R' => @as(i64, state.current_position) + amount,
        else => unreachable,
    };
    const new_position = @mod(intermediate_position, MODULO_VALUE);
    const new_count_of_zeroes = if (new_position == 0) state.count_of_zeroes + 1 else state.count_of_zeroes;
    return State{ .current_position = @intCast(new_position), .count_of_zeroes = new_count_of_zeroes };
}

/// Part Two reducer: counts every time the dial clicks to 0 during rotation.
pub fn reducePartTwo(state: State, command: []const u8) State {
    if (command.len < 2) unreachable;

    const direction = command[0];
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch unreachable;
    const intermediate_position = switch (direction) {
        'L' => @as(i64, state.current_position) - amount,
        'R' => @as(i64, state.current_position) + amount,
        else => unreachable,
    };
    const new_position = @mod(intermediate_position, MODULO_VALUE);

    // Count how many times we click to 0 during this rotation
    const zero_crossings: u32 = switch (direction) {
        'R' => @intCast(@divFloor(state.current_position + amount, MODULO_VALUE)),
        'L' => blk: {
            const pos = state.current_position;
            if (pos == 0) {
                break :blk @intCast(@divFloor(amount, MODULO_VALUE));
            } else if (amount >= pos) {
                break :blk @intCast(@divFloor(amount - pos, MODULO_VALUE) + 1);
            } else {
                break :blk 0;
            }
        },
        else => unreachable,
    };

    return State{
        .current_position = @intCast(new_position),
        .count_of_zeroes = state.count_of_zeroes + zero_crossings,
    };
}

fn runActions(actions: []const []const u8, reducer_func: fn (State, []const u8) State) State {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    var current_state = initial_state;

    for (actions) |action| {
        current_state = reducer_func(current_state, action);
    }

    return current_state;
}

pub fn getExampleActions() []const []const u8 {
    const EXAMPLE_ACTIONS = [_][]const u8{
        "L68",
        "L30",
        "R48",
        "L5",
        "R60",
        "L55",
        "L1",
        "L99",
        "R14",
        "L82",
    };
    return &EXAMPLE_ACTIONS;
}

pub fn loadActions(allocator: std.mem.Allocator) ![][]const u8 {
    return loadDayOneInput(allocator, 1);
}

pub fn solvePartOne(actions: []const []const u8) i64 {
    const final_state = runActions(actions, reducePartOne);
    return @intCast(final_state.count_of_zeroes);
}

pub fn solvePartTwo(actions: []const []const u8) i64 {
    const final_state = runActions(actions, reducePartTwo);
    return @intCast(final_state.count_of_zeroes);
}

/// Reads lines from a file and returns them as a slice of strings.
/// Caller is responsible for freeing the returned slice.
pub fn readLinesFromFile(allocator: std.mem.Allocator, file_path: []const u8) ![][]const u8 {
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();

    var actions: std.ArrayList([]const u8) = .empty;
    errdefer actions.deinit(allocator);

    var read_buf: [4096]u8 = undefined;
    var file_reader = file.reader(&read_buf);
    const reader = &file_reader.interface;

    var line_writer = std.Io.Writer.Allocating.init(allocator);
    defer line_writer.deinit();

    while (true) {
        _ = reader.streamDelimiter(&line_writer.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the newline delimiter

        const line_str = try line_writer.toOwnedSlice();
        if (line_str.len == 0) {
            allocator.free(line_str);
            break;
        }

        try actions.append(allocator, line_str);
    }

    return actions.toOwnedSlice(allocator);
}

pub fn loadDayOneInput(allocator: std.mem.Allocator, day_number: u32) ![][]const u8 {
    var path_buf: [64]u8 = undefined;
    const day_path = try utils.getInputPathForDay(&path_buf, day_number);
    return readLinesFromFile(allocator, day_path);
}

// Tests
test "solve part one with input file" {
    const allocator = std.testing.allocator;
    const actions = try loadActions(allocator);
    defer {
        for (actions) |action| {
            allocator.free(action);
        }
        allocator.free(actions);
    }
    const result = solvePartOne(actions);
    try std.testing.expectEqual(@as(i64, 1052), result);
}

test "solve part one with example" {
    const actions = getExampleActions();
    const result = solvePartOne(actions);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "solve part two with example" {
    const actions = getExampleActions();
    const result = solvePartTwo(actions);
    try std.testing.expectEqual(@as(i64, 6), result);
}

test "reducer works on simple commands" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    try std.testing.expectEqual(@as(u8, INITIAL_VALUE), initial_state.current_position);

    var current_state = initial_state;
    current_state = reducePartOne(current_state, "L3");
    try std.testing.expectEqual(@as(u8, 47), current_state.current_position);

    current_state = reducePartOne(current_state, "R10");
    try std.testing.expectEqual(@as(u8, 57), current_state.current_position);
}

test "handle wraparound" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    try std.testing.expectEqual(@as(u8, INITIAL_VALUE), initial_state.current_position);

    var current_state = initial_state;
    current_state = reducePartOne(current_state, "L50");
    try std.testing.expectEqual(@as(u8, 0), current_state.current_position);

    current_state = reducePartOne(current_state, "L1");
    try std.testing.expectEqual(@as(u8, 99), current_state.current_position);
}
