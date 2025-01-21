const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    // Open puzzle file
    const cwd = std.fs.cwd();
    var resources_dir = try cwd.openDir("resources", .{});
    defer resources_dir.close();
    var resource_file = try resources_dir.openFile("01-historian-hysteria.txt", .{});
    defer resource_file.close();

    // Get file size
    const file_size = (try resource_file.stat()).size;

    // Initialize allocator
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Initialize buffer to store file contents
    const contents: []u8 = try allocator.alloc(u8, file_size);
    defer allocator.free(contents);

    _ = try resource_file.read(contents);

    var left = std.ArrayList(u32).init(allocator);
    defer left.deinit();
    var right = std.ArrayList(u32).init(allocator);
    defer right.deinit();

    var lines = std.mem.tokenizeAny(u8, contents, "\n");
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeSequence(u8, line, " ");

        var i: u8 = 0;
        while (tokens.next()) |token| {
            switch (i) {
                0 => try left.append(try std.fmt.parseUnsigned(u32, token, 10)),
                1 => try right.append(try std.fmt.parseUnsigned(u32, token, 10)),
                else => unreachable,
            }
            i += 1;
        }
    }

    std.mem.sort(u32, left.items, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, right.items, {}, comptime std.sort.asc(u32));

    var total_distance: u32 = 0;
    for (0..left.items.len) |i| {
        total_distance += if (left.items[i] > right.items[i]) (left.items[i] - right.items[i]) else (right.items[i] - left.items[i]);
    }

    print("total_distance: {}\n", .{total_distance});

    var similarity_score: u32 = 0;
    for (0..left.items.len) |i| {
        const needle: []u32 = try allocator.alloc(u32, 1);
        defer allocator.free(needle);
        needle[0] = left.items[i];

        similarity_score += left.items[i] * @as(u32, @intCast(std.mem.count(u32, right.items, needle)));
    }

    print("similarity_score: {}\n", .{similarity_score});
}
