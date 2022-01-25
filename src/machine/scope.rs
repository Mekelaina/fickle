use super::register::{Ptr, REGISTER_AMT};

#[derive(Debug)]
pub struct Scope ([Ptr; REGISTER_AMT]);

impl Default for Scope {
    fn default() -> Scope {
        todo!(); 
    }
}






