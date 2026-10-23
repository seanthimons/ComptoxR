# Independent official Specmill 0.1.47 verification

Exact source/tag: 5ec825277c686a7142ad113340897039b6c3a793.
Official release: https://github.com/seanthimons/specmill/releases/tag/v0.1.47

Official tarball matches SHA256SUMS and supplied df63aac70ec12d4f7d819cf4392fbee384cfe37fc8cdd29675130de63e78e60a. All76 tracked R/inst files match exact git archive. Pin git archive SHA256:27639e010a7aabee957389f58406d5094f3769a540d60ac7887b562d5fce2024. Installation is isolated at library/specmill. No active prior library or root files were edited.

Forms proof:492assertions,36actual localhost requests,84zeroHTTP rejections,3actual transport failures. Plan/apply/check with validationTRUE and11ownerhashes pass. All3 wrapper bytes and requiredbody formals match held wrappers. No deployed auth/session calls. Unchanged official tests/free-form-fields.R passes.

Evidence: forms-replay.log, upstream-free-form.log, verification.json, replay-root/dev/chet-admin-auth/pr180-exact/results.json. Official manuals are in project-106cef4c746c83/man. The private replay changes only the source identity/archive URL recorded in the original accepted proof; it loads the exact official47 library.

Root adoption recipe: extend existing apis/chemi-chet-admin-auth.yml selection/operations with held.yml entries for POST/auth/login, POST/auth/register, POST/auth/report; maintain existing id and canonical source. Add3exports/manuals/hook-config bespoke test registrations. Extend existing dev/chet-admin-auth/cases.json and tests/testthat/fixtures/native-chet-admin-auth.rds plus3names in test-native_chet_admin_auth.R (builder count14to17). Add focused finite-scalar and ambiguous-value rejection cases from accepted proof; use existing testserver rather than a new transport abstraction. Preserve public required body formals and exact canonical URLencoded schemas. No credential/session lifecycle is invented.

46to47 generator source diff is restricted to form_bodies.R and request.R freeform scalar handling. Fresh complete official helper comparison scaffold46-to47.diff confirms pagination/batch/decode companions unchanged. A separate227assertion PR179 replay on47 is retained beside forms proof, using the same frozen baseline as46.

No root adoption, deployed auth/session behavior, full package check or migration completion is claimed.
