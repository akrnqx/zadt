const std = @import("std");

pub fn RedBlackTree(comptime NodeType: type) type {

    // since we allow custom node types, we need to be very careful, with the node having the right fields
    // so we check all fields that MUST exist and raise a compileError if one is missing
    comptime {
        if (@typeInfo(NodeType) != .@"struct") {
            @compileError("NodeType must be a struct type, but found: " ++ @typeName(NodeType));
        }

        const required_attributes = .{
            "key",
            "parent",
            "left",
            "right",
            "color",
        };

        for (required_attributes) |field| {
            if (!@hasField(NodeType, field)) {
                @compileError("NodeType '" ++ @typeName(NodeType) ++
                    "' is missing the required field: '" ++ field ++ "'");
            }
        }
        for (@typeInfo(NodeType).@"struct".fields) |field| {
            if (std.mem.eql(u8, field.name, "left") or
                std.mem.eql(u8, field.name, "right") or
                std.mem.eql(u8, field.name, "parent"))
            {
                if (field.type != ?*NodeType) {
                    @compileError("Field '" ++ field.name ++ "' must be of type '*" ++
                        @typeName(NodeType) ++ "', but found '" ++ @typeName(field.type) ++ "'");
                }
            }

            if (std.mem.eql(u8, field.name, "color")) {
                if (@typeInfo(field.type) != .@"enum") {
                    @compileError("Field 'color' must be an enum, but found '" ++ @typeName(field.type) ++ "'");
                }
            }
        }
        if (!@hasDecl(NodeType, "compare")) {
            @compileError("NodeType '" ++ @typeName(NodeType) ++
                "' must define a public 'compare' function");
        }
    }

    const T: type = get_node_type(NodeType, "key");

    return struct {
        const Self = @This();
        const Node = NodeType;

        root: ?*Node,

        pub fn init(self: *Self) void {
            self.root = null;
        }

        pub fn search(self: *const Self, elem: T) ?*Node {
            var cur = self.root;

            while (cur) |c| {
                if (c.compare(elem) == 1) {
                    cur = c.left;
                } else if (c.compare(elem) == -1) {
                    cur = c.right;
                } else {
                    return c;
                }
            }
            return null;
        }

        pub fn insert(self: *Self, node: *Node) void {
            var parent: ?*Node = null;
            var current: ?*Node = self.root;

            while (current) |c| {
                parent = c;
                if (node.compare(c.key) == -1) {
                    current = c.left;
                } else if (node.compare(c.key) == 1) {
                    current = c.right;
                } else {
                    return;
                }
            }

            // my nodes all have an init function, maybe i should add that? - but this would kinda destroy more complex nodes
            node.parent = parent;
            node.left = null;
            node.right = null;
            node.color = .red;

            if (parent) |p| {
                if (node.compare(p.key) == -1) {
                    p.left = node;
                } else {
                    p.right = node;
                }
            } else {
                self.root = node;
            }

            self.insert_correct(node);
        }

        pub fn delete(self: *Self, elem: T) ?*Node {
            const node_d = self.search(elem) orelse return null;

            var x: ?*Node = null;
            var x_parent: ?*Node = null;
            var old_color = node_d.color;

            if (node_d.left == null) {
                x = node_d.right;
                x_parent = node_d.parent;
                self.transplant(node_d, node_d.right);
            } else if (node_d.right == null) {
                x = node_d.left;
                x_parent = node_d.parent;
                self.transplant(node_d, node_d.left);
            } else {
                var min = node_d.right.?;
                while (min.left) |left| {
                    min = left;
                }

                old_color = min.color;
                x = min.right;

                if (min.parent == node_d) {
                    x_parent = min;
                } else {
                    x_parent = min.parent;
                    self.transplant(min, min.right);
                    min.right = node_d.right;
                    if (min.right) |r| r.parent = min;
                }

                self.transplant(node_d, min);
                min.left = node_d.left;
                if (min.left) |l| l.parent = min;
                min.color = node_d.color;
            }

            if (old_color == .black) {
                self.delete_fixup(x, x_parent);
            }

            node_d.left = null;
            node_d.right = null;
            node_d.parent = null;

            return node_d;
        }

        // helpers
        fn getColor(node: ?*Node) Color {
            if (node) |n| return n.color;
            return .black;
        }

        fn insert_correct(self: *Self, node: *Node) void {
            var current = node;

            while (current.parent) |parent| {
                if (parent.color == .black) break; // tree is valid

                // If parent is red, it MUST have a parent (root is always black)
                const grand_parent = parent.parent orelse break;

                if (grand_parent.left == parent) {
                    const uncle = grand_parent.right;

                    if (getColor(uncle) == .red) {
                        parent.color = .black;
                        uncle.?.color = .black;
                        grand_parent.color = .red;
                        current = grand_parent;
                    } else {
                        if (parent.right == current) {
                            current = parent;
                            self.rotate_left(current);
                        }
                        const new_parent = current.parent orelse break;
                        const new_gp = new_parent.parent orelse break;

                        new_parent.color = .black;
                        new_gp.color = .red;
                        self.rotate_right(new_gp);
                    }
                } else {
                    const uncle = grand_parent.left;

                    if (getColor(uncle) == .red) {
                        parent.color = .black;
                        uncle.?.color = .black;
                        grand_parent.color = .red;
                        current = grand_parent;
                    } else {
                        if (parent.left == current) {
                            current = parent;
                            self.rotate_right(current);
                        }
                        const new_parent = current.parent orelse break;
                        const new_gp = new_parent.parent orelse break;

                        new_parent.color = .black;
                        new_gp.color = .red;
                        self.rotate_left(new_gp);
                    }
                }
            }

            if (self.root) |r| {
                r.color = .black;
            }
        }

        fn transplant(self: *Self, node_d: *Node, node_k: ?*Node) void {
            if (node_d.parent) |parent| {
                if (parent.left == node_d) {
                    parent.left = node_k;
                } else {
                    parent.right = node_k;
                }
            } else {
                self.root = node_k;
            }

            if (node_k) |k| {
                k.parent = node_d.parent;
            }
        }

        fn delete_fixup(self: *Self, node_opt: ?*Node, parent_opt: ?*Node) void {
            var x = node_opt;
            var x_parent = parent_opt;

            while (x != self.root and getColor(x) == .black) {
                const parent = x_parent orelse break; // should never be null unless tree is broken

                if (x == parent.left) {
                    var w = parent.right;

                    if (getColor(w) == .red) {
                        w.?.color = .black;
                        parent.color = .red;
                        self.rotate_left(parent);
                        w = parent.right;
                    }

                    if (w == null) {
                        x = parent;
                        x_parent = x.?.parent;
                        continue;
                    }

                    if (getColor(w.?.left) == .black and getColor(w.?.right) == .black) {
                        w.?.color = .red;
                        x = parent;
                        x_parent = x.?.parent;
                    } else {
                        if (getColor(w.?.right) == .black) {
                            if (w.?.left) |l| l.color = .black;
                            w.?.color = .red;
                            self.rotate_right(w);
                            w = parent.right;
                        }

                        if (w) |sibling| {
                            sibling.color = parent.color;
                            parent.color = .black;
                            if (sibling.right) |r| r.color = .black;
                            self.rotate_left(parent);
                            x = self.root;
                            x_parent = null;
                        }
                    }
                } else {
                    var w = parent.left;

                    if (getColor(w) == .red) {
                        w.?.color = .black;
                        parent.color = .red;
                        self.rotate_right(parent);
                        w = parent.left;
                    }

                    if (w == null) {
                        x = parent;
                        x_parent = x.?.parent;
                        continue;
                    }

                    if (getColor(w.?.right) == .black and getColor(w.?.left) == .black) {
                        w.?.color = .red;
                        x = parent;
                        x_parent = x.?.parent;
                    } else {
                        if (getColor(w.?.left) == .black) {
                            if (w.?.right) |r| r.color = .black;
                            w.?.color = .red;
                            self.rotate_left(w);
                            w = parent.left;
                        }

                        if (w) |sibling| {
                            sibling.color = parent.color;
                            parent.color = .black;
                            if (sibling.left) |l| l.color = .black;
                            self.rotate_right(parent);
                            x = self.root;
                            x_parent = null;
                        }
                    }
                }
            }

            if (x) |n| n.color = .black;
        }

        fn rotate_left(self: *Self, node_opt: ?*Node) void {
            const node = node_opt orelse return;
            const right = node.right orelse return; // no left rotate without right child

            node.right = right.left;
            if (right.left) |right_left| {
                right_left.parent = node;
            }

            right.parent = node.parent;

            if (node.parent) |parent| {
                if (parent.left == node) {
                    parent.left = right;
                } else {
                    parent.right = right;
                }
            } else {
                self.root = right;
            }

            right.left = node;
            node.parent = right;
        }

        fn rotate_right(self: *Self, node_opt: ?*Node) void {
            const node = node_opt orelse return;
            const left = node.left orelse return;

            node.left = left.right;
            if (left.right) |left_right| {
                left_right.parent = node;
            }

            left.parent = node.parent;

            if (node.parent) |parent| {
                if (parent.right == node) {
                    parent.right = left;
                } else {
                    parent.left = left;
                }
            } else {
                self.root = left;
            }

            left.right = node;
            node.parent = left;
        }
    };
}

pub const Color = enum {
    black,
    red,
};

fn get_node_type(comptime N: type, comptime field_name: []const u8) type {
    // to avoid parameter duplication, we try to get the "type" of the value field by iterating over the struct and finding the correct one
    inline for (@typeInfo(N).@"struct".fields) |field| {
        if (std.mem.eql(u8, field.name, field_name)) {
            return field.type;
        }
    }
}
