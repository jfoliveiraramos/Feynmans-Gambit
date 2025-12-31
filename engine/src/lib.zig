const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const movement = engine.movement;
const Match = game.Match;
const Board = game.Board;
const Piece = game.Piece;
const Pos = game.Pos;
const Move = movement.Move;
const MAX_MOVES = movement.MAX_MOVES;

pub export fn create_default_match(opt_match: ?*Match) c_int {
    const match = opt_match orelse return -1;
    match.* = Match.default();
    return 0;
}

pub export fn create_match(
    opt_match: ?*Match,
    opt_fen: ?[*]const u8,
    fen_len: usize,
) c_int {
    const match = opt_match orelse return -1;
    const fen = opt_fen orelse return -1;

    match.* = Match.fromFEN(fen[0..fen_len]) catch return -2;

    return 0;
}

pub export fn generate_moves(
    opt_match: ?*Match,
    opt_out: ?[*]Move,
    capacity: usize,
    idx: u8,
) c_int {
    const match = opt_match orelse return -1;
    const out = opt_out orelse return -1;

    const pos = Pos.fromIndex(idx);
    const moves = movement.getPiecePlayableMoves(
        match,
        pos,
    );

    const len = @min(moves.len, capacity);
    for (moves.items()[0..len], 0..) |move, i| {
        out[i] = move;
    }

    return @intCast(len);
}

pub export fn execute_move(
    opt_match: ?*Match,
    move: Move,
) c_int {
    const match = opt_match orelse return -1;
    _ = movement.executeMove(match, move);
    return 0;
}
