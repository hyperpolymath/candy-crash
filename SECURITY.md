# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.1.x   | :white_check_mark: | (Gleam/AffineScript stack)
| 1.0.x   | :x:                | (Legacy Rails implementation)

## Reporting a Vulnerability

**DO NOT** report security vulnerabilities through public GitHub issues.

Instead, please report them responsibly to our security team:

### Preferred Contact Method
- **Email**: security@candycrash.example.com
- **Expected Response Time**: Within 48 hours
- **Disclosure Timeline**: 90 days from initial report

### What to Include
Please provide:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (if available)
- Your contact information for follow-up

## Security Best Practices

### For Users
- Always use HTTPS in production.
- Keep Gleam and all hex packages updated.
- Use environment variables for secrets (never commit `.env`).
- Ensure `gossamer` and `burble` are correctly configured.

### For Contributors
- Never commit secrets, API keys, or credentials.
- Use Gleam's strong type system to prevent injection attacks.
- Validate and sanitize all user input at the edge.
- All WASM components must be sandboxed.
- Follow OWASP Top 10 guidelines.

## Security Tools

This project uses:
- **Gleam Audit**: Checks for vulnerable Gleam packages.
- **AffineScript Linter**: Ensures type safety and security-best practices in WASM modules.
- **VeriSimDB Attestation**: Formally verifies data integrity.

## Known Security Considerations

### Authentication
- Authentication is handled via Gleam middleware.
- Passwords are hashed using Argon2id.

### Authorization
- Role-based access control (RBAC) enforced in the backend.

### Data Protection
- Sensitive data is encrypted before being stored in VeriSimDB.
- CSRF protection is enabled for all stateful requests.
- WASM-level isolation for frontend components.

## Compliance

This application aims to comply with:
- OWASP Top 10 Web Application Security Risks.
- GDPR (for EU student data).
- UK Data Protection Act 2018.
- WCAG 2.3 AAA (accessibility).

## Security Champions

Current security maintainers:
- See MAINTAINERS.md for contact information.

Last updated: 2025-01-22
