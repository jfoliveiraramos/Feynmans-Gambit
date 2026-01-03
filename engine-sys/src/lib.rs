use std::{ffi::c_int, str::FromStr};

#[link(name = "engine")]
unsafe extern "C" {
    fn create_default_match(match_ptr: *mut Match) -> c_int;
    fn create_match(match_ptr: *mut Match, fen_ptr: *const u8, fen_len: usize) -> c_int;
    fn convert_match_to_fen(match_ptr: *const Match, fen_ptr: *mut u8) -> c_int;
    fn generate_moves(
        match_ptr: *const Match,
        out_ptr: *mut Play,
        capacity: usize,
        idx: u8,
    ) -> c_int;
    fn execute_move(match_ptr: *mut Match, play: Play) -> c_int;
}

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

    pub fn to_fen(&self) -> String {
        let mut buffer: [u8; 87] = [0; 87];
        unsafe {
            let len = convert_match_to_fen(self, buffer.as_mut_ptr()) as usize;
            std::str::from_utf8(&buffer[..len])
                .expect("Zig sent invalid UTF-8")
                .to_owned()
        }
    }

    pub fn get_moves(&mut self, idx: u8) -> Vec<Play> {
        let mut buffer = [Play::default(); 256];
        let count = unsafe { generate_moves(self, buffer.as_mut_ptr(), 256, idx) };
        buffer[0..(count as usize)].to_vec()
    }

    pub fn execute(&mut self, play: Play) {
        unsafe {
            execute_move(self, play);
        }
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
pub struct Play {
    pub org: u8,
    pub dst: u8,
    pub flag: u8,
}

impl Default for Play {
    fn default() -> Self {
        Self {
            org: 255, // Using 255 as a "sentinel" value for empty
            dst: 255,
            flag: 0,
        }
    }
}
