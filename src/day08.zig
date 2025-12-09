const std = @import("std");
const Day = @import("day.zig").Day;
const utils = @import("utils.zig");

pub const day = Day([]const u8, u64){
    .load = &loadInput,
    .getExample = &getExampleInput,
    .solvers = &.{
        .{ .name = "Part One", .func = &solvePartOne },
    },
};

const Point = struct {
    x: i64,
    y: i64,
    z: i64,
};

const Pair = struct {
    i: usize,
    j: usize,
    dist_sq: u64,
};

fn comparePairs(_: void, a: Pair, b: Pair) bool {
    return a.dist_sq < b.dist_sq;
}

// Union-Find data structure
const UnionFind = struct {
    parent: []usize,
    rank: []usize,
    size: []usize,

    fn init(allocator: std.mem.Allocator, n: usize) !UnionFind {
        const parent = try allocator.alloc(usize, n);
        const rank = try allocator.alloc(usize, n);
        const size = try allocator.alloc(usize, n);

        for (0..n) |i| {
            parent[i] = i;
            rank[i] = 0;
            size[i] = 1;
        }

        return .{ .parent = parent, .rank = rank, .size = size };
    }

    fn find(self: *UnionFind, x: usize) usize {
        if (self.parent[x] != x) {
            self.parent[x] = self.find(self.parent[x]); // Path compression
        }
        return self.parent[x];
    }

    fn unite(self: *UnionFind, x: usize, y: usize) bool {
        const root_x = self.find(x);
        const root_y = self.find(y);

        if (root_x == root_y) {
            return false; // Already in same circuit
        }

        // Union by rank
        if (self.rank[root_x] < self.rank[root_y]) {
            self.parent[root_x] = root_y;
            self.size[root_y] += self.size[root_x];
        } else if (self.rank[root_x] > self.rank[root_y]) {
            self.parent[root_y] = root_x;
            self.size[root_x] += self.size[root_y];
        } else {
            self.parent[root_y] = root_x;
            self.size[root_x] += self.size[root_y];
            self.rank[root_x] += 1;
        }

        return true;
    }
};

fn distanceSquared(a: Point, b: Point) u64 {
    const dx: i64 = a.x - b.x;
    const dy: i64 = a.y - b.y;
    const dz: i64 = a.z - b.z;

    const dx_sq: u64 = @intCast(dx * dx);
    const dy_sq: u64 = @intCast(dy * dy);
    const dz_sq: u64 = @intCast(dz * dz);

    return dx_sq + dy_sq + dz_sq;
}

pub fn solvePartOne(input: []const []const u8) !u64 {
    return solve(input, 1000);
}

pub fn solveExample(input: []const []const u8) !u64 {
    return solve(input, 10);
}

fn solve(input: []const []const u8, num_connections: usize) !u64 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Parse points
    var points: std.ArrayList(Point) = .empty;
    for (input) |line| {
        if (line.len == 0) continue;

        var parts = std.mem.splitScalar(u8, line, ',');
        const x = try std.fmt.parseInt(i64, parts.next().?, 10);
        const y = try std.fmt.parseInt(i64, parts.next().?, 10);
        const z = try std.fmt.parseInt(i64, parts.next().?, 10);

        try points.append(allocator, .{ .x = x, .y = y, .z = z });
    }

    const n = points.items.len;

    // Generate all pairs with distances
    var pairs: std.ArrayList(Pair) = .empty;
    for (0..n) |i| {
        for (i + 1..n) |j| {
            const dist_sq = distanceSquared(points.items[i], points.items[j]);
            try pairs.append(allocator, .{ .i = i, .j = j, .dist_sq = dist_sq });
        }
    }

    // Sort by distance
    std.mem.sort(Pair, pairs.items, {}, comparePairs);

    // Union-Find to track circuits
    var uf = try UnionFind.init(allocator, n);

    // Process the first num_connections pairs (not num_connections successful unions!)
    // The problem says "the ten shortest connections" which means we try 10 pairs
    for (pairs.items[0..@min(num_connections, pairs.items.len)]) |pair| {
        _ = uf.unite(pair.i, pair.j);
    }

    // Collect circuit sizes
    var circuit_sizes: std.ArrayList(u64) = .empty;
    for (0..n) |i| {
        if (uf.find(i) == i) {
            // This is a root, so get the size of this circuit
            try circuit_sizes.append(allocator, uf.size[i]);
        }
    }

    // Sort descending to get largest
    std.mem.sort(u64, circuit_sizes.items, {}, struct {
        fn cmp(_: void, a: u64, b: u64) bool {
            return a > b;
        }
    }.cmp);

    // Multiply top 3
    var result: u64 = 1;
    const count = @min(3, circuit_sizes.items.len);
    for (0..count) |i| {
        result *= circuit_sizes.items[i];
    }

    return result;
}

pub fn getExampleInput() []const []const u8 {
    const input = [_][]const u8{
        "162,817,812",
        "57,618,57",
        "906,360,560",
        "592,479,940",
        "352,342,300",
        "466,668,158",
        "542,29,236",
        "431,825,988",
        "739,650,466",
        "52,470,668",
        "216,146,977",
        "819,987,18",
        "117,168,530",
        "805,96,715",
        "346,949,466",
        "970,615,88",
        "941,993,340",
        "862,61,35",
        "984,92,344",
        "425,690,689",
    };
    return &input;
}

pub fn loadInput(allocator: std.mem.Allocator) ![][]const u8 {
    return try utils.readLinesForDay(allocator, 8);
}
