const std = @import("std");
const engine = @import("engine");
const game = engine.game;
const moves = engine.moves;
const ArrayList = std.ArrayList;
const Match = game.Match;
const Move = moves.Move;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic(" FAIL");
    }

    var match = Match.init(allocator);
    try match.fromStr(
        \\PWPWPWPWPWPWPWPW
        \\RWHWBWQWKWBWHWKW
        \\................
        \\................
        \\................
        \\................
        \\PBPBPBPBPBPBPBPB
        \\RBHBBBQBKBBBHBKB
    );
    defer match.deinit();

    match.print();

    const movements = moves.getMoves(
        &match.board,
        .{ .x = 3, .y = 1 },
    );

    if (movements) |move_list| {
        std.debug.print("Number of moves: {}\n", .{move_list.items.len});
        for (move_list.items, 1..) |move, index| {
            std.debug.print("{}. {s}Move: {},{}\n", .{
                index,
                (if (move.type == .Capture) "Capture " else ""),
                move.dest.x,
                move.dest.y,
            });
        }

        moves.executeMove(&match.board, move_list.items[4]);
        match.print();
        moves.reverseMove(&match.board, move_list.items[4]);
        match.print();
        // const stdin = std.io.getStdIn().reader();
        //
        // var buf: [1]u8 = undefined;
        // if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |user_input| {
        //     const index = try std.fmt.parseInt(usize, user_input, 10);
        //     moves.executeMove(&match.board, move_list.items[index]);
        // } else {}
        move_list.deinit();
    } else {
        std.debug.print("No moves\n", .{});
    }
}
