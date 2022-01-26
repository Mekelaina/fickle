use super::register::{Ptr, REGISTER_AMT};

#[derive(Debug)]
pub struct Scope([Ptr; REGISTER_AMT]);

impl Scope {
    fn new() -> Scope {
        todo!();
    }
}
