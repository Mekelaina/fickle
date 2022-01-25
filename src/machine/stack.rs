#![allow(dead_code)]
use super::{Result, ProgramError};

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

pub struct Stack {
    stack: [Register; 1024],
    pointer: usize,
}

impl Stack {
    pub fn new() -> Self {
        Self {
            stack: [Register::Byte(0); 1024],
            pointer: 0,
        }
    }

    pub fn clear_stack(&mut self) {
        self.pointer = 0;
    }

    pub fn push(&mut self, value: Register) -> Result<()> {
        if self.is_valid_pointer() {
            self.stack[self.pointer] = value;
            self.pointer += 1;
            Ok(())
        } else {
            Err(ProgramError::StackOverflow)
        }
    }

    pub fn peek(&mut self) -> Result<Register> {
        if self.pointer == 0 {
            Err(ProgramError::StackUnderflow)
        } else {
            Ok(self.stack[self.pointer - 1])
        }
    }

    pub fn pop(&mut self) -> Result<Register> {
        let value = self.peek()?;
        self.pointer -= 1;
        Ok(value)
    }

    pub fn drop(&mut self) -> Result<()> {
        self.pop()?;
        Ok(())
    }

    fn is_valid_pointer(&self) -> bool {
        self.stack.get(self.pointer).is_some()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const X: Register = Register::Byte(1);
    const Y: Register = Register::Short(2);
    const Z: Register = Register::Double(3.14);

    #[test]
    fn push_pop() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        assert_eq!(s.pop()?, Z);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, X);
        Ok(())
    }

    #[test]
    fn peek() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        assert_eq!(s.peek()?, Z);
        assert_eq!(s.peek()?, Z);
        assert_eq!(s.pop()?, Z);
        assert_eq!(s.peek()?, Y);
        assert_eq!(s.peek()?, Y);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.peek()?, X);
        assert_eq!(s.peek()?, X);
        assert_eq!(s.pop()?, X);
        Ok(())
    }
}
