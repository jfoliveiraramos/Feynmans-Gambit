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
        \\RWNWBWQWKWBWNWKW
    );
    defer match.deinit();

    match.print();

    var movements = match.getMoves(
        .{ .x = 1, .y = 6 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 1..) |move, index| {
            std.debug.print("{}. {s}{s}Move: {},{}\n", .{
                index,
                (if (move.promotion) "Promotion " else ""),
                (if (move.type == .Capture) "Capture " else if (move.type == .EnPassant) "EnPassant " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        match.executeMove(move_list.items[1]);
        match.print();
        // match.undoMove(move_list.items[1]);
        // match.print();
        move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }

    for (match.double_pawns.items) |dpawn| {
        if (dpawn) |pawn| {
            std.log.debug("There's pawn of color: {c}", .{pawn.color.toString()});
        } else {
            std.log.debug("No Pawn\n", .{});
        }
    }
    movements = match.getMoves(
        .{ .x = 0, .y = 4 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 0..) |move, index| {
            std.debug.print("{}. {s}{s}Move: {},{}\n", .{
                index,
                (if (move.promotion) "Promotion " else ""),
                (if (move.type == .Capture) "Capture " else if (move.type == .EnPassant) "EnPassant " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        match.executeMove(move_list.items[1]);
        match.print();
        match.undoMove(move_list.items[1]);
        match.print();
        // move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
}
