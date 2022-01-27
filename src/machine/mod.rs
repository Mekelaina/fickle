#![allow(dead_code)]

// mod ram; // Uncomment this when starting work on the Ram module
mod pointer;
mod register;
mod scope;
mod stack;

//type _Result<T, E> = std::result::Result<T, E>;
pub type Result<T> = std::result::Result<T, ProgramError>;

#[derive(Debug, PartialEq)]
pub enum ProgramError {
    StackOverflow,
    StackUnderflow,
    InvalidPointer,
    TooManyRegisters,
}
