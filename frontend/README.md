# AutoClean Frontend

A React application for identifying and removing temporary or duplicate files.

## Features

- Identify and remove temporary files automatically
- Detect common temporary file extensions (.tmp, .temp, .cache)
- Free up disk space efficiently

## Tech Stack

- React 19.2.0
- TypeScript 5.6.3
- Vite 5.4.11
- TailwindCSS 3.4.14
- React Router 7.9.3
- TanStack Query 5.90.2
- Axios 1.12.2
- Zustand 5.0.8

## Getting Started

### Prerequisites

- Node.js 18+ and npm

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Update `.env` with your API configuration:
```
VITE_API_URL=http://localhost:3000
VITE_API_VERSION=v1
VITE_API_TIMEOUT=30000
```

### Development

Start the development server:
```bash
npm run dev
```

The application will be available at `http://localhost:5173`

### Build

Create a production build:
```bash
npm run build
```

### Preview

Preview the production build:
```bash
npm run preview
```

## Project Structure

```
src/
├── app/                    # Application configuration
│   ├── App.tsx            # Root component
│   ├── router.tsx         # Routing configuration
│   └── providers.tsx      # Global providers
├── pages/                 # Page components
│   ├── layouts/          # Layout components
│   ├── Home/             # Home page
│   └── NotFound/         # 404 page
├── domain/               # Business domains (features)
├── core/                 # Shared components and utilities
│   ├── components/       # Generic UI components
│   ├── lib/             # Library configurations
│   ├── utils/           # Utility functions
│   ├── types/           # Global types
│   └── constants/       # Global constants
└── assets/              # Static assets
    └── styles/          # Global styles
```

## API Integration

The application uses two API clients:

- `publicClient`: For public endpoints (`/api/v1/external/`)
- `authenticatedClient`: For authenticated endpoints (`/api/v1/internal/`)

Both are configured in `src/core/lib/api.ts`

## License

MIT