---
description: Initialize Node.js TypeScript project with best practices
---

Initialize a new Node.js TypeScript project following best practices from CLAUDE.md.

## What this does

Creates a production-ready Node.js + TypeScript project with:
- Package manager (pnpm/npm/yarn - asks user)
- TypeScript strict mode configuration
- ESLint + Prettier for code quality
- Vitest for testing
- Standard scripts (dev, build, start, test, lint, format, typecheck)
- Proper .gitignore

## Steps

1. **Check if already initialized**:
   - If package.json exists, ask user if they want to overwrite
   - If user says no, exit gracefully

2. **Ask user preferences** (using AskUserQuestion):
   - Package manager (pnpm/npm/yarn)
   - Project name (default: current directory name)
   - Add ESLint + Prettier? (yes/no)

3. **Initialize Git** (if not already):
   - Run `git init` if .git doesn't exist
   - Create .gitignore with common Node/TS excludes

4. **Initialize package manager**:
   - Run `pnpm init` / `npm init -y` / `yarn init -y`
   - Update package.json with user's project name

5. **Install TypeScript**:
   - Install: `typescript`, `@types/node`, `tsx` (for dev runner)
   - Dev dependencies

6. **Create tsconfig.json** (strict mode):
   ```json
   {
     "compilerOptions": {
       "strict": true,
       "target": "ES2022",
       "module": "NodeNext",
       "moduleResolution": "NodeNext",
       "esModuleInterop": true,
       "skipLibCheck": true,
       "forceConsistentCasingInFileNames": true,
       "rootDir": "./src",
       "outDir": "./dist",
       "declaration": true,
       "declarationMap": true,
       "sourceMap": true
     },
     "include": ["src/**/*"],
     "exclude": ["node_modules", "dist", "**/*.test.ts"]
   }
   ```

7. **Install quality tools** (if user opted in):
   - ESLint: `eslint`, `@typescript-eslint/parser`, `@typescript-eslint/eslint-plugin`
   - Prettier: `prettier`, `eslint-config-prettier`
   - Create .eslintrc.json and .prettierrc

8. **Install test framework**:
   - Vitest: `vitest`, `@vitest/ui`
   - Create vitest.config.ts

9. **Create project structure**:
   - `src/` directory
   - `src/index.ts` with basic "Hello World"
   - `tests/` directory
   - `tests/index.test.ts` with sample test

10. **Add scripts to package.json**:
    ```json
    {
      "scripts": {
        "dev": "tsx watch src/index.ts",
        "build": "tsc",
        "start": "node dist/index.js",
        "test": "vitest run",
        "test:watch": "vitest",
        "test:ui": "vitest --ui",
        "typecheck": "tsc --noEmit",
        "lint": "eslint src tests --ext .ts",
        "format": "prettier --write \"src/**/*.ts\" \"tests/**/*.ts\"",
        "format:check": "prettier --check \"src/**/*.ts\" \"tests/**/*.ts\""
      }
    }
    ```

11. **Update .gitignore**:
    ```
    # Dependencies
    node_modules/

    # Build output
    dist/

    # Environment
    .env
    .env.local
    .env.*.local

    # Logs
    logs/
    *.log
    npm-debug.log*

    # IDE
    .vscode/
    .idea/
    *.swp
    *.swo
    *~

    # OS
    .DS_Store
    Thumbs.db

    # Test coverage
    coverage/
    .nyc_output/
    ```

12. **Final verification**:
    - Run `pnpm install` / `npm install` / `yarn install`
    - Run typecheck to verify TypeScript setup
    - Show summary of what was created

## Output

```
🚀 Initializing Node.js + TypeScript project...

✓ Git initialized
✓ .gitignore created
✓ pnpm initialized
✓ TypeScript installed and configured (strict mode)
✓ ESLint + Prettier configured
✓ Vitest installed
✓ Project structure created:
  src/
  ├─ index.ts
  tests/
  ├─ index.test.ts

✓ Scripts added:
  - pnpm dev        # Run with watch mode
  - pnpm build      # Compile TypeScript
  - pnpm start      # Run compiled code
  - pnpm test       # Run tests
  - pnpm typecheck  # Type check only
  - pnpm lint       # Lint code
  - pnpm format     # Format code

✓ Dependencies installed

Project ready! Run 'pnpm dev' to start developing.
```

## Usage

```bash
# In current directory
/init-node-ts

# The command will ask for preferences interactively
```

## Integration

This command is referenced by `/plan-to-stories` when a project is not initialized. Can be run standalone or triggered automatically.

## Notes

- Follows CLAUDE.md strict TypeScript rules
- Uses pnpm by default (user's preferred package manager)
- Creates minimal but production-ready setup
- Token-efficient: no unnecessary dependencies
- Security-first: .env in .gitignore, strict TypeScript
