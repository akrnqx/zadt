const std = @import("std");
const Dict = @import("./Dict.zig").Dict;
const HashMap = @import("./HashMap.zig").Map;

test "the hashing function works and distributes well over the n hash_table entries available" {
    const io = std.testing.io;
    const cwd = std.Io.Dir.cwd;

    var file = try cwd().openFile(io, "/home/akrn/zig/sys_zig/src/Map/words.txt", .{ .mode = .read_only });
    defer file.close(io);

    var buf: [256]u8 = undefined;
    var reader = file.reader(io, &buf);

    // we make a little array with the size of the hash map array
    var arr: [2048]u32 = .{0} ** 2048;
    var counter = 0;

    while (try reader.interface.takeDelimiter('\n')) |line| {
        const x = HashMap(i32).hash(line);
        arr[x] += 1;
        counter += 1;
    }
    const expected_avg = counter / 2048;

    for (arr) |entry| {
        try std.testing.expect(expected_avg - entry > -3);
    }
}
