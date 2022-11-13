def test_guards():
    assert guard(0) == :number_less_than_6
    assert guard(20) == :number_bigger_than_6
    assert guard(()) == :empty_tuple
    assert guard((1, 2)) == :tuple_with_items
    assert guard({"number": 1}) == :dict_with_number
    assert guard({"number": True}) == :dict_not_number
    assert guard({"ola": 1}) == :dict

def guard(val) if is_number(val) and val < 6:
    :number_less_than_6

def guard(val) if is_number(val) and val >= 6:
    :number_bigger_than_6

def guard(val) if is_tuple(val) and tuple_size(val) == 0:
    :empty_tuple

def guard(val) if is_tuple(val) and tuple_size(val) > 0:
    :tuple_with_items

def guard(_full <- {"number": number}) if is_number(number):
    :dict_with_number

def guard(_full <- {"number": number}) if is_number(number) == False:
    :dict_not_number

def guard(val) if is_map(val):
    :dict
