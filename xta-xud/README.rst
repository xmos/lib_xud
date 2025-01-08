Timing Analysis for LIB_XUD
===========================

This directory contains a program to analyse timing behaviour of
lib_xud.

* There must be one label ``xta_start`` signifying where the LLD starts in
  memory.

* There must be one label ``xta_end`` signifying where the LLD ends in
  memory. ALl code between ``xta_start`` and ``xta_end`` is analyzed

* Each endpoint (in or out instruction) must either have

  * a label ``xta_ep_LABEL`` where LABEL will be used as the name of
    the endpoint for constraints; or

  * a label ``xta_no_pauseX`` where X is a value to make the label unique

* Every instruction that changes control to a non-obvious destination (eg,
  bru, bau, retsp) must have a label ``xta_targetX_DESTINATION_LABEL``
  where ``DESTINATION_LABEL`` is a possible target address and ``X`` is a
  character to make the whole label unique. Multple ``xta_target`` labels
  must be supplied if there are multiple destinations, for example for ``bau``
  and ``bru``

The timing constraints file takes the following lines of input (they are
not parsed for errors so be careful):

* A line that starts with ``FLOATING_POINT_VALUE ns`` indicates that
  subsequent pairs of endpoints should execute within that many
  nano-seconds.

* A line ``{ENDPOINT1} {ENDPOINT2}`` specifies that the time frmo ENDPOINT1
  to ENDPOINT2 should be constraint to the last number of nano-seconds set

* All other data is ignored.

Run, for example::

  python3 xta.py ../examples/app_hid_mouse/bin/xc/app_hid_mouse_xc.xe

And it will output diagnostic information finishing with the following sections::

  Labelled timing endpoints:
     [...]

  Unlabelled timing endpoints
     ('<LABEL>', NUMBER, None)
     [...]

  Found ... paths between timing endpoints.
  Unconstrained:
    [...]
  ... unconstrained paths found

  ERROR: unused constraints
      [...]

  Constrained assuming 8 threads running:
       435 MHz: required for {ENDPOINT1} => {ENDPOINT2} 29 cycles
       315 MHz: required for ...

THe meaning of these is as follows:

* The labelled timing endpoints are all the endpoints that were found in
  the binary provided

* The unlabelled timing endpoints are inputs and outputs that had not been labelled
  The instruction was the ``NUMBER``\ :sup:`th` instruction after ``LABEL``.
  
* The unconstrained paths list pairs of endpoints where it found a path but
  no constraint. These should be added to constraints.txt with an
  appropriate time.

* The unused constraints are paths that were specified that it could not
  identify in the binary. This indicates missing ``xta_target`` labels

* Finally, the constraint paths are printed with their two endpoints, the
  number of cycles between them, and the MHz the processor should run at to
  make timing assuming all 8 threads are busy. If the LLD runs as a
  priority thread, then this number can be multiplied by 5/8.
