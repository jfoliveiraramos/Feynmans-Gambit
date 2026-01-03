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
const Pos = game.Pos;

test "game: pawn movement" {
    var match = game.Match.default();
    const org = Pos.fromXY(0, 1);
    var correct_moves = moves.PieceMoveList{};
    correct_moves.append(.{
        .org = org,
        .dst = Pos.fromXY(0, 2),
    });

    correct_moves.append(.{
        .org = org,
        .dst = Pos.fromXY(0, 3),
    });

    const movements = moves.getPiecePlayableMoves(
        &match,
        org,
    );

    try std.testing.expect(correct_moves.len == movements.len);

    for (correct_moves.items(), movements.items()) |correct, move| {
        try std.testing.expect(correct.eq(move));
    }
}

test "game: check detection" {
    var m1 = try game.Match.fromFEN("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3");
    try std.testing.expect(moves.check(&m1, .White));

    var m2 = try game.Match.fromFEN("4k3/8/8/8/8/8/4Q3/4K3 b - - 0 1");
    try std.testing.expect(moves.check(&m2, .Black));
}

test "game: stalemate detection" {
    var m = try game.Match.fromFEN("k7/8/1Q6/8/8/8/8/7K b - - 0 1");

    try std.testing.expect(moves.stalemate(&m, .Black));
}

test "game: checkmate detection" {
    var m1 = try game.Match.fromFEN("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3");
    try std.testing.expect(moves.checkmate(&m1, .White));

    var m2 = try game.Match.fromFEN("4R1k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1");
    try std.testing.expect(moves.checkmate(&m2, .Black));

    var m3 = try game.Match.fromFEN("6rk/6pp/7N/8/8/8/8/6K1 b - - 0 1");
    try std.testing.expect(!moves.checkmate(&m3, .Black));
    _ = moves.executeMove(&m3, .{
        .org = Pos.fromXY(7, 2),
        .dst = Pos.fromXY(5, 1),
    });
    try std.testing.expect(moves.checkmate(&m3, .Black));

    var m4 = try game.Match.fromFEN("7k/6Q1/6K1/8/8/8/8/8 b - - 0 1");
    try std.testing.expect(moves.checkmate(&m4, .Black));
}

test "game: fen" {
    const fen1 = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq -";
    var buf1: [128]u8 = undefined;
    const m1 = try game.Match.fromFEN(fen1);
    const len1 = m1.toFEN(buf1[0..]);
    try std.testing.expectEqualStrings(fen1, buf1[0..len1]);
}
