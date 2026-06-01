pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        elem: T,
        next: ?*LinkedList(T),

        pub fn init(elem: T) Self {
            return .{
                .elem = elem,
                .next = null,
            };
        }
    };
}

pub fn DoubleLinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        elem: T,
        next: ?*DoubleLinkedList(T),
        prev: ?*DoubleLinkedList(T),

        pub fn init(elem: T) Self {
            return .{
                .elem = elem,
                .next = null,
                .prev = null,
            };
        }
    };
}

pub fn KeyValueDLL(comptime T: type) type {
    return struct {
        const Self = @This();
        key: []const u8,
        value: T,
        next: ?*KeyValueDLL(T),
        prev: ?*KeyValueDLL(T),

        pub fn init(k: []const u8, v: T) Self {
            return .{
                .key = k,
                .value = v,
                .next = null,
                .prev = null,
            };
        }
    };
}
