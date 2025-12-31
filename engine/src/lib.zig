const engine = @import("engine");
const game = engine.game;
const movement = engine.movement;
const Match = game.Match;
const Board = game.Board;
const Piece = game.Piece;
const Pos = game.Pos;
const Move = movement.Move;
const MAX_MOVES = movement.MAX_MOVES;

const MoveFFI = extern struct {
    org: u8,
    dst: u8,
    flags: u8,
    promo: u8,

    pub fn fromMove(move: Move) MoveFFI {
        return .{
            .org = move.org.y * 8 + move.org.x,
            .dst = move.dst.y * 8 + move.dst.x,
            .flags = (@as(u8, @intFromBool(move.castling)) << 0) |
                (@as(u8, @intFromBool(move.en_passant)) << 1),
            .promo = @intFromEnum(move.promotion),
        };
    }

    pub fn toMove(self: MoveFFI) !Move {
        return Move{
            .org = try Pos.from(self.org),
            .dst = try Pos.from(self.dst),
            .promotion = if (self.promo == 0)
                .Queen
            else
                @enumFromInt(self.promo),
            .castling = (self.flags & 0b0000_0001) != 0,
            .en_passant = (self.flags & 0b0000_0010) != 0,
        };
    }
};

const MatchFFI = extern struct {
    board: [64]u8,
    turn: u8,
    castling_rights: u8,
    en_passant: u8,

    pub fn fromMatch(match: Match) MatchFFI {
        var pieces: [64]u8 = .{0b1111_1111} ** 64;
        for (match.board.pieces, 0..) |spot, i| {
            if (spot) |piece| {
                pieces[i] = @as(u8, @intFromEnum(piece.type)) | (@as(u8, @intFromEnum(piece.colour)) << 3);
            }
        }
        const en_passant: u8 = if (match.en_passant) |en_passant|
            en_passant.toIdx()
        else
            0b1111;

        return MatchFFI{
            .board = pieces,
            .turn = @intFromEnum(match.turn),
            .castling_rights = match.castling_rights,
            .en_passant = en_passant,
        };
    }
    pub fn toMatch(self: MatchFFI) Match {
        var board = Board{ .pieces = .{null} ** 64 };
        for (self.board, 0..) |piece, i| {
            if (piece != 0) {
                board.setPos(Piece{
                    .type = @enumFromInt(piece & 0b0111),
                    .colour = @enumFromInt(piece >> 3),
                }, Pos.from(i) catch unreachable);
            }
        }
        const en_passant: ?Pos = if (self.en_passant != 0b1111)
            Pos.from(self.en_passant) catch unreachable
        else
            null;

        return Match{
            .board = board,
            .turn = @enumFromInt(self.turn),
            .castling_rights = @intCast(self.castling_rights),
            .en_passant = en_passant,
        };
    }
};

pub export fn create_default_match() MatchFFI {
    return MatchFFI.fromMatch(Match.default());
}

pub export fn generate_moves(
    matchFFI: *MatchFFI,
    out: [*]MoveFFI,
    idx: u8,
) c_int {
    const pos = Pos.from(idx) catch return -1;
    var match = matchFFI.toMatch();
    const moves = movement.getPiecePlayableMoves(
        &match,
        pos,
    );

    for (moves.items(), 0..) |mv, i| {
        out[i] = MoveFFI.fromMove(mv);
    }
    if (moves.len >= MAX_MOVES) return -1;
    return @intCast(moves.len);
}

pub export fn execute_move(
    match: *Match,
    moveFFI: MoveFFI,
) c_int {
    const move = moveFFI.toMove() catch return -1;
    _ = movement.executeMove(match, move);
    return 0;
}
