const std = @import("std");
const Color = @import("./RedBlackTree.zig").Color;

pub fn RedBlackTreeNode(comptime T: type) type {
    return struct {
        const Self = @This();
        parent: ?*RedBlackTreeNode(T),
        left: ?*RedBlackTreeNode(T),
        right: ?*RedBlackTreeNode(T),
        key: T,
        color: Color,

        pub fn init(self: *Self, elem: T, color: Color) void {
            self.parent = null;
            self.left = null;
            self.right = null;
            self.key = elem;
            self.color = color;
        }

        pub fn compare(self: Self, other: T) i8 {
            if (self.key == other) {
                return 0;
            } else if (self.key > other) {
                return 1;
            } else {
                return -1;
            }
        }
    };
}

pub fn NamedRedBlackTreeNode(comptime T: type) type {
    return struct {
        const Self = @This();
        parent: ?*NamedRedBlackTreeNode(T),
        left: ?*NamedRedBlackTreeNode(T),
        right: ?*NamedRedBlackTreeNode(T),
        // idk how to document this
        key: []const u8,
        data: T,
        color: Color,

        pub fn init(self: *Self, key: []const u8, data: T, color: Color) void {
            self.parent = null;
            self.left = null;
            self.right = null;
            self.key = key;
            self.color = color;
            self.data = data;
        }

        pub fn compare(self: Self, other: []const u8) i8 {
            return switch (std.mem.order(u8, self.key, other)) {
                .eq => 0,
                .gt => 1,
                .lt => -1,
            };
        }
    };
}
