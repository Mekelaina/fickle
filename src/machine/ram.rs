



#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn set_and_get() {
        let r = Ram::new();
        let index: u16 = 0x0420;
        let value: u8 = 0x69;
        r.insert_at(index, value);
        assert_eq!(r.get_at(index), value);
    }

    #[test]
    fn clear() {
        let r = Ram::new();
        let index: u16 = 0x3141;
        let value: u8 = 0x59;
        r.insert_at(index, value);
        assert_eq!(r.get_at(index), value);
        r.clear();
        assert_eq!(r.get_at(index), 0x00);
    }

    #[test]
    fn mapping() {
        let r = Ram::new();
        let start: u16 = 0x0006;
        let end: u16 = 0x0789;
        let value: u8 = 0x2a;
        r.map_to_range(start, end, value);
        for i in start..end {
            assert_eq!(r.get_at(i), value);
        }
        assert_eq!(r.get_at(start - 1), 0x00);
        assert_eq!(r.get_at(end), 0x00);
    }
}
