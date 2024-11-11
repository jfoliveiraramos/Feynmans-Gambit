const std = @import("std");
const moves = @import("structures/moves.zig");
const Move = moves.Move;
const ArrayList = std.ArrayList;
const Game = @import("structures/game.zig").Game;

pub fn main() !void {
    var game: Game = .{};

    game.init();
    game.print();

    const movements = moves.getMoves(
        game.board,
        .{ .x = 1, .y = 1 },
    );

    if (movements) |move_list| {
        for (move_list.items) |move| {
            std.debug.print("Move: {},{}", .{ move.dest.x, move.dest.y });
        }
        move_list.deinit();
    }
}
