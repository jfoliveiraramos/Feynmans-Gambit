const std = @import("std");
const game = @import("game.zig");
const ArrayList = std.ArrayList;
const Board = game.Board;
const Piece = game.Piece;

pub const Move = struct {
    type: enum { Quiet, Capture, Castling },
    promotion: bool = false,
    dest: struct {
        x: usize,
        y: usize,
    },
};

pub fn getMoves(board: Board, pos: struct { x: usize, y: usize }) ArrayList(Move) {
    const piece = board[pos.y][pos.x].?;

    return switch (piece.type) {
        .Pawn => getPawnMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
        else => ArrayList(Move).init(std.heap.page_allocator),
    };
}

fn getPawnMoves(board: Board, pos: struct { x: usize, y: usize }, piece: *const Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    for (1..3) |i| {
        const target = board[pos.y + i][pos.x];
        if (target != null) {
            if (!piece.isSameColor(target.?)) {
                moves.append(.{
                    .type = .Capture,
                    .promotion = false,
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
                .type = .Quiet,
                .promotion = false,
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
