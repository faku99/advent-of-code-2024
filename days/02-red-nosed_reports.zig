const std = @import("std");

fn isSafe(level: []u32) bool {
    const is_asc = std.sort.isSorted(u32, level, {}, comptime std.sort.asc(u32));
    const is_desc = std.sort.isSorted(u32, level, {}, comptime std.sort.desc(u32));
    const is_sorted = (is_asc or is_desc);

    if (!is_sorted) return false;

    var highest_diff: u32 = 0;
    var lowest_diff: u32 = std.math.maxInt(u32);
    for (1..level.len) |i| {
        const diff: u32 = if (is_asc) level[i] - level[i - 1] else level[i - 1] - level[i];
        if (diff > highest_diff) highest_diff = diff;
        if (diff < lowest_diff) lowest_diff = diff;
    }

    return ((lowest_diff >= 1) and (highest_diff <= 3));
}

pub fn main() !void {
    // Open puzzle file
    const cwd = std.fs.cwd();
    var resources_dir = try cwd.openDir("resources", .{});
    defer resources_dir.close();
    var resource_file = try resources_dir.openFile("02-red-nosed_reports.txt", .{});
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

    var levels = std.mem.tokenizeAny(u8, contents, "\n");
    var safe: usize = 0;
    levels: while (levels.next()) |level| {
        var reports = std.ArrayList(u32).init(allocator);
        defer reports.deinit();

        var tokens = std.mem.tokenizeAny(u8, level, " ");
        while (tokens.next()) |token| {
            try reports.append(try std.fmt.parseUnsigned(u32, token, 10));
        }

        if (isSafe(reports.items)) {
            safe += 1;
            continue;
        }

        for (0..reports.items.len) |i| {
            var tmp_reports = try reports.clone();
            defer tmp_reports.deinit();

            _ = tmp_reports.orderedRemove(i);

            if (isSafe(tmp_reports.items)) {
                safe += 1;
                continue :levels;
            }
        }
    }

    std.debug.print("Found {d} safe levels\n", .{safe});
}
