const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const moves = engine.moves;
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
    try match.fromStr(
        \\....PW..QW......
        \\PBPBPBPBPBPBPBPB
        \\................
        \\................
        \\PB..............
        \\................
        \\PWPWPWPWPWPWPWPW
        \\RWNWBWQWKW....RW
    );
    defer match.deinit();

    match.print();

    const movements = moves.getMoves(
        &match,
        .{ .x = 4, .y = 7 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 1..) |move, index| {
            std.debug.print("{}. {s}{s}Move: {},{}\n", .{
                index,
                (if (move.promotion) "Promotion " else ""),
                (if (move.type == .Capture) "Capture " else if (move.type == .EnPassant) "EnPassant " else if (move.type == .Castling) "Caslting " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        moves.executeMove(&match, move_list.items[2]);
        match.print();
        moves.undoMove(&match, move_list.items[2]);
        match.print();
        move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
}
