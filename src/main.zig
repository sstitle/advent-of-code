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

// The first challenge requires a reducer that counts only when we stop on 0 after a rotation.
pub fn reducePartOne(state: State, command: []const u8) State {
    std.debug.print("Reducing state with command: {s}\n", .{command});
    if (command.len < 2) unreachable;

    const direction = command[0];
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch unreachable;
    const intermediate_position = switch (direction) {
        // Take the new position with modulo without overflow
        'L' => @as(i64, state.current_position) - amount,
        'R' => @as(i64, state.current_position) + amount,
        else => unreachable,
    };
    const new_position = @mod(intermediate_position, MODULO_VALUE);
    const new_count_of_zeroes = if (new_position == 0) state.count_of_zeroes + 1 else state.count_of_zeroes;
    return State{ .current_position = @intCast(new_position), .count_of_zeroes = new_count_of_zeroes };
}

pub fn reducePartTwo(state: State, command: []const u8) State {
    std.debug.print("Reducing state with command: {s}\n", .{command});
    if (command.len < 2) unreachable;

    const direction = command[0];
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch unreachable;
    const intermediate_position = switch (direction) {
        // Take the new position with modulo without overflow
        'L' => @as(i64, state.current_position) - amount,
        'R' => @as(i64, state.current_position) + amount,
        else => unreachable,
    };
    const new_position = @mod(intermediate_position, MODULO_VALUE);
    const new_count_of_zeroes = if (new_position == 0) state.count_of_zeroes + 1 else state.count_of_zeroes;
    return State{ .current_position = @intCast(new_position), .count_of_zeroes = new_count_of_zeroes };
}

pub fn getInputPathForDay(buf: []u8, day_number: u32) ![]const u8 {
    return std.fmt.bufPrint(buf, "data/day_{d}.txt", .{day_number});
}

pub fn runActions(actions: []const []const u8, reducer_func: fn (State, []const u8) State) State {
    std.debug.print("Initializing state\n", .{});
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    std.debug.print("Starting state:\n", .{});
    initial_state.logState();
    var current_state = initial_state;

    for (actions) |action| {
        std.debug.print("Applying command: '{s}'\n", .{action});
        current_state = reducer_func(current_state, action);
        current_state.logState();
        std.debug.print("\n", .{});
    }

    return current_state;
}

pub fn readActionsFromFile(file_path: []const u8) ![][]const u8 {
    const allocator = std.heap.page_allocator;
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

pub fn getExampleActions() ![]const []const u8 {
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

pub fn loadDayOneActions() ![]const []const u8 {
    const day_number = 1;
    var path_buf: [64]u8 = undefined;
    const day_path = try getInputPathForDay(&path_buf, day_number);
    const actions = try readActionsFromFile(day_path);
    return actions;
}

pub fn solveDayOnePartOne(actions: []const []const u8) !i64 {
    const final_state = runActions(actions, reducePartOne);
    std.debug.print("Final state:\n", .{});
    final_state.logState();
    return @intCast(final_state.count_of_zeroes);
}

pub fn solveDayOnePartTwo(actions: []const []const u8) !i64 {
    const final_state = runActions(actions, reducePartTwo);
    std.debug.print("Final state:\n", .{});
    final_state.logState();
    return @intCast(final_state.count_of_zeroes);
}

pub fn main() !void {
    std.debug.print("Start of main with CLI arguments: {s}\n", .{std.os.argv[0]});
    var args = try std.process.argsWithAllocator(std.heap.page_allocator);
    defer args.deinit();

    var use_example = false;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--example")) {
            use_example = true;
        }
    }
    std.debug.print("Using example: {}\n", .{use_example});

    var actions: []const []const u8 = &[_][]const u8{};
    if (use_example) {
        actions = try getExampleActions();
    } else {
        actions = try loadDayOneActions();
    }
    const day_one_solution = try solveDayOnePartOne(actions);
    std.debug.print("Day One Solution: {}\n", .{day_one_solution});
}

test "verify that we can still solve day one part one with data from input file" {
    const actions = try loadDayOneActions();
    const result = try solveDayOnePartOne(actions);
    try std.testing.expectEqual(@as(i64, 1052), result);
}

test "verify that we can still solve day one part one with the simple example" {
    const actions = try getExampleActions();
    const result = try solveDayOnePartOne(actions);
    try std.testing.expectEqual(@as(i64, 3), result);
}

test "verify that we can still solve day one part twowith the simple example" {
    const actions = try getExampleActions();
    const result = try solveDayOnePartTwo(actions);
    try std.testing.expectEqual(@as(i64, 6), result);
}

test "verify state reducer works on simple commands" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    try std.testing.expectEqual(@as(i32, 50), initial_state.current_position);

    var current_state = initial_state;
    current_state = reducePartOne(current_state, "L3");
    try std.testing.expectEqual(@as(i32, 47), current_state.current_position);

    current_state = reducePartOne(current_state, "R10");
    try std.testing.expectEqual(@as(i32, 57), current_state.current_position);
}

test "verify that we handle wraparound" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = 50 };
    try std.testing.expectEqual(@as(i32, 50), initial_state.current_position);

    var current_state = initial_state;
    current_state = reducePartOne(current_state, "L50");
    try std.testing.expectEqual(@as(i32, 0), current_state.current_position);

    current_state = reducePartOne(current_state, "L1");
    try std.testing.expectEqual(@as(i32, 99), current_state.current_position);
}
