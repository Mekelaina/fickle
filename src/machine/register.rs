

/* two registers of each type */
pub const REGISTER_AMT: usize = 12;


#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Ptr {
    Register(u16),
    Static(u16),
    Memory(u16),
}

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
