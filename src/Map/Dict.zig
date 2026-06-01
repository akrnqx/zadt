const std = @import("std");
const Nodes = @import("../RedBlackTree/Nodes.zig");
const RBT = @import("../RedBlackTree/RedBlackTree.zig");
const RedBlackTree = RBT.RedBlackTree;
const NamedNode = Nodes.NamedRedBlackTreeNode;

pub fn Dict(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = NamedNode(T);

        tree: *RedBlackTree(Node),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            var tree = try allocator.create(RedBlackTree(Node));
            tree.init("");
            return .{
                .allocator = allocator,
                .tree = tree,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.tree.root != &self.tree.nil) {
                self.allocator.destroy(self.tree.delete(self.tree.root.key));
            }
        }

        pub fn insert(self: *Self, k: []const u8, v: T) !void {
            var node = try self.allocator.create(Node);
            node.init(k, v, .black);
            self.tree.insert(node);
        }

        pub fn delete(self: *Self, k: []const u8) !void {
            const node = self.tree.delete(k);
            if (node) |n| {
                self.allocator.destroy(n);
                return;
            }
            return error.node_not_found;
        }

        pub fn get(self: Self, k: []const u8) ?T {
            return self.tree.search(k);
        }

        pub fn update(self: *Self, k: []const u8, v: T) void {
            const node_to_update = self.tree.delete(k);
            if (node_to_update) |n| {
                n.data = v;
                self.tree.insert(n);
            } else {
                var new = try self.allocator.create(Node);
                new.init(k, v, .black);
                self.tree.insert(new);
            }
        }
    };
}
