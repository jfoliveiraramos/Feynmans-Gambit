const std = @import("std");
const utils = @import("utils.zig");
const List = utils.List;

pub const Pos = struct { x: usize, y: usize };

pub const Piece = struct {
    const Self = @This();
    pub const Type = enum { Pawn, Bishop, Knight, Rook, Queen, King };
    pub const Colour = enum {
        White,
        Black,
        pub fn toString(self: Colour) u8 {
            return if (self == .White) 'W' else 'B';
        }
    };
    type: Type,
    colour: Colour,
    alive: bool = true,
    has_moved: bool = false,

    pub fn toString(self: Piece) u8 {
        return switch (self.type) {
            .Pawn => 'P',
            .Rook => 'R',
            .Knight => 'N',
            .Bishop => 'B',
            .Queen => 'Q',
            .King => 'K',
        };
    }

    pub fn typeFrom(c: u8) ?Type {
        return switch (c) {
            'P' => .Pawn,
            'R' => .Rook,
            'N' => .Knight,
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
    pub fn colourFrom(c: u8) Colour {
        return switch (c) {
            'W' => .White,
            'B' => .Black,
            else => {
                std.debug.print("Unreachable character: {}\n", .{c});
                unreachable;
            },
        };
    }
    pub fn isSameColour(self: *Self, p2: *Piece) bool {
        return self.colour == p2.colour;
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
    const PieceList = List(Piece, 32);
    const DoublePawnHist = List(*Piece, 16);

    pieces: PieceList = .{},
    double_pawn_hist: DoublePawnHist = .{},
    board: Board = .{ .pieces = .{null} ** 64 },
    turn: Piece.Colour = .White,

    pub fn default(self: *Self) !void {
        self.initBoard();
    }

    pub fn fromStr(self: *Self, board: []const u8) !void {
        var i: usize = 0;
        var reading_colour = false;
        var read_piece_type: ?Piece.Type = null;
        for (board) |c| {
            if (c == '\n' or c == ',') {
                continue;
            }

            if (reading_colour) {
                if (read_piece_type) |piece_type| {
                    const colour: Piece.Colour = Piece.colourFrom(c);
                    self.initPiece(i % 8, i / 8, piece_type, colour);
                }
                i += 1;
            } else {
                read_piece_type = Piece.typeFrom(c);
            }
            reading_colour = !reading_colour;
        }
    }

    fn initPiece(self: *Self, x: usize, y: usize, piece_type: Piece.Type, piece_colour: Piece.Colour) void {
        const piece = self.pieces.append(.{
            .type = piece_type,
            .colour = piece_colour,
        });
        self.board.set(piece, x, y);
    }

    fn initBoard(self: *Self) !void {
        for (0..8) |x| {
            self.initPiece(x, 1, .Pawn, .Black);
            self.initPiece(x, 6, .Pawn, .White);
        }
        const layout = [8]Piece.Type{
            .Rook,
            .Knight,
            .Bishop,
            .Queen,
            .King,
            .Bishop,
            .Knight,
            .Rook,
        };
        for (0.., layout) |x, piece_type| {
            self.initPiece(x, 0, piece_type, .Black);
            self.initPiece(x, 7, piece_type, .White);
        }
    }

    pub fn deinit(_: *Self) void {}

    pub fn print(self: *Match) void {
        for (0..8) |row| {
            var rowBuf: [16]u8 = .{0} ** 16;
            for (0..8) |col| {
                const piece = self.board.at(col, row);
                if (piece == null) {
                    rowBuf[col * 2] = '.'; // Empty square
                    rowBuf[col * 2 + 1] = '.'; // Empty square
                } else {
                    rowBuf[col * 2] = piece.?.toString();
                    rowBuf[col * 2 + 1] = piece.?.colour.toString();
                }
            }
            std.debug.print("{s}\n", .{rowBuf});
        }
    }

    pub fn nextTurn(self: *Match) void {
        self.turn = if (self.turn == .White) .Black else .White;
    }

    pub fn printTurn(self: *Match) void {
        if (self.turn == .White) {
            std.debug.print("It is Player 1's turn!\n", .{});
        } else {
            std.debug.print("It is Player 2's turn!\n", .{});
        }
    }
};
