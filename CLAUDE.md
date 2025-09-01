# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a complex multi-project workspace containing diverse software projects across different domains including AI frameworks, trading systems, security tools, web applications, and research projects. The repository serves as a development workspace with active projects in various stages of development.

## Key Project Categories

### AI/ML Frameworks & Tools
- **agentic-radar**: Poetry-based Python library for generating agentic system reports
- **cai**: Modern UV-based cybersecurity AI framework with multi-agent capabilities
- **SuperClaude_Framework**: Claude Code extension framework with command system and MCP integration
- **llm-guard**: Security framework for LLM applications
- **promptfoo**: LLM evaluation and red teaming toolkit (TypeScript/Node.js)

### Financial Trading Systems & Libraries
- **MQ4/**: MetaTrader 4/5 trading ecosystem
  - EA31337, nomadtown-ea-system, and trading indicators
  - **IMPORTANT**: Educational/research purposes only
- **aaaa/**: 40+ quantitative finance libraries collection
  - Major libraries: freqtrade (40k stars), ccxt (32k stars), openbb (28k stars)
  - pandas, numpy, matplotlib (scientific computing stack)
  - Research papers from Goldman Sachs, JPMorgan, academic institutions
- **ea31337-src/**: Expert Advisor source code collection

### Security & Network Tools
- **medusa/**: C/Autotools network login brute-forcer
  - **WARNING**: Security research only - authorized testing required
  - Modular design with 20+ protocol modules (SSH, HTTP, SMB, etc.)
  - Built with `./configure && make`

### Web Applications & Crowdfunding
- **fund-02/**: Full-stack crowdfunding platform
  - Frontend: HTML5/CSS3/Bootstrap 5/Chart.js static version
  - Backend: Flask with SQLAlchemy ORM and PostgreSQL support
  - Admin panel with authentication (password: nomadtown2025!)
- **php/**: Alternative PHP implementation

### Research & Academic Tools
- **PDF/**: Academic paper processing pipeline
  - Automated downloaders for arXiv and Korean academic sources
  - PDF-to-Markdown conversion with metadata extraction
  - Scheduled crawling and content analysis
- **Projects/0801/**: Real-time document scanning and metadata extraction
- **Projects/0801 FOLDER/**: Flutter mobile app collection and project management tools

## Development Commands by Project Type

### Python Projects

#### Poetry-based Projects (agentic-radar)
```bash
# Setup
poetry install

# Development
poetry run pytest                    # Run tests
poetry run ruff check               # Linting
poetry run mypy .                   # Type checking

# CLI usage
poetry run agentic-radar            # Main CLI
```

#### UV-based Modern Projects (cai)
```bash
# Setup
uv sync                             # Install dependencies

# Development
uv run pytest                       # Run tests  
uv run ruff check                   # Linting
uv run mypy .                       # Type checking

# CLI usage
uv run cai                          # Main CLI command
uv run cai-cli                      # Alternative CLI
```

#### Hatchling-based Projects (SuperClaude_Framework)
```bash
# Setup
pip install -e .                    # Editable install

# Development
python -m pytest                    # Run tests
python -m SuperClaude               # Run CLI

# Build
python -m build                     # Build wheel/sdist
```

#### Standard Python Projects (llm-guard, PDF tools)
```bash
# Setup
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or venv\Scripts\activate  # Windows
pip install -r requirements.txt

# Development
pytest                              # Run tests
python -m flask run                 # Flask apps
black .                             # Code formatting
flake8                              # Linting
```

### Node.js/TypeScript Projects

#### Promptfoo (LLM Evaluation)
```bash
# Setup
npm install                         # Install dependencies

# Development
npm run build                       # Build project
npm test                            # Run tests
npm run lint                        # ESLint

# Usage
npx promptfoo eval                  # Run evaluations
npx promptfoo redteam               # Security testing
```

### C/C++ Projects (medusa)
```bash
# Build
./configure                         # Configure build
make                               # Compile
make install                       # Install (as root)

# Development
make clean                         # Clean build files
make distclean                     # Full cleanup

# Usage (security research only)
./medusa -h                        # Help
./medusa -H hosts.txt -U users.txt -P passwords.txt -M ssh

# Available modules
ls *.so                            # List compiled modules
./medusa -d                        # List available modules
```

### Web Applications

#### Flask-based Crowdfunding (fund-02)
```bash
# Development setup
python -m venv funding_env
source funding_env/bin/activate    # Linux/Mac
pip install -r requirements.txt

# Development server
python app.py                      # SQLite backend
python app_postgresql.py           # PostgreSQL backend

# Production
gunicorn app:app --bind 0.0.0.0:5000

# Database migration
python migrate_data.py             # Migrate to PostgreSQL

# Frontend (static version)
python -m http.server 8000
# Access: admin.html (password: nomadtown2025!)
```

#### PHP Alternative
```bash
# Setup
php -S localhost:8000              # Development server
```

### Academic/Research Tools

#### PDF Processing Pipeline
```bash
# Enhanced paper scheduler
python enhanced_paper_scheduler.py  # Main scheduler
python korean_enhanced_scheduler.py # Korean papers only

# Manual processing
python academic_document_scanner.py # Scan documents
python txt_to_md_converter.py      # Convert formats

# Setup scheduled processing
bash setup_enhanced_cron.sh        # Setup automation
```

#### Document Analysis (Projects/0801)
```bash
# Real-time scanning
python realtime_document_scanner.py
python continuous_scanner.py

# Metadata extraction
python document_metadata_extractor.py
python document_type_detector.py
```

## High-Level Architecture Patterns

### Multi-Language Ecosystem
The repository demonstrates several architectural patterns:

1. **Python-Centric AI Tools**: Modern Python projects using Poetry/UV for dependency management
2. **Legacy C/Autotools**: Traditional Unix-style tools (medusa) with autotools build system
3. **Web Stack Diversity**: From pure HTML/JS to Flask applications
4. **Research Pipeline**: Document processing and academic paper management systems

### Key Architectural Components

#### AI Framework Integration (SuperClaude)
- **Framework Files**: Documentation-driven behavior in `~/.claude/`
- **MCP Integration**: External service connections (Context7, Sequential, Magic, Playwright)
- **Command System**: 16 specialized slash commands for development tasks
- **Persona System**: Auto-activated AI specialists for different domains
- **Token Optimization**: Intelligent compression and caching strategies

#### Modern Python Development Patterns
- **UV Package Manager**: Fast dependency resolution and virtual environments
- **Poetry**: Dependency management with lock files and semantic versioning
- **Hatchling**: Modern build backend for packaging
- **Type Safety**: mypy, ruff for modern Python tooling
- **Multi-Agent Architecture**: CAI framework with agent coordination

#### Security Architecture (medusa, cai)
- **Modular Design**: Plugin-based service modules (.so files)
- **Multi-Protocol Support**: 20+ protocols (SSH, HTTP, FTP, SMB, RDP, etc.)
- **Thread-Safe Operations**: Parallel testing with configurable concurrency
- **Configuration-Driven**: External config files and combo files
- **AI-Enhanced Security**: CAI integration for intelligent threat analysis

#### Financial Systems Architecture
- **Expert Advisor Pattern**: MQL4/5 automated trading systems
- **Quantitative Libraries**: 40+ libraries spanning backtesting to live trading
- **Multi-Exchange Support**: CCXT-based unified API for 100+ exchanges
- **Research Integration**: Academic papers and institutional reports
- **Risk Management**: Position sizing, drawdown control, portfolio optimization

### Data Flow Patterns

1. **Research Pipeline**: PDF → Processing → Markdown → Analysis → Knowledge Base
2. **Trading Pipeline**: Market Data → Indicators → Signals → Risk Check → Orders → Portfolio
3. **Security Pipeline**: Targets → Modules → Tests → Results → Reports → Mitigation
4. **Web Pipeline**: Frontend → API → Database → Admin Panel → Analytics
5. **AI Development**: Data → Training → Model → Evaluation → Deployment → Monitoring
6. **Academic Processing**: Scheduled Crawl → Download → Convert → Extract Metadata → Store

## Development Workflow Guidelines

### Before Starting Work
1. Identify project type and technology stack
2. Check for project-specific README files
3. Verify required dependencies and tools
4. Review any security considerations (especially for medusa, trading tools)

### Working with Multiple Projects
- Each project has its own development environment
- Use virtual environments for Python projects
- Check build requirements for C/C++ projects
- Be aware of project-specific licensing and usage restrictions

### Security Considerations
- **medusa**: Only use for authorized security testing
- **Trading tools**: Educational/research purposes only
- **Academic tools**: Respect copyright and usage terms
- **Web applications**: Use provided test credentials, change for production

### Testing Approach
- **Python projects**: Use pytest with project-specific configurations
  - Poetry: `poetry run pytest`
  - UV: `uv run pytest`  
  - Virtual env: `pytest`
- **C projects**: Check for test suites in source directories, use `make check`
- **Node.js projects**: `npm test` or `yarn test`
- **Web applications**: Test both frontend and backend components
- **Security tools**: Use isolated test environments only
- **Financial tools**: Backtest with historical data before any live testing

## Important Notes

### Legal and Ethical Usage
- **Security tools**: Only use on systems you own or have explicit permission to test
- **Trading systems**: Past performance does not guarantee future results
- **Academic content**: Respect copyright and fair use guidelines
- **Web applications**: Change default passwords and secure for production use

### Performance Considerations
- **AI frameworks**: May require significant computational resources
- **Trading systems**: Real-time processing requirements
- **Document processing**: Handle large file processing efficiently
- **Web applications**: Consider scalability for production deployment

## Project-Specific Quick Reference

### Common Build Commands by Technology
- **Poetry projects**: `poetry install && poetry run pytest`
- **UV projects**: `uv sync && uv run pytest`
- **C/Autotools**: `./configure && make && make check`
- **Node.js**: `npm install && npm test`
- **Flask apps**: `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python app.py`

### Key Configuration Files to Check
- **Python**: `pyproject.toml`, `requirements*.txt`, `setup.py`
- **Node.js**: `package.json`, `tsconfig.json`
- **C/C++**: `configure.ac`, `Makefile.am`, `CMakeLists.txt`
- **Web**: Look for `app.py`, `index.html`, database config files

### Directory Structure Patterns
- **Multi-language projects** often have language-specific subdirectories
- **Research tools** typically separate raw data, processed data, and scripts
- **Financial projects** separate indicators, strategies, and backtesting
- **Security tools** have modular architecture with separate protocol handlers

This repository represents a sophisticated development environment with projects spanning multiple domains. Each project should be approached with understanding of its specific purpose, technology stack, and usage constraints.