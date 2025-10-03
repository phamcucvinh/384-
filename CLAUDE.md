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
**Location**: `저작권/work/01_HIGH_PRIORITY/EA31337/`
```bash
# Requirements check (requires git, ex, wine64)
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

# Testing modes
make set-testing        # Set testing mode
make test              # Run tests with wine64
```


### SpanModelTrader (MQL4)
**Location**: `SpanModelTrader/`
```bash
# 일본식 기술적 분석 EA - 일목균형표 + 슈퍼볼린저 조합

# 설치 및 실행
cp -r SpanModelTrader/* "$MT_PATH/MQL4/"
# MetaEditor에서 컴파일 후 차트 적용 (권장: H1, USDJPY/EURJPY)

# 주요 기능: 3중 신호 필터, MTF 분석, 자동 리스크 관리, 일본어 로깅
```

### Trailing-Stop-on-Profit (MT4/MT5/cTrader)
**Location**: `Trailing-Stop-on-Profit/`
```bash
# 수익 달성 후 자동 손절 이동 EA (EarnForex.com)

# 설치
# MT4: Copy to MQL4/Experts/
# MT5: Copy to MQL5/Experts/

# 기능
# - 설정한 수익 포인트 달성 시 자동으로 손절가 추적
# - 차트 버튼으로 간편한 활성화/비활성화
# - 필터링 옵션으로 특정 거래만 선택 가능
# - 완전 자동화된 손절 관리

# 상세 가이드: https://www.earnforex.com/metatrader-expert-advisors/Trailing-Stop-on-Profit/
```

### Show-Time-To-Close-Indicator (MT4/MT5)
**Location**: `Show-Time-To-Close-Indicator-Metatrader/`
```bash
# 캔들 종료까지 남은 시간 실시간 표시 인디케이터 (TFLab)

# 설치
# MT4: ShowTimeToClose MT4 - By TFLab.mq4 → MQL4/Indicators/
# MT5: Show Time To Close MT5 - By TFLab.mq5 → MQL5/Indicators/

# 주요 기능
# - 실시간 카운트다운 (HH:MM:SS 형식)
# - 모든 타임프레임 지원 (M1~MN1)
# - 커스터마이징 가능 (위치, 색상)
# - 주간/월간 차트는 "XD & HH:MM:SS" 형식

# 활용
# - 스캘핑: 정확한 진입/청산 타이밍
# - 데이 트레이딩: 캔들 마감 전 포지션 관리
# - 스윙: 중요한 일봉/주봉 마감 모니터링
```

### Three-Line-Break (MT4/MT5)
**Location**: `Three-Line-Break/`
```bash
# 3라인 브레이크 차트 인디케이터 (marbotek)

# 설치
# Releases 페이지에서 .ex4/.ex5 다운로드 → Indicators 폴더 복사

# 특징
# - 가격 움직임의 독특한 시각화
# - 커스터마이징 가능 (라인 색상, 두께, 알림)
# - 멀티 타임프레임 지원
# - 명확한 트렌드 전환 신호

# GitHub: https://github.com/marbotek/Three-Line-Break/releases
```

### EABTCGrid (MQL4)
**Location**: `EABTCGrid/`
```bash
# 비트코인 그리드 트레이딩 EA v5.1 - 멀티타임프레임 + EMA 전략

# 주요 전략
# - ATR 기반 동적 그리드 간격
# - EMA 크로스오버 신호 (12/26/9 기본값)
# - 변동성 필터링
# - 트레일링 스톱
# - 자동 Lot 크기 조정

# 타임프레임 모드
# - M5: 고빈도 매매
# - M15: 균형 잡힌 설정 (권장)
# - H1: 안정적 운용
# - H4: 보수적 전략

# 리스크 관리
# - 최대 주문 수 제한
# - 자산 손실률 정지 (기본 15%)
# - 자동 레벨 갱신

# 파일: EABTCShidiqMtp.mq4
# 개발: qhusi + ChatGPT Enhanced
```

### MTx_EA_framework (MT4/MT5)
**Location**: `MTx_EA_framework/`
```bash
# 크로스 플랫폼 EA 개발 프레임워크 (모듈형 아키텍처 + 단위 테스트)

# 환경 설정
export MT4_TARGET_DIR=/path/to/mt4
export MT5_TARGET_DIR=/path/to/mt5

# 심볼릭 링크 생성
./make_link.sh          # MT4용
./make_link_mt5.sh      # MT5용
# WSL: make_link_wsl.sh 사용

# 모듈 구조
# - my-mt4-infra / my-mt5-infra: 기본 인프라
# - my-mtx-infra-commons: 공통 컴포넌트
# - my-mt4-auto-trader: 자동 매매 시스템
# - my-mt4-multiple-signals: 복합 신호 통합
# - my-mt4-filter: 신호 필터링
# - my-mt4-mocker: 테스팅 프레임워크

# 테스트 실행
# Scripts/{module_name}/run_unittest.mq4 (MT4)
# Scripts/{module_name}/run_unittest.mq5 (MT5)

# 특징
# - 테스트 주도 개발 (TDD)
# - MQLUNIT 프레임워크 통합
# - 높은 재사용성과 유지보수성
# - 확장 가능한 설계
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

### Korean Forex Analysis System (Node.js)
**Location**: `저작권/daniel8824-del_korea-forex/`
```bash
# Install dependencies
npm install

# Run daily FX prediction system
python daily_fx_prediction.py

# Test the FX API
open test_fx_api.html    # Open in browser to test

# API server
python api.py           # Start API server for FX data
```

### Web Projects (Node.js/TypeScript)
**Location**: `bazi-calculator-by-alvamind/`
```bash
# Install dependencies
npm install
# or for bazi calculator specifically
bun install             

# Development
npm run build           # Build TypeScript to dist/
npm run lint           # Lint TypeScript code
npm run format         # Format code with prettier
npm run source         # Generate documentation
npm run commit         # Commit using custom tool
npm run clean          # Clean build artifacts

# Publishing
npm run publish-npm    # Publish to npm with version bump
```

### Security Research Projects
**Location**: `저작권/AI-Security-Projects-Downloaded/`
```bash
# Contains downloaded security research projects including:
# - h4cker: Cybersecurity learning materials and tools
# - AI-Security-Projects-50k-Stars: High-starred security projects
# - FATE: Federated AI Technology Enabler
# - sherlock: Social media username investigation tool
```

### Medusa Security Scanner
**Location**: Various locations as per Medusa 사용법 상세 가이드.hwpx
```bash
# Basic Medusa usage for security testing
./medusa -h                              # Show help
./medusa -H hosts.txt -U users.txt -P passwords.txt -M ssh
MEDUSA_MODULE_PATH=/path/to/modules ./medusa -d  # Debug mode
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

# Windows EXE creation
python build_windows_exe.py         # Create Windows executable
python create_windows_package.py    # Create packaged distribution

# Korean-specific tools
python korean_font_manager.py       # Manage Korean fonts
python korean_typography.py         # Korean text processing utilities
python enhanced_korean_search.py    # Enhanced search for Korean content
```

### Document Processing and Conversion (Python)
**Location**: Various scripts in `저작권/`
```bash
# PDF processing utilities
python pdf_to_txt_converter.py      # Basic PDF to text conversion
python pdf_to_txt_advanced.py       # Advanced PDF processing with OCR
python pdf_to_txt_ocr.py            # OCR-specific processing
python pdf_final_converter.py       # Final converter with all features

# Text and document conversion
python txt_to_pdf_converter.py      # Convert text files to PDF
python hwp_to_pdf_converter.py      # Convert Korean HWP files to PDF

# Image processing
python resize_image.py               # Image resizing utilities

# Data collection and analysis
python kosis_api_client.py          # Korean Statistical Information Service API client
python korean_mql4_repos.py         # Analyze Korean MQL4 repositories
```

## Architecture and Code Organization

### Trading Systems Architecture
- **EA31337**: Advanced modular expert advisor framework
  - Location: `저작권/work/01_HIGH_PRIORITY/EA31337/`
  - `src/EA31337.mq4/.mq5`: Main EA source files
  - `src/include/`: Shared header files and includes
  - `sets/`: Optimized parameter sets for different strategies
  - Mode-based compilation system supporting Lite/Advanced/Rider variants
  - Cross-platform compilation using Wine + MetaEditor on Linux/macOS
  - Comprehensive testing and backtesting capabilities
  
- **EA31337 Classes**: Supporting framework library
  - Location: `저작권/work/01_HIGH_PRIORITY/EA31337-classes/`
  - Extensive library with 80+ indicators, account management, chart analysis
  - Modular architecture with Account, Buffer, Chart, Indicator, Strategy modules
  - Advanced features: 3D visualization, database support, serialization

- **SpanModelTrader**: Japanese technical analysis EA (Ichimoku + Super Bollinger)
  - Location: `SpanModelTrader/`
  - 3-signal filter system with multi-timeframe analysis
  - Optimized for JPY pairs on H1 timeframe

- **Trailing-Stop-on-Profit**: Automated trailing stop EA (EarnForex)
  - Location: `Trailing-Stop-on-Profit/`
  - Cross-platform: MT4, MT5, cTrader
  - Trails stop-loss only after profit threshold reached

- **Show-Time-To-Close-Indicator**: Real-time candle countdown (TFLab)
  - Location: `Show-Time-To-Close-Indicator-Metatrader/`
  - Live countdown timer for all timeframes
  - Essential for precise timing strategies

- **Three-Line-Break**: Price action chart indicator (marbotek)
  - Location: `Three-Line-Break/`
  - Unique trend visualization method
  - Clear reversal signals

- **EABTCGrid**: Bitcoin grid trading EA v5.1
  - Location: `EABTCGrid/`
  - ATR-based dynamic grid spacing
  - EMA crossover strategy with volatility filtering
  - Multiple timeframe modes (M5/M15/H1/H4)

- **MTx_EA_framework**: Professional EA development framework
  - Location: `MTx_EA_framework/`
  - Modular architecture for MT4/MT5
  - Unit testing with MQLUNIT
  - TDD-oriented development workflow

- **MQL4 Collections**: Legacy trading systems and indicators
  - `github-mql4-collection/`: 100+ community expert advisors
  - `mql4_experts/`, `mql4-template/`: Template and example systems
  - Wide variety of trading strategies and technical indicators


### Web Development Structure
- **Modern Stack**: React/TypeScript with modern build tools (Webpack, Vite)
- **Multi-platform**: Support for npm, yarn, and bun package managers
- **Component Architecture**: Reusable component libraries and design systems

### Korean Content Management
- **Multi-format Support**: HWP, Markdown, PDF, and various Korean document formats
- **Encoding**: UTF-8 throughout with proper Korean character support  
- **Publishing Pipeline**: Content creation → Review → Publication workflows
- **Document Conversion**: HWP ↔ PDF, text processing, OCR capabilities
- **Contact Management**: Excel to VCF conversion, KakaoTalk integration
- **Typography**: Korean font management and text rendering

### Security Research Collection
- **Educational Resources**: Comprehensive cybersecurity learning materials
- **Analysis Tools**: Security analysis and penetration testing resources
- **Research Organization**: Categorized by security domains and skill levels
- **AI Security Focus**: Machine learning security, federated learning projects
- **Penetration Testing**: Username investigation, vulnerability scanning tools

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
- EA31337 main source: `저작권/work/01_HIGH_PRIORITY/EA31337/src/EA31337.mq4` and `.mq5`
- EA31337 classes library: `저작권/work/01_HIGH_PRIORITY/EA31337-classes/`
- SpanModelTrader: `SpanModelTrader/` (Ichimoku + Super Bollinger EA)
  - Main EA: `SpanModelTrader/Experts/SpanModelTrader.mq4`
  - Indicators: `SpanModelTrader/Indicators/*.mq4`
  - Libraries: `SpanModelTrader/Libraries/SMT000*.ex4`
  - Documentation: `SpanModelTrader/README.md`
- MQL4 collections: `github-mql4-collection/` and `mql4_experts/`
- Trading templates and utilities: `mql4-template/`, `ma-cross-ea/`
- Other MQL4 EAs: `Trailing-Stop-on-Profit/`, `Show-Time-To-Close-Indicator-Metatrader/`, `EABTCGrid/`, `MTx_EA_framework/`, `Three-Line-Break/`
- Korean forex analysis: `저작권/daniel8824-del_korea-forex/`
- Custom trading EAs: `저작권/work/` (various MQL4 files)

### Web Development
- Bazi calculator: `bazi-calculator-by-alvamind/`
- Static web examples: `popup.html`

### Security Research
- Downloaded projects: `저작권/AI-Security-Projects-Downloaded/`
- h4cker materials: Cybersecurity guides and tools
- AI security projects: FATE, sherlock, differential privacy

### Documentation and Content
- Project documentation: `Documents/`, `md/`
- Korean language content: `hwp/`, `저작권/`
- Technical manuals: `manual/`
- Resource collection: `awesome-claude-code/`

### Korean Management Tools
- Contact management: `저작권/contacts/`, conversion scripts
- Document processing: PDF, HWP, text conversion utilities
- Typography and fonts: Korean-specific text handling
- Data analysis: KOSIS API, repository analysis tools

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
# EA31337 automated testing (requires wine64)
cd 저작권/work/01_HIGH_PRIORITY/EA31337
make requirements       # Check dependencies
make test              # Run automated tests with MetaEditor
make Backtest          # Build backtest versions
make Optimize          # Build optimization versions

# Manual testing in MetaTrader Strategy Tester
# Load generated .ex4/.ex5 files into MetaTrader
# Configure test parameters and run backtests

# Security testing with Medusa
./medusa -h                              # Show help
./medusa -H hosts.txt -U users.txt -P passwords.txt -M ssh
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

## Project Structure and Priorities

### Priority-Based Organization
- **01_HIGH_PRIORITY**: `저작권/work/01_HIGH_PRIORITY/` - Active EA31337 development
- **02_MEDIUM_PRIORITY**: `저작권/work/02_MEDIUM_PRIORITY/` - Secondary projects  
- **03_LOW_PRIORITY**: `저작권/work/03_LOW_PRIORITY/` - Experimental or archived work

### Specialized Directories
- **Korean Content**: `저작권/` - All Korean language and localization work
- **Security Research**: `저작권/AI-Security-Projects-Downloaded/` - Educational cybersecurity materials
- **Resource Collection**: `awesome-claude-code/` - Claude Code community resources
- **Documentation**: `md/`, `Documents/`, `manual/` - Project documentation

### Common File Patterns
- **MQL4/MQL5**: `.mq4`, `.mq5`, `.ex4`, `.ex5` files for MetaTrader
- **Korean Documents**: `.hwp`, `.hwpx` files (Korean HWP format)
- **Build Artifacts**: Look for `Makefile`, `package.json`, `pyproject.toml`
- **Configuration**: `requirements.txt`, `tsconfig.json`, `docker-compose.yml`

## Important Development Notes

### Cross-Platform Considerations
- **MetaTrader Development**: Requires Wine64 on Linux/macOS for MQL compilation
- **Korean Language Support**: UTF-8 encoding essential, requires Korean fonts
- **Document Formats**: HWP files need special handling, PDF conversion available
- **Contact Data**: Large VCF files generated in batches for phone contact management

### Security and Compliance
- **Educational Use Only**: All trading systems are for learning and backtesting
- **Security Research**: Downloaded materials are for educational cybersecurity learning
- **Korean Regulations**: Document formats and business registration compliance
- **Data Privacy**: Contact management tools handle personal information responsibly

### Performance Considerations
- **Large File Collections**: 500+ VCF contact files, extensive MQL4 collections
- **Memory Usage**: OCR and PDF processing require significant resources
- **Korean Text Processing**: Font rendering and encoding require special attention
- **Trading System Compilation**: MetaEditor compilation can be resource-intensive

This workspace represents a sophisticated multi-domain development environment with particular strengths in financial technology, cybersecurity research, and Korean language processing. The modular architecture supports both individual project development and integrated workflows across different domains.