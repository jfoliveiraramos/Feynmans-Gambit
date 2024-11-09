const std = @import("std");

const Piece = struct {
    type: enum { Pawn, Bishop, Knight, Rook, Queen, King },
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
};

const Game = struct {
    board: [8][8]?*const Piece = .{.{null} ** 8} ** 8,
    white_turn: bool = true,

    pub fn init(self: *Game) void {
        initBoard(self);
    }

    fn initBoard(self: *Game) void {
        for (0..8) |i| {
            self.board[1][i] = &Piece{ .type = .Pawn, .white = true };
        }
        self.board[0][0] = &Piece{ .type = .Rook, .white = false };
        self.board[0][1] = &Piece{ .type = .Knight, .white = false };
        self.board[0][2] = &Piece{ .type = .Bishop, .white = false };
        self.board[0][3] = &Piece{ .type = .Queen, .white = false };
        self.board[0][4] = &Piece{ .type = .King, .white = false };
        self.board[0][5] = &Piece{ .type = .Bishop, .white = false };
        self.board[0][6] = &Piece{ .type = .Knight, .white = false };
        self.board[0][7] = &Piece{ .type = .Rook, .white = false };

        for (0..8) |i| {
            self.board[6][i] = &Piece{ .type = .Pawn, .white = false };
        }
        self.board[7][0] = &Piece{ .type = .Rook, .white = true };
        self.board[7][1] = &Piece{ .type = .Knight, .white = true };
        self.board[7][2] = &Piece{ .type = .Bishop, .white = true };
        self.board[7][3] = &Piece{ .type = .Queen, .white = true };
        self.board[7][4] = &Piece{ .type = .King, .white = true };
        self.board[7][5] = &Piece{ .type = .Bishop, .white = true };
        self.board[7][6] = &Piece{ .type = .Knight, .white = true };
        self.board[7][7] = &Piece{ .type = .Rook, .white = true };
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

pub fn main() void {
    var game: Game = .{};

    game.init();

    game.print();
}
