from fython.core.interpreter.types.base import Value


class List(Value):
  def __init__(self, elements):
    super().__init__()
    self.elements = elements

  def added_to(self, other):
    new_list = self.copy()
    new_list.elements.append(other)
    return new_list, None

  def copy(self):
    copy = List(self.elements[:])
    copy.set_pos(self.pos_start, self.pos_end)
    copy.set_context(self.context)
    return copy

  def __repr__(self):
    return f'[{", ".join([str(x) for x in self.elements])}]'
