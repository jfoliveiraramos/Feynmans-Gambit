const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const movement = engine.movement;
const ArrayList = std.ArrayList;
const Match = game.Match;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic(" FAIL");
    }

    var match = Match.init(allocator);
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
        \\................
        \\................
        \\................
        \\..............QB
        \\................
        \\................
        \\RW......KW....RW
    );
    defer match.deinit();

    match.print();

    const movements = movement.getPlayableMoves(
        &match,
        .{ .x = 7, .y = 7 },
    );
    defer movements.deinit();

    for (movements.items, 0..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }

    const move = movements.items[0];
    movement.executeMove(&match, move);
    match.print();
    movement.undoMove(&match, move);
    match.print();
}
