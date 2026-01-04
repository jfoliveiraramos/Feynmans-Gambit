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

use engine_sys::{Colour, Match, Piece, PieceType};

const COLOR_EMPTY: &str = "100;100;100";
const COLOR_WHITE: &str = "255;255;255";
const COLOR_BLACK: &str = "80;160;80";

fn print_board(board: [Piece; 64]) {
    println!("\n  a b c d e f g h");
    for rank in (0..8).rev() {
        print!("{} ", rank + 1);

        for file in 0..8 {
            let index = rank * 8 + file;
            let piece = board[index];
            let piece_type = piece.get_type();
            let glyph = char::from(piece);

            if piece_type == PieceType::None {
                print!("\x1b[38;2;{}m{} \x1b[0m", COLOR_EMPTY, glyph);
            } else if piece.get_colour() == Colour::White {
                print!("\x1b[38;2;{}m{} \x1b[0m", COLOR_WHITE, glyph);
            } else {
                print!("\x1b[38;2;{}m{} \x1b[0m", COLOR_BLACK, glyph);
            }
        }
        println!("{}", rank + 1);
    }
    println!("  a b c d e f g h\n");
}
fn main() {
    let mut m = Match::from_fen("rnbqkbnr/p1pppppp/8/Pp6/8/8/1PPPPPPP/RNBQKBNR w KQkq b5");

    print_board(m.board);
    let plays = m.get_moves(8 * 4);

    print_board(m.board);
    let play = plays.get(1).unwrap();
    m.execute(*play);

    print_board(m.board);
}
