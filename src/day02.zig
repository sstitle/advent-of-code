const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const Pair = struct { u64, u64 };

pub const day = Day(Pair, u64){
    .load = &loadPairs,
    .getExample = &getExamplePairs,
    .solvers = &.{ .{ .name = "Part One", .func = &solvePartOne }, .{ .name = "Part Two", .func = &solvePartTwo } },
};

const ParseError = error{
    MalformedPair,
    MissingValue,
};

/// Reads pairs from a comma-separated file in format "a-b,c-d,...".
/// Caller is responsible for freeing the returned slice.
pub fn readPairsFromFile(allocator: std.mem.Allocator, file_path: []const u8) ![]Pair {
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = .read_only });
    defer file.close();
    const content = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(content);

    const input = std.mem.trim(u8, content, &std.ascii.whitespace);

    var pairs: std.ArrayList(Pair) = .empty;
    errdefer pairs.deinit(allocator);

    var pair_iter = std.mem.splitSequence(u8, input, ",");
    while (pair_iter.next()) |pair_str| {
        var num_iter = std.mem.splitSequence(u8, pair_str, "-");

        const a_str = num_iter.next() orelse return ParseError.MalformedPair;
        const b_str = num_iter.next() orelse return ParseError.MissingValue;

        const a = try std.fmt.parseInt(u64, a_str, 10);
        const b = try std.fmt.parseInt(u64, b_str, 10);

        try pairs.append(allocator, Pair{ a, b });
    }
    return pairs.toOwnedSlice(allocator);
}

pub fn loadPairs(allocator: std.mem.Allocator) ![]Pair {
    var path_buf: [64]u8 = undefined;
    const day_path = try utils.getInputPathForDay(&path_buf, 2);
    return readPairsFromFile(allocator, day_path);
}

pub fn getExamplePairs() []const Pair {
    const example = [_]Pair{
        .{ 11, 22 },
        .{ 95, 115 },
        .{ 998, 1012 },
        .{ 1188511880, 1188511890 },
        .{ 222220, 222224 },
        .{ 1698522, 1698528 },
        .{ 446443, 446449 },
        .{ 38593856, 38593862 },
        .{ 565653, 565659 },
        .{ 824824821, 824824827 },
        .{ 2121212118, 2121212124 },
    };
    return &example;
}

/// Sum "mirror" numbers in range where first half equals second half.
/// For 2n digits, the number is x * (10^n + 1) where x has n digits.
/// Uses arithmetic series formula to avoid iteration: sum = n * (first + last) / 2
fn sumMirrorNumbersInRange(min_id: u64, max_id: u64) error{InvalidRange}!u64 {
    if (max_id < min_id) {
        return error.InvalidRange;
    }

    var total: u64 = 0;

    // Try each even digit length: 2, 4, 6, 8, ... up to 20 digits (u64 max is ~1.8e19)
    var half_digits: u6 = 1;
    while (half_digits <= 10) : (half_digits += 1) {
        const multiplier = std.math.pow(u64, 10, half_digits) + 1;
        const min_half = std.math.pow(u64, 10, half_digits - 1); // e.g., 10 for 2 half-digits
        const max_half = std.math.pow(u64, 10, half_digits) - 1; // e.g., 99 for 2 half-digits

        // Find the range of x values that produce numbers in [min_id, max_id]
        const start_x = @max(min_half, (min_id + multiplier - 1) / multiplier); // ceil division
        const end_x = @min(max_half, max_id / multiplier);

        if (start_x > end_x) continue;

        // Sum of arithmetic series: count * (first + last) / 2
        // where first = start_x * multiplier, last = end_x * multiplier
        const count = end_x - start_x + 1;
        const first_val = start_x * multiplier;
        const last_val = end_x * multiplier;
        total += count * (first_val + last_val) / 2;
    }

    return total;
}

pub fn solvePartOne(pairs: []const Pair) !u64 {
    var acc: u64 = 0;
    for (pairs) |pair| {
        acc += try sumMirrorNumbersInRange(pair[0], pair[1]);
    }
    return acc;
}

/// Result of DP: count and sum of repdigits
const DpResult = struct {
    count: u64,
    sum: u64,

    fn add(self: DpResult, other: DpResult) DpResult {
        return .{ .count = self.count + other.count, .sum = self.sum + other.sum };
    }

    fn zero() DpResult {
        return .{ .count = 0, .sum = 0 };
    }
};

/// Digit DP for summing repdigits (numbers with repeating digit patterns).
/// A repdigit has a base pattern that repeats at least twice: 77, 123123, 5555, etc.
const RepdigitCounter = struct {
    /// The digits of the upper bound, most significant first
    limit_digits: [20]u8,
    limit_len: u8,

    const Self = @This();

    fn init(limit: u64) Self {
        var self = Self{
            .limit_digits = undefined,
            .limit_len = 0,
        };

        // Extract digits from limit (most significant first)
        var n = limit;
        var temp: [20]u8 = undefined;
        var len: u8 = 0;

        if (n == 0) {
            self.limit_digits[0] = 0;
            self.limit_len = 1;
            return self;
        }

        while (n > 0) : (len += 1) {
            temp[len] = @intCast(n % 10);
            n /= 10;
        }

        // Reverse to get most significant first
        for (0..len) |i| {
            self.limit_digits[i] = temp[len - 1 - i];
        }
        self.limit_len = len;

        return self;
    }

    /// Sum repdigits with a PRIMITIVE pattern length (pattern doesn't repeat internally)
    /// This avoids double-counting: 222222 is only counted for pattern_len=1, not 2 or 3
    fn sumWithPrimitivePatternLen(self: *const Self, pattern_len: u8) DpResult {
        const min_total_digits = pattern_len * 2;
        if (self.limit_len < min_total_digits) return DpResult.zero();

        var total = DpResult.zero();

        var total_digits: u8 = min_total_digits;
        while (total_digits <= self.limit_len) : (total_digits += pattern_len) {
            total = total.add(self.sumExactLengthPrimitive(pattern_len, total_digits));
        }

        return total;
    }

    /// Sum repdigits with exact length where the pattern is primitive
    fn sumExactLengthPrimitive(self: *const Self, pattern_len: u8, total_digits: u8) DpResult {
        if (total_digits < self.limit_len) {
            return sumAllPrimitiveRepdigits(pattern_len, total_digits);
        }
        if (total_digits > self.limit_len) {
            return DpResult.zero();
        }

        // total_digits == limit_len: use DP with primitive check
        var pattern: [10]u8 = undefined;
        return self.dpPrimitive(0, pattern_len, total_digits, &pattern, true, 0);
    }

    /// Sum all primitive repdigits with given pattern_len and total_digits (no upper bound)
    fn sumAllPrimitiveRepdigits(pattern_len: u8, total_digits: u8) DpResult {
        // A repdigit with pattern P repeated r times equals P * multiplier
        // where multiplier = 1 + 10^k + 10^(2k) + ... + 10^((r-1)*k) = (10^(r*k) - 1) / (10^k - 1)
        const reps = total_digits / pattern_len;
        const k: u64 = pattern_len;

        // multiplier = (10^(total_digits) - 1) / (10^k - 1)
        const pow_total = std.math.pow(u64, 10, total_digits);
        const pow_k = std.math.pow(u64, 10, k);
        const multiplier = (pow_total - 1) / (pow_k - 1);

        // Sum of primitive patterns of length k, times multiplier
        // We need to compute sum of all primitive k-digit patterns
        const pattern_sum_result = sumPrimitivePatterns(pattern_len);

        _ = reps;

        return .{
            .count = pattern_sum_result.count,
            .sum = pattern_sum_result.sum * multiplier,
        };
    }

    /// Sum of all primitive patterns of given length (the pattern values themselves)
    fn sumPrimitivePatterns(pattern_len: u8) DpResult {
        if (pattern_len == 1) {
            // Primitive single digits: 1-9, sum = 45
            return .{ .count = 9, .sum = 45 };
        }

        // Sum of all k-digit numbers (no leading zeros): 10..99, 100..999, etc.
        // = sum from 10^(k-1) to 10^k - 1
        // = (10^k - 1 + 10^(k-1)) * (10^k - 10^(k-1)) / 2
        const pow_k = std.math.pow(u64, 10, pattern_len);
        const pow_k_minus_1 = std.math.pow(u64, 10, pattern_len - 1);
        const count_all = pow_k - pow_k_minus_1;
        const sum_all = (pow_k - 1 + pow_k_minus_1) * count_all / 2;

        // Subtract non-primitive patterns (those with internal repetition)
        var non_primitive = DpResult.zero();
        for (1..pattern_len) |d| {
            if (pattern_len % d == 0) {
                // Patterns of length pattern_len that are repetitions of length-d patterns
                const sub = sumPrimitivePatterns(@intCast(d));
                // Each primitive d-digit pattern P creates a pattern_len pattern by repetition
                // Value = P * (10^(pattern_len - d) + 10^(pattern_len - 2d) + ... + 1)
                const reps = pattern_len / @as(u8, @intCast(d));
                var pattern_multiplier: u64 = 0;
                for (0..reps) |r| {
                    pattern_multiplier += std.math.pow(u64, 10, @as(u64, @intCast(d)) * r);
                }
                non_primitive = non_primitive.add(.{
                    .count = sub.count,
                    .sum = sub.sum * pattern_multiplier,
                });
            }
        }

        return .{
            .count = count_all - non_primitive.count,
            .sum = sum_all - non_primitive.sum,
        };
    }

    /// DP that sums repdigits where the pattern is primitive
    /// prefix_value: the numeric value of digits placed so far
    fn dpPrimitive(
        self: *const Self,
        pos: u8,
        pattern_len: u8,
        total_digits: u8,
        pattern: *[10]u8,
        tight: bool,
        prefix_value: u64,
    ) DpResult {
        if (pos == total_digits) {
            // Check if pattern is primitive (doesn't have shorter repeating structure)
            if (isPatternPrimitive(pattern, pattern_len)) {
                return .{ .count = 1, .sum = prefix_value };
            }
            return DpResult.zero();
        }

        const pattern_pos = pos % pattern_len;
        const in_first_pattern = pos < pattern_len;

        const max_digit: u8 = if (tight) self.limit_digits[pos] else 9;
        const min_digit: u8 = if (pos == 0) 1 else 0;

        var result = DpResult.zero();

        if (in_first_pattern) {
            for (min_digit..max_digit + 1) |d_usize| {
                const d: u8 = @intCast(d_usize);
                pattern[pattern_pos] = d;
                const new_prefix = prefix_value * 10 + d;
                result = result.add(self.dpPrimitive(
                    pos + 1,
                    pattern_len,
                    total_digits,
                    pattern,
                    tight and (d == self.limit_digits[pos]),
                    new_prefix,
                ));
            }
        } else {
            const expected = pattern[pattern_pos];

            if (tight) {
                if (expected <= self.limit_digits[pos]) {
                    const new_prefix = prefix_value * 10 + expected;
                    result = result.add(self.dpPrimitive(
                        pos + 1,
                        pattern_len,
                        total_digits,
                        pattern,
                        expected == self.limit_digits[pos],
                        new_prefix,
                    ));
                }
            } else {
                const new_prefix = prefix_value * 10 + expected;
                result = result.add(self.dpPrimitive(
                    pos + 1,
                    pattern_len,
                    total_digits,
                    pattern,
                    false,
                    new_prefix,
                ));
            }
        }

        return result;
    }

    /// Check if a pattern is primitive (no shorter repeating subpattern)
    fn isPatternPrimitive(pattern: *const [10]u8, len: u8) bool {
        // Try each potential shorter period
        for (1..len) |period| {
            if (len % period != 0) continue;

            var matches = true;
            for (0..len) |i| {
                if (pattern[i] != pattern[i % period]) {
                    matches = false;
                    break;
                }
            }
            if (matches) return false; // Found a shorter period, not primitive
        }
        return true;
    }
};

/// Sum all repdigits in range [1, limit]
/// Each repdigit is counted once, using its primitive (shortest) pattern.
fn sumRepdigitsUpTo(limit: u64) DpResult {
    if (limit < 11) return DpResult.zero(); // Smallest repdigit is 11

    const counter = RepdigitCounter.init(limit);
    var total = DpResult.zero();

    // Try each pattern length from 1 to 10
    // Only count repdigits where this is the PRIMITIVE pattern length
    for (1..11) |pattern_len| {
        const result = counter.sumWithPrimitivePatternLen(@intCast(pattern_len));
        if (result.count > 0) {
            std.debug.print("  Pattern length {d}: {d} repdigits, sum {d}\n", .{ pattern_len, result.count, result.sum });
        }
        total = total.add(result);
    }

    return total;
}

/// Sum repdigits in range [min_val, max_val]
fn sumRepdigitsInRange(min_val: u64, max_val: u64) DpResult {
    if (max_val < min_val) return DpResult.zero();
    if (max_val < 11) return DpResult.zero();

    const result_to_max = sumRepdigitsUpTo(max_val);
    const result_to_min = if (min_val > 1) sumRepdigitsUpTo(min_val - 1) else DpResult.zero();

    return .{
        .count = result_to_max.count - result_to_min.count,
        .sum = result_to_max.sum - result_to_min.sum,
    };
}

/// Check if a number is a repdigit (for verification/logging)
fn isRepdigit(n: u64) bool {
    if (n < 11) return false;

    // Extract digits
    var digits: [20]u8 = undefined;
    var len: u8 = 0;
    var temp = n;
    while (temp > 0) : (len += 1) {
        digits[len] = @intCast(temp % 10);
        temp /= 10;
    }

    // Try each pattern length
    for (1..len / 2 + 1) |pattern_len_usize| {
        const pattern_len: u8 = @intCast(pattern_len_usize);
        if (len % pattern_len != 0) continue;
        if (len / pattern_len < 2) continue;

        var is_valid = true;
        for (0..len) |i| {
            if (digits[i] != digits[i % pattern_len]) {
                is_valid = false;
                break;
            }
        }
        if (is_valid) return true;
    }

    return false;
}

/// Find and log all repdigits in a range (for debugging)
fn logRepdigitsInRange(min_val: u64, max_val: u64) DpResult {
    std.debug.print("Repdigits in range [{d}, {d}]:\n", .{ min_val, max_val });

    var count: u64 = 0;
    var sum: u64 = 0;
    var n = min_val;
    while (n <= max_val) : (n += 1) {
        if (isRepdigit(n)) {
            std.debug.print("  {d}\n", .{n});
            count += 1;
            sum += n;
        }
    }

    std.debug.print("Total: {d} repdigits, sum: {d}\n", .{ count, sum });
    return .{ .count = count, .sum = sum };
}

pub fn solvePartTwo(pairs: []const Pair) !u64 {
    var total: u64 = 0;

    for (pairs) |pair| {
        const min_val = pair[0];
        const max_val = pair[1];

        std.debug.print("\n=== Range [{d}, {d}] ===\n", .{ min_val, max_val });

        // Log actual repdigits for small ranges (verification)
        if (max_val - min_val < 1000) {
            const brute = logRepdigitsInRange(min_val, max_val);
            _ = brute;
        }

        // Sum using DP
        const result = sumRepdigitsInRange(min_val, max_val);
        std.debug.print("DP result: count={d}, sum={d}\n", .{ result.count, result.sum });

        total += result.sum;
    }

    return total;
}

test "solve with example" {
    const pairs = getExamplePairs();
    const result = try solvePartOne(pairs);
    try std.testing.expectEqual(1227775554, result);
}

test "solve with input file" {
    const allocator = std.testing.allocator;
    const pairs = try loadPairs(allocator);
    defer allocator.free(pairs);
    const result = try solvePartOne(pairs);
    try std.testing.expectEqual(38158151648, result);
}

test "isRepdigit identifies valid repdigits" {
    // Single digit repeated
    try std.testing.expect(isRepdigit(11));
    try std.testing.expect(isRepdigit(22));
    try std.testing.expect(isRepdigit(99));
    try std.testing.expect(isRepdigit(111));
    try std.testing.expect(isRepdigit(7777));

    // Multi-digit patterns
    try std.testing.expect(isRepdigit(1212));
    try std.testing.expect(isRepdigit(123123));
    try std.testing.expect(isRepdigit(81818181));

    // Not repdigits
    try std.testing.expect(!isRepdigit(10));
    try std.testing.expect(!isRepdigit(12));
    try std.testing.expect(!isRepdigit(123));
    try std.testing.expect(!isRepdigit(1234));
    try std.testing.expect(!isRepdigit(1));
    try std.testing.expect(!isRepdigit(9));
}

test "sumRepdigitsUpTo small values" {
    // Repdigits up to 100: 11, 22, 33, 44, 55, 66, 77, 88, 99
    // count = 9, sum = 11+22+33+44+55+66+77+88+99 = 495
    const result_100 = sumRepdigitsUpTo(100);
    try std.testing.expectEqual(9, result_100.count);
    try std.testing.expectEqual(495, result_100.sum);

    // Repdigits up to 50: 11, 22, 33, 44
    // count = 4, sum = 11+22+33+44 = 110
    const result_50 = sumRepdigitsUpTo(50);
    try std.testing.expectEqual(4, result_50.count);
    try std.testing.expectEqual(110, result_50.sum);

    // Repdigits up to 1000: 9 two-digit + 9 three-digit = 18
    // sum = 495 + (111+222+333+444+555+666+777+888+999) = 495 + 4995 = 5490
    const result_1000 = sumRepdigitsUpTo(1000);
    try std.testing.expectEqual(18, result_1000.count);
    try std.testing.expectEqual(5490, result_1000.sum);
}

test "sumRepdigitsInRange" {
    // Range [11, 22] should have 11, 22 -> count=2, sum=33
    const result_11_22 = sumRepdigitsInRange(11, 22);
    try std.testing.expectEqual(2, result_11_22.count);
    try std.testing.expectEqual(33, result_11_22.sum);

    // Range [95, 115] should have 99, 111 -> count=2, sum=210
    const result_95_115 = sumRepdigitsInRange(95, 115);
    try std.testing.expectEqual(2, result_95_115.count);
    try std.testing.expectEqual(210, result_95_115.sum);

    // Range [222220, 222224] should have just 222222 -> count=1, sum=222222
    const result_222220 = sumRepdigitsInRange(222220, 222224);
    try std.testing.expectEqual(1, result_222220.count);
    try std.testing.expectEqual(222222, result_222220.sum);
}
