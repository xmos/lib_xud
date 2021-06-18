
import pytest

PARAMS = {
    "default": {
        "arch":["xs3"],
        "ep": [1],
        "address": [1],
        "bus_speed": ["HS", "FS"],
    },
}

def pytest_generate_tests(metafunc):
    try:
        PARAMS = metafunc.module.PARAMS
        params = PARAMS["default"]

    except AttributeError:
        params = {}

    for name, values in params.items():
        if name in metafunc.fixturenames:
            metafunc.parametrize(name, values)


@pytest.fixture()
def test_ep(ep: int) -> int:
    return ep

@pytest.fixture()
def test_address(address: int) -> int:
    return address

@pytest.fixture()
def test_bus_speed(bus_speed: str) -> str:
    return bus_speed

@pytest.fixture()
def test_arch(arch: str) -> str:
    return arch

