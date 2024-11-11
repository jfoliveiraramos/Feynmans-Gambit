const std = @import("std");
const game = @import("structures/game.zig");
const moves = @import("structures/moves.zig");
const Move = moves.Move;
const ArrayList = std.ArrayList;

const Board = game.Board;
const Piece = game.Piece;

fn boardFromString(boardStr: *const [71]u8) Board {
    var board: Board = .{null} ** 64;
    var i: usize = 0;
    for (boardStr) |c| {
        if (c == '\n') {
            continue;
        }
        board[i] = Piece.fromString(c, i < 32);
        i += 1;
    }
    return board;
}

test "initial pawn movement" {
    const board = boardFromString(
        \\RHBQKBHK
        \\PPPPPPPP
        \\........
        \\........
        \\........
        \\........
        \\PPPPPPPP
        \\RHBQKBHK
    );

    var correct_moves = ArrayList(Move).init(std.testing.allocator);
    defer correct_moves.deinit();
    correct_moves.append(.{
        .type = .Quiet,
        .promotion = false,
        .dest = .{
            .x = 1,
            .y = 2,
        },
    }) catch |err| {
        std.debug.print("Error: {}", .{err});
    };
    correct_moves.append(.{
        .type = .Quiet,
        .promotion = false,
        .dest = .{
            .x = 1,
            .y = 3,
        },
    }) catch |err| {
        std.debug.print("Error: {}", .{err});
    };

    const movements = moves.getMoves(
        board,
        .{ .x = 1, .y = 1 },
    );

    if (movements) |move_list| {
        defer move_list.deinit();

        try std.testing.expect(correct_moves.items.len == move_list.items.len);

        for (correct_moves.items, move_list.items) |correct, move| {
            try std.testing.expect(correct.eq(move));
        }
    }
}
