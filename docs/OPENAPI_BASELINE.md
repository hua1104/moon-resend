# OpenAPI compatibility baseline

The compatibility statement in docs/COMPATIBILITY.md is a deliberately narrow
subset of the Resend API. Before changing a covered endpoint, compare it with
the official resend/resend-openapi repository and record the inspected
revision, endpoint, request fields, response fields and intentional omissions.

The current published compatibility baseline is Resend OpenAPI 1.5.1. The
repository does not vendor the full upstream specification because it contains
many unrelated platform resources. This file is a release checklist, not a
claim of full-platform support. A future drift job should fetch and pin an
upstream commit hash before expanding the supported surface.
