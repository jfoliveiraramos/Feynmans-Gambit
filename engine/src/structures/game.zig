const std = @import("std");
const ArrayList = std.ArrayList;

pub const Pos = struct { x: usize, y: usize };

pub const Piece = struct {
    const Self = @This();
    pub const Type = enum { Pawn, Bishop, Knight, Rook, Queen, King };
    pub const Color = enum { White, Black };
    type: Type,
    color: Color,

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

    pub fn fromString(c: u8, color: Piece.Color) ?Piece {
        return switch (c) {
            'P' => .{ .type = .Pawn, .color = color },
            'R' => .{ .type = .Rook, .color = color },
            'H' => .{ .type = .Knight, .color = color },
            'B' => .{ .type = .Bishop, .color = color },
            'Q' => .{ .type = .Queen, .color = color },
            'K' => .{ .type = .King, .color = color },
            '.' => null,
            else => {
                std.debug.print("Unreachable character: {}\n", .{c});
                unreachable;
            },
        };
    }
    pub fn isSameColor(self: *Self, p2: *Piece) bool {
        return self.color == p2.color;
    }
};

pub const Board = struct {
    const Self = @This();
    pieces: [64]?*Piece,

    pub fn at(self: *Self, x: usize, y: usize) ?*Piece {
        return self.pieces[y * 8 + x];
    }
    pub fn set(self: *Self, piece: *Piece, x: usize, y: usize) void {
        self.pieces[y * 8 + x] = piece;
    }
};

pub const Player = struct {
    const Self = @This();
    counter: usize = 0,
    pieces: [16]*Piece = undefined,

    pub fn addPiece(self: *Self, piece: *Piece) void {
        self.pieces[self.counter] = piece;
        self.counter += 1;
    }

    pub fn destroyPiece(self: *Self, allocator: std.mem.Allocator, index: usize) void {
        allocator.destroy(self.pieces[index]);
    }
};

pub const Match = struct {
    const Self = @This();
    white: Player = .{},
    black: Player = .{},
    board: Board = .{ .pieces = .{null} ** 64 },
    white_turn: bool = true,

    pub fn init(self: *Self, allocator: std.mem.Allocator) !void {
        try self.initBoard(allocator);
    }

    fn initBoard(self: *Self, allocator: std.mem.Allocator) !void {
        for (0..8) |x| {
            try initPeace(self, x, 1, .Pawn, .Black, allocator);
            try initPeace(self, x, 6, .Pawn, .White, allocator);
        }
        const layout = [8]Piece.Type{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };
        for (0.., layout) |x, piece_type| {
            try initPeace(self, x, 0, piece_type, .Black, allocator);
            try initPeace(self, x, 7, piece_type, .White, allocator);
        }
    }

    fn initPeace(self: *Self, x: usize, y: usize, piece_type: Piece.Type, color: Piece.Color, allocator: std.mem.Allocator) !void {
        const piece: *Piece = try allocator.create(Piece);
        piece.type = piece_type;
        piece.color = color;

        switch (color) {
            .White => self.white.addPiece(piece),
            .Black => self.black.addPiece(piece),
        }
        self.board.set(piece, x, y);
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        for (0..16) |i| {
            self.white.destroyPiece(allocator, i);
            self.black.destroyPiece(allocator, i);
        }
    }

    pub fn print(self: *Match) void {
        for (0..8) |row| {
            var rowBuf: [8]u8 = .{0} ** 8;
            for (0..8) |col| {
                const piece = self.board.at(col, row);
                if (piece == null) {
                    rowBuf[col] = '.'; // Empty square
                } else {
                    rowBuf[col] = piece.?.toString();
                }
            }
            std.debug.print("{s}\n", .{rowBuf});
        }
    }

    pub fn nextTurn(self: *Match) void {
        self.white_turn = !self.white_turn;
    }

    pub fn printTurn(self: *Match) void {
        if (self.white_turn) {
            std.debug.print("It is Player 1's turn!\n", .{});
        } else {
            std.debug.print("It is Player 2's turn!\n", .{});
        }
    }
};
