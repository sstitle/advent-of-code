const std = @import("std");
const utils = @import("utils.zig");

const INITIAL_VALUE: u8 = 50;
const MODULO_VALUE: u32 = 100;

pub const State = struct {
    current_position: u8,
    count_of_zeroes: u32,
};

const Command = struct {
    direction: u8,
    amount: u32,
};

const ParseError = error{
    InvalidCommand,
    InvalidAmount,
    InvalidDirection,
};

fn parseCommand(command: []const u8) ParseError!Command {
    if (command.len < 2) return ParseError.InvalidCommand;
    const direction = command[0];
    if (direction != 'L' and direction != 'R') return ParseError.InvalidDirection;
    const amount = std.fmt.parseInt(u32, command[1..], 10) catch return ParseError.InvalidAmount;
    return .{
        .direction = direction,
        .amount = amount,
    };
}

fn computeNewPosition(current: u8, cmd: Command) u8 {
    const intermediate: i64 = switch (cmd.direction) {
        'L' => @as(i64, current) - cmd.amount,
        'R' => @as(i64, current) + cmd.amount,
        else => unreachable, // Direction validated in parseCommand
    };
    return @intCast(@mod(intermediate, MODULO_VALUE));
}

/// Part One reducer: counts only when we stop on 0 after a rotation.
pub fn reducePartOne(state: State, command: []const u8) !State {
    const cmd = try parseCommand(command);
    const new_position = computeNewPosition(state.current_position, cmd);
    const new_count = if (new_position == 0) state.count_of_zeroes + 1 else state.count_of_zeroes;
    return State{ .current_position = new_position, .count_of_zeroes = new_count };
}

/// Part Two reducer: counts every time the dial clicks to 0 during rotation.
pub fn reducePartTwo(state: State, command: []const u8) !State {
    const cmd = try parseCommand(command);
    const new_position = computeNewPosition(state.current_position, cmd);

    // Count how many times we click to 0 during this rotation
    const zero_crossings: u32 = switch (cmd.direction) {
        'R' => @intCast(@divFloor(state.current_position + cmd.amount, MODULO_VALUE)),
        'L' => blk: {
            const pos = state.current_position;
            if (pos == 0) {
                break :blk @intCast(@divFloor(cmd.amount, MODULO_VALUE));
            } else if (cmd.amount >= pos) {
                break :blk @intCast(@divFloor(cmd.amount - pos, MODULO_VALUE) + 1);
            } else {
                break :blk 0;
            }
        },
        else => unreachable, // Direction validated in parseCommand
    };

    return State{
        .current_position = new_position,
        .count_of_zeroes = zero_crossings + state.count_of_zeroes,
    };
}

fn runActions(actions: []const []const u8, reducer_func: *const fn (State, []const u8) anyerror!State) !State {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    var current_state = initial_state;

    for (actions) |action| {
        current_state = try reducer_func(current_state, action);
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
    return utils.readLinesForDay(allocator, 1);
}

pub fn solvePartOne(actions: []const []const u8) !u32 {
    const final_state = try runActions(actions, &reducePartOne);
    return final_state.count_of_zeroes;
}

pub fn solvePartTwo(actions: []const []const u8) !u32 {
    const final_state = try runActions(actions, &reducePartTwo);
    return final_state.count_of_zeroes;
}

// Tests
test "solve part one with input file" {
    const allocator = std.testing.allocator;
    const actions = try loadActions(allocator);
    defer utils.freeLines(allocator, actions);
    const result = try solvePartOne(actions);
    try std.testing.expectEqual(1052, result);
}

test "solve part one with example" {
    const actions = getExampleActions();
    const result = try solvePartOne(actions);
    try std.testing.expectEqual(3, result);
}

test "solve part two with example" {
    const actions = getExampleActions();
    const result = try solvePartTwo(actions);
    try std.testing.expectEqual(6, result);
}

test "solve part two with input file" {
    const allocator = std.testing.allocator;
    const actions = try loadActions(allocator);
    defer utils.freeLines(allocator, actions);
    const result = try solvePartTwo(actions);
    try std.testing.expectEqual(6295, result);
}

test "reducer works on simple commands" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    try std.testing.expectEqual(INITIAL_VALUE, initial_state.current_position);

    var current_state = initial_state;
    current_state = try reducePartOne(current_state, "L3");
    try std.testing.expectEqual(47, current_state.current_position);

    current_state = try reducePartOne(current_state, "R10");
    try std.testing.expectEqual(57, current_state.current_position);
}

test "handle wraparound" {
    const initial_state = State{ .count_of_zeroes = 0, .current_position = INITIAL_VALUE };
    try std.testing.expectEqual(INITIAL_VALUE, initial_state.current_position);

    var current_state = initial_state;
    current_state = try reducePartOne(current_state, "L50");
    try std.testing.expectEqual(0, current_state.current_position);

    current_state = try reducePartOne(current_state, "L1");
    try std.testing.expectEqual(99, current_state.current_position);
}

test "parseCommand returns error for invalid input" {
    try std.testing.expectError(ParseError.InvalidCommand, parseCommand(""));
    try std.testing.expectError(ParseError.InvalidCommand, parseCommand("L"));
    try std.testing.expectError(ParseError.InvalidDirection, parseCommand("X5"));
    try std.testing.expectError(ParseError.InvalidAmount, parseCommand("Labc"));
}
