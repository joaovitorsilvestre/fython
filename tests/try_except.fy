def test_try():
    try:
        raise Tests.Try_except.MyException()
    except Tests.Try_except.MyException as e:
        assert e.message == "Error"

exception MyException:
    message = "Error"