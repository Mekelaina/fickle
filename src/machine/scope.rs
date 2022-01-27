use super::pointer::Ptr;
use super::register::{Reg, Register, RegisterPool, REGISTER_AMT};
use super::Result;

use std::fmt;
use std::ops::{Index, IndexMut};

pub struct Scope<'a> {
    ptrs: [Ptr; REGISTER_AMT],
    ator: &'a mut RegisterPool,
}

impl fmt::Debug for Scope<'_> {
    fn fmt(&self, _f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // TODO: Debug needs to be implemented manually here because we don't
        // want printing a scope to also print the whole contents of the
        // RegisterPool it's allocated in.
        todo!();
    }
}

impl Index<Reg> for Scope<'_> {
    type Output = Ptr;

    fn index(&self, r: Reg) -> &Self::Output {
        &self.ptrs[r as usize]
    }
}

impl IndexMut<Reg> for Scope<'_> {
    fn index_mut(&mut self, r: Reg) -> &mut Self::Output {
        &mut self.ptrs[r as usize]
    }
}

impl Scope<'_> {
    fn new(ator: &mut RegisterPool) -> Result<Scope> {
        Ok(Scope {
            ptrs: [
                ator.alloc_with(Register::Byte(0u8))?,
                ator.alloc_with(Register::Byte(0u8))?,
                ator.alloc_with(Register::Word(0i16))?,
                ator.alloc_with(Register::Word(0i16))?,
                ator.alloc_with(Register::Pointer(Ptr::Null))?,
                ator.alloc_with(Register::Pointer(Ptr::Null))?,
                ator.alloc_with(Register::Float(0f64))?,
                ator.alloc_with(Register::Float(0f64))?,
                ator.alloc_with(Register::Char('\0'))?,
                ator.alloc_with(Register::Char('\0'))?,
                // ator.alloc_with(Register::Str())?,
                // ator.alloc_with(Register::Str())?,
                ator.alloc_with(Register::Bool(false))?,
                ator.alloc_with(Register::Bool(false))?,
            ],
            ator,
        })
    }

    fn mov() {
        todo!();
    }
}
