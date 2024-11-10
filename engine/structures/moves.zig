const std = @import("std");
const game = @import("game.zig");
const ArrayList = std.ArrayList;
const Board = game.Board;
const Piece = game.Piece;

pub const Move = struct {
    type: enum { Quiet, Capture, Castling },
    promotion: bool = false,
    destination: struct {
        x: i32,
        y: i32,
    },
};

pub fn getMoves(board: Board, pos: struct { x: usize, y: usize }) ArrayList(Move) {
    const piece = board[pos.y][pos.x].?;

    return switch (piece.type) {
        .Pawn => getPawnMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
        else => ArrayList(Move).init(std.heap.HeapAllocator),
    };
}

fn getPawnMoves(board: Board, pos: struct { x: usize, y: usize }, piece: *const Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.HeapAllocator);

    const target = board[pos.y + 1][pos.x];

    if (target != null) {
        if (!piece.isSameColor(target)) {
            moves.append(.{ .Capture, false, .{ .x, .y + 1 } });
        }
    } else {
        moves.append(.{ .Quiet, false, .{ .x, .y + 1 } });
    }

    target = board[pos.y + 2][pos.x];

    return moves;
}
