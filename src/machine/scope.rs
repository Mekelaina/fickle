use super::pointer::{Ptr};
use super::register::REGISTER_AMT;
#[derive(Debug)]
pub struct Scope([Ptr; REGISTER_AMT]);

impl Scope {
    fn new() -> Scope {
        todo!();
    }
}
