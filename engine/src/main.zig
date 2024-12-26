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
        \\................
        \\................
        \\PWPWPWPWPWPWPWPW
        \\RWHWBWQWKWBWHWKW
    );
    defer match.deinit();

    match.print();

    var movements = match.getMoves(
        .{ .x = 3, .y = 1 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 1..) |move, index| {
            std.debug.print("{}. {s}{s}Move: {},{}\n", .{
                index,
                (if (move.promotion) "Promotion " else "Non-promotion "),
                (if (move.type == .Capture) "Capture " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        match.executeMove(move_list.items[1]);
        match.print();
        match.undoMove(move_list.items[1]);
        match.print();
        move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
    movements = match.getMoves(
        .{ .x = 3, .y = 0 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 0..) |move, index| {
            std.debug.print("{}. {s}{s}Move: {},{}\n", .{
                index,
                (if (move.promotion) "Promotion " else "Non-promotion "),
                (if (move.type == .Capture) "Capture " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        // match.executeMove(move_list.items[12]);
        // match.print();
        // match.undoMove(move_list.items[12]);
        // match.print();
        // move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
}
