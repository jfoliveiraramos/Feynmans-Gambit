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
const engine = @import("engine");
const moves = engine.movement;
const game = engine.game;
const MoveList = moves.Move;
const Move = moves.Move;

const Board = game.Board;
const Piece = game.Piece;

test "initial pawn movement" {
    var match = try game.Match.default();
    var correct_moves = moves.PieceMoveList{};
    _ = correct_moves.append(.{
        .type = .Quiet,
        .promotion = false,
        .org = .{
            .x = 0,
            .y = 1,
        },
        .dest = .{
            .x = 0,
            .y = 2,
        },
        .piece = match.board.at(0, 1).?,
    });

    _ = correct_moves.append(.{
        .type = .Quiet,
        .promotion = false,
        .org = .{
            .x = 0,
            .y = 1,
        },
        .dest = .{
            .x = 0,
            .y = 3,
        },
        .piece = match.board.at(0, 1).?,
    });

    const movements = moves.getPiecePlayableMoves(
        &match,
        .{ .x = 0, .y = 1 },
    );

    try std.testing.expect(correct_moves.len == movements.len);

    for (correct_moves.items(), movements.items()) |correct, move| {
        try std.testing.expect(correct.eq(move));
    }
}
