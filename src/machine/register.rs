use super::Result;
use std::ops::Index;

/* two registers of each type */
pub const REGISTER_AMT: usize = 12;

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Register {
    Byte(u8),
    Word(i16),
    Pointer(Ptr),
    Float(f64),
    Char(char),
    //String{ptr: u16, len: u16},
    Bool(bool),
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Ptr {
    Register(u16),
    Static(u16),
    Memory(u16),
}

const MAX_REGISTERS: usize = 1024;

pub struct RegisterPool(Vec<Register>);

impl Index<Ptr> for RegisterPool {
    type Output = Register;

    fn index(&self, ptr: Ptr) -> &Self::Output {
        self.get(&ptr).unwrap()
    }
}

impl RegisterPool {
    fn new() -> RegisterPool {
        RegisterPool(Vec::with_capacity(1024))
    }

    fn alloc(&self) -> Result<Ptr> {
        todo!();
    }

    fn free(&self, _ptr: Ptr) -> Result<()> {
        todo!();
    }

    fn get(&self, _ptr: &Ptr) -> Result<&Register> {
        todo!();
    }
}
