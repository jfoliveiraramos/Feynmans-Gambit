const std = @import("std");

pub const Piece = struct {
    const Self = @This();
    pub const Type = enum { Pawn, Bishop, Knight, Rook, Queen, King };
    type: Type,
    white: bool,

    pub fn toString(self: Piece) u8 {
        return switch (self.type) {
            .Pawn => 'P',
            .Rook => 'R',
            .Knight => 'H',
            .Bishop => 'B',
            .Queen => 'Q',
            .King => 'K',
        };
    }

    pub fn fromString(c: u8, white: bool) ?Piece {
        return switch (c) {
            'P' => .{ .type = .Pawn, .white = white },
            'R' => .{ .type = .Rook, .white = white },
            'H' => .{ .type = .Knight, .white = white },
            'B' => .{ .type = .Bishop, .white = white },
            'Q' => .{ .type = .Queen, .white = white },
            'K' => .{ .type = .King, .white = white },
            '.' => null,
            else => {
                std.debug.print("Unreachable character: {}\n", .{c});
                unreachable;
            },
        };
    }
    pub fn isSameColor(self: Self, p2: Piece) bool {
        return self.white == p2.white;
    }
};

pub const Board = [64]?Piece;

pub const Game = struct {
    const Self = @This();
    board: Board = .{null} ** 64,
    white_turn: bool = true,

    pub fn init(self: *Self) void {
        self.initBoard();
    }

    fn initBoard(self: *Self) void {
        for (0..8) |x| {
            initPeace(self, x, 1, .Pawn, false);
            initPeace(self, x, 6, .Pawn, true);
        }
        const layout = [8]Piece.Type{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };
        for (0.., layout) |x, piece_type| {
            initPeace(self, x, 0, piece_type, false);
            initPeace(self, x, 7, piece_type, true);
        }
    }

    fn initPeace(self: *Self, x: usize, y: usize, piece_type: Piece.Type, white: bool) void {
        self.board[y * 8 + x] = .{
            .type = piece_type,
            .white = white,
        };
    }

    pub fn print(self: *Game) void {
        for (0..8) |row| {
            var rowBuf: [8]u8 = .{0} ** 8;
            for (0..8) |col| {
                const piece = self.board[row * 8 + col];
                if (piece == null) {
                    rowBuf[col] = '.'; // Empty square
                } else {
                    rowBuf[col] = piece.?.toString();
                }
            }
            std.debug.print("{s}\n", .{rowBuf});
        }
    }

    pub fn nextTurn(self: *Game) void {
        self.white_turn = !self.white_turn;
    }

    pub fn printTurn(self: *Game) void {
        if (self.white_turn) {
            std.debug.print("It is Player 1's turn!\n", .{});
        } else {
            std.debug.print("It is Player 2's turn!\n", .{});
        }
    }
};
