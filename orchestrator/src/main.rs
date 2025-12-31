use std::ffi::c_int;

#[repr(C)]
#[derive(Debug)]
pub struct MatchFFI {
    pub board: [u8; 64],
    pub turn: u8,
    pub castling_rights: u8,
    pub en_passant: u8,
}

#[repr(C)]
pub struct MoveFFI {
    org: u8,
    dst: u8,
    flags: u8,
    promo: u8,
}

unsafe extern "C" {
    pub fn create_default_match() -> MatchFFI;
    pub fn generate_moves(match_ffi: *mut MatchFFI, out: *mut MoveFFI, idx: u8) -> c_int;
    pub fn execute_move(match_ffi: *mut MatchFFI, move_ffi: MoveFFI) -> c_int;
}

fn main() {
    let m: MatchFFI = unsafe { create_default_match() };
    println!("{:?}", m);
}
