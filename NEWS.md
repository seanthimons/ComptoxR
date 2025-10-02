# ComptoxR 1.3.0



# ComptoxR NEWS

## Unreleased (2025-10-02)

#### New features

-   updated NEWS.md
    ([967e114](https://github.com/seanthimons/ComptoxR/tree/967e1143125dcf2651e5d768b21a6eba135afa22))
-   update input component styles and add new features
    ([3076ce7](https://github.com/seanthimons/ComptoxR/tree/3076ce7f89cd939d0c89c856fc5a47d203f4556c))
-   updated ct_hazard to new endpoints and added GET / POST methods.
    ([4017449](https://github.com/seanthimons/ComptoxR/tree/40174495727dff69d58c4fb5a2d4c848549adb5d))
-   added schema download feature
    ([c161f9a](https://github.com/seanthimons/ComptoxR/tree/c161f9aeb7c35b58b682ee4b74f37b42c3eb12e3))
-   enhance chemi_resolver output and documentation
    ([7c284eb](https://github.com/seanthimons/ComptoxR/tree/7c284eb9cca4d7376cca6da996f518c42fb10bc1))
-   add batch processing for large chemical queries
    ([ed1b5c3](https://github.com/seanthimons/ComptoxR/tree/ed1b5c3e29684672b0ac7bf33ca96e6cf9b8f669))
-   Add TODO comment for batched query preparation
    ([cae89c7](https://github.com/seanthimons/ComptoxR/tree/cae89c7e19e946dc11e457696077895ca105ed9f))
-   improve parameter validation and error handling in chemi_resolver
    ([609f673](https://github.com/seanthimons/ComptoxR/tree/609f67322ae68bf324b64644cf4f92a1d83037d5))
-   enhance chemi_resolver with ID type and fuzzy search options
    ([e66c86f](https://github.com/seanthimons/ComptoxR/tree/e66c86f53244cd72b0481d6dd45273a2fe3d19f2))

#### Bug fixes

-   updated documentation
    ([5205621](https://github.com/seanthimons/ComptoxR/tree/5205621229e307825bdfe5572030f34d6dedc237))
-   minor adjustment to server ping test
    ([b6dc2c2](https://github.com/seanthimons/ComptoxR/tree/b6dc2c2600ec162b9b81bd2fb14f1f46f4083589))
-   Update server path and added schema download
    ([91c2c82](https://github.com/seanthimons/ComptoxR/tree/91c2c8239408b8b0a7a1dcb2c251a227bfac6c2c))

#### Refactorings

-   simplify column renaming in chemi_resolver using rename_with
    ([5d3bf43](https://github.com/seanthimons/ComptoxR/tree/5d3bf43fbe36a6618ef6712b7c3fc43a0e5ee3d2))
-   simplify chemi_resolver query handling and response processing
    ([6e93660](https://github.com/seanthimons/ComptoxR/tree/6e936604f0fc4c03b60f2a24f7aca5ac78965c55))

#### Docs

-   improve chemi_resolver function documentation
    ([d21172e](https://github.com/seanthimons/ComptoxR/tree/d21172ede9e3bffa167a85e969cdf581fb67f256))

#### Other changes

-   update build script and bump minor version
    ([0a5aabc](https://github.com/seanthimons/ComptoxR/tree/0a5aabc9e7a50ac031d72a8e8534275980e0f199))

Full set of changes:
[`v1.2.2.9009...8b5df40`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9009...8b5df40)

## v1.2.2.9009 (2025-08-27)

#### New features

-   remove exposure and production volume endpoints
    ([6d1e946](https://github.com/seanthimons/ComptoxR/tree/6d1e94673ee21e279d922bcdf08cb61c2c5381f8))
-   reduce POST request chunk size and standardize pipe operators
    ([e0ef96f](https://github.com/seanthimons/ComptoxR/tree/e0ef96fc051a1a6545075b5ef7ea1b10c1748a4e))
-   add base request class implementation
    ([6ce800f](https://github.com/seanthimons/ComptoxR/tree/6ce800f01e3cce6ebd17cff51fa26281eed0b595))

#### Bug fixes

-   clean up server setup and error messages
    ([ca5b04d](https://github.com/seanthimons/ComptoxR/tree/ca5b04d447f69f09c91279f82c1d419b03445ae1))

#### Docs

-   update NEWS.md format and build process
    ([528b1c4](https://github.com/seanthimons/ComptoxR/tree/528b1c4300d03b433b681313b23d179b260dd2fa))

#### Other changes

-   remove unused/ old R functions, now available through stable/
    staging documentation.
    ([09526ef](https://github.com/seanthimons/ComptoxR/tree/09526ef49ebbcb5d1383aaf224f3a57d8a19aff6))
-   update GitHub Actions workflow with changelog builder
    ([bd86b4f](https://github.com/seanthimons/ComptoxR/tree/bd86b4f8cc2b12bee69e9d6477f62bd6cdca5fb3))

Full set of changes:
[`v1.2.2.9008...v1.2.2.9009`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9008...v1.2.2.9009)

## v1.2.2.9008 (2025-08-18)

#### Style

-   replace pipe operator |\> with %\>% for consistency
    ([577d215](https://github.com/seanthimons/ComptoxR/tree/577d215c4d1565d9f58b986c5afe3cdd6eaa7833))

Full set of changes:
[`v1.2.2.9007...v1.2.2.9008`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9007...v1.2.2.9008)

## v1.2.2.9007 (2025-07-16)

Full set of changes:
[`v1.2.2.9006...v1.2.2.9007`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9006...v1.2.2.9007)

## v1.2.2.9006 (2025-06-18)

Full set of changes:
[`v1.2.2.9005...v1.2.2.9006`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9005...v1.2.2.9006)

## v1.2.2.9005 (2025-06-17)

Full set of changes:
[`v1.2.2.9004...v1.2.2.9005`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9004...v1.2.2.9005)

## v1.2.2.9004 (2025-06-10)

Full set of changes:
[`v1.2.2.9003...v1.2.2.9004`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9003...v1.2.2.9004)

## v1.2.2.9003 (2024-08-21)

Full set of changes:
[`v1.2.2.9002...v1.2.2.9003`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9002...v1.2.2.9003)

## v1.2.2.9002 (2024-06-04)

Full set of changes:
[`v1.2.2.9001...v1.2.2.9002`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9001...v1.2.2.9002)

## v1.2.2.9001 (2024-05-23)

Full set of changes:
[`v1.2.2.9000...v1.2.2.9001`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9000...v1.2.2.9001)

## v1.2.2.9000 (2024-05-14)

Full set of changes:
[`v1.2.0...v1.2.2.9000`](https://github.com/seanthimons/ComptoxR/compare/v1.2.0...v1.2.2.9000)

## v1.2.0 (2023-12-19)

Full set of changes:
[`v1.1.0...v1.2.0`](https://github.com/seanthimons/ComptoxR/compare/v1.1.0...v1.2.0)

## v1.1.0 (2023-12-06)

Full set of changes:
[`v1.0.0...v1.1.0`](https://github.com/seanthimons/ComptoxR/compare/v1.0.0...v1.1.0)

## v1.0.0 (2023-07-18)

Full set of changes:
[`9a3b104...v1.0.0`](https://github.com/seanthimons/ComptoxR/compare/9a3b104...v1.0.0)
