
Lib_xud Tests
=============

Set up envirnment
.................

In infr_scripts_pl, run:
``source ./SetupEnv``

In test_support, run:
``./Build.pl build install``


Installation and prerequiste for running pytest
...............................................

``pip install pytest``

To run all tests:

``pytest -n 4 --enabletracing --xcov [test level]``

test level: smoke < default < extended

To run specific test:

``pytest -n 4 --enabletracing --xcov [test level] <test_name>.py``

test level: smoke < default < extended
