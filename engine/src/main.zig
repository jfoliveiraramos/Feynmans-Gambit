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
        \\KW..............
        \\..NW..RB........
        \\................
        \\................
        \\................
        \\................
        \\................
        \\................
        \\................
    );
    defer match.deinit();

    match.print();

    const movements = movement.getPlayableMoves(
        &match,
        .{ .x = 1, .y = 1 },
    );
    defer movements.deinit();

    for (movements.items, 1..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }

    movement.executeMove(&match, movements.items[1]);
    match.print();
    movement.undoMove(&match, movements.items[1]);
    match.print();
}
