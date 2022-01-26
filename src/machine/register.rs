use super::ProgramError;
use super::Result;
use super::pointer::Ptr;
use std::collections::HashMap;
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



const MAX_REGISTERS: usize = 1024;

pub struct RegisterPool {
    pool: HashMap<u16, Register>,
    free: Vec<u16>,
    top: u16,
}

impl Index<Ptr> for RegisterPool {
    type Output = Register;

    fn index(&self, ptr: Ptr) -> &Self::Output {
        self.get(ptr).unwrap()
    }
}

impl RegisterPool {
    pub fn new() -> RegisterPool {
        /* this code is written with the assumption that MAX_REGISTERS is less
        than u16::MAX. */
        assert!(MAX_REGISTERS < (u16::MAX as usize));
        RegisterPool {
            pool: HashMap::with_capacity(MAX_REGISTERS),
            free: Vec::new(),
            top: 0u16,
        }
    }

    pub fn alloc_with(&mut self, register: Register) -> Result<Ptr> {
        if self.pool.len() < MAX_REGISTERS {
            if self.free.is_empty() {
                self.pool.insert(self.top, register);
                if self.top.checked_add(1).is_none() {
                    /* if self.top is at u16::MAX, and therefore adding 1 would overflow it,
                    because the capacity of the pool is less than u16::MAX, there
                    theoretically *must* be free addresses, so this branch is unreachable. */
                    unreachable!();
                } else {
                    self.top += 1;
                }
                Ok(Ptr::Register(self.top - 1))
            } else {
                let addr = self.free.pop().unwrap(); /* this never panics, we already know self.free isn't empty in this branch */
                self.pool.insert(addr, register);
                Ok(Ptr::Register(addr))
            }
        } else {
            Err(ProgramError::TooManyRegisters)
        }
    }

    pub fn free(&mut self, ptr: Ptr) -> Result<()> {
        if let Ptr::Register(rp) = ptr {
            if self.pool.contains_key(&rp) {
                self.pool.remove(&rp);
                self.free.push(rp);
                Ok(())
            } else {
                Err(ProgramError::InvalidPointer)
            }
        } else {
            Err(ProgramError::InvalidPointer)
        }
    }

    pub fn get(&self, ptr: Ptr) -> Result<&Register> {
        if let Ptr::Register(rp) = ptr {
            if let Some(reg) = self.pool.get(&rp) {
                Ok(reg)
            } else {
                Err(ProgramError::InvalidPointer)
            }
        } else {
            Err(ProgramError::InvalidPointer)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const A: Register = Register::Bool(false);

    #[test]
    fn alloc_free() -> Result<()> {
        let mut rpool = RegisterPool::new();
        let ptr = rpool.alloc_with(A)?;
        assert_eq!(rpool[ptr], A);
        rpool.free(ptr)?;
        /* double free should err */
        assert_eq!(rpool.free(ptr), Err(ProgramError::InvalidPointer));
        /* access to freed mem should err */
        assert_eq!(rpool.get(ptr), Err(ProgramError::InvalidPointer));
        Ok(())
    }


    #[test]
    fn wrong_ptr_typ() {
        let  rpool = RegisterPool::new();
        let wrong_ptr = Ptr::Memory(420);
        assert_eq!(rpool.get(wrong_ptr), Err(ProgramError::InvalidPointer));
    }

    #[test]
    fn too_many() -> Result<()> {
        let mut rpool = RegisterPool::new();
        let first = rpool.alloc_with(A)?;
        /* fill up the pool */
        for _ in 0..(MAX_REGISTERS - 1) {
            rpool.alloc_with(A)?;
        }
        assert_eq!(rpool.alloc_with(A), Err(ProgramError::TooManyRegisters));
        rpool.free(first)?;
        assert!(rpool.alloc_with(A).is_ok());
        Ok(())

    }
}
