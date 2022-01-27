#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Ptr {
    Register(u16),
    Static(u16),
    Memory(u16),
    Null,
}
