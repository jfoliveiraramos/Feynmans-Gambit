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
const constants = @cImport({
    @cInclude("constants.h");
});
const List = utils.List;

pub const Pos = packed struct(u8) {
    const Self = @This();

    val: u8,

    pub const none = Self{ .val = 0xFF };

    pub fn fromIndex(idx: usize) Self {
        return .{ .val = @intCast(idx) };
    }

    pub fn fromXY(x: u3, y: u3) Self {
        return .{ .val = @as(u8, 7 - y) * 8 + x };
    }

    pub fn isNone(self: Self) bool {
        return self.val > 63;
    }

    pub fn coords(self: Self) struct { x: u3, y: u3 } {
        return .{ .x = @intCast(self.val % 8), .y = @intCast(7 - self.val / 8) };
    }

    pub fn eq(self: Pos, other: Pos) bool {
        return self.val == other.val;
    }
};

pub const Colour = enum(u8) {
    White = constants.WHITE,
    Black = constants.BLACK,

    pub fn opposite(self: Colour) Colour {
        return if (self == .White) .Black else .White;
    }
};

pub const Piece = packed struct(u8) {
    const Self = @This();
    pub const Type = enum(u4) {
        None = constants.PIECE_NONE,
        Pawn = constants.PIECE_PAWN,
        Bishop = constants.PIECE_BISHOP,
        Knight = constants.PIECE_KNIGHT,
        Rook = constants.PIECE_ROOK,
        Queen = constants.PIECE_QUEEN,
        King = constants.PIECE_KING,
    };
    type: Type,
    colour: u1 = 0,
    _: u3 = 0,

    pub const empty = Self{
        .type = .None,
    };

    pub fn new(piece_type: Type, piece_colour: Colour) Self {
        return Self{ .type = piece_type, .colour = @intCast(@intFromEnum(piece_colour)) };
    }

    pub fn isColour(self: Self, colour: Colour) bool {
        return self.colour == @intFromEnum(colour);
    }

    pub fn isWhite(self: Self) bool {
        return self.isColour(Colour.White);
    }

    pub fn isBlack(self: Self) bool {
        return self.isColour(Colour.Black);
    }

    pub fn oppositeColour(self: Self) Colour {
        return @as(Colour, @enumFromInt(self.colour)).opposite();
    }

    pub fn toChar(self: Self) u8 {
        const c: u8 = switch (self.type) {
            .None => '.',
            .Pawn => 'p',
            .Rook => 'r',
            .Knight => 'n',
            .Bishop => 'b',
            .Queen => 'q',
            .King => 'k',
        };

        return if (self.isBlack()) c else std.ascii.toUpper(c);
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
        if (!std.ascii.isAlphabetic(c)) {
            std.debug.print("Unreachable character: {c}\n", .{c});
            unreachable;
        }
        return if (std.ascii.isLower(c)) .Black else .White;
    }
    pub fn isSameColour(self: Self, p2: Piece) bool {
        return self.colour == p2.colour;
    }

    pub fn promoteTo(self: Self, new_type: Type) Piece {
        return Self{ .colour = self.colour, .type = new_type };
    }
};

pub const Board = extern struct {
    const Self = @This();

    pieces: [64]Piece,

    pub inline fn at(self: *const Self, pos: Pos) Piece {
        return self.pieces[pos.val];
    }

    pub fn set(self: *Self, piece: Piece, pos: Pos) void {
        self.pieces[pos.val] = piece;
    }
};

pub const Castling = enum(u4) {
    WhiteKing = 1 << 0,
    WhiteQueen = 1 << 1,
    BlackKing = 1 << 2,
    BlackQueen = 1 << 3,
};

pub const FULL_CASTLING_RIGHTS = @intFromEnum(Castling.WhiteKing) |
    @intFromEnum(Castling.WhiteQueen) |
    @intFromEnum(Castling.BlackKing) |
    @intFromEnum(Castling.BlackQueen);

pub const CastlingRights = u4;

pub const Match = extern struct {
    const Self = @This();
    const PieceList = List(Piece, 32);

    board: Board,
    turn: Colour,
    castling_rights: u8,
    en_passant: Pos,

    half_move: u8,
    full_move: u32,

    const FenError = error{
        InvalidRowCount,
        UnexpectedChar,
        UnexpectedSpace,
        InvalidPosition,
    };

    pub fn default() Self {
        return Self.fromFEN("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 0") catch unreachable;
    }

    pub fn empty() Self {
        return Self{
            .board = .{ .pieces = .{null} ** 64 },
            .turn = .White,
            .castling_rights = FULL_CASTLING_RIGHTS,
            .en_passant = null,
            .half_move = 0,
            .full_move = 0,
        };
    }

    pub fn toFEN(self: Self, buf: []u8) usize {
        var fen: List(u8, 128) = .{};

        var rank: i8 = 7;
        while (rank >= 0) : (rank -= 1) {
            var empty_count: u8 = 0;
            var file: u8 = 0;
            while (file < 8) : (file += 1) {
                const index = @as(usize, @intCast(rank)) * 8 + file;
                const piece = self.board.pieces[index];

                if (piece.type == .None) {
                    empty_count += 1;
                } else {
                    if (empty_count != 0) {
                        fen.append('0' + empty_count);
                        empty_count = 0;
                    }
                    fen.append(piece.toChar());
                }
            }

            if (empty_count != 0) fen.append('0' + empty_count);

            if (rank > 0) fen.append('/');
        }

        fen.append(' ');
        fen.append(if (self.turn == .White) 'w' else 'b');
        fen.append(' ');

        const start_len = fen.len;
        if ((self.castling_rights & @intFromEnum(Castling.WhiteKing)) != 0) fen.append('K');
        if ((self.castling_rights & @intFromEnum(Castling.WhiteQueen)) != 0) fen.append('Q');
        if ((self.castling_rights & @intFromEnum(Castling.BlackKing)) != 0) fen.append('k');
        if ((self.castling_rights & @intFromEnum(Castling.BlackQueen)) != 0) fen.append('q');
        if (fen.len == start_len) fen.append('-');
        fen.append(' ');

        if (self.en_passant.isNone()) {
            fen.append('-');
        } else {
            const coords = self.en_passant.coords();
            fen.append('a' + @as(u8, @intCast(coords.x)));
            fen.append('1' + @as(u8, @intCast(7 - coords.y)));
        }
        fen.append(' ');

        var half_move_buf: [3]u8 = undefined;
        const half_move = std.fmt.bufPrint(&half_move_buf, "{d}", .{self.half_move}) catch unreachable;
        fen.appendSlice(half_move);
        fen.append(' ');

        var full_move_buf: [10]u8 = undefined;
        const full_move = std.fmt.bufPrint(&full_move_buf, "{d}", .{self.full_move}) catch
            unreachable;

        fen.appendSlice(full_move);

        @memcpy(buf[0..fen.len], fen.items());

        return fen.len;
    }

    pub fn fromFEN(fen: []const u8) FenError!Self {
        var board: Board = .{ .pieces = .{Piece.empty} ** 64 };
        var turn: Colour = undefined;
        var castle_availability: u4 = 0;
        var en_passant: Pos = undefined;
        var half_move: u8 = undefined;
        var full_move: u32 = undefined;
        var i: usize = 0;

        var row: u8 = 0;
        var col: u8 = 0;
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
                    board.set(
                        Piece.new(piece_type, piece_colour),
                        Pos.fromXY(@intCast(col), @intCast(row)),
                    );
                    col += 1;
                },
                ' ' => {
                    if (row != 7 or col != 8) {
                        return error.UnexpectedSpace;
                    }
                    i = index + 1;
                    break;
                },
                else => return error.UnexpectedChar,
            }
            if (col > 8) return error.InvalidRowCount;
        }

        switch (fen[i]) {
            'w' => turn = .White,
            'b' => turn = .Black,
            else => return error.UnexpectedChar,
        }
        if (fen[i + 1] != ' ') return error.UnexpectedChar;
        i += 2;

        if (fen[i] != '-') {
            while (true) : (i += 1) {
                switch (fen[i]) {
                    'K' => castle_availability |= @intFromEnum(Castling.WhiteKing),
                    'Q' => castle_availability |= @intFromEnum(Castling.WhiteQueen),
                    'k' => castle_availability |= @intFromEnum(Castling.BlackKing),
                    'q' => castle_availability |= @intFromEnum(Castling.BlackQueen),
                    ' ' => break,
                    else => return error.UnexpectedChar,
                }
            }
        } else {
            i += 1;
        }
        i += 1;

        if (fen[i] != '-') {
            if (fen[i] < 'a' or fen[i] > 'h') return error.InvalidPosition;
            if (fen[i + 1] < '1' or fen[i + 1] > '8') return error.InvalidPosition;
            en_passant = Pos.fromXY(
                @intCast(fen[i] - 'a'),
                @intCast(7 - (fen[i + 1] - '1')),
            );
            i += 2;
        } else {
            en_passant = Pos.none;
            i += 1;
        }

        if (fen[i] != ' ') return error.UnexpectedChar;
        i += 1;

        half_move = blk: {
            var it = std.mem.tokenizeScalar(
                u8,
                fen[i..],
                ' ',
            );
            const token = it.next() orelse return error.UnexpectedChar;
            const value = std.fmt.parseInt(u8, token, 10) catch {
                return error.UnexpectedChar;
            };
            i += token.len;
            break :blk value;
        };

        if (fen[i] != ' ') return error.UnexpectedChar;
        i += 1;

        full_move = std.fmt.parseInt(u32, fen[i..], 10) catch {
            return error.UnexpectedChar;
        };

        return Self{
            .board = board,
            .turn = turn,
            .castling_rights = castle_availability,
            .en_passant = en_passant,
            .half_move = half_move,
            .full_move = full_move,
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

    pub fn print(self: *const Match) void {
        for (0..8) |row| {
            var rowBuf: [8]u8 = .{0} ** 8;
            for (0..8) |col| {
                const piece = self.board.at(
                    Pos.fromXY(@intCast(col), @intCast(row)),
                );
                rowBuf[col] = piece.toChar();
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
