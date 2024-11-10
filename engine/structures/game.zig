const std = @import("std");
const allocator = std.heap.page_allocator;

pub const Piece = struct {
    pub const Type = enum { Pawn, Bishop, Knight, Rook, Queen, King };
    type: Type,
    white: bool,

    pub fn toString(self: *const Piece) u8 {
        return switch (self.type) {
            .Pawn => 'P',
            .Rook => 'R',
            .Knight => 'H',
            .Bishop => 'B',
            .Queen => 'Q',
            .King => 'K',
        };
    }

    pub fn isSameColor(self: *const Piece, p2: *const Piece) bool {
        return self.white == p2.white;
    }
};

pub const Board = [8][8]?*Piece;

pub const Game = struct {
    const Self = @This();
    board: Board = .{.{null} ** 8} ** 8,
    white_turn: bool = true,

    pub fn init(self: *Self) !void {
        try self.initBoard();
    }

    fn initBoard(self: *Self) !void {
        for (0..8) |x| {
            try initPeace(self, x, 1, .Pawn, false);
            try initPeace(self, x, 6, .Pawn, true);
        }
        const layout = [8]Piece.Type{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };
        for (0.., layout) |x, piece_type| {
            try initPeace(self, x, 0, piece_type, false);
            try initPeace(self, x, 7, piece_type, true);
        }
    }

    fn initPeace(self: *Self, x: usize, y: usize, piece_type: Piece.Type, white: bool) !void {
        self.board[y][x] = try allocator.create(Piece);
        self.board[y][x].?.* = .{ .type = piece_type, .white = white };
    }

    pub fn print(self: *Game) void {
        for (0..8) |row| {
            var rowBuf: [8]u8 = .{0} ** 8;
            for (0..8) |col| {
                const piece = self.board[row][col];
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
