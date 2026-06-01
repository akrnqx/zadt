const std = @import("std");
const DuplexPipeUtils = @import("./DuplexPipe.zig");
const DuplexPipe = DuplexPipeUtils.DuplexPipe;
const LinkedList = DuplexPipeUtils.LinkedList;
const Side = DuplexPipeUtils.Side;

pub fn RWPipeHandle(comptime T: type) type {
    return struct {
        const Self = @This();
        side: Side,
        pipe: *DuplexPipe(T),

        pub fn init(side: Side, pipe: *DuplexPipe(T)) Self {
            return .{
                .side = side,
                .pipe = pipe,
            };
        }

        pub fn read(self: Self) !*LinkedList(T) {
            return try self.pipe.receive(self.side);
        }

        pub fn read_deallocate(self: Self, allocator: std.mem.Allocator) !T {
            return try self.pipe.receive_allocate(allocator, self.side);
        }

        pub fn write(self: Self, node: *LinkedList(T)) !void {
            try self.pipe.send(self.side, node);
        }

        pub fn write_allocate(self: Self, allocator: std.mem.Allocator, elem: T) !void {
            try self.pipe.send_allocate(allocator, self.side, elem);
        }
    };
}

pub fn create_handle_pair(comptime T: type, pipe: *DuplexPipe(T)) struct { master: RWPipeHandle(T), slave: RWPipeHandle(T) } {
    return .{
        .master = RWPipeHandle(T).init(.master, pipe),
        .slave = RWPipeHandle(T).init(.slave, pipe),
    };
}
