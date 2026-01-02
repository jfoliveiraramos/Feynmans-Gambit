use std::ffi::c_int;

#[repr(C)]
#[derive(Debug)]
pub struct Match {
    pub board: [u8; 64],
    pub turn: u8,
    pub castling_rights: u8,
    pub en_passant: u8,
}

impl Match {
    pub fn empty() -> Self {
        Self {
            board: [0u8; 64],
            turn: 0,
            castling_rights: 0,
            en_passant: 0,
        }
    }

    pub fn from_fen(fen: &str) -> Self {
        let mut r#match = Self::empty();
        unsafe {
            create_match(&mut r#match, fen.as_ptr(), fen.len());
        }
        r#match
    }
}

impl Default for Match {
    fn default() -> Self {
        let mut r#match = Self::empty();
        unsafe {
            create_default_match(&mut r#match);
        }
        r#match
    }
}

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct Move {
    pub org: u8,
    pub dst: u8,
    pub flag: u8,
}

impl Default for Move {
    fn default() -> Self {
        Self {
            org: 255, // Using 255 as a "sentinel" value for empty
            dst: 255,
            flag: 0,
        }
    }
}

#[link(name = "engine")]
unsafe extern "C" {
    pub fn create_default_match(match_ptr: *mut Match) -> c_int;
    pub fn create_match(match_ptr: *mut Match, fen_ptr: *const u8, fen_len: usize) -> c_int;
    pub fn generate_moves(
        match_ptr: *const Match,
        out_ptr: *mut Move,
        capacity: usize,
        idx: u8,
    ) -> c_int;
    pub fn execute_move(match_ptr: *mut Match, move_val: Move) -> c_int;
}

pub fn get_moves(m: &Match, idx: u8) -> Vec<Move> {
    let mut buffer = [Move::default(); 256];
    let count = unsafe { generate_moves(m, buffer.as_mut_ptr(), 256, idx) };
    buffer[0..(count as usize)].to_vec()
}
