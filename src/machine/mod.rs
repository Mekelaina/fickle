//type _Result<T, E> = std::result::Result<T, E>;
pub type Result<T> = std::result::Result<T, ProgramError>;

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

#[derive(Debug, PartialEq)]
pub enum ProgramError {
    StackOverflow,
    StackUnderflow,
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
    pub fn pop(&mut self) -> Result<Register> {
        if self.pointer == 0 {
            Err(ProgramError::StackUnderflow)
        } else {
            self.pointer -= 1;
            Ok(self.stack[self.pointer])
        }
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
    #[test]
    fn stack() -> Result<()> {
        let mut s = Stack::new();
        let x = Register::Byte(1);
        let y = Register::Short(2);
        let z = Register::Double(3.14);
        s.push(x)?;
        s.push(y)?;
        s.push(z)?;
        assert_eq!(s.pop()?, z);
        assert_eq!(s.pop()?, y);
        assert_eq!(s.pop()?, x);
        Ok(())
    }
}
