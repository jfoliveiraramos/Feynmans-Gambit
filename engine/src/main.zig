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
const engine = @import("engine");
const game = engine.game;
const movement = engine.movement;
const ArrayList = std.ArrayList;
const Match = game.Match;

pub fn main() !void {
    var match = Match{};
    // try match.fromStr(
    //     \\....PW..QW......
    //     \\PBPBPBPBPBPBPBPB
    //     \\................
    //     \\................
    //     \\PB..............
    //     \\................
    //     \\PWPWPWPWPWPWPWPW
    //     \\RWNWBWQWKW....RW
    // );
    try match.fromStr(
        \\................
        \\....PB..........
        \\................
        \\......PW........
        \\................
        \\................
        \\................
        \\................
    );
    defer match.deinit();

    match.print();

    var movements = movement.getPiecePlayableMoves(
        &match,
        .{ .x = 2, .y = 1 },
    );
    for (movements.items(), 0..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }
    movement.executeMove(&match, movements.items()[1]);
    match.print();
    movements = movement.getPiecePlayableMoves(
        &match,
        .{ .x = 3, .y = 3 },
    );
    for (movements.items(), 0..) |move, index| {
        std.debug.print("{}. ", .{index});
        move.print();
    }
    movement.executeMove(&match, movements.items()[1]);
    match.print();

    if (movement.checkmate(&match, match.turn)) {
        std.debug.print("Checkmate\n", .{});
    } else if (movement.stalemate(&match, match.turn)) {
        std.debug.print("Stalemate\n", .{});
    } else {
        std.debug.print("Nothing\n", .{});
    }

    // const move = movements.items[5];
    // movement.executeMove(&match, move);
    // match.print();
    // movement.undoMove(&match, move);
    // match.print();
}
