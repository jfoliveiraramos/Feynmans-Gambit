// Branches' Gambit Copyright (C) 2025 João Ramos
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");

pub fn List(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        ptr: [capacity]T = undefined,
        len: usize = 0,

        pub fn items(self: *const Self) []const T {
            return self.ptr[0..self.len];
        }

        pub fn append(self: *Self, item: T) void {
            std.debug.assert(self.len < capacity);
            self.ptr[self.len] = item;
            self.len += 1;
        }

        pub fn appendSlice(self: *Self, slice_items: []const T) void {
            for (slice_items) |item| {
                std.debug.assert(self.len < capacity);
                self.ptr[self.len] = item;
                self.len += 1;
            }
        }

        pub fn pop(self: *Self) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.ptr[self.len];
        }

        pub fn clear(self: *Self) void {
            self.len = 0;
        }

        pub fn top(self: *Self) ?*T {
            if (self.len == 0) return null;
            return &self.ptr[self.len - 1];
        }
    };
}
