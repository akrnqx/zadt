const std = @import("std");
const LinkedList = @import("../Lists/Lists.zig").LinkedList;
const PipeFailError = error{ channel_does_not_exist_error, queue_empty_error };

pub const Side = enum {
    master,
    slave,
};

pub fn DuplexPipe(comptime T: type) type {
    return struct {
        const Self = @This();

        mutex_m: std.Io.Mutex = .{ .state = .{ .raw = .unlocked } },
        mutex_s: std.Io.Mutex = .{ .state = .{ .raw = .unlocked } },
        io: std.Io,

        queues: [2]Queue(T),

        pub fn init(io: std.Io) @This() {
            return .{
                .io = io,
                .queues = [2]Queue(T){ Queue(T).init(), Queue(T).init() },
            };
        }

        pub fn send(self: *Self, channel: Side, node: *LinkedList(T)) !void {
            switch (channel) {
                Side.master => {
                    try self.mutex_m.lock(self.io);
                    defer self.mutex_m.unlock(self.io);
                    self.queues[0].enqueue(node);
                },
                Side.slave => {
                    try self.mutex_s.lock(self.io);
                    defer self.mutex_s.unlock(self.io);
                    self.queues[1].enqueue(node);
                },
            }
        }

        pub fn receive(self: *Self, channel: Side) !*LinkedList(T) {
            switch (channel) {
                Side.slave => {
                    try self.mutex_m.lock(self.io);
                    defer self.mutex_m.unlock(self.io);
                    return try self.queues[0].dequeue();
                },
                Side.master => {
                    try self.mutex_s.lock(self.io);
                    defer self.mutex_s.unlock(self.io);
                    return try self.queues[1].dequeue();
                },
            }
        }

        pub fn send_allocate(self: *Self, allocator: std.mem.Allocator, channel: Side, elem: T) !void {
            const node = try allocator.create(LinkedList(T));
            node.* = LinkedList(T).init(elem);
            try self.send(channel, node);
        }

        pub fn receive_allocate(self: *Self, allocator: std.mem.Allocator, channel: Side) !T {
            const node = try self.receive(channel);
            defer allocator.destroy(node);
            return node.elem;
        }
    };
}

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();
        last: ?*LinkedList(T),
        first: ?*LinkedList(T),

        pub fn is_empty(self: Self) bool {
            return self.first == null;
        }

        pub fn init() Self {
            return .{
                .last = null,
                .first = null,
            };
        }

        fn enqueue(self: *Self, node: *LinkedList(T)) void {
            if (self.last) |li| {
                li.next = node;
                self.last = node;
            } else {
                self.first = node;
                self.last = node;
            }
        }

        fn dequeue(self: *Self) !*LinkedList(T) {
            if (self.first) |li| {
                self.first = li.next;

                if (li.next == null) {
                    self.last = null;
                }

                return li;
            } else {
                return PipeFailError.queue_empty_error;
            }
        }
    };
}

test "Queue: init creates empty queue" {
    var queue = Queue(i32).init();
    try std.testing.expect(queue.is_empty());
}

test "Queue: enqueue and dequeue single element" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init();

    const node = try allocator.create(LinkedList(i32));
    node.* = LinkedList(i32).init(42);

    queue.enqueue(node);
    try std.testing.expect(!queue.is_empty());

    const result = try queue.dequeue();
    try std.testing.expectEqual(@as(i32, 42), result.elem);
    try std.testing.expect(queue.is_empty());

    allocator.destroy(node);
}

test "Queue: enqueue and dequeue multiple elements" {
    const allocator = std.testing.allocator;
    var queue = Queue(i32).init();

    var nodes: [3]*LinkedList(i32) = undefined;
    const values = [_]i32{ 10, 20, 30 };

    for (values, 0..) |val, i| {
        nodes[i] = try allocator.create(LinkedList(i32));
        nodes[i].* = LinkedList(i32).init(val);
        queue.enqueue(nodes[i]);
    }

    for (values) |val| {
        const result = try queue.dequeue();
        try std.testing.expectEqual(val, result.elem);
    }

    try std.testing.expect(queue.is_empty());

    for (nodes) |node| {
        allocator.destroy(node);
    }
}

test "Queue: dequeue empty queue returns error" {
    var queue = Queue(i32).init();

    try std.testing.expectError(error.queue_empty_error, queue.dequeue());
}

test "LinkedList: init creates node with correct value" {
    const node = LinkedList(i32).init(99);
    try std.testing.expectEqual(@as(i32, 99), node.elem);
    try std.testing.expect(node.next == null);
}

test "LinkedList: chain nodes together" {
    var node1 = LinkedList(i32).init(1);
    var node2 = LinkedList(i32).init(2);

    node1.next = &node2;

    try std.testing.expectEqual(@as(i32, 2), node1.next.?.elem);
}

test "DuplexPipe: send and receive between master and slave" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var duplex = DuplexPipe(i32).init(io);

    // Master sends to slave
    try duplex.send_allocate(allocator, .master, 100);

    // Slave receives from master
    const received = try duplex.receive_allocate(allocator, .slave);
    try std.testing.expectEqual(@as(i32, 100), received);
}

test "DuplexPipe: bidirectional communication" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var duplex = DuplexPipe(i32).init(io);

    // Both directions
    try duplex.send_allocate(allocator, .master, 42);
    try duplex.send_allocate(allocator, .slave, 99);

    const from_master = try duplex.receive_allocate(allocator, .slave);
    const from_slave = try duplex.receive_allocate(allocator, .master);

    try std.testing.expectEqual(@as(i32, 42), from_master);
    try std.testing.expectEqual(@as(i32, 99), from_slave);
}

test "DuplexPipe: multiple messages in sequence" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var duplex = DuplexPipe(i32).init(io);

    const messages = [_]i32{ 1, 2, 3, 4, 5 };

    for (messages) |msg| {
        try duplex.send_allocate(allocator, .master, msg);
    }

    for (messages) |msg| {
        const received = try duplex.receive_allocate(allocator, .slave);
        try std.testing.expectEqual(msg, received);
    }
}
