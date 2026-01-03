use engine_sys::Match;

fn main() {
    let mut m = Match::default();

    println!("Match initialized successfully!");
    println!("Turn: {}", if m.turn == 0 { "White" } else { "Black" });
    println!("Board: {:?}", m.board);
    println!("Fen: {:?}", m.to_fen());

    let plays = m.get_moves(8);
    m.execute(plays.get(1).unwrap().clone());

    println!("Moves: {:?}", plays);
    println!("Board: {:?}", m.board);
}
