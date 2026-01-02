use engine_sys::{Match, execute_move, get_moves};

fn main() {
    let mut m = Match::default();

    println!("Match initialized successfully!");
    println!("Turn: {}", if m.turn == 0 { "White" } else { "Black" });
    println!("Board: {:?}", m.board);

    let moves = get_moves(&m, 8);
    println!("Moves: {:?}", moves);
    unsafe { execute_move(&mut m, moves[1]) };
    println!("Board: {:?}", m.board);
}
