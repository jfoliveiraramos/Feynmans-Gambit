const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const moves = engine.moves;
const ArrayList = std.ArrayList;
const Match = game.Match;
const Move = moves.Move;

pub fn main() !void {
    var match: Match = .{};

    match.init();
    match.print();

    const movements = moves.getMoves(
        match.board,
        .{ .x = 1, .y = 1 },
    );

    if (movements) |move_list| {
        for (move_list.items) |move| {
            std.debug.print("Move: {},{}", .{ move.dest.x, move.dest.y });
        }
        move_list.deinit();
    }
}
