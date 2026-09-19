# Contributing to Candy Crash

Thank you for your interest in contributing to Candy Crash! This
document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)

- [Getting Started](#getting-started)

- [Development Workflow](#development-workflow)

- [Coding Standards](#coding-standards)

- [Testing Requirements](#testing-requirements)

- [Commit Guidelines](#commit-guidelines)

- [Pull Request Process](#pull-request-process)

- [Security Vulnerabilities](#security-vulnerabilities)

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are
expected to follow. Please read
<a href="../CODE_OF_CONDUCT.adoc" class="adoc">CODE_OF_CONDUCT</a> before
contributing.

## Getting Started

### Prerequisites

- Ruby 3.3.6

- Rails 7.1.3

- SQLite3

- Node.js (for asset compilation)

- Git

### Setup Development Environment

``` bash
# Clone the repository
git clone https://github.com/Hyperpolymath/candy-crash.git
cd candy-crash

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Run tests
rspec

# Start development server
rails server
```

## Development Workflow

1.  **Fork the repository** and create your branch from `main`

2.  **Make your changes** following our coding standards

3.  **Write tests** for new functionality

4.  **Update documentation** as needed

5.  **Run the test suite** and ensure all tests pass

6.  **Submit a pull request**

### Branch Naming Convention

- `feature/description` - New features

- `fix/description` - Bug fixes

- `docs/description` - Documentation updates

- `refactor/description` - Code refactoring

- `test/description` - Test additions/improvements

## Coding Standards

### Ruby Style Guide

We follow the [Ruby Style Guide](https://rubystyle.guide/) with these
conventions:

- **Indentation**: 2 spaces (no tabs)

- **Line length**: 120 characters maximum

- **Method length**: Keep methods under 10 lines when possible

- **Class length**: Keep classes focused and under 100 lines

### Rails Conventions

- Keep controllers thin, models fat

- Use service objects for complex business logic

- Follow RESTful routing conventions

- Use strong parameters for security

- Write self-documenting code with clear naming

### Code Quality Tools

``` bash
# Run RuboCop for style checking
rubocop

# Auto-fix violations
rubocop -a

# Run Brakeman for security analysis
brakeman

# Check for vulnerable dependencies
bundle audit check
```

## Testing Requirements

### Test Coverage

- All new features must include tests

- Bug fixes should include regression tests

- Aim for \>80% code coverage

- Test both happy paths and error cases

### Running Tests

``` bash
# Run all tests
rspec

# Run specific test file
rspec spec/models/user_spec.rb

# Run with coverage report
COVERAGE=true rspec
```

### Test Structure

- **Unit tests**: Test individual methods and classes

- **Integration tests**: Test component interactions

- **Request tests**: Test HTTP endpoints

- **System tests**: Test user workflows (optional)

## Commit Guidelines

### Commit Message Format

    <type>(<scope>): <subject>

    <body>

    <footer>

**Types:**

- `feat`: New feature

- `fix`: Bug fix

- `docs`: Documentation only

- `style`: Formatting, missing semicolons, etc.

- `refactor`: Code restructuring

- `test`: Adding tests

- `chore`: Maintenance tasks

**Example:**

    feat(courses): Add course search functionality

    Implement ransack-based search allowing users to filter
    courses by title, category, and difficulty level.

    Closes #123

### Commit Best Practices

- Use present tense ("Add feature" not "Added feature")

- Use imperative mood ("Move cursor to…" not "Moves cursor to…")

- First line max 50 characters

- Body wrapped at 72 characters

- Reference issues and PRs when relevant

## Pull Request Process

### Before Submitting

- [ ] All tests pass (`rspec`)

- [ ] Code passes linting (`rubocop`)

- [ ] Security scan passes (`brakeman`)

- [ ] Documentation updated

- [ ] CHANGELOG.adoc updated (for significant changes)

- [ ] Database migrations tested both up and down

### PR Template

    ## Description
    Brief description of changes

    ## Type of Change
    - [ ] Bug fix
    - [ ] New feature
    - [ ] Breaking change
    - [ ] Documentation update

    ## Testing
    How has this been tested?

    ## Checklist
    - [ ] Tests pass
    - [ ] Code follows style guidelines
    - [ ] Self-review completed
    - [ ] Documentation updated

### Review Process

1.  **Automated checks** must pass (CI/CD pipeline)

2.  **At least one maintainer** must approve

3.  **Security review** required for auth/authorization changes

4.  **Performance impact** assessed for database/query changes

### Merge Strategy

- We use **squash and merge** for feature branches

- Maintain **linear history** on main branch

- Delete branch after merge

## Security Vulnerabilities

**Never** report security issues via public GitHub issues.

See <a href="../SECURITY.md" class="md">SECURITY</a> for responsible
disclosure procedures.

## Recognition

Contributors are recognized in:

- Git commit history

- CHANGELOG.adoc for significant contributions

- README.adoc contributors section (optional)

- Annual contributor appreciation (if applicable)

## Questions?

- Open a **Discussion** for general questions

- **Issue tracker** for bugs and feature requests

- Contact maintainers (see MAINTAINERS.adoc)

## License

By contributing, you agree that your contributions will be licensed
under the same license as the project (see LICENSE file).

------------------------------------------------------------------------

Thank you for making Candy Crash better! 🚗📚

## Local environment setup

_Carried over from the former root `CONTRIBUTING.md` when the guide moved to `.github/`, so nothing is lost: the setup steps this repository had at the root._

git clone https://github.com/hyperpolymath/candy-crash.git
cd candy-crash

# Using Guix (recommended for reproducibility)
guix develop

# Or using toolbox/distrobox
toolbox create candy-crash-dev
toolbox enter candy-crash-dev
# Install dependencies manually

# Verify setup
just check   # or: cargo check / mix compile / etc.
just test    # Run test suite
```

### Repository Structure
```
candy-crash/
├── src/                 # Source code (Perimeter 1-2)
├── lib/                 # Library code (Perimeter 1-2)
├── extensions/          # Extensions (Perimeter 2)
├── plugins/             # Plugins (Perimeter 2)
├── tools/               # Tooling (Perimeter 2)
├── docs/                # Documentation (Perimeter 3)
│   ├── architecture/    # ADRs, specs (Perimeter 2)
│   └── proposals/       # RFCs (Perimeter 3)
├── examples/            # Examples (Perimeter 3)
├── spec/                # Spec tests (Perimeter 3)
├── tests/               # Test suite (Perimeter 2-3)
├── .well-known/         # Protocol files (Perimeter 1-3)
├── .github/             # GitHub config (Perimeter 1)
│   ├── CONTRIBUTING.md  # This file
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── GOVERNANCE.md
├── LICENSE
├── MAINTAINERS.md
├── README.adoc
├── SECURITY.md
├── flake.guix            # Guix flake (Perimeter 1)
└── Justfile             # Task runner (Perimeter 1)
```

---

## How to Contribute

### Reporting Bugs

**Before reporting**:
1. Search existing issues
2. Check if it's already fixed in `main`
3. Determine which perimeter the bug affects

**When reporting**:

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:

- Clear, descriptive title
- Environment details (OS, versions, toolchain)
- Steps to reproduce
- Expected vs actual behaviour
- Logs, screenshots, or minimal reproduction

### Suggesting Features

**Before suggesting**:
1. Check the [roadmap](ROADMAP.md) if available
2. Search existing issues and discussions
3. Consider which perimeter the feature belongs to

**When suggesting**:

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- Problem statement (what pain point does this solve?)
- Proposed solution
- Alternatives considered
- Which perimeter this affects

### Your First Contribution

Look for issues labelled:

- [`good first issue`](https://github.com/hyperpolymath/candy-crash/labels/good%20first%20issue) — Simple Perimeter 3 tasks
- [`help wanted`](https://github.com/hyperpolymath/candy-crash/labels/help%20wanted) — Community help needed
- [`documentation`](https://github.com/hyperpolymath/candy-crash/labels/documentation) — Docs improvements
- [`perimeter-3`](https://github.com/hyperpolymath/candy-crash/labels/perimeter-3) — Community sandbox scope

---

## Development Workflow

### Branch Naming
```
docs/short-description       # Documentation (P3)
test/what-added              # Test additions (P3)
feat/short-description       # New features (P2)
fix/issue-number-description # Bug fixes (P2)
refactor/what-changed        # Code improvements (P2)
security/what-fixed          # Security fixes (P1-2)
```

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/):
```
<type>(<scope>): <description>

[optional body]

[optional footer]
