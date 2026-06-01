const std = @import("std");
const KeyValueDLL = @import("../Lists/Lists.zig").KeyValueDLL;

pub fn Map(comptime T: type) type {
    return struct {
        const Self = @This();
        const table_indicies = 2048;
        allocator: std.mem.Allocator,
        hash_table: [table_indicies]?*KeyValueDLL(T),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .hash_table = init_null(),
            };
        }

        fn init_null() []?*KeyValueDLL(T) {
            var tmp: [table_indicies]?*KeyValueDLL(T) = undefined;
            for (0..tmp.len) |i| {
                tmp[i] = null;
            }
            return tmp;
        }

        pub fn deinit(self: *Self) void {
            for (self.hash_table) |entry| {
                while (entry) |h| {
                    entry = h.next;
                    self.allocator.destroy(h);
                }
            }
        }

        fn get_node(self: Self, key: []const u8) ?KeyValueDLL(T) {
            var dll = self.hash_table[hash(key)];
            while (dll) |ll| {
                if (std.mem.eql(u8, key, ll.key)) {
                    return ll;
                }
                dll = ll.next;
            }
            return null;
        }

        pub fn get(self: Self, key: []const u8) ?T {
            const node = self.get_node(key);

            if (node) |n| {
                return n.value;
            }
            return null;
        }

        pub fn add(self: *Self, key: []const u8, elem: T) !void {
            var spot = self.hash_table[hash(key)];
            if (spot == null) {
                var kv = try self.allocator.create(KeyValueDLL(T));
                kv.init(key, elem);
                spot = kv;
                return;
            }

            while (spot) |s| {
                if (std.mem.eql(u8, s.key, key)) {
                    s.value = elem;
                    std.debug.print("value updated", .{});
                    return;
                }
                if (s.next) {
                    spot = s.next;
                } else break;
            }

            var kv_pair = try self.allocator.create(KeyValueDLL(T));
            kv_pair.init(key, elem);
            kv_pair.prev = spot;
            spot.?.next = kv_pair;
        }

        pub fn delete(self: *Self, key: []const u8) !void {
            const node = self.get_node(key);
            if (node) |n| {
                n.prev = n.next;
                self.allocator.destroy(n);
                return;
            }
            return error.key_not_found;
        }

        pub fn hash(key: []const u8) usize {
            var r: usize = 0;
            for (key) |c| {
                const d: usize = @intCast(c);
                r += @intCast(d * d * 347);
            }
            return r % table_indicies;
        }
    };
}
