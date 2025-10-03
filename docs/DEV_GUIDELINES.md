## Development Workflow Guidelines



## Coding Standards
- Backend: Follow Go standard formatting
- Frontend: Follow Flutter/Dart style guide
- Document new features
- Include tests for new functionality


### Code Philosophy: YAGNI Principles

**YAGNI (You Aren't Gonna Need It)** is our core development principle for maintaining clean, maintainable code:

#### 🎯 **Core Principles**
- **Implement only what you need NOW** - Not what you might need in the future
- **Keep dependencies minimal** - Import and depend only on what's immediately used
- **Avoid speculative code** - Don't write abstractions for hypothetical use cases
- **Prioritize code clarity** - Simple, direct solutions over complex frameworks
- **Remove unused code** - Dead code adds maintenance burden without value

#### 📦 **Import Guidelines**
- ❌ **Don't import speculative dependencies** - Add only when actively used
- ✅ **Remove unused imports immediately** - Go build warnings must be zero
- ✅ **Keep imports minimal** - Only import what's actively used in the file

#### 🏗️ **Architecture Guidelines**
- ❌ **Don't create generic frameworks** - For the sake of future hypothetical use
- ✅ **Build specific solutions** - That solve current, concrete problems
- ✅ **Refactor when needed** - Evolution through real requirements, not anticipation
- ✅ **Keep interfaces simple** - Complex APIs indicate over-engineering

#### 🔧 **Testing Philosophy**
- ❌ **Don't test for future features** - Only test implemented functionality
- ✅ **Test what exists** - Comprehensive coverage of current code
- ✅ **Avoid brittle tests** - Tests should serve code, not constrain evolution
- ✅ **TDD-First Development** - Write tests BEFORE implementing features
- ✅ **Red-Green-Refactor** - Make tests fail first, then implement, then clean up

### Definition of Done

#### ✅ **Before Git Check-In (Daily Code Review)**
- **Compilation**: `go build` passes with **zero errors**
- **Unit Tests**: All related unit tests pass (`go test ./...`)
- **Code Quality**: `go vet` passes with acceptable warnings only
- **Code Formatting**: `gofmt -d .` shows no formatting differences
- **Self Review**: Code meets YAGNI principles, no dead code or unused imports
- **Documentation**: New functionality documented if user-facing

#### ✅ **Before Release/New Version**
- **Full Test Suite**: `go test ./...` passes completely
- **Integration Tests**: All integration tests pass (network tests with appropriate environments)
- **Performance Tests**: `./test_release.sh` passes with acceptable timing
- **Cross-Platform**: Binaries build successfully for supported platforms
- **API Compatibility**: No breaking changes without version bump justification
- **Documentation**: All new features documented in appropriate guides
- **Changelog**: CHANGELOG.md updated with comprehensive change summary
- **Security Review**: No new security vulnerabilities introduced
- **Dependency Check**: `go mod verify` passes and no critical vulnerabilities (`go mod why` for dependency auditing)

> **Note:** Frequent, incremental check-ins are encouraged for ongoing work. A formal Release should be created only when a cohesive piece of functionality is complete. The CHANGELOG for that release must comprehensively document the full set of changes.
