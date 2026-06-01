const std = @import("std");

const RedBlackTree = @import("RedBlackTree.zig").RedBlackTree;
const NamedRedBlackTreeNode = @import("Nodes.zig").NamedRedBlackTreeNode;
const RedBlackTreeNode = @import("Nodes.zig").RedBlackTreeNode;
const Color = @import("RedBlackTree.zig").Color;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;

test "empty tree: root == null" {
    var tree: RedBlackTree(RedBlackTreeNode(void)) = undefined;
    tree.init();

    try expect(tree.root == null);
}

test "appending node to empty tree becomes new root with children/parent == null" {
    var tree: RedBlackTree(RedBlackTreeNode(i8)) = undefined;
    tree.init();

    var node: RedBlackTreeNode(i8) = undefined;
    node.init(8, .black);

    tree.insert(&node);
    // delete the node and do the same thing with the returned node (search was theoretically executed in delete so is must work properly)
    var node2 = tree.delete(8);

    _ = &node2;
    // the root should be null / nil again
    try expect(tree.root == null);
    if (node2) |n| {
        try expect(&node == n);
    } else {
        // TODO
    }
}

test "Initializing a RBtree with a custom Node" {
    var tree: RedBlackTree(NamedRedBlackTreeNode(i32)) = undefined;
    tree.init();

    const names = [_][]const u8{
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
    };
    const nums = [_]i32{ 1, 2, 3, 4, 5, 6, 7 };
    var node_arr: [7]NamedRedBlackTreeNode(i32) = undefined;
    for (0..7) |i| {
        node_arr[i].init(names[i], nums[i], Color.black);
        tree.insert(&node_arr[i]);
    }

    for (names) |name| {
        const x = tree.search(name);
        if (x) |y| {
            std.debug.print("found {d} \n", .{y.data});
        } else {
            std.debug.print("not found", .{});
        }
    }
    try expectEqual(null, tree.search("qwe"));

    _ = tree.delete("f");
    try verify_tree_order(tree);
}

pub fn verify_tree_order(tree: RedBlackTree(NamedRedBlackTreeNode(i32))) !void {
    if (!verify_subtree(tree.root.?)) return error.tree_incorrect;
}

fn verify_subtree(node: ?*NamedRedBlackTreeNode(i32)) bool {
    var is_tree = true;
    const right = node.?.right;
    const left = node.?.left;

    if (right != null and right.?.compare(node.?.key) == 1) {
        is_tree &= verify_subtree(right);
    } else {
        if (right != null) return false;
    }
    if (left != null and left.?.compare(node.?.key) == -1) {
        is_tree &= verify_subtree(left);
    } else {
        if (left != null) return false;
    }
    return is_tree;
}
