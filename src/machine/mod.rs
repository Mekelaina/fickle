#![allow(dead_code)]

mod stack;

//type _Result<T, E> = std::result::Result<T, E>;
pub type Result<T> = std::result::Result<T, ProgramError>;

#[derive(Debug, PartialEq)]
pub enum ProgramError {
    StackOverflow,
    StackUnderflow,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Register {
    Byte(u8),
    ShortSigned(i16),
    Short(u16),
    Double(f64),
    Char(char),
    //String{ptr: u16, len: u16},
    Bool(bool),
}


