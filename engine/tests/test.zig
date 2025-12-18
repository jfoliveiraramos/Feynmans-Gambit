// Branches' Gambit Copyright (C) 2025 João Ramos
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const moves = @import("engine").movement;
const game = @import("engine").game;
const MoveList = moves.Move;
const Move = moves.Move;

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

    var correct_moves = moves.PieceMoveList.empty;
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

    const movements = moves.getPiecePlayableMoves(
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
