"""Exposes "--fdo_instrument or --cs_fdo_instrument is set" to config_setting.

Both flags take an arbitrary path, so no config_setting can match them, and
rules outside rules_cc cannot read them from the cpp fragment. A transition can
read native options, so the `_requested` edge copies "either flag set" into
:fdo_instrument_requested, and this rule reports that value as a feature flag
for config_setting.flag_values.

Only the one-target `_requested` edge changes configuration, and only when a
flag is set; with neither set the transition writes the setting's default.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

_FDO_INSTRUMENT_REQUESTED = Label("//runtimes:fdo_instrument_requested")

def _fdo_instrument_requested_transition_impl(settings, _attr):
    return {
        str(_FDO_INSTRUMENT_REQUESTED): bool(
            settings["//command_line_option:fdo_instrument"] or
            settings["//command_line_option:cs_fdo_instrument"],
        ),
    }

_fdo_instrument_requested_transition = transition(
    implementation = _fdo_instrument_requested_transition_impl,
    inputs = [
        "//command_line_option:fdo_instrument",
        "//command_line_option:cs_fdo_instrument",
    ],
    outputs = [str(_FDO_INSTRUMENT_REQUESTED)],
)

def _fdo_instrument_flag_impl(ctx):
    value = ctx.attr._requested[0][BuildSettingInfo].value
    return [config_common.FeatureFlagInfo(value = str(value).lower())]

fdo_instrument_flag = rule(
    doc = "\"true\" when --fdo_instrument or --cs_fdo_instrument is set, else \"false\".",
    implementation = _fdo_instrument_flag_impl,
    attrs = {
        "_requested": attr.label(
            default = _FDO_INSTRUMENT_REQUESTED,
            cfg = _fdo_instrument_requested_transition,
        ),
    },
)
