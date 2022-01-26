#![allow(dead_code)]
use super::register::Register;
use super::{ProgramError, Result};
use super::register::Ptr;

#[derive(Debug, Clone)]
pub struct Stack {
    pointer: usize,
    stack: [Register; 1024],
}

impl Stack {
    pub fn new() -> Self {
        Self {
            stack: [Register::Byte(0); 1024],
            pointer: 0,
        }
    }

    pub fn clear(&mut self) {
        self.pointer = 0;
    }

    pub fn get_size(&self) -> usize {
        self.pointer
    }

    pub fn push(&mut self, value: Register) -> Result<()> {
        if self.pointer < self.stack.len() {
            self.stack[self.pointer] = value;
            self.pointer += 1;
            Ok(())
        } else {
            Err(ProgramError::StackOverflow)
        }
    }

    pub fn peek(&self) -> Result<Register> {
        if let Some(ptr) = self.pointer.checked_sub(1) {
            if ptr >= self.stack.len() {
                panic!("Illegal stack pointer value: {}", self.pointer);
            }
            // NOTE: Consider using `get_unchecked` here, since the compiler doesn't
            // know that `self.pointer` will never exceed the length of the stack
            Ok(self.stack[ptr])
        } else {
            Err(ProgramError::StackUnderflow)
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

    pub fn dup(&mut self) -> Result<()> {
        let top = self.peek()?;
        self.push(top)
    }

    pub fn swap(&mut self) -> Result<()> {
        let first = self.pop()?;
        let second = self.pop()?;
        // Theoretically this should never panic.
        self.push(first).unwrap();
        self.push(second).unwrap();
        Ok(())
    }

    pub fn cycle(&mut self, elements: usize, cycles: usize) -> Result<()> {
        // Any internal `cycle` call where cycles >= elements is likely erroneous.
        // Alternatively, especially if the arguments can be set by user code, either
        // `cycles` should wrap or this panic should be converted to a ProgramError.
        if cycles >= elements {
            panic!(
                "Number of cycles ({}) must be less than the number of elements ({})",
                cycles, elements
            );
        }
        if let Some(bottom) = self.pointer.checked_sub(elements) {
            let slice = &self.stack[bottom..self.pointer];
            let rotated: Vec<_> = slice.iter().chain(slice).skip(cycles).copied().collect();
            for (i, v) in (bottom..self.pointer).zip(rotated) {
                self.stack[i] = v;
            }
            Ok(())
        } else {
            Err(ProgramError::StackUnderflow)
        }
    }

    pub fn flip(&mut self) {
        self.stack[..self.pointer].reverse();
    }
}

impl std::fmt::Display for Stack {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{:?}", &self.stack[..self.pointer])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const X: Register = Register::Byte(1);
    const Y: Register = Register::Word(2);
    const Z: Register = Register::Float(3.14);
    const A: Register = Register::Pointer(Ptr::Register(41));
    const B: Register = Register::Char('🦀');
    const C: Register = Register::Bool(true);

    #[test]
    fn push_pop() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        assert_eq!(s.pop()?, Z);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, X);
        assert_eq!(s.pop(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn overflow() -> Result<()> {
        let mut s = Stack::new();
        for _ in 0..1024 {
            s.push(X)?;
        }
        assert_eq!(s.push(X), Err(ProgramError::StackOverflow));
        Ok(())
    }

    #[test]
    fn peek() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        assert_eq!(s.peek()?, Y);
        assert_eq!(s.peek()?, Y);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.peek()?, X);
        assert_eq!(s.peek()?, X);
        assert_eq!(s.pop()?, X);
        assert_eq!(s.peek(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn drop() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        s.drop()?;
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, X);
        assert_eq!(s.drop(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn dup() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.dup()?;
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, X);
        assert_eq!(s.dup(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn swap() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.swap()?;
        assert_eq!(s.pop()?, X);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.swap(), Err(ProgramError::StackUnderflow));
        s.push(Z)?;
        assert_eq!(s.swap(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn cycle_3() -> Result<()> {
        let mut s = Stack::new();
        s.push(A)?;
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        let mut s1 = s.clone();
        s1.cycle(3, 1)?;
        assert_eq!(s1.pop()?, X);
        assert_eq!(s1.pop()?, Z);
        assert_eq!(s1.pop()?, Y);
        assert_eq!(s1.pop()?, A);
        assert_eq!(s1.pop(), Err(ProgramError::StackUnderflow));
        let mut s2 = s.clone();
        s2.cycle(3, 2)?;
        assert_eq!(s2.pop()?, Y);
        assert_eq!(s2.pop()?, X);
        assert_eq!(s2.pop()?, Z);
        assert_eq!(s2.pop()?, A);
        assert_eq!(s2.pop(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn cycle_5() -> Result<()> {
        let mut s = Stack::new();
        s.push(A)?;
        s.push(B)?;
        s.push(C)?;
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        s.cycle(5, 2)?;
        assert_eq!(s.pop()?, C);
        assert_eq!(s.pop()?, B);
        assert_eq!(s.pop()?, Z);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, X);
        assert_eq!(s.pop()?, A);
        assert_eq!(s.pop(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    #[should_panic = "Number of cycles (5) must be less than the number of elements (5)"]
    fn cycle_panic_equal() {
        let mut s = Stack::new();
        for _ in 0..20 {
            if s.push(A).is_err() {
                return;
            }
        }
        let _ = s.cycle(5, 5);
    }

    #[test]
    #[should_panic = "Number of cycles (6) must be less than the number of elements (5)"]
    fn cycle_panic_greater() {
        let mut s = Stack::new();
        for _ in 0..20 {
            if s.push(A).is_err() {
                return;
            }
        }
        let _ = s.cycle(5, 6);
    }

    #[test]
    fn flip() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        s.flip();
        assert_eq!(s.pop()?, X);
        assert_eq!(s.pop()?, Y);
        assert_eq!(s.pop()?, Z);
        assert_eq!(s.swap(), Err(ProgramError::StackUnderflow));
        Ok(())
    }

    #[test]
    fn to_string() -> Result<()> {
        let mut s = Stack::new();
        s.push(X)?;
        s.push(Y)?;
        s.push(Z)?;
        assert_eq!(s.to_string(), "[Byte(1), Word(2), Float(3.14)]");
        Ok(())
    }
}
