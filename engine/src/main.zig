const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const moves = engine.moves;
const ArrayList = std.ArrayList;
const Match = game.Match;
const Move = moves.Move;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic(" FAIL");
    }

    var match: Match = .{};
    try match.init(allocator);
    defer match.deinit(allocator);

    match.print();

    const movements = moves.getMoves(
        &match.board,
        .{ .x = 3, .y = 3 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items) |move| {
            std.debug.print("{s}Move: {},{}\n", .{
                (if (move.type == .Capture) "Capture " else ""),
                move.dest.x,
                move.dest.y,
            });
        }
        move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
}
