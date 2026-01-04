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

use std::ffi::c_int;

pub mod ffi {
    include!(concat!(env!("OUT_DIR"), "/constants.rs"));
}

#[repr(u8)]
#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum PieceType {
    None = ffi::PIECE_NONE as u8,
    Pawn = ffi::PIECE_PAWN as u8,
    Knight = ffi::PIECE_KNIGHT as u8,
    Bishop = ffi::PIECE_BISHOP as u8,
    Rook = ffi::PIECE_ROOK as u8,
    Queen = ffi::PIECE_QUEEN as u8,
    King = ffi::PIECE_KING as u8,
}

#[repr(u8)]
#[derive(Debug, PartialEq, Eq, Clone, Copy)]
pub enum Colour {
    White = ffi::WHITE as u8,
    Black = ffi::BLACK as u8,
}

use std::convert::TryFrom;

impl TryFrom<u8> for Colour {
    type Error = ();

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value as u32 {
            ffi::WHITE => Ok(Colour::White),
            ffi::BLACK => Ok(Colour::Black),
            _ => Err(()),
        }
    }
}

impl TryFrom<u8> for PieceType {
    type Error = ();
    fn try_from(value: u8) -> Result<Self, Self::Error> {
        match value as u32 {
            ffi::PIECE_NONE => Ok(PieceType::None),
            ffi::PIECE_PAWN => Ok(PieceType::Pawn),
            ffi::PIECE_KNIGHT => Ok(PieceType::Knight),
            ffi::PIECE_BISHOP => Ok(PieceType::Bishop),
            ffi::PIECE_ROOK => Ok(PieceType::Rook),
            ffi::PIECE_QUEEN => Ok(PieceType::Queen),
            ffi::PIECE_KING => Ok(PieceType::King),
            _ => Err(()),
        }
    }
}

impl From<PieceType> for char {
    fn from(piece: PieceType) -> Self {
        match piece {
            PieceType::Pawn => 'p',
            PieceType::Knight => 'n',
            PieceType::Bishop => 'b',
            PieceType::Rook => 'r',
            PieceType::Queen => 'q',
            PieceType::King => 'k',
            PieceType::None => ' ',
        }
    }
}

#[repr(transparent)]
#[derive(Debug, Copy, Clone, PartialEq, Eq)]
pub struct Piece(pub u8);

impl Piece {
    const TYPE_MASK: u8 = 0b0000_1111;
    const COLOUR_BIT: u8 = 4;

    pub fn new(piece_type: u8, colour: u8) -> Self {
        Self((piece_type & Self::TYPE_MASK) | (colour << Self::COLOUR_BIT))
    }

    pub fn get_type(&self) -> PieceType {
        PieceType::try_from(self.0 & Self::TYPE_MASK).unwrap()
    }

    pub fn get_colour(&self) -> Colour {
        Colour::try_from((self.0 >> Self::COLOUR_BIT) & 1).unwrap()
    }
}

impl From<Piece> for char {
    fn from(piece: Piece) -> Self {
        let c = char::from(piece.get_type());
        if piece.get_colour() == Colour::White {
            c.to_ascii_uppercase()
        } else {
            c
        }
    }
}

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
    pub board: [Piece; 64],
    pub turn: u8,
    pub castling_rights: u8,
    pub en_passant: u8,
}

impl Match {
    pub fn empty() -> Self {
        Self {
            board: [Piece(0); 64],
            turn: 0,
            castling_rights: 0,
            en_passant: 0,
        }
    }

    pub fn from_fen(fen: &str) -> Self {
        let mut m = Self::empty();
        unsafe {
            let result = create_match(&mut m, fen.as_ptr(), fen.len());
            if result != 0 {
                panic!("Failed to parse FEN: error code {}", result);
            }
        }
        m
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
            org: 255,
            dst: 255,
            flag: 0,
        }
    }
}
