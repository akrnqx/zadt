const std = @import("std");

test "Run all" {
    _ = @import("RedBlackTree/tests.zig");
    _ = @import("DuplexPipe/DuplexPipe.zig");
    _ = @import("Map/tests.zig");
}

pub fn main() !void {
    std.debug.print("hello world", .{});
}
