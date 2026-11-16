# Release procedure

Every published Mooncakes version follows one atomic sequence:

1. update moon.mod, CHANGELOG.md and the generated .mbti interface;
2. run moon update, moon info, moon fmt, moon check, all available targets,
   coverage and the credential-free service E2E;
3. run moon publish --dry-run with an authenticated local Mooncakes session;
4. commit the release, create the matching vX.Y.Z tag and push both;
5. run moon publish for that exact tagged commit;
6. verify the package page and record the commit, tag and registry version.

The public CI workflow never publishes and never requires registry credentials.
Real Resend delivery checks remain opt-in and must use a verified domain; keys,
signing secrets, message bodies and attachments must not enter logs or commits.
