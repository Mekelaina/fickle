module unit_tests.vm_stack;

import std.stdint;

import machine.vm;

const RegisterValue a = RegisterValue(cast(uint8_t) 1);
const RegisterValue b = RegisterValue(cast(uint8_t) 2);
const RegisterValue c = RegisterValue(cast(uint8_t) 3);
const RegisterValue d = RegisterValue(cast(uint8_t) 4);
const RegisterValue e = RegisterValue(cast(uint8_t) 5);

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.push(c);
    assert(s.pop() == c);
    assert(s.pop() == b);
    assert(s.pop() == a);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.push(c);
    assert(s.getSize() == 3);
    s.clearStack();
    assert(s.getSize() == 0);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    assert(s.peek() == b);
    assert(s.pop() == b);
    assert(s.peek() == a);
    assert(s.pop() == a);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.drop();
    assert(s.pop() == a);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.duplicate();
    assert(s.pop() == b);
    assert(s.pop() == b);
    assert(s.pop() == a);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.swap();
    assert(s.pop() == a);
    assert(s.pop() == b);
}

unittest {
    Stack s = Stack();
    assert(s.getSize() == 0);
    s.push(a);
    assert(s.getSize() == 1);
    s.push(b);
    assert(s.getSize() == 2);
    s.drop();
    assert(s.getSize() == 1);
    s.drop();
    assert(s.getSize() == 0);
}

unittest {
    Stack s = Stack();
    s.push(d);
    s.push(d);
    s.push(a);
    s.push(b);
    s.push(c);
    // temp = [a b c a b c]
    // temp[1]
    s.cycleStack(3, 1);
    assert(s.pop() == a);
    assert(s.pop() == c);
    assert(s.pop() == b);

    s.push(a);
    s.push(b);
    s.push(c);
    s.cycleStack(3, 2);
    assert(s.pop() == b);
    assert(s.pop() == a);
    assert(s.pop() == c);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.push(c);
    s.push(d);
    s.push(e);
    s.cycleStack(5, 3);
    assert(s.pop() == c);
    assert(s.pop() == b);
    assert(s.pop() == a);
    assert(s.pop() == e);
    assert(s.pop() == d);
}

unittest {
    Stack s = Stack();
    s.push(a);
    s.push(b);
    s.push(c);
    s.flip();
    assert(s.pop() == a);
    assert(s.pop() == b);
    assert(s.pop() == c);
}
