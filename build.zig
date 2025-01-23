const std = @import("std");

fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.ascii.lessThanIgnoreCase(lhs, rhs);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get all zig files in 'days' directory
    const cwd = std.fs.cwd();
    var days_dir = try cwd.openDir("days", .{ .iterate = true, .access_sub_paths = false });
    defer days_dir.close();

    // Store files in an intermediate array because we want to sort them alphabetically
    var files = std.ArrayList([]const u8).init(b.allocator);
    defer files.deinit();

    var iter = days_dir.iterate();
    while (try iter.next()) |entry| {
        if ((entry.kind != .file) or (std.ascii.endsWithIgnoreCase(entry.name, ".zig") == false)) {
            continue;
        }

        try files.append(entry.name);
    }

    std.mem.sort([]const u8, files.items, {}, lessThan);

    for (files.items) |file| {
        std.debug.print("Building '{s}'...\n", .{file});

        var path = std.ArrayList(u8).init(b.allocator);
        defer path.deinit();

        try path.appendSlice("days/");
        try path.appendSlice(file);

        const exe = b.addExecutable(.{
            .name = file[0..(std.ascii.indexOfIgnoreCase(file, ".zig") orelse unreachable)],
            .root_source_file = b.path(path.items),
            .target = target,
            .optimize = optimize,
        });

        b.installArtifact(exe);
    }
}
