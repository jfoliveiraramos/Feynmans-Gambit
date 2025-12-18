const std = @import("std");

pub fn List(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        moves: [capacity]T = undefined,
        len: usize = 0,

        pub fn items(self: *const Self) []const T {
            return self.moves[0..self.len];
        }

        pub fn append(self: *Self, item: T) *T {
            std.debug.assert(self.len < capacity);
            self.moves[self.len] = item;
            self.len += 1;
            return &self.moves[self.len - 1];
        }

        pub fn appendSlice(self: *Self, slice_items: []const T) void {
            for (slice_items) |item| {
                std.debug.assert(self.len < capacity);
                self.moves[self.len] = item;
                self.len += 1;
            }
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.moves[self.len];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn top(self: *Self) ?*T {
            if (self.len == 0) return null;
            return &self.moves[self.len - 1];
        }
    };
}
