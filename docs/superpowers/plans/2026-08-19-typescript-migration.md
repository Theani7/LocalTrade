# TypeScript Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate both Admin Web (React + Vite) and Backend (Node.js + Express 5) from JavaScript to strongly typed TypeScript, maintaining 100% API parity, passing all tests, and validating with an automated verification agent.

**Architecture:** 
- Admin Web uses TypeScript 5 with `tsconfig.json` & Vite for fast compilation, extracting monolithic views into typed components and shared interfaces (`src/types/index.ts`).
- Backend uses TypeScript 5 compiling from `src/` to `dist/`, `tsx` for rapid development, Mongoose document interfaces, typed Express handlers, and `ts-jest` for unit/integration testing.
- Verification agent runs full static type checks, production builds, and API parity smoke checks.

**Tech Stack:** React 19, Vite, TypeScript 5, Node.js, Express 5, Mongoose 9, Jest, Supertest, ts-jest, tsx.

## Global Constraints
- Target TypeScript version: 5.x.
- Zero type errors allowed under `tsc --noEmit`.
- All 18 backend tests must pass with `ts-jest`.
- API endpoints, JSON response formats, error objects, and MongoDB schemas must remain 100% backward compatible.
- All commits must follow conventional commits format (`<type>(<scope>): <description>`).

---

### Task 1: Admin Web TypeScript Toolchain & Type Contracts

**Files:**
- Create: `admin_web/tsconfig.json`
- Create: `admin_web/tsconfig.node.json`
- Create: `admin_web/vite.config.ts`
- Create: `admin_web/src/types/index.ts`
- Modify: `admin_web/package.json`
- Modify: `admin_web/index.html`
- Delete: `admin_web/vite.config.js`

**Interfaces:**
- Produces: `User`, `Vendor`, `Product`, `Order`, `Category`, `AnalyticsData`, `NotificationItem`, `FeedbackItem`, `TabFilters` interfaces in `src/types/index.ts`.

- [ ] **Step 1: Install TypeScript devDependencies in `admin_web`**
Run:
```bash
cd admin_web && npm install --save-dev typescript @types/react @types/react-dom @types/node
```

- [ ] **Step 2: Create `admin_web/tsconfig.json` and `admin_web/tsconfig.node.json`**
Write `admin_web/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
```
Write `admin_web/tsconfig.node.json`:
```json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
```

- [ ] **Step 3: Convert `vite.config.js` to `vite.config.ts` and update `package.json`**
Write `admin_web/vite.config.ts`:
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
});
```
Update `admin_web/package.json` scripts:
```json
"scripts": {
  "dev": "vite",
  "build": "tsc -b && vite build",
  "typecheck": "tsc --noEmit",
  "lint": "oxlint",
  "preview": "vite preview"
}
```
Remove `admin_web/vite.config.js`.

- [ ] **Step 4: Update `index.html` entry point**
Change `/src/main.jsx` to `/src/main.tsx` in `admin_web/index.html`.

- [ ] **Step 5: Create `admin_web/src/types/index.ts`**
Create comprehensive type interfaces for User, Vendor, Product, Order, Category, Feedback, Notification, AnalyticsData, TabTypes, and Modal states.

- [ ] **Step 6: Commit**
```bash
git add admin_web/
git commit -m "feat(admin): setup TypeScript config and type definitions"
```

---

### Task 2: Modularize and Convert Admin Web UI Components

**Files:**
- Create: `admin_web/src/components/common/NavItem.tsx`
- Create: `admin_web/src/components/common/StatCard.tsx`
- Create: `admin_web/src/components/common/MiniStatCard.tsx`
- Create: `admin_web/src/components/common/PaginationFooter.tsx`
- Create: `admin_web/src/components/common/ConfirmModal.tsx`
- Create: `admin_web/src/components/common/CategoryModal.tsx`
- Create: `admin_web/src/components/common/Skeletons.tsx`
- Create: `admin_web/src/components/tabs/AnalyticsTab.tsx`
- Create: `admin_web/src/components/tabs/UsersTab.tsx`
- Create: `admin_web/src/components/tabs/VendorsTab.tsx`
- Create: `admin_web/src/components/tabs/ProductsTab.tsx`
- Create: `admin_web/src/components/tabs/OrdersTab.tsx`
- Create: `admin_web/src/components/tabs/CategoriesTab.tsx`
- Create: `admin_web/src/components/tabs/FeedbackTab.tsx`
- Create: `admin_web/src/components/tabs/ProfileTab.tsx`
- Create: `admin_web/src/components/details/VendorDetail.tsx`
- Create: `admin_web/src/components/details/ProductDetail.tsx`
- Create: `admin_web/src/components/details/OrderDetail.tsx`

**Interfaces:**
- Consumes: Types from `admin_web/src/types/index.ts`.
- Produces: Exported typed React functional components for each tab and detail view.

- [ ] **Step 1: Create common components in `src/components/common/`**
Implement `NavItem.tsx`, `StatCard.tsx`, `MiniStatCard.tsx`, `PaginationFooter.tsx`, `ConfirmModal.tsx`, `CategoryModal.tsx`, and `Skeletons.tsx`.

- [ ] **Step 2: Create detail components in `src/components/details/`**
Implement `VendorDetail.tsx`, `ProductDetail.tsx`, and `OrderDetail.tsx` with typed props (`data`, `onStatusChange`, `onDelete`).

- [ ] **Step 3: Create tab components in `src/components/tabs/`**
Implement all 8 tab components (`AnalyticsTab`, `UsersTab`, `VendorsTab`, `ProductsTab`, `OrdersTab`, `CategoriesTab`, `FeedbackTab`, `ProfileTab`).

- [ ] **Step 4: Commit**
```bash
git add admin_web/src/components/
git commit -m "refactor(admin): modularize and strongly type admin tab and detail components"
```

---

### Task 3: Migrate Admin Web `App.jsx` & `main.jsx` to TypeScript

**Files:**
- Create: `admin_web/src/App.tsx`
- Create: `admin_web/src/main.tsx`
- Delete: `admin_web/src/App.jsx`
- Delete: `admin_web/src/main.jsx`

**Interfaces:**
- Consumes: Components from `src/components/` and types from `src/types/index.ts`.
- Produces: Type-safe Admin dashboard application with Vite build.

- [ ] **Step 1: Create `admin_web/src/main.tsx`**
```tsx
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import './index.css';
import App from './App';

const rootElement = document.getElementById('root');
if (rootElement) {
  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
}
```

- [ ] **Step 2: Create `admin_web/src/App.tsx`**
Implement the main App shell using modular typed tabs and components.

- [ ] **Step 3: Remove old `.jsx` files**
```bash
rm admin_web/src/App.jsx admin_web/src/main.jsx
```

- [ ] **Step 4: Verify Admin Web build and typecheck**
Run:
```bash
cd admin_web && npm run typecheck && npm run build
```
Expected: `0 errors`, `dist/` bundle created successfully.

- [ ] **Step 5: Commit**
```bash
git add admin_web/
git commit -m "feat(admin): complete TypeScript migration for admin web dashboard"
```

---

### Task 4: Setup Backend TypeScript Toolchain & Build Pipeline

**Files:**
- Create: `backend/tsconfig.json`
- Modify: `backend/package.json`
- Modify: `render.yaml`
- Modify: `.github/workflows/backend-ci.yml`

**Interfaces:**
- Produces: Configured `tsc` compilation to `backend/dist/`, `tsx` for dev/scripts, and `ts-jest` for tests.

- [ ] **Step 1: Install TypeScript devDependencies in `backend`**
Run:
```bash
cd backend && npm install --save-dev typescript @types/node @types/express @types/cors @types/morgan @types/multer @types/bcryptjs @types/jsonwebtoken @types/jest @types/supertest tsx ts-jest
```

- [ ] **Step 2: Create `backend/tsconfig.json`**
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "CommonJS",
    "moduleResolution": "Node",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests/**/*"]
}
```

- [ ] **Step 3: Update `backend/package.json` scripts**
```json
"scripts": {
  "dev": "tsx watch src/server.ts",
  "build": "tsc",
  "start": "node dist/server.js",
  "typecheck": "tsc --noEmit",
  "test": "cross-env NODE_ENV=test jest --runInBand --detectOpenHandles",
  "test:watch": "cross-env NODE_ENV=test jest --watch",
  "seed:admin": "tsx seed-admin.ts",
  "clear:data": "tsx clear-data.ts"
}
```

- [ ] **Step 4: Commit**
```bash
git add backend/
git commit -m "feat(backend): configure TypeScript build pipeline and tsx runner"
```

---

### Task 5: Migrate Backend Types, Utils, Config, and Mongoose Models

**Files:**
- Create: `backend/src/types/index.ts`
- Create: `backend/src/types/express.d.ts`
- Rename & Convert: `backend/src/config/*.js` -> `backend/src/config/*.ts` (`db.ts`, `cloudinary.ts`, `email.ts`, `firebase.ts`)
- Rename & Convert: `backend/src/utils/*.js` -> `backend/src/utils/*.ts` (`appError.ts`, `catchAsync.ts`, `authUtils.ts`, `cloudinaryUtils.ts`, `notificationUtils.ts`)
- Rename & Convert: `backend/src/models/*.js` -> `backend/src/models/*.ts` (`userModel.ts`, `productModel.ts`, `orderModel.ts`, `categoryModel.ts`, `reviewModel.ts`, `notificationModel.ts`, `feedbackModel.ts`)

**Interfaces:**
- Produces: `IUser`, `IProduct`, `IOrder`, `ICategory`, `IReview`, `INotification`, `IFeedback` document types and typed Mongoose models.

- [ ] **Step 1: Create `backend/src/types/index.ts` and `backend/src/types/express.d.ts`**
Define shared entity interfaces and extend Express Request with `user?: IUserDocument`.

- [ ] **Step 2: Convert `backend/src/config/` to TypeScript**
Convert `db.ts`, `cloudinary.ts`, `email.ts`, `firebase.ts`.

- [ ] **Step 3: Convert `backend/src/utils/` to TypeScript**
Convert `appError.ts`, `catchAsync.ts`, `authUtils.ts`, `cloudinaryUtils.ts`, `notificationUtils.ts`.

- [ ] **Step 4: Convert `backend/src/models/` to TypeScript**
Implement typed Mongoose schemas for User, Product, Order, Category, Review, Notification, Feedback.

- [ ] **Step 5: Commit**
```bash
git add backend/
git commit -m "feat(backend): migrate models, utils, and config to TypeScript"
```

---

### Task 6: Migrate Backend Middleware, Controllers, Routes, and Entrypoints

**Files:**
- Rename & Convert: `backend/src/middleware/*.js` -> `backend/src/middleware/*.ts` (`authMiddleware.ts`, `uploadMiddleware.ts`)
- Rename & Convert: `backend/src/controllers/*.js` -> `backend/src/controllers/*.ts`
- Rename & Convert: `backend/src/routes/*.js` -> `backend/src/routes/*.ts`
- Rename & Convert: `backend/src/app.js` -> `backend/src/app.ts`
- Rename & Convert: `backend/src/server.js` -> `backend/src/server.ts`
- Rename & Convert: `backend/seed-*.js` / `clear-data.js` -> `seed-*.ts` / `clear-data.ts`

**Interfaces:**
- Consumes: Models, utils, and middleware.
- Produces: Fully typed Express REST API with TypeScript compilation.

- [ ] **Step 1: Convert `backend/src/middleware/` to TypeScript**
Type `protect`, `restrictTo`, and Multer upload middleware.

- [ ] **Step 2: Convert `backend/src/controllers/` to TypeScript**
Type all 9 controllers (`authController.ts`, `adminController.ts`, `productController.ts`, `orderController.ts`, `categoryController.ts`, `vendorController.ts`, `feedbackController.ts`, `reviewController.ts`, `notificationController.ts`).

- [ ] **Step 3: Convert `backend/src/routes/` to TypeScript**
Type all Express router instances and export them.

- [ ] **Step 4: Convert `backend/src/app.js` and `backend/src/server.js` to `.ts`**
Implement typed Express app setup, CORS, security middlewares, and server listener.

- [ ] **Step 5: Convert seed and maintenance scripts to TypeScript**
Convert `seed-admin.ts`, `seed-categories.ts`, `seed-data.ts`, `clear-data.ts`.

- [ ] **Step 6: Test build `npm run build`**
Run:
```bash
cd backend && npm run build
```
Expected: `dist/` directory generated with compiled JavaScript and 0 compilation errors.

- [ ] **Step 7: Commit**
```bash
git add backend/
git commit -m "feat(backend): migrate controllers, routes, middleware, and server to TypeScript"
```

---

### Task 7: Migrate Backend Jest Test Suite to TypeScript

**Files:**
- Create: `backend/jest.config.js`
- Rename & Convert: `backend/tests/setup.js` -> `backend/tests/setup.ts`
- Rename & Convert: `backend/tests/*.test.js` -> `backend/tests/*.test.ts` (`auth.test.ts`, `product.test.ts`, `order.test.ts`, `review.test.ts`, `authAddressTest.test.ts`)

**Interfaces:**
- Consumes: `backend/src/app.ts`, models, and MongoDB Memory Server.
- Produces: Type-safe automated test execution.

- [ ] **Step 1: Configure `jest.config.js` with `ts-jest`**
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testTimeout: 30000,
  testMatch: ['**/tests/**/*.test.ts'],
};
```

- [ ] **Step 2: Convert `backend/tests/setup.js` to `setup.ts`**
Configure in-memory MongoDB lifecycle in TypeScript.

- [ ] **Step 3: Convert all 5 test files to `.ts`**
Convert `auth.test.ts`, `product.test.ts`, `order.test.ts`, `review.test.ts`, `authAddressTest.test.ts`.

- [ ] **Step 4: Run Jest test suite**
Run:
```bash
cd backend && npm test
```
Expected: All 5 test suites (18 tests) pass.

- [ ] **Step 5: Commit**
```bash
git add backend/
git commit -m "test(backend): migrate Jest test suite to ts-jest and TypeScript"
```

---

### Task 8: Verification Agent Execution & Parity Audit

**Files:**
- Inspect & Verify: `admin_web/`, `backend/`, `.github/workflows/`

- [ ] **Step 1: Run Full Static Typecheck Gate**
Run:
```bash
cd admin_web && npm run typecheck
cd ../backend && npm run typecheck
```
Expected: 0 errors in both projects.

- [ ] **Step 2: Run Production Builds**
Run:
```bash
cd admin_web && npm run build
cd ../backend && npm run build
```
Expected: Clean bundles in `admin_web/dist` and `backend/dist`.

- [ ] **Step 3: Run Full Backend Test Suite**
Run:
```bash
cd backend && npm test
```
Expected: 18/18 tests pass.

- [ ] **Step 4: Local Server Smoke Test**
Start backend on a test port using `dist/server.js`, query `/health`, verify JSON response shape and CORS headers, then shut down cleanly.

- [ ] **Step 5: Final Commit & Push**
```bash
git push origin main
```
