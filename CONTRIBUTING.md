# Contributing to zsh-ai

Thank you for your interest in contributing to zsh-ai! This document provides guidelines and instructions for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/zsh-ai.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests: `./run_tests.sh`
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/your-feature-name`
8. Submit a pull request

## Development Setup

### Prerequisites

- zsh 5.0+
- curl
- jq (optional but recommended)
- git

### Running the Plugin Locally

```bash
# Clone the repo
git clone https://github.com/matheusml/zsh-ai.git
cd zsh-ai

# Source the plugin in your current shell
source zsh-ai.plugin.zsh

# Test it out
# list files
```

## Testing

The project uses [zunit](https://github.com/zunit-zsh/zunit) for testing.

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run specific test file
./run_tests.sh tests/config.test.zsh

# Run tests matching a pattern
./run_tests.sh --filter "validates anthropic provider"
```

### Test Structure

```
tests/
├── test_helper.zsh         # Test utilities and mocking functions
├── config.test.zsh         # Configuration validation tests
├── context.test.zsh        # Context detection tests
├── providers/
│   ├── anthropic.test.zsh # Anthropic API tests
│   └── ollama.test.zsh    # Ollama API tests
├── widget.test.zsh         # Widget behavior tests
└── utils.test.zsh         # Utility function tests
```

### Writing Tests

Tests use zunit's BDD-style syntax:

```zsh
@test "Detects Node.js project" {
    touch package.json
    run _zsh_ai_detect_project_type
    assert "$output" equals "node"
}
```

#### Test Guidelines

1. **Test one thing at a time** - Each test should verify a single behavior
2. **Use descriptive test names** - Test names should clearly describe what is being tested
3. **Mock external dependencies** - Use the mock functions in `test_helper.zsh`
4. **Clean up after tests** - Use `@setup` and `@teardown` blocks
5. **Test edge cases** - Include tests for error conditions and boundary cases

#### Available Test Helpers

- `mock_command`: Mock any command with custom output and exit code
- `mock_curl_response`: Mock curl API responses
- `mock_jq`: Mock jq availability
- `assert_equals`: Assert exact string match
- `assert_contains`: Assert substring presence
- `assert_called`: Verify a mocked command was called

### CI/CD

Tests run automatically on GitHub Actions for:
- Every push to main branch
- All pull requests
- Multiple ZSH versions (5.8, 5.9)

## Code Style

### Shell Script Guidelines

- Use 4 spaces for indentation (no tabs)
- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html) conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Naming Conventions

- Internal functions: `_zsh_ai_function_name`
- User-facing functions: `zsh-ai-command`
- Variables: `lowercase_with_underscores`
- Constants: `UPPERCASE_WITH_UNDERSCORES`

## Adding New Features

### Provider Support

To add a new AI provider:

1. Create a new provider file: `lib/providers/newprovider.zsh`
2. Implement the query function: `_zsh_ai_query_newprovider()`
3. Add provider validation in `lib/config.zsh`
4. Update the router in `lib/utils.zsh`
5. Add comprehensive tests in `tests/providers/newprovider.test.zsh`
6. Update documentation

### Context Detection

To add new project type detection:

1. Update `_zsh_ai_detect_project_type()` in `lib/context.zsh`
2. Add test cases in `tests/context.test.zsh`
3. Consider the priority order of detection

## Submitting Pull Requests

### Before Submitting

- [ ] All tests pass (`./run_tests.sh`)
- [ ] New features include tests
- [ ] Code follows the style guidelines
- [ ] Commit messages are clear and descriptive
- [ ] Documentation is updated if needed

### PR Guidelines

1. **Keep PRs focused** - One feature/fix per PR
2. **Write clear descriptions** - Explain what and why
3. **Link related issues** - Use "Fixes #123" in the description
4. **Be responsive** - Address review feedback promptly
5. **Be patient** - Reviews may take time

### Commit Message Format

```
type: brief description

Longer explanation if needed. Wrap at 72 characters.

Fixes #123
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions or changes
- `refactor`: Code refactoring
- `style`: Code style changes
- `chore`: Maintenance tasks

## Reporting Issues

### Bug Reports

Please include:
- zsh version (`zsh --version`)
- OS and version
- Steps to reproduce
- Expected behavior
- Actual behavior
- Error messages (if any)

### Feature Requests

Please include:
- Use case description
- Expected behavior
- Why this would be valuable
- Possible implementation approach (optional)

## Questions?

Feel free to:
- Open an issue for questions
- Start a discussion in the Discussions tab
- Reach out to maintainers

Thank you for contributing to zsh-ai! 🎉