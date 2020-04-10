from fython.core.interpreter.types.base import Value


class String(Value):
    def __init__(self, value):
        self.value = value

    def added_to(self, other):
        if isinstance(other, String):
            return String(
                self.value + other.value
            ).set_context(self.context), None
        else:
            return None, Value.illegal_operation(self, other)

    def multed_by(self, other):
        if isinstance(other, Number):
            return String(
                self.value * other.value
            ).set_context(self.context), None
        else:
            return None, Value.illegal_operation(self, other)

    def is_true(self):
        return len(self.value) > 0

    def copy(self):
        copy = String(self.value)
        copy.set_pos(self.pos_start, self.pos_end)
        copy.set_context(self.context)
        return copy

    def __repr__(self):
        return f'"{self.value}"'
