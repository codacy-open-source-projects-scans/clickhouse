#!/usr/bin/env python

import unittest
from argparse import ArgumentTypeError
from dataclasses import dataclass
from pathlib import Path

import version_helper as vh
from git_helper import Git

CHV = vh.ClickHouseVersion


class TestFunctions(unittest.TestCase):
    def test_version_arg(self):
        cases = (
            ("0.0.0.0", vh.get_version_from_string("0.0.0.0")),
            ("1.1.1.2", vh.get_version_from_string("1.1.1.2")),
            ("v11.1.1.2-lts", vh.get_version_from_string("11.1.1.2")),
            ("v01.1.1.2-prestable", vh.get_version_from_string("1.1.1.2")),
            ("v21.1.1.2-stable", vh.get_version_from_string("21.1.1.2")),
            ("v31.1.1.2-testing", vh.get_version_from_string("31.1.1.2")),
            ("refs/tags/v31.1.1.2-testing", vh.get_version_from_string("31.1.1.2")),
        )
        for test_case in cases:
            version = vh.version_arg(test_case[0])
            self.assertEqual(test_case[1], version)
        error_cases = (
            "0.0.0",
            "1.1.1.a",
            "1.1.1.1.1",
            "1.1.1.2-testing",
            "v1.1.1.2-testing",
            "v1.1.1.2-testin",
            "refs/tags/v1.1.1.2-testin",
        )
        for error_case in error_cases:
            with self.assertRaises(ArgumentTypeError):
                version = vh.version_arg(error_case[0])

    def test_get_version_from_repo(self):
        @dataclass
        class TestCase:
            latest_tag: str
            commits_since_latest: int
            new_tag: str
            commits_since_new: int
            expected: CHV

        cases = (
            TestCase(
                "v24.6.1.1-new",
                15,
                "v24.4.1.2088-stable",
                415,
                CHV(24, 5, 1, 54487, None, 415),
            ),
            TestCase(
                "v24.6.1.1-testing",
                15,
                "v24.4.1.2088-stable",
                415,
                CHV(24, 5, 1, 54487, None, 16),
            ),
            TestCase(
                "v24.6.1.1-stable",
                15,
                "v24.4.1.2088-stable",
                415,
                CHV(24, 5, 1, 54487, None, 15),
            ),
            TestCase(
                "v24.5.1.1-stable",
                15,
                "v24.4.1.2088-stable",
                415,
                CHV(24, 5, 1, 54487, None, 15),
            ),
        )
        git = Git(True)
        for tc in cases:
            git.latest_tag = tc.latest_tag
            git.commits_since_latest = tc.commits_since_latest
            git.new_tag = tc.new_tag
            git.commits_since_new = tc.commits_since_new
            self.assertEqual(
                vh.get_version_from_repo(
                    Path("tests/ci/tests/autogenerated_versions.txt"), git
                ),
                tc.expected,
            )