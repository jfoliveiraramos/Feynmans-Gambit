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
const game = @import("game.zig");
const utils = @import("utils.zig");

const List = utils.List;
const Match = game.Match;
const Castling = game.Castling;
const Piece = game.Piece;
const Colour = game.Colour;
const Pos = game.Pos;

pub const Undo = struct {
    captured: Piece,
    en_passant: Pos,
    castling_rights: u8,
};

pub const Move = extern struct {
    org: Pos,
    dst: Pos,
    flag: Flag = .None,

    const Flag = enum(u8) {
        None,
        EnPassant,
        Castling,
        PromoteToKnight,
        PromoteToBishop,
        PromoteToRook,
        PromoteToQueen,
    };

    const PROMOTIONS: [4]Move.Flag = .{
        .PromoteToBishop,
        .PromoteToRook,
        .PromoteToKnight,
        .PromoteToQueen,
    };

    pub fn eq(self: Move, other: Move) bool {
        return self.org.eq(other.org) and self.dst.eq(other.dst) and self.flag == other.flag;
    }
};

const MAX_PIECE_MOVES = 27;
pub const MAX_MOVES = 256;

pub const PieceMoveList = List(Move, MAX_PIECE_MOVES);
pub const MoveList = List(Move, MAX_MOVES);

pub fn executeMove(match: *Match, move: Move) Undo {
    var board = &match.board;
    const piece = board.at(move.org);
    const captured = board.at(move.dst);

    const orgCoords = move.org.coords();
    const dstCoords = move.dst.coords();

    match.board.set(Piece.empty, move.org);

    switch (move.flag) {
        .None => match.board.set(piece, move.dst),
        .Castling => {
            const rook = match.board.at(move.dst);
            const x: u3 = if (dstCoords.x == 7) 6 else 1;
            match.board.set(rook, Pos.fromXY(x, dstCoords.y));
        },
        .EnPassant => match.board.set(
            Piece.empty,
            Pos.fromXY(dstCoords.x, orgCoords.y),
        ),
        .PromoteToBishop => match.board.set(
            piece.promoteTo(.Bishop),
            move.dst,
        ),
        .PromoteToRook => match.board.set(
            piece.promoteTo(.Rook),
            move.dst,
        ),
        .PromoteToKnight => match.board.set(
            piece.promoteTo(.Rook),
            move.dst,
        ),
        .PromoteToQueen => match.board.set(
            piece.promoteTo(.Queen),
            move.dst,
        ),
    }

    return Undo{
        .captured = captured,
        .en_passant = match.en_passant,
        .castling_rights = match.castling_rights,
    };
}

pub fn undoMove(match: *Match, move: Move, undo: Undo) void {
    var board = &match.board;
    const orgCoords = move.org.coords();
    const dstCoords = move.dst.coords();

    const piece = board.at(move.dst);
    board.set(piece, move.org);

    if (undo.captured.type != .None) {
        board.set(undo.captured, move.dst);
    }

    switch (move.flag) {
        .None => match.board.set(Piece.empty, move.dst),
        .Castling => {
            const x: u3 = if (dstCoords.x == 7) 6 else 1;
            const rook = board.at(Pos.fromXY(x, dstCoords.y));
            board.set(rook, move.dst);
            board.set(Piece.empty, Pos.fromXY(x, dstCoords.y));
        },
        .EnPassant => match.board.set(
            Piece.new(.Pawn, piece.oppositeColour()),
            Pos.fromXY(dstCoords.x, orgCoords.y),
        ),
        else => match.board.set(
            piece.promoteTo(.Pawn),
            move.dst,
        ),
    }

    match.en_passant = undo.en_passant;
    match.castling_rights = undo.castling_rights;
}

fn getPieceMoves(match: *Match, pos: Pos) PieceMoveList {
    const piece = match.board.at(pos);
    return switch (piece.type) {
        .Pawn => getPawnMoves(match, pos, piece),
        .Rook => getRookMoves(match, pos, piece),
        .Bishop => getBishopMoves(match, pos, piece),
        .Knight => getKnightMoves(match, pos, piece),
        .Queen => getQueenMoves(match, pos, piece),
        .King => getKingMoves(match, pos, piece),
        .None => PieceMoveList{},
    };
}

pub fn getPiecePlayableMoves(match: *Match, pos: Pos) PieceMoveList {
    const pieceMoves = getPieceMoves(match, pos);
    return filterMoves(match, MAX_PIECE_MOVES, pieceMoves);
}

fn hasPawnMoved(piece: Piece, y: u3) bool {
    return ((piece.isBlack() and y > 1) or (piece.isWhite() and y < 6));
}

fn getPawnMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    var moves = PieceMoveList{};

    const vdir: i8 = if (piece.isWhite()) -1 else 1;

    const coords = pos.coords();

    const range: []const i8 = if (hasPawnMoved(piece, coords.y)) &.{
        1 * vdir,
    } else &.{
        1 * vdir,
        2 * vdir,
    };

    for (range) |i| {
        const new_y = @as(i8, @intCast(coords.y)) + i;
        if (new_y < 0 or new_y >= 8) break;
        const dst = Pos.fromXY(coords.x, @intCast(new_y));
        if (match.board.at(dst).type == .None) {
            var move = Move{ .org = pos, .dst = dst };
            if (new_y == 0 or new_y == 7) {
                for (Move.PROMOTIONS) |promotion| {
                    move.flag = promotion;
                    moves.append(move);
                }
            } else {
                moves.append(move);
            }
        }
    }

    for ([2]i8{ -1, 1 }) |hdir| {
        const new_x: i8 = @as(i8, @intCast(coords.x)) + hdir;
        const new_y: i8 = @as(i8, @intCast(coords.y)) + vdir;
        if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) continue;
        const dst = Pos.fromXY(@intCast(new_x), @intCast(new_y));
        const target = match.board.at(dst);
        if (target.type != .None and target.isSameColour(piece)) {
            var move = Move{ .org = pos, .dst = dst };
            if (new_y == 0 or new_y == 7) {
                for (Move.PROMOTIONS) |promotion| {
                    move.flag = promotion;
                    moves.append(move);
                }
            } else {
                moves.append(move);
            }
        }
        if (!match.en_passant.isNone()) {
            const en_passant_coords = match.en_passant.coords();
            if (en_passant_coords.x == new_x and en_passant_coords.y == coords.y) {
                moves.append(.{
                    .org = pos,
                    .dst = dst,
                    .flag = .EnPassant,
                });
            }
        }
    }
    return moves;
}

fn getRookMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    return getMovesInDirections(
        match,
        pos,
        piece,
        &[_][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } },
        false,
    );
}
fn getBishopMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    return getMovesInDirections(
        match,
        pos,
        piece,
        &[_][2]i8{ .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } },
        false,
    );
}

fn getKnightMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    return getMovesInDirections(
        match,
        pos,
        piece,
        &[_][2]i8{
            .{ -1, 2 },
            .{ 1, 2 },
            .{ 2, 1 },
            .{ 2, -1 },
            .{ -1, -2 },
            .{ 1, -2 },
            .{ -2, 1 },
            .{ -2, -1 },
        },
        true,
    );
}

fn getQueenMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    const moves = getMovesInDirections(
        match,
        pos,
        piece,
        &[_][2]i8{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, 1 },
            .{ 1, -1 },
            .{ -1, 1 },
            .{ -1, -1 },
        },
        false,
    );

    return moves;
}

fn getKingMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    var moves = getMovesInDirections(
        match,
        pos,
        piece,
        &[_][2]i8{
            .{ -1, 0 },
            .{ 1, 0 },
            .{ 0, -1 },
            .{ 0, 1 },
            .{ 1, 1 },
            .{ 1, -1 },
            .{ -1, 1 },
            .{ -1, -1 },
        },
        true,
    );

    moves.appendSlice(getCastling(match, pos, piece).items());
    return moves;
}

fn getMovesInDirections(match: *Match, pos: Pos, piece: Piece, directions: []const [2]i8, limited: bool) PieceMoveList {
    var moves = PieceMoveList{};
    const coords = pos.coords();
    for (directions) |dpos| {
        var i: i8 = 1;
        while (true) : (i += 1) {
            const new_x = @as(i8, @intCast(coords.x)) + dpos[0] * i;
            const new_y = @as(i8, @intCast(coords.y)) + dpos[1] * i;
            if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;

            const dst = Pos.fromXY(
                @intCast(new_x),
                @intCast(new_y),
            );
            const target = (match.board.at(dst));
            if (target.type != .None) {
                if (!target.isSameColour(piece)) {
                    moves.append(.{
                        .org = pos,
                        .dst = dst,
                    });
                }
                break;
            } else {
                moves.append(
                    .{
                        .org = pos,
                        .dst = dst,
                    },
                );
            }

            if (limited) break;
        }
    }

    return moves;
}

fn getCastling(match: *Match, pos: Pos, king: Piece) PieceMoveList {
    var moves = PieceMoveList{};
    const coords = pos.coords();

    for ([2]u3{ 0, 7 }) |x| {
        const shift: u2 = (if (x == 0) @as(u2, 1) else 0) + (if (king.isWhite()) @as(u2, 0) else 2);
        const flag: u4 = @as(u4, 1) << shift;

        if ((flag & match.castling_rights) == 0) continue;
        const dst = Pos.fromXY(x, coords.y);
        const rook = match.board.at(dst);

        if (rook.type != .Rook or !rook.isSameColour(king)) continue;

        var curr: u3 = @min(x, coords.x) + 1;
        const end: u3 = @max(x, coords.x);

        var can_castle = true;
        while (can_castle and curr < end) : (curr += 1) {
            const piece = match.board.at(
                Pos.fromXY(curr, coords.y),
            );
            if (piece.type == .None) {
                const king_move: Move = .{
                    .org = Pos.fromXY(coords.x, coords.y),
                    .dst = Pos.fromXY(curr, coords.y),
                };
                if (!validMove(match, king_move)) {
                    can_castle = false;
                    break;
                }
            }
            can_castle = false;
        }

        if (can_castle) {
            moves.append(.{
                .org = pos,
                .dst = dst,
                .flag = .Castling,
            });
        }
    }
    return moves;
}

fn filterMoves(
    match: *Match,
    comptime capacity: usize,
    moves: List(Move, capacity),
) List(
    Move,
    capacity,
) {
    var filtered_moves = List(
        Move,
        capacity,
    ){};

    for (moves.items()) |move| {
        if (validMove(match, move)) {
            filtered_moves.append(move);
        }
    }
    return filtered_moves;
}

fn validMove(match: *Match, move: Move) bool {
    const undo = executeMove(match, move);
    const valid = !check(match, match.turn);
    undoMove(match, move, undo);
    return valid;
}

pub fn check(match: *Match, colour: Colour) bool {
    for (match.board.pieces, 0..) |piece, i| {
        if (piece.type != .None and !piece.isColour(colour)) {
            const moves = getPieceMoves(
                match,
                Pos.fromIndex(i),
            );

            for (moves.items()) |move| {
                const captured = match.board.at(move.dst);
                if (captured.type == .King and captured.isColour(colour)) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn cantPlay(match: *Match, colour: Colour) bool {
    for (match.board.pieces, 0..) |piece, i| {
        if (piece.type != .None and piece.isColour(colour)) {
            const moves = getPieceMoves(
                match,
                Pos.fromIndex(i),
            );

            for (moves.items()) |move| {
                if (validMove(match, move)) return false;
            }
        }
    }

    return true;
}

pub fn checkmate(match: *Match, colour: Colour) bool {
    return check(match, match.turn) and cantPlay(match, colour);
}
pub fn stalemate(match: *Match, colour: Colour) bool {
    return !check(match, match.turn) and cantPlay(match, colour);
}
