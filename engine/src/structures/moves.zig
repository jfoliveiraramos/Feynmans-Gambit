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

    pub fn eq(self: Move, other: Move) bool {
        return self.dest.x == other.dest.x and self.dest.y == other.dest.y and self.promotion == other.promotion and self.type == other.type;
    }
};

pub fn getMoves(board: Board, pos: struct { x: usize, y: usize }) ?ArrayList(Move) {
    if (board[pos.y * 8 + pos.x]) |piece| {
        return switch (piece.type) {
            .Pawn => getPawnMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            else => unreachable,
        };
    }
    return null;
}

fn getPawnMoves(board: Board, pos: struct { x: usize, y: usize }, piece: Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    for (1..3) |i| {
        // if (i == 2 and ((piece.white and pos.y != 7) or (!piece.white and pos.y != 1))) {
        //     continue;
        // }

        const spot = board[(pos.y + i) * 8 + pos.x];
        if (spot) |target| {
            if (!piece.isSameColor(target)) {
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
