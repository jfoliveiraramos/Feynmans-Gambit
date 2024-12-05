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

pub fn getMoves(board: *Board, pos: struct { x: usize, y: usize }) ?ArrayList(Move) {
    if (board.at(pos.x, pos.y)) |piece| {
        return switch (piece.type) {
            .Pawn => getPawnMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            .Rook => getRookMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            else => unreachable,
            // .Bishop => getBishopMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            // .Knight => getKnightMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            // .Queen => getQueenMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
            // .King => getKingMoves(board, .{ .x = pos.x, .y = pos.y }, piece),
        };
    }
    return null;
}

fn hasPawnMoved(piece: *Piece, y: usize) bool {
    return (piece.color == .Black and y != 1) or (piece.color == .White and y != 6);
}

fn getPawnMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    const limit: usize = if (hasPawnMoved(piece, pos.y)) 2 else 3;
    for (1..limit) |i| {
        const spot = board.at(pos.x, pos.y + i);
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

fn getRookMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
    var moves = ArrayList(Move).init(std.heap.page_allocator);

    const x = pos.x;
    const y = pos.y;
    for ([4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } }) |dpos| {
        var i: i8 = 1;
        while (true) : (i += 1) {
            const new_x = @as(i8, @intCast(x)) + dpos[0] * i;
            const new_y = @as(i8, @intCast(y)) + dpos[1] * i;
            if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;

            const ux: usize = @intCast(new_x);
            const uy: usize = @intCast(new_y);
            if (board.at(ux, uy)) |target| {
                if (target.color != piece.color) {
                    moves.append(.{
                        .type = .Capture,
                        .promotion = false,
                        .dest = .{ .x = ux, .y = uy },
                    }) catch |err| {
                        std.debug.print("Error: {}", .{err});
                    };
                }
                break;
            } else {
                moves.append(
                    .{
                        .type = .Quiet,
                        .promotion = false,
                        .dest = .{ .x = ux, .y = uy },
                    },
                ) catch |err| {
                    std.debug.print("Error: {}", .{err});
                };
            }
        }
    }

    return moves;
}
// fn getBishopMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
//     var moves = ArrayList(Move).init(std.heap.page_allocator);
//     for ([4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } }) |dpos| {
//         var i: usize = 1;
//         while (true) : (i += 1) {
//             const new_y = pos.y + dpos[1] * i;
//             const new_x = pos.x + dpos[0] * i;
//             if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;
//             if (board.at(new_x, new_y)) |target| {
//                 if (target.color != piece.color) {
//                     moves.append(.{ .Capture, false, .{ new_x, new_y } });
//                 }
//                 break;
//             } else {
//                 moves.append(.{ .Capture, false, .{ new_x, new_y } });
//             }
//         }
//     }
//     return moves;
// }
//
// fn getKnightMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
//     var moves = ArrayList(Move).init(std.heap.page_allocator);
//     for ([4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } }) |dpos| {
//         var i: usize = 1;
//         while (true) : (i += 1) {
//             const new_y = pos.y + dpos[1] * i;
//             const new_x = pos.x + dpos[0] * i;
//             if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;
//             if (board.at(new_x, new_y)) |target| {
//                 if (target.color != piece.color) {
//                     moves.append(.{ .Capture, false, .{ new_x, new_y } });
//                 }
//                 break;
//             } else {
//                 moves.append(.{ .Capture, false, .{ new_x, new_y } });
//             }
//         }
//     }
//     return moves;
// }
//
// fn getQueenMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
//     var moves = ArrayList(Move).init(std.heap.page_allocator);
//     for ([4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } }) |dpos| {
//         var i: usize = 1;
//         while (true) : (i += 1) {
//             const new_y = pos.y + dpos[1] * i;
//             const new_x = pos.x + dpos[0] * i;
//             if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;
//             if (board.at(new_x, new_y)) |target| {
//                 if (target.color != piece.color) {
//                     moves.append(.{ .Capture, false, .{ new_x, new_y } });
//                 }
//                 break;
//             } else {
//                 moves.append(.{ .Capture, false, .{ new_x, new_y } });
//             }
//         }
//     }
//     return moves;
// }
//
// fn getKingMoves(board: *Board, pos: struct { x: usize, y: usize }, piece: *Piece) ArrayList(Move) {
//     var moves = ArrayList(Move).init(std.heap.page_allocator);
//     for ([4][2]i8{ .{ -1, 0 }, .{ 1, 0 }, .{ 0, -1 }, .{ 0, 1 } }) |dpos| {
//         var i: usize = 1;
//         while (true) : (i += 1) {
//             const new_y = pos.y + dpos[1] * i;
//             const new_x = pos.x + dpos[0] * i;
//             if (new_y < 0 or new_x < 0 or new_x >= 8 or new_y >= 8) break;
//             if (board.at(new_x, new_y)) |target| {
//                 if (target.color != piece.color) {
//                     moves.append(.{ .Capture, false, .{ new_x, new_y } });
//                 }
//                 break;
//             } else {
//                 moves.append(.{ .Capture, false, .{ new_x, new_y } });
//             }
//         }
//     }
//     return moves;
// }
