const std = @import("std");

const MUL_TOKEN: []const u8 = "mul(";
const DO_TOKEN: []const u8 = "do()";
const DONT_TOKEN: []const u8 = "don't()";

pub fn main() !void {
    // Open puzzle file
    const cwd = std.fs.cwd();
    var resources_dir = try cwd.openDir("resources", .{});
    defer resources_dir.close();
    var resource_file = try resources_dir.openFile("03-mull_it_over.txt", .{});
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

    const read_bytes = try resource_file.read(contents);
    std.debug.assert(read_bytes == file_size);

    var index: usize = 0;
    var result: i32 = 0;
    var do: bool = true;
    while (true) : (index += 1) {
        // Find start of "mul(X,Y)" or "do()" or "don't()"
        const mul_index = std.mem.indexOfPos(u8, contents, index, MUL_TOKEN) orelse break;
        const do_index = std.mem.indexOfPos(u8, contents, index, DO_TOKEN) orelse contents.len;
        const dont_index = std.mem.indexOfPos(u8, contents, index, DONT_TOKEN) orelse contents.len;

        // Update index
        index = @min(mul_index, do_index, dont_index);

        // 'do()' is the current token
        if (index == do_index) {
            do = true;
            continue;
        }
        // 'don't()' is the current token
        else if (index == dont_index) {
            do = false;
            continue;
        }

        // then, 'mul(X,Y)' is the current token

        // skip if "don't" instruction applies
        if (do == false) {
            continue;
        }

        const start_index = index + MUL_TOKEN.len;

        // Find comma
        const comma_index = std.mem.indexOfPos(u8, contents, start_index, ",") orelse break;

        // Ensure 'X' is a number and 1-3 digits long
        const x = std.fmt.parseInt(i32, contents[start_index..comma_index], 10) catch 0;
        if ((x >= 1000) or (x <= -1000)) continue;

        // Find closing parenthesis
        const end_index = std.mem.indexOfPos(u8, contents, comma_index, ")") orelse break;

        // Ensure 'Y' is a number and 1-3 digits long
        const y = std.fmt.parseInt(i32, contents[comma_index + 1 .. end_index], 10) catch 0;
        if ((y >= 1000) or (y <= -1000)) continue;

        // Add up result
        result += (x * y);
    }

    std.debug.print("result: {d}\n", .{result});
}
