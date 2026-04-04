# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**DO NOT** report security vulnerabilities through public GitHub issues.

Instead, please report them responsibly to our security team:

### Preferred Contact Method
- **Email**: security@candycrash.example.com (replace with actual email)
- **Expected Response Time**: Within 48 hours
- **Disclosure Timeline**: 90 days from initial report

### What to Include
Please provide:
- Description of the vulnerability
- Steps to reproduce
- Potential impact assessment
- Suggested fix (if available)
- Your contact information for follow-up

### Our Commitment
- Acknowledge receipt within 48 hours
- Provide regular status updates (at least weekly)
- Credit researchers who report valid vulnerabilities (unless anonymity requested)
- Coordinate disclosure timeline with reporter

## Security Best Practices

### For Users
- Always use HTTPS in production
- Keep Rails and all gems updated
- Use environment variables for secrets (never commit `.env`)
- Enable 2FA for admin accounts
- Regular security audits via `bundle audit`

### For Contributors
- Never commit secrets, API keys, or credentials
- Use strong parameter filtering in controllers
- Validate and sanitize all user input
- Follow OWASP Top 10 guidelines
- Run `brakeman` security scanner before PRs

## Security Tools

This project uses:
- **Brakeman**: Static analysis security scanner
- **Bundler Audit**: Checks for vulnerable gem versions
- **Rails Security Checklist**: Production deployment security

Run security checks:
```bash
# Install tools
gem install brakeman bundler-audit

# Run checks
brakeman --run-all-checks
bundle audit check --update
```

## Known Security Considerations

### Authentication
- Devise configured with secure defaults
- Password requirements: 6+ characters (configurable)
- Session timeout: 30 days (configurable)

### Authorization
- Pundit policies enforce role-based access
- All sensitive actions require authentication

### Data Protection
- Passwords hashed with bcrypt
- CSRF protection enabled
- SQL injection prevention via ActiveRecord
- XSS prevention via Rails HTML escaping

## Security Updates

We follow semantic versioning with security patches:
- **Patch releases** (1.0.x): Security fixes only
- **Minor releases** (1.x.0): Security + features
- **Major releases** (x.0.0): Breaking changes may include security redesigns

Subscribe to security advisories:
- GitHub Security Advisories (Watch this repository)
- Rails Security mailing list
- Ruby Security advisories

## Compliance

This application aims to comply with:
- OWASP Top 10 Web Application Security Risks
- GDPR (for EU student data)
- UK Data Protection Act 2018
- WCAG 2.1 Level AA (accessibility)

## Security Champions

Current security maintainers:
- See MAINTAINERS.md for contact information

Last updated: 2025-01-22
