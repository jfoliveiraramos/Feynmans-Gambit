const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const moves = engine.moves;
const ArrayList = std.ArrayList;
const Match = game.Match;
const Move = moves.Move;

pub fn main() !void {
    var match: Match = .{};
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("TEST FAIL");
    }
    try match.init(allocator);
    defer match.deinit(allocator);
    match.print();

    const movements = moves.getMoves(
        &match.board,
        .{ .x = 1, .y = 1 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items) |move| {
            std.debug.print("Move: {},{}", .{ move.dest.x, move.dest.y });
        }
        move_list.deinit();
    } else {
        std.debug.print("No moves", .{});
    }
}
