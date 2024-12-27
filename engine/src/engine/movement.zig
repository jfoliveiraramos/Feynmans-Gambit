const std = @import("std");
const game = @import("game.zig");

const ArrayList = std.ArrayList;
const Match = game.Match;
const Piece = game.Piece;
const Color = Piece.Color;
const Pos = game.Pos;

pub const Move = struct {
    type: enum { Quiet, Capture, Castling, EnPassant },
    piece: *Piece,
    promotion: bool = false,
    org: Pos,
    dest: Pos,

    capture: ?struct { piece: *Piece, pos: Pos } = null,

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

pub fn executeMove(match: *Match, move: Move) void {
    match.board.set(null, move.org.x, move.org.y);

    if (move.capture) |capture| {
        capture.piece.alive = false;
        match.board.set(null, capture.pos.x, capture.pos.y);
    }

    if (move.type == .Castling) {
        const rook = match.board.at(move.dest.x, move.dest.y);
        const x: u8 = if (move.dest.x == 7) 6 else 1;
        match.board.set(rook, x, move.dest.y);
    }
    match.board.set(move.piece, move.dest.x, move.dest.y);

    if (move.promotion) {
        move.piece.type = .Queen;
    }
    if (move.piece.type == .Pawn and @abs(@as(i8, @intCast(move.dest.y)) - @as(i8, @intCast(move.org.y))) == 2) {
        match.double_pawns.append(move.piece) catch |err| {
            std.debug.print("Error: {}", .{err});
        };
    } else {
        match.double_pawns.append(null) catch |err| {
            std.debug.print("Error: {}", .{err});
        };
    }
    move.piece.has_moved = true;
}

pub fn undoMove(match: *Match, move: Move) void {
    match.board.set(move.piece, move.org.x, move.org.y);

    match.board.set(null, move.dest.x, move.dest.y);

    if (move.type == .Castling) {
        const x: u8 = if (move.dest.x == 7) 6 else 1;
        const rook = match.board.at(x, move.dest.y);
        match.board.set(rook, move.dest.x, move.dest.y);
        match.board.set(null, x, move.dest.y);
    }

    if (move.capture) |capture| {
        capture.piece.alive = true;
        match.board.set(capture.piece, capture.pos.x, capture.pos.y);
    }

    if (move.promotion) {
        move.piece.type = .Pawn;
    }

    _ = match.double_pawns.pop();

    move.piece.has_moved = false;
}

fn getMoves(match: *Match, pos: Pos) ArrayList(Move) {
    if (match.board.at(pos.x, pos.y)) |piece| {
        return switch (piece.type) {
            .Pawn => getPawnMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
            .Rook => getRookMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
            .Bishop => getBishopMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
            .Knight => getKnightMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
            .Queen => getQueenMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
            .King => getKingMoves(match, .{ .x = pos.x, .y = pos.y }, piece),
        };
    }
    return ArrayList(Move).init(std.heap.page_allocator);
}

pub fn getPlayableMoves(match: *Match, pos: Pos) ArrayList(Move) {
    return filterMoves(match, getMoves(match, pos));
}

fn hasPawnMoved(piece: *Piece, y: usize) bool {
    return (piece.color == .Black and y != 1) or (piece.color == .White and y != 6);
}

fn getPawnMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    const vdir: i8 = if (piece.color == .White) -1 else 1;

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
            moves.append(.{
                .piece = piece,
                .type = .Quiet,
                .promotion = uy == 0 or uy == 7,
                .org = pos,
                .dest = .{
                    .x = pos.x,
                    .y = uy,
                },
            }) catch |err| {
                std.debug.print("Error: {}", .{err});
            };
        }
    }

    for ([2]i8{ -1, 1 }) |hdir| {
        const new_x: i8 = @as(i8, @intCast(pos.x)) + hdir;
        const new_y: i8 = @as(i8, @intCast(pos.y)) + vdir;
        if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) continue;
        const ux: usize = @intCast(new_x);
        const uy: usize = @intCast(new_y);
        if (match.board.at(ux, uy)) |target| {
            if (target.color != piece.color) {
                moves.append(.{
                    .piece = piece,
                    .type = .Capture,
                    .capture = .{
                        .piece = target,
                        .pos = .{
                            .x = ux,
                            .y = uy,
                        },
                    },
                    .promotion = uy == 0 or uy == 7,
                    .org = pos,
                    .dest = .{
                        .x = ux,
                        .y = uy,
                    },
                }) catch |err| {
                    std.debug.print("Error: {}", .{err});
                };
            }
        }
        if (match.double_pawns.getLast()) |double| {
            if (match.board.at(ux, pos.y)) |target| {
                if (target == double and target.color != piece.color) {
                    moves.append(.{
                        .piece = piece,
                        .type = .EnPassant,
                        .capture = .{
                            .piece = target,
                            .pos = .{
                                .x = ux,
                                .y = pos.y,
                            },
                        },
                        .promotion = uy == 0 or uy == 7,
                        .org = pos,
                        .dest = .{
                            .x = ux,
                            .y = uy,
                        },
                    }) catch |err| {
                        std.debug.print("Error: {}", .{err});
                    };
                }
            }
        }
    }
    return moves;
}

fn getRookMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        match,
        pos,
        piece,
        &[_][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } },
        false,
    );
}
fn getBishopMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        match,
        pos,
        piece,
        &[_][2]i8{ .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } },
        false,
    );
}

fn getKnightMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
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

fn getQueenMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
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
}

fn getKingMoves(match: *Match, pos: Pos, piece: *Piece) ArrayList(Move) {
    var moves = getMovesInDirection(
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

    moves.appendSlice(getCastling(match, pos, piece).items) catch |err| {
        std.debug.print("Error: {}", .{err});
    };

    return moves;
}

fn getMovesInDirection(match: *Match, pos: Pos, piece: *Piece, directions: []const [2]i8, limited: bool) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);
    for (directions) |dpos| {
        var i: i8 = 1;
        while (true) : (i += 1) {
            const new_x = @as(i8, @intCast(pos.x)) + dpos[0] * i;
            const new_y = @as(i8, @intCast(pos.y)) + dpos[1] * i;
            if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;

            const ux: usize = @intCast(new_x);
            const uy: usize = @intCast(new_y);
            if (match.board.at(ux, uy)) |target| {
                if (target.color != piece.color) {
                    moves.append(.{
                        .piece = piece,
                        .type = .Capture,
                        .org = pos,
                        .dest = .{ .x = ux, .y = uy },
                        .capture = .{
                            .piece = target,
                            .pos = .{ .x = ux, .y = uy },
                        },
                    }) catch |err| {
                        std.debug.print("Error: {}", .{err});
                    };
                }
                break;
            } else {
                moves.append(
                    .{
                        .piece = piece,
                        .type = .Quiet,
                        .org = pos,
                        .dest = .{ .x = ux, .y = uy },
                    },
                ) catch |err| {
                    std.debug.print("Error: {}", .{err});
                };
            }
            if (limited) break;
        }
    }
    return moves;
}

fn getCastling(match: *Match, pos: Pos, king: *Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    if (king.has_moved) return moves;

    for ([2]u8{ 0, 7 }) |x| {
        if (match.board.at(x, pos.y)) |rook| {
            if (rook.type != .Rook) continue;
            if (rook.has_moved) continue;

            moves.append(.{
                .type = .Castling,
                .dest = .{ .x = x, .y = pos.y },
                .org = pos,
                .piece = king,
            }) catch |err| {
                std.debug.print("Error: {}", .{err});
            };
        }
    }
    return moves;
}

fn filterMoves(match: *Match, moves: ArrayList(Move)) ArrayList(Move) {
    var filtered_moves = ArrayList(Move).init(std.heap.page_allocator);

    for (moves.items) |move| {
        executeMove(match, move);
        if (!inCheck(match, match.turn)) {
            filtered_moves.append(move) catch |err| {
                std.debug.print("Error: {}", .{err});
            };
        }
        undoMove(match, move);
    }
    return filtered_moves;
}
fn inCheck(match: *Match, color: Color) bool {
    for (match.board.pieces, 0..) |spot, i| {
        if (spot) |piece| {
            if (piece.color != color) {
                const moves = getMoves(match, .{
                    .x = i % 8,
                    .y = i / 8,
                });

                for (moves.items) |move| {
                    if (move.capture) |capture| {
                        if (capture.piece.type == .King) return true;
                    }
                }
            }
        }
    }
    return false;
}
