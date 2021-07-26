# Copyright 2016-2021 XMOS LIMITED.
# This Software is subject to the terms of the XMOS Public Licence: Version 1.
import re
import sys


class TestError(Exception):
    """
    This exception is used for any errors that occur whilst calling
    functions in the Pyxsim module.
    """

    def __init__(self, value):
        super().__init__(self)
        self.value = value

    def __str__(self):
        return repr(self.value)


class ComparisonTester:
    """
    This tester will compare ouput against a file and pass a test if
    the output matches

     :param golden:   The expected data to compare the output against.
                      Can be a list of strings, a string split on new lines,
                      or a file to read.
     :param product:  The name of the product that is being
                      tested e.g. 'lib_uart'
     :param group:    The group that the test belongs to
     :param test:     The name of the test
     :param config:   A dictionary representing the configuration of the test.
     :param env:      A dictionary representing the environment the test was
                      run under.
     :param regexp:   A bool that controls whether the expect lines are treated
                      as regular expressions or not.
     :param ignore:   A list of regular expressions to ignore
     :param ordered:  A bool that determines whether the expected input needs
                      to be matched in an ordered manner or not.
    """

    def __init__(
        self,
        golden,
        product,
        group,
        test,
        config={},
        env={},
        regexp=False,
        ignore=[],
        ordered=True,
    ):
        # self.register_test(product, group, test, config)
        self._golden = golden
        self._test = (product, group, test, config, env)
        self._regexp = regexp
        self._ignore = ignore
        self._ordered = ordered
        self.result = None
        self.failures = []

    def record_failure(self, failure_reason):
        # Append a newline if there isn't one already
        if not failure_reason.endswith("\n"):
            failure_reason += "\n"
        self.failures.append(failure_reason)
        sys.stderr.write("ERROR: %s" % failure_reason)
        self.result = False

    def run(self, output):
        golden = self._golden
        (_product, _group, test, config, _env) = self._test
        regexp = self._regexp
        if isinstance(golden, list):
            expected = golden
        elif isinstance(golden, str):
            expected = golden.split("\n")
        else:
            expected = [x.strip() for x in golden.readlines()]
        if expected[0].strip() == "":
            expected = expected[1:]
        if expected[-1].strip() == "":
            expected = expected[:-1]
        self.result = True
        self.failures = []
        line_num = -1

        num_expected = len(expected)

        for line in output:
            ignore = False
            for p in self._ignore:
                if re.match(p, line.strip()):
                    ignore = True
                    break
            if ignore:
                continue
            line_num += 1

            if line_num >= num_expected:
                self.record_failure(
                    "Length of expected output less than output"
                )
                break

            if self._ordered:
                if regexp:
                    match = re.match(
                        expected[line_num] + "$", line.strip()
                    )
                else:
                    match = expected[line_num] == line.strip()

                if not match:
                    self.record_failure(
                        (
                            "Line %d of output does not match expected\n"
                            + "  Expected: %s\n"
                            + "  Actual  : %s"
                        )
                        % (
                            line_num,
                            expected[line_num].strip(),
                            line.strip(),
                        )
                    )
            else:  # Unordered testing
                stripped = line.strip()
                if regexp:
                    match = any(re.match(e + "$", stripped) for e in expected)
                else:
                    match = any(e == stripped for e in expected)

                if not match:
                    self.record_failure(
                        (
                            "Line %d of output not found in expected\n"
                            + "  Actual  : %s"
                        )
                        % (line_num, line.strip())
                    )

        if num_expected > line_num + 1:
            self.record_failure(
                "Length of expected output greater than output\nMissing:\n"
                + "\n".join(expected[line_num + 1 :])  # noqa E203
            )
        output = {"output": "".join(output)}

        if not self.result:
            output["failures"] = "".join(self.failures)

        if self.result:
            sys.stdout.write(
                "%-30s %-6s %-6s Pass\n"
                % (test, config.get("arch"), config.get("speed"))
            )
        else:
            sys.stderr.write(
                "%-30s %-6s %-6s Fail\n"
                % (test, config.get("arch"), config.get("speed"))
            )

        return self.result
