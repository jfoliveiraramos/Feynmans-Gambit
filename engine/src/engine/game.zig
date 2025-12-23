// Branches' Gambit Copyright (C) 2025 João Ramos
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
    };
    type: Type,
    colour: Colour,
    has_moved: bool = false,

    pub fn toString(self: *const Piece) u8 {
        const c: u8 = blk: {
            break :blk switch (self.type) {
                .Pawn => 'p',
                .Rook => 'r',
                .Knight => 'n',
                .Bishop => 'b',
                .Queen => 'q',
                .King => 'k',
            };
        };
        return if (self.colour == .White) c else std.ascii.toUpper(c);
    }

    pub fn typeFrom(c: u8) Type {
        return switch (std.ascii.toLower(c)) {
            'p' => .Pawn,
            'r' => .Rook,
            'n' => .Knight,
            'b' => .Bishop,
            'q' => .Queen,
            'k' => .King,
            else => {
                std.debug.print("Unreachable character: {c}\n", .{c});
                unreachable;
            },
        };
    }
    pub fn colourFrom(c: u8) Colour {
        if (!std.ascii.isAlphabetic(c)) unreachable;
        return if (std.ascii.isLower(c)) .White else .Black;
    }
    pub fn isSameColour(self: *Self, p2: *Piece) bool {
        return self.colour == p2.colour;
    }
};

pub const Board = struct {
    const Self = @This();
    pieces: [64]?Piece,

    pub fn at(self: *const Self, x: usize, y: usize) ?Piece {
        return self.pieces[y * 8 + x];
    }
    pub fn set(self: *Self, piece: ?Piece, x: usize, y: usize) void {
        self.pieces[y * 8 + x] = piece;
    }
};

pub const Castling = enum(u4) {
    WhiteKing = 1 << 0,
    WhiteQueen = 1 << 1,
    BlackKing = 1 << 2,
    BlackQueen = 1 << 3,
};

pub const Match = struct {
    const Self = @This();
    const PieceList = List(Piece, 32);

    board: Board,
    turn: Piece.Colour,
    castle_availability: u4,
    en_passant: ?Pos,

    pub fn empty() Self {
        return Self{
            .board = .{ .pieces = .{null} ** 64 },
            .turn = .White,
            .castle_availability = @intFromEnum(Castling.WhiteKing) |
                @intFromEnum(Castling.WhiteQueen) |
                @intFromEnum(Castling.BlackKing) |
                @intFromEnum(Castling.BlackQueen),
            .en_passant = null,
        };
    }
    pub fn fromFEN(fen: []const u8) error{
        InvalidRowCount,
        UnexpectedChar,
        UnexpectedSpace,
        InvalidPosition,
    }!Self {
        var board: Board = .{ .pieces = .{null} ** 64 };
        var turn: Piece.Colour = undefined;
        var castle_availability: u4 = 0;
        var en_passant: ?Pos = undefined;
        const State = enum {
            PiecePlacement,
            ActiveColor,
            CastleAvailability,
            EnPassantTargetSqr,
            HalfmoveClock,
            FullmoveNumber,
            End,
        };
        var state = State.PiecePlacement;
        var i: usize = 0;
        while (state != .End and i < fen.len) {
            switch (state) {
                .PiecePlacement => {
                    var row: usize = 0;
                    var col: usize = 0;
                    for (fen, 0..) |c, index| {
                        switch (c) {
                            '/' => {
                                if (col != 8) return error.InvalidRowCount;
                                row += 1;
                                col = 0;
                            },
                            '1'...'8' => {
                                col += c - '0';
                            },
                            'a'...'z', 'A'...'Z' => {
                                const piece_colour = Piece.colourFrom(c);
                                const piece_type = Piece.typeFrom(c);
                                board.set(.{ .type = piece_type, .colour = piece_colour }, col, row);
                                col += 1;
                            },
                            ' ' => {
                                if (row != 7 or col != 8) {
                                    std.debug.print("{d},{d}\n", .{ row, col });
                                    return error.UnexpectedSpace;
                                }
                                state = .ActiveColor;
                                i = index + 1;
                                break;
                            },
                            else => return error.UnexpectedChar,
                        }
                        if (col > 8) return error.InvalidRowCount;
                    }
                },
                .ActiveColor => {
                    switch (fen[i]) {
                        'w' => turn = .White,
                        'b' => turn = .Black,
                        else => return error.UnexpectedChar,
                    }
                    if (fen[i + 1] != ' ') return error.UnexpectedChar;
                    i += 2;
                    state = .CastleAvailability;
                },
                .CastleAvailability => {
                    switch (fen[i]) {
                        'K' => castle_availability |= @intFromEnum(Castling.WhiteKing),
                        'Q' => castle_availability |= @intFromEnum(Castling.WhiteQueen),
                        'k' => castle_availability |= @intFromEnum(Castling.BlackKing),
                        'q' => castle_availability |= @intFromEnum(Castling.BlackKing),
                        '-' => {},
                        ' ' => state = .EnPassantTargetSqr,
                        else => return error.UnexpectedChar,
                    }
                    i += 1;
                },
                .EnPassantTargetSqr => {
                    if (fen[i] != '-') {
                        if (fen[i] < 'a' or fen[i] > 'h') return error.InvalidPosition;
                        if (fen[i + 1] < '0' or fen[i + 1] > '7') return error.InvalidPosition;
                        if (fen[i + 2] != ' ') return error.UnexpectedChar;
                        en_passant = .{ .x = fen[i] - 'a', .y = fen[i + 1] - '0' };
                        i += 3;
                    }
                    state = .End;
                },
                else => unreachable,
            }
        }
        return Self{
            .board = board,
            .turn = turn,
            .castle_availability = castle_availability,
            .en_passant = en_passant,
        };
    }

    pub fn fromStr(board: []const u8) Self {
        var match = Self.empty();
        var i: usize = 0;
        for (board) |c| {
            if (c == '\n' or c == ' ') {
                continue;
            }
            if (std.ascii.isAlphabetic(c)) {
                const piece_colour = Piece.colourFrom(c);
                const piece_type = Piece.typeFrom(c);
                match.board.set(.{
                    .type = piece_type,
                    .colour = piece_colour,
                }, i % 8, i / 8);
            }
            i += 1;
        }
        return match;
    }

    fn default() Self {
        const match = Self.empty();
        for (0..8) |x| {
            match.board.set(.{ .type = .Pawn, .colour = .Black }, x, 1);
            match.board.set(.{ .type = .Pawn, .colour = .White }, x, 6);
        }
        const layout = [8]Piece.Type{ .Rook, .Knight, .Bishop, .Queen, .King, .Bishop, .Knight, .Rook };
        for (0.., layout) |x, piece_type| {
            match.board.set(.{ .type = piece_type, .colour = .Black }, x, 0);
            match.board.set(.{ .type = piece_type, .colour = .White }, x, 7);
        }
        return match;
    }

    pub fn print(self: *const Match) void {
        for (0..8) |row| {
            var rowBuf: [8]u8 = .{0} ** 8;
            for (0..8) |col| {
                const occupant = self.board.at(col, row);
                if (occupant) |piece| {
                    rowBuf[col] = piece.toString();
                } else {
                    rowBuf[col] = '.';
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
