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

    pub fn typeFrom(c: u8) ?Type {
        return switch (c) {
            'P' => .Pawn,
            'R' => .Rook,
            'H' => .Knight,
            'B' => .Bishop,
            'Q' => .Queen,
            'K' => .King,
            '.' => null,
            else => {
                std.debug.print("Unreachable character: {}\n", .{c});
                unreachable;
            },
        };
    }
    pub fn colorFrom(c: u8) Color {
        return switch (c) {
            'W' => .White,
            'B' => .Black,
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
    pub fn set(self: *Self, piece: ?*Piece, x: usize, y: usize) void {
        self.pieces[y * 8 + x] = piece;
    }
};

pub const Match = struct {
    const Self = @This();
    white: ArrayList(*Piece),
    black: ArrayList(*Piece),
    board: Board = .{ .pieces = .{null} ** 64 },
    white_turn: bool = true,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .white = ArrayList(*Piece).init(allocator),
            .black = ArrayList(*Piece).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn default(self: *Self) !void {
        try self.initBoard();
    }

    pub fn fromStr(self: *Self, board: []const u8) !void {
        var i: usize = 0;
        var color = false;
        var read_piece_type: ?Piece.Type = null;
        for (board) |c| {
            if (c == '\n' or c == ',') {
                continue;
            }

            if (color) {
                if (read_piece_type) |piece_type| {
                    const piece_color: Piece.Color = Piece.colorFrom(c);
                    try self.initPeace(i % 8, i / 8, piece_type, piece_color);
                }
                i += 1;
            } else {
                read_piece_type = Piece.typeFrom(c);
            }
            color = !color;
        }
    }

    fn initBoard(self: *Self) !void {
        for (0..8) |x| {
            try self.initPeace(x, 1, .Pawn, .Black);
            try self.initPeace(x, 6, .Pawn, .White);
        }
        const layout = [8]Piece.Type{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };
        for (0.., layout) |x, piece_type| {
            try self.initPeace(x, 0, piece_type, .Black);
            try self.initPeace(x, 7, piece_type, .White);
        }
    }

    fn initPeace(self: *Self, x: usize, y: usize, piece_type: Piece.Type, color: Piece.Color) !void {
        const piece: *Piece = try self.allocator.create(Piece);
        piece.type = piece_type;
        piece.color = color;

        switch (color) {
            .White => try self.white.append(piece),
            .Black => try self.black.append(piece),
        }
        self.board.set(piece, x, y);
    }

    pub fn deinit(self: *Self) void {
        for (self.white.items) |piece| {
            self.allocator.destroy(piece);
        }
        for (self.black.items) |piece| {
            self.allocator.destroy(piece);
        }
        self.white.deinit();
        self.black.deinit();
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
