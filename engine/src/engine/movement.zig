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
const Colour = Piece.Colour;
const Pos = game.Pos;

pub const Move = struct {
    type: enum { Quiet, Capture, Castling, EnPassant },
    piece: Piece,
    org: Pos,
    dest: Pos,
    promotion: ?Piece.Type = null,
    capture: ?struct { piece: Piece, pos: Pos } = null,

    pub fn eq(self: Move, other: Move) bool {
        return self.dest.x == other.dest.x and self.dest.y == other.dest.y and self.promotion == other.promotion and self.type == other.type;
    }

    pub fn print(self: Move) void {
        const move_type = switch (self.type) {
            .Quiet => "Move",
            .Capture => "Capture",
            .Castling => "Castling",
            .EnPassant => "EnPassant",
        };
        std.debug.print("{s}: ({},{})\n", .{ move_type, self.dest.x, self.dest.y });
    }
};

const MAX_PIECE_MOVES = 27;
const MAX_MOVES = 256;

pub const PieceMoveList = List(Move, MAX_PIECE_MOVES);
pub const MoveList = List(Move, MAX_MOVES);

pub fn executeMove(match: *Match, move: Move) ?Pos {
    match.board.set(null, move.org.x, move.org.y);

    if (move.capture) |capture| {
        match.board.set(null, capture.pos.x, capture.pos.y);
    }

    if (move.type == .Castling) {
        const rook = match.board.at(move.dest.x, move.dest.y);
        const x: u8 = if (move.dest.x == 7) 6 else 1;
        match.board.set(rook, x, move.dest.y);
    }
    match.board.set(move.piece, move.dest.x, move.dest.y);

    if (move.promotion) |new_type| {
        match.board.set(move.piece.promoteTo(new_type), move.dest.x, move.dest.y);
    }
    if (move.piece.type == .Pawn and @abs(@as(i8, @intCast(move.dest.y)) - @as(i8, @intCast(move.org.y))) == 2) {
        const previous_en_passant = match.en_passant;
        match.en_passant = move.dest;
        return previous_en_passant;
    }
    return null;
}

pub fn undoMove(match: *Match, move: Move, prev_en_passant: ?Pos) void {
    const piece = if (move.promotion) |_| move.piece.promoteTo(.Pawn) else move.piece;

    match.board.set(piece, move.org.x, move.org.y);

    if (move.type == .Castling) {
        const x: u8 = if (move.dest.x == 7) 6 else 1;
        const rook = match.board.at(x, move.dest.y);
        match.board.set(rook, move.dest.x, move.dest.y);
        match.board.set(null, x, move.dest.y);
    }

    if (move.capture) |capture| {
        match.board.set(capture.piece, capture.pos.x, capture.pos.y);
    } else {
        match.board.set(null, move.dest.x, move.dest.y);
    }

    match.en_passant = prev_en_passant;
}

fn getPieceMoves(match: *Match, pos: Pos) PieceMoveList {
    if (match.board.at(pos.x, pos.y)) |piece| {
        return switch (piece.type) {
            .Pawn => getPawnMoves(match, pos, piece),
            .Rook => getRookMoves(match, pos, piece),
            .Bishop => getBishopMoves(match, pos, piece),
            .Knight => getKnightMoves(match, pos, piece),
            .Queen => getQueenMoves(match, pos, piece),
            .King => getKingMoves(match, pos, piece),
        };
    }
    return PieceMoveList{};
}

pub fn getPiecePlayableMoves(match: *Match, pos: Pos) PieceMoveList {
    const pieceMoves = getPieceMoves(match, pos);
    return filterMoves(match, MAX_PIECE_MOVES, pieceMoves);
}

fn hasPawnMoved(piece: Piece, y: usize) bool {
    return (piece.colour == .White and y != 6) or (piece.colour == .Black and y != 1);
}

fn getPawnMoves(match: *Match, pos: Pos, piece: Piece) PieceMoveList {
    var moves = PieceMoveList{};

    const vdir: i8 = if (piece.colour == .White) -1 else 1;

    const range: []const i8 = if (hasPawnMoved(piece, pos.y)) &.{
        1 * vdir,
    } else &.{
        1 * vdir,
        2 * vdir,
    };
    for (range) |i| {
        const new_y = @as(i8, @intCast(pos.y)) + i;
        if (new_y < 0 or new_y >= 8) break;
        const uy: usize = @intCast(new_y);
        if (match.board.at(pos.x, uy) == null) {
            var move = Move{
                .piece = piece,
                .type = .Quiet,
                .promotion = null,
                .org = pos,
                .dest = .{
                    .x = @intCast(pos.x),
                    .y = @intCast(uy),
                },
            };
            if (uy == 0 or uy == 7) {
                const promotable: [4]Piece.Type = .{ .Queen, .Rook, .Bishop, .Knight };
                for (promotable) |piece_type| {
                    move.promotion = piece_type;
                    _ = moves.append(move);
                }
            } else {
                _ = moves.append(move);
            }
        }
    }

    for ([2]i8{ -1, 1 }) |hdir| {
        const new_x: i8 = @as(i8, @intCast(pos.x)) + hdir;
        const new_y: i8 = @as(i8, @intCast(pos.y)) + vdir;
        if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) continue;
        const ux: usize = @intCast(new_x);
        const uy: usize = @intCast(new_y);
        if (match.board.at(ux, uy)) |target| {
            if (target.colour != piece.colour) {
                var move = Move{
                    .piece = piece,
                    .type = .Capture,
                    .capture = .{
                        .piece = target,
                        .pos = .{
                            .x = @intCast(ux),
                            .y = @intCast(uy),
                        },
                    },
                    .org = pos,
                    .dest = .{
                        .x = @intCast(ux),
                        .y = @intCast(uy),
                    },
                };
                if (uy == 0 or uy == 7) {
                    const promotable: [4]Piece.Type = .{ .Queen, .Rook, .Bishop, .Knight };
                    for (promotable) |piece_type| {
                        move.promotion = piece_type;
                        _ = moves.append(move);
                    }
                } else {
                    _ = moves.append(move);
                }
            }
        }
        if (match.en_passant) |en_passant_pos| {
            if (match.board.at(en_passant_pos.x, en_passant_pos.y)) |target| {
                _ = moves.append(.{
                    .piece = piece,
                    .type = .EnPassant,
                    .capture = .{
                        .piece = target,
                        .pos = .{
                            .x = @intCast(ux),
                            .y = @intCast(pos.y),
                        },
                    },
                    .org = pos,
                    .dest = .{
                        .x = @intCast(ux),
                        .y = @intCast(uy),
                    },
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
    for (directions) |dpos| {
        var i: i8 = 1;
        while (true) : (i += 1) {
            const new_x = @as(i8, @intCast(pos.x)) + dpos[0] * i;
            const new_y = @as(i8, @intCast(pos.y)) + dpos[1] * i;
            if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;

            const ux: usize = @intCast(new_x);
            const uy: usize = @intCast(new_y);
            if (match.board.at(ux, uy)) |target| {
                if (target.colour != piece.colour) {
                    _ = moves.append(.{
                        .piece = piece,
                        .type = .Capture,
                        .org = pos,
                        .dest = .{ .x = @intCast(ux), .y = @intCast(uy) },
                        .capture = .{
                            .piece = target,
                            .pos = .{ .x = @intCast(ux), .y = @intCast(uy) },
                        },
                    });
                }
                break;
            } else {
                _ = moves.append(
                    .{
                        .piece = piece,
                        .type = .Quiet,
                        .org = pos,
                        .dest = .{ .x = @intCast(ux), .y = @intCast(uy) },
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

    for ([2]usize{ 0, 7 }) |x| {
        const shift: u2 = (if (x == 0) @as(u2, 1) else 0) + (if (king.colour == .White) @as(u2, 0) else 2);
        const flag: u4 = @as(u4, 1) << shift;

        if ((flag & match.castle_availability) == 0) continue;
        if (match.board.at(x, pos.y)) |rook| {
            if (rook.type != .Rook) continue;
            if (rook.colour != king.colour) continue;

            const start: usize = (if (x < pos.x) x else pos.x) + 1;
            const end: usize = (if (x < pos.x) pos.x else x);

            var can_castle = true;
            for (start..end) |curr| {
                if (match.board.at(curr, pos.y)) |_| {
                    can_castle = false;
                    break;
                }

                const king_move: Move = .{
                    .type = .Quiet,
                    .dest = .{ .x = @intCast(curr), .y = @intCast(pos.y) },
                    .org = .{ .x = @intCast(pos.x), .y = @intCast(pos.y) },
                    .piece = king,
                };
                if (!validMove(match, king_move)) {
                    can_castle = false;
                    break;
                }
            }

            if (can_castle) {
                _ = moves.append(.{
                    .type = .Castling,
                    .dest = .{ .x = @intCast(x), .y = @intCast(pos.y) },
                    .org = pos,
                    .piece = king,
                });
            }
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
            _ = filtered_moves.append(move);
        }
    }
    return filtered_moves;
}

fn validMove(match: *Match, move: Move) bool {
    const prev_en_passant = executeMove(match, move);
    const valid = !check(match, match.turn);
    undoMove(match, move, prev_en_passant);
    return valid;
}

pub fn check(match: *Match, colour: Colour) bool {
    for (match.board.pieces, 0..) |spot, i| {
        if (spot) |piece| {
            if (piece.colour != colour) {
                const moves = getPieceMoves(match, .{
                    .x = @intCast(i % 8),
                    .y = @intCast(i / 8),
                });

                for (moves.items()) |move| {
                    if (move.capture) |capture| {
                        if (capture.piece.type == .King) return true;
                    }
                }
            }
        }
    }
    return false;
}

fn cantPlay(match: *Match, colour: Colour) bool {
    for (match.board.pieces, 0..) |spot, i| {
        if (spot) |piece| {
            if (piece.colour == colour) {
                const moves = getPieceMoves(match, .{
                    .x = @intCast(i % 8),
                    .y = @intCast(i / 8),
                });

                for (moves.items()) |move| {
                    if (validMove(match, move)) return false;
                }
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
