# Third-Party Licenses

This project has no third-party runtime libraries linked into the macOS app binary.

The app itself is built with Apple-provided SDKs/frameworks under Apple's developer terms.

## Build and CI Dependencies

The repository uses the following GitHub Actions in workflows:

1. `actions/checkout`
   - Repository: https://github.com/actions/checkout
   - License: MIT
2. `actions/github-script`
   - Repository: https://github.com/actions/github-script
   - License: MIT
3. `softprops/action-gh-release`
   - Repository: https://github.com/softprops/action-gh-release
   - License: MIT

## MIT License Text (for listed GitHub Actions)

Copyright (c) respective contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Notes

- If you add new third-party packages, update this file.
- Keep SPDX-compatible identifiers in future additions when possible.
