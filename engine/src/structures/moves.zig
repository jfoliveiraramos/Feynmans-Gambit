const std = @import("std");
const game = @import("game.zig");

const ArrayList = std.ArrayList;
const Board = game.Board;
const Piece = game.Piece;
const Pos = game.Pos;

pub const Move = struct {
    piece: *Piece,
    captured: ?*Piece = null,
    type: enum { Quiet, Capture, Castling },
    promotion: bool = false,
    org: Pos,
    dest: Pos,

    pub fn eq(self: Move, other: Move) bool {
        return self.dest.x == other.dest.x and self.dest.y == other.dest.y and self.promotion == other.promotion and self.type == other.type;
    }
};

pub fn executeMove(board: *Board, move: Move) void {
    board.set(null, move.org.x, move.org.y);
    board.set(move.piece, move.dest.x, move.dest.y);

    if (move.promotion) {
        move.piece.type = .Queen;
    }
}

pub fn reverseMove(board: *Board, move: Move) void {
    board.set(move.piece, move.org.x, move.org.y);
    board.set(move.captured, move.dest.x, move.dest.y);
}

pub fn getMoves(board: *Board, pos: Pos) ?ArrayList(Move) {
    if (board.at(pos.x, pos.y)) |piece| {
        return switch (piece.type) {
            .Pawn => getPawnMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .Rook => getRookMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .Bishop => getBishopMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .Knight => getKnightMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .Queen => getQueenMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .King => getKingMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
        };
    }
    return null;
}

fn hasPawnMoved(piece: *Piece, y: usize) bool {
    return (piece.color == .Black and y != 1) or (piece.color == .White and y != 6);
}

fn getPawnMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    const limit: usize = if (hasPawnMoved(piece, pos.y)) 2 else 3;
    for (1..limit) |i| {
        const spot = board.at(pos.x, pos.y + i);
        if (spot) |target| {
            if (!piece.isSameColor(target)) {
                moves.append(.{
                    .piece = piece,
                    .captured = target,
                    .type = .Capture,
                    .promotion = pos.y == 0 or pos.y == 7,
                    .org = pos,
                    .dest = .{
                        .x = pos.x,
                        .y = pos.y + i,
                    },
                }) catch |err| {
                    std.debug.print("Error: {}", .{err});
                };
            }
        } else {
            moves.append(.{
                .piece = piece,
                .type = .Quiet,
                .promotion = pos.y == 0 or pos.y == 7,
                .org = pos,
                .dest = .{
                    .x = pos.x,
                    .y = pos.y + i,
                },
            }) catch |err| {
                std.debug.print("Error: {}", .{err});
            };
        }
    }
    return moves;
}

fn getRookMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        board,
        pos,
        piece,
        &[_][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } },
        false,
    );
}
fn getBishopMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        board,
        pos,
        piece,
        &[_][2]i8{ .{ 1, 1 }, .{ 1, -1 }, .{ -1, 1 }, .{ -1, -1 } },
        false,
    );
}

fn getKnightMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        board,
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

fn getQueenMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        board,
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

fn getKingMoves(board: *Board, pos: Pos, piece: *Piece) ArrayList(Move) {
    return getMovesInDirection(
        board,
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
}

fn getMovesInDirection(board: *Board, pos: Pos, piece: *Piece, directions: []const [2]i8, limited: bool) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);
    for (directions) |dpos| {
        var i: i8 = 1;
        while (true) : (i += 1) {
            const new_x = @as(i8, @intCast(pos.x)) + dpos[0] * i;
            const new_y = @as(i8, @intCast(pos.y)) + dpos[1] * i;
            if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;

            const ux: usize = @intCast(new_x);
            const uy: usize = @intCast(new_y);
            if (board.at(ux, uy)) |target| {
                if (target.color != piece.color) {
                    moves.append(.{
                        .piece = piece,
                        .captured = target,
                        .type = .Capture,
                        .promotion = false,
                        .org = pos,
                        .dest = .{ .x = ux, .y = uy },
                    }) catch |err| {
                        std.debug.print("Error: {}", .{err});
                    };
                }
                break;
            } else {
                moves.append(
                    .{
                        .piece = piece,
                        .captured = null,
                        .type = .Quiet,
                        .promotion = false,
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
