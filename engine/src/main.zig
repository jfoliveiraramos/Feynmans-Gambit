const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const movement = engine.movement;
const ArrayList = std.ArrayList;
const Match = game.Match;

pub fn main() !void {
    var match = Match{};
    // try match.fromStr(
    //     \\....PW..QW......
    //     \\PBPBPBPBPBPBPBPB
    //     \\................
    //     \\................
    //     \\PB..............
    //     \\................
    //     \\PWPWPWPWPWPWPWPW
    //     \\RWNWBWQWKW....RW
    // );
    try match.fromStr(
        \\................
        \\....PB..........
        \\................
        \\......PW........
        \\................
        \\................
        \\................
        \\................
    );
    defer match.deinit();

    match.print();

    var movements = movement.getPiecePlayableMoves(
        &match,
        .{ .x = 2, .y = 1 },
    );
    for (movements.items(), 0..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }
    movement.executeMove(&match, movements.items()[1]);
    match.print();
    movements = movement.getPiecePlayableMoves(
        &match,
        .{ .x = 3, .y = 3 },
    );
    for (movements.items(), 0..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }
    movement.executeMove(&match, movements.items()[1]);
    match.print();

    if (movement.checkmate(&match, match.turn)) {
        std.debug.print("Checkmate\n", .{});
    } else if (movement.stalemate(&match, match.turn)) {
        std.debug.print("Stalemate\n", .{});
    } else {
        std.debug.print("Nothing\n", .{});
    }

    // const move = movements.items[5];
    // movement.executeMove(&match, move);
    // match.print();
    // movement.undoMove(&match, move);
    // match.print();
}
