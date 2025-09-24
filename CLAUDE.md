# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a multi-project developer workspace containing diverse systems spanning financial trading, web development, AI-powered automation, and Korean language content management. The workspace has grown organically and contains several major project categories:

- **Trading Systems**: MQL4/MQL5 Expert Advisors for MetaTrader platforms (EA31337, collections)
- **AI/ML Projects**: LLM integration tools, automation frameworks, and business plan generators  
- **Web Development**: React/TypeScript projects, utilities, and content management tools
- **Korean Content Management**: Documentation systems, publishing tools, and localization frameworks
- **Security Research**: Downloaded cybersecurity educational resources and analysis tools

## Primary Projects and Build Commands

### EA31337 Trading System (MQL4/MQL5)
**Location**: `EA31337/`
```bash
# Requirements check
make requirements

# Build variants (Lite/Advanced/Rider modes)
make EA                    # Build all EA variants
make Lite                 # Build Lite version only
make Advanced             # Build Advanced version only
make Rider                # Build Rider version only

# Release builds
make Release              # Build all release versions
make Lite-Release         # Build Lite release version
make Advanced-Release     # Build Advanced release version
make Rider-Release        # Build Rider release version

# Testing and optimization builds
make Backtest            # Build backtest versions
make Optimize            # Build optimization versions

# Compilation targets
make compile-mql4        # Compile MQL4 version
make compile-mql5        # Compile MQL5 version

# Cleanup
make clean-all          # Clean all build artifacts
make clean-src          # Clean source artifacts

# Installation (MetaTrader 4)
make mt4-install        # Install to MetaTrader 4 Experts folder
```


### Awesome Claude Code (Python)
**Location**: `awesome-claude-code/`
```bash
# Development setup
pip install -e ".[dev]"

# Code quality
ruff check               # Lint code
ruff format             # Format code
pre-commit run --all-files  # Run all pre-commit hooks

# Testing
pytest                  # Run tests
make test               # Run validation tests

# Resource management (using Makefile)
make add_resource       # Interactive tool to add new resource
make submit             # One-command submission workflow
make validate           # Validate all links in resource CSV
make generate           # Generate README from CSV data
make sort               # Sort resources by category
make update             # Process and validate resources
make clean              # Remove generated files

# Manual scripts (alternative to Makefile)
python scripts/generate_readme.py      # Generate README from resources
python scripts/validate_links.py       # Validate all resource links
python scripts/add_resource.py         # Add new resource
```

### SuperClaude Framework (Python)
**Location**: `SuperClaude_Framework/`
```bash
# Installation
pip install -e .

# Run SuperClaude CLI
SuperClaude             # CLI entry point

# Development mode
python -m SuperClaude   # Run as module
```

### Web Projects (Node.js/TypeScript)
**Location**: `wjswkcp-ebook-creator/`, `bazi-calculator-by-alvamind/`
```bash
# Install dependencies
npm install
# or for bazi calculator specifically
bun install             

# Development
npm run dev            # Start development server
npm run build          # Build for production
npm run lint           # Lint code (if configured)
npm test               # Run tests (if configured)
```

### TikTok Automation Tools (Python)
**Location**: `TikTokAutoUploader/`, `tiktok-autouploader/`
```bash
# Install requirements
pip install -r requirements.txt

# Run automation (check specific README in each directory)
python run.py           # Main automation script
python TikTok_Uploader.py  # Alternative uploader
```

### Korean Contact Management Tools (Python)
**Location**: `저작권/` (contact management scripts)
```bash
# Install requirements
pip install -r requirements.txt

# Contact management workflows
python excel_to_vcf_converter.py    # Convert Excel to VCF format
python phone_data_manager.py        # Manage phone contact data
python kakao_contact_manager_gui.py # GUI for KakaoTalk contacts
```

### Document Processing and Conversion (Python)
**Location**: Various scripts in `저작권/`
```bash
# PDF processing utilities
python pdf_to_txt_converter.py      # Basic PDF to text conversion
python pdf_to_txt_advanced.py       # Advanced PDF processing with OCR
python pdf_to_txt_ocr.py            # OCR-specific processing

# Image processing
python resize_image.py               # Image resizing utilities
```

## Architecture and Code Organization

### Trading Systems Architecture
- **EA31337**: Advanced modular expert advisor framework
  - `src/EA31337.mq4/.mq5`: Main EA source files
  - `src/include/`: Shared header files and includes
  - `sets/`: Optimized parameter sets for different strategies
  - Mode-based compilation system supporting Lite/Advanced/Rider variants
  - Cross-platform compilation using Wine + MetaEditor on Linux/macOS


### Web Development Structure
- **Modern Stack**: React/TypeScript with modern build tools (Webpack, Vite)
- **Multi-platform**: Support for npm, yarn, and bun package managers
- **Component Architecture**: Reusable component libraries and design systems

### Korean Content Management
- **Multi-format Support**: HWP, Markdown, and various Korean document formats
- **Encoding**: UTF-8 throughout with proper Korean character support
- **Publishing Pipeline**: Content creation → Review → Publication workflows

### Security Research Collection
- **Educational Resources**: Comprehensive cybersecurity learning materials
- **Analysis Tools**: Security analysis and penetration testing resources
- **Research Organization**: Categorized by security domains and skill levels

## Development Conventions

### MQL4/MQL5 Development
- Follow EA31337 framework patterns and conventions
- Use MetaTrader standard naming conventions and file organization
- Implement comprehensive error handling and logging systems
- Utilize Strategy Tester for thorough backtesting before deployment
- Store optimized parameters in SET files with version control

### Python Development
- Adhere to PEP 8 style guidelines with Black/Ruff formatting
- Use type hints for better code documentation and IDE support
- Implement comprehensive unit testing with pytest
- Manage dependencies with virtual environments and requirements.txt
- Follow semantic versioning for releases

### Web Development
- Use modern JavaScript/TypeScript best practices and ESLint configurations
- Implement responsive design patterns with mobile-first approach
- Include comprehensive error handling and user feedback systems
- Optimize for performance, accessibility, and SEO
- Use consistent naming conventions across components and modules

### Korean Language Development
- Ensure UTF-8 encoding across all text processing
- Implement proper Korean text handling and normalization
- Support Korean government standards and documentation formats
- Include Korean language validation and input methods
- Use HWP format support for official Korean documents


## Key File Locations

### Trading Systems
- EA31337 main source: `EA31337/src/EA31337.mq4` and `EA31337/src/EA31337.mq5`
- MQL4 collections: `github-mql4-collection/` and `mql4_experts/`
- Trading templates and utilities: `mql4-template/`, `ma-cross-ea/`


### Web Development
- E-book creator: `wjswkcp-ebook-creator/`
- Bazi calculator: `bazi-calculator-by-alvamind/`
- Static web examples: `popup.html`

### Documentation and Content
- Project documentation: `Documents/`, `md/`
- Korean language content: `hwp/`, `저작권/`
- Technical manuals: `manual/`
- SuperClaude framework docs: `SuperClaude_Framework/Docs/`

### Automation Tools
- TikTok automation: `TikTokAutoUploader/`, `tiktok-autouploader/`
- Contact management: Various Python scripts in `저작권/`
- Data conversion utilities: Scattered across multiple directories

## Environment Setup and Dependencies

### Core System Requirements
- **Python**: 3.8+ (3.11+ recommended for modern projects)
- **Node.js**: 16+ with npm/yarn/bun support
- **Wine64**: Required for MetaTrader compilation on Linux/macOS
- **Korean Language Support**: Fonts and input methods for Korean content

### MetaTrader Development Environment
```bash
# Wine configuration for cross-platform development
export WINEDEBUG=fixme-all

# MetaTrader installation path
export MT_PATH="$HOME/.wine/drive_c/Program Files/MetaTrader 4"
```

### Python Virtual Environment Setup
```bash
# Create isolated development environment
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows

# Install common dependencies
pip install -r requirements.txt  # If available
# Or install manually:
pip install tqdm python-docx requests beautifulsoup4 selenium pandas
```

### Node.js Project Setup
```bash
# Install dependencies
npm install  # or yarn install / bun install

# Development server
npm run dev  # Start development with hot reload

# Production build
npm run build && npm run preview
```

## Data Management and Storage

### Directory Structure
```
/
├── EA31337/                           # Trading system main project
├── awesome-claude-code/               # Claude Code resource collection
├── bazi-calculator-by-alvamind/       # TypeScript Bazi calculator
├── github-mql4-collection/            # MQL4 trading expert advisors collection
├── 저작권/                            # Korean intellectual property content
│   ├── contacts/                      # Contact management data
│   └── AI-Security-Projects-Downloaded/  # Security research materials
├── Documents/                         # General project documentation
├── hwp/                               # Korean HWP document files
├── manual/                            # Technical manuals and guides
└── md/                                # Various documentation and guides
```

### Data Processing Pipelines
- **Contact Management**: Excel → Python Processing → VCF/CSV Export
- **Trading Data**: Historical Data → Backtesting → Optimization → Strategy Files
- **Document Processing**: PDF → Text conversion with OCR support

## Testing and Quality Assurance

### Trading System Testing
```bash
# Run EA31337 backtests
make Backtest           # Build backtest versions
# Use MetaTrader Strategy Tester for comprehensive testing

# Parameter optimization
make Optimize           # Build optimization versions
```

### Python Testing
```bash
# Run test suites
pytest                  # awesome-claude-code
python -m pytest       # General pytest execution

# Code quality
ruff check              # Linting
ruff format             # Code formatting
pre-commit run --all-files  # Pre-commit hooks

```

### Manual Testing Procedures
- **Web Applications**: Cross-browser testing and responsive design validation
- **Korean Content**: Character encoding and font rendering verification
- **Document Processing**: PDF to text conversion accuracy verification
- **Contact Management**: Excel to VCF conversion validation

### Logging and Monitoring
**Log Files**:
- Application-specific log files generated by individual tools
- TikTok automation logs
- Document processing operation logs

**Real-time Monitoring**:
```bash
# Monitor active processes
tail -f application.log

# Check system status for resource-intensive operations
```

## Important Operational Notes

### Security and Safety
1. **Trading Systems**: All trading systems are for educational and backtesting purposes. Use proper risk management and never risk capital you cannot afford to lose.

2. **Web Scraping**: Respect robots.txt and implement rate limiting to avoid overloading target servers.

3. **API Usage**: Monitor API rate limits and implement proper error handling for external services.

4. **Document Processing**: Ensure proper handling of Korean characters in PDF and document conversion processes.

### Cross-Platform Considerations
- **Wine Dependencies**: MetaTrader compilation requires Wine64 on non-Windows systems
- **Korean Fonts**: Ensure proper Korean font installation for document rendering
- **File Encoding**: Maintain UTF-8 encoding for all Korean text processing
- **Path Separators**: Use platform-appropriate path handling in scripts

### Performance Optimization
- **Concurrent Processing**: Leverage multiprocessing for batch operations
- **Memory Management**: Monitor memory usage during large-scale operations
- **Caching**: Implement caching for frequently accessed data

### Version Control Best Practices
- **Git LFS**: Use for large binary files (videos, compiled executables)
- **Sensitive Data**: Never commit API keys, credentials, or personal information
- **Korean Content**: Ensure proper Git configuration for Korean file names
- **Binary Files**: Be selective about which compiled files to include in version control

This workspace represents a sophisticated multi-domain development environment with particular strengths in financial technology, web development automation, and Korean language processing. The modular architecture allows independent development of different components while sharing common infrastructure and utilities.