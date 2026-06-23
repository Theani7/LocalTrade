# LocalTrade — Nepal's Community Marketplace

LocalTrade is a full-stack mobile marketplace platform connecting local producers — vegetable sellers, handicraft makers, dairy farmers, tailors, bakers — directly with their community through a reservation-based ordering system. Built for Nepal's micro and small businesses.

## Screenshots

The app features a warm, accessible design language built for non-technical users, with a cream background (`#FBF5EA`), coral accents (`#FF6F52`), and high-contrast ink text.

## Features

### Customer
- Browse products by category with search and filtering
- Product detail view with image carousel, pricing units (kg, piece, liter, etc.), and quantity stepper
- Shopping cart with animated add-to-cart fly effect
- Checkout with saved delivery addresses and order notes
- Order tracking with real-time status updates and ETA
- Order cancellation with feedback prompt
- Vendor shop pages
- Reviews and ratings on delivered products
- Push notifications with segmented unread/earlier views
- Help & Support and Privacy Policy screens
- Profile management with address book

### Vendor
- Dashboard with sales analytics, order stats, and revenue overview
- Product management with multi-image upload (up to 4 images via Cloudinary)
- Pricing units: per piece, per kg, per 100g, per liter, per dozen, per packet, per bundle
- Minimum order quantity per product
- Inventory management with stock tracking and edit/delete
- Order management with status updates (Confirm, Process, Ship, Deliver)
- Vendor profile and business information
- Pending approval status screen with progress tracker

### Admin
- Platform overview dashboard with analytics charts and stat tiles
- Vendor management: approve, suspend, reject vendors
- Product moderation: view, approve, deactivate products
- Order oversight with status tracking
- Dynamic category management (CRUD with sorting)
- User management and feedback results
- Export analytics (CSV)
- Profile with admin identity card

### Shared
- Role-based authentication (Customer, Vendor, Admin)
- JWT-based auth with secure token storage
- Push notifications via Firebase Cloud Messaging
- Standardized bottom navigation across all roles
- Custom design system with shared components (AppButton, StatusBadge, ProductCard, etc.)
- Skeleton loaders and micro-animations (stagger, fade-slide, page transitions)
- Responsive layout with accessibility considerations
- Reduce-motion support

## Project Structure

```
PROJ_CT/
├── backend/                     # Node.js/Express REST API
│   ├── src/
│   │   ├── controllers/         # Business logic (8 controllers)
│   │   ├── models/              # Mongoose schemas (7 models)
│   │   ├── routes/              # API routes (8 route files)
│   │   ├── middleware/          # Auth, upload middleware
│   │   ├── config/             # DB, Cloudinary, Firebase config
│   │   └── utils/              # Error handling, notifications, auth
│   ├── tests/                  # Jest + Supertest (in-memory MongoDB)
│   └── .env.example            # Required env vars
├── frontend/localtrade_app/     # Flutter mobile app
│   ├── lib/
│   │   ├── core/               # Constants, theme, network, models, utils
│   │   │   ├── constants/      # App-wide constants
│   │   │   ├── models/         # Data models (Product, Cart, etc.)
│   │   │   ├── network/        # API services (Auth, Product, Order, etc.)
│   │   │   ├── theme/          # AppColors, AppTextStyles, AppSpacing
│   │   │   └── utils/          # Animations, auth guard, helpers
│   │   ├── features/           # Screen modules by role
│   │   │   ├── auth/           # Login, Register, Forgot Password
│   │   │   ├── customer/       # Home, Cart, Checkout, Orders, etc. (14 screens)
│   │   │   ├── vendor/         # Dashboard, Products, Orders, etc. (6 screens)
│   │   │   ├── admin/          # Dashboard, Vendors, Products, etc. (6 screens)
│   │   │   └── common/         # Splash, Logout dialog, Change password
│   │   ├── providers/          # Provider state management (8 providers)
│   │   └── widgets/            # Shared widgets (ProductCard, StatusBadge, etc.)
│   ├── assets/images/          # App icon and images
│   └── pubspec.yaml
├── DESIGN_LANGUAGE.md          # Color, typography, spacing, component specs
├── localtrade-design-system-revised.md  # Full design system reference
└── render.yaml                 # Render deployment config
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x, Dart, Provider state management |
| Backend | Node.js, Express 5, Mongoose 8 |
| Database | MongoDB Atlas (SRV connection) |
| Auth | JWT with bcrypt password hashing |
| Image Storage | Cloudinary |
| Push Notifications | Firebase Cloud Messaging |
| Testing | Jest + Supertest + mongodb-memory-server |
| Deployment | Render (backend), Flutter build (frontend) |

## API Endpoints

### Authentication
| Method | Endpoint | Access |
|--------|----------|--------|
| POST | `/api/v1/auth/register` | Public |
| POST | `/api/v1/auth/login` | Public |
| POST | `/api/v1/auth/forgot-password` | Public |
| GET | `/api/v1/auth/me` | Authenticated |
| PATCH | `/api/v1/auth/update-password` | Authenticated |
| PATCH | `/api/v1/auth/change-password` | Authenticated |

### Products
| Method | Endpoint | Access |
|--------|----------|--------|
| GET | `/api/v1/products` | Public |
| GET | `/api/v1/products/:id` | Public |
| POST | `/api/v1/products` | Vendor |
| PATCH | `/api/v1/products/:id` | Vendor (owner) |
| DELETE | `/api/v1/products/:id` | Vendor (owner) / Admin |

### Orders
| Method | Endpoint | Access |
|--------|----------|--------|
| POST | `/api/v1/orders` | Customer |
| GET | `/api/v1/orders/my-orders` | Customer |
| GET | `/api/v1/orders/vendor-orders` | Vendor |
| PATCH | `/api/v1/orders/:id/status` | Vendor |
| PATCH | `/api/v1/orders/:id/cancel` | Customer |

### Categories
| Method | Endpoint | Access |
|--------|----------|--------|
| GET | `/api/v1/categories` | Public |
| GET | `/api/v1/categories/admin` | Admin |
| POST | `/api/v1/categories` | Admin |
| PATCH | `/api/v1/categories/:id` | Admin |
| DELETE | `/api/v1/categories/:id` | Admin |

### Reviews
| Method | Endpoint | Access |
|--------|----------|--------|
| GET | `/api/v1/reviews/product/:productId` | Public |
| POST | `/api/v1/reviews` | Customer (delivered order) |

### Notifications
| Method | Endpoint | Access |
|--------|----------|--------|
| GET | `/api/v1/notifications` | Authenticated |
| PATCH | `/api/v1/notifications/:id/read` | Authenticated |
| PATCH | `/api/v1/notifications/read-all` | Authenticated |

### Admin
| Method | Endpoint | Access |
|--------|----------|--------|
| GET | `/api/v1/admin/analytics` | Admin |
| GET | `/api/v1/admin/vendors` | Admin |
| PATCH | `/api/v1/admin/vendors/:id/approve` | Admin |
| PATCH | `/api/v1/admin/vendors/:id/reject` | Admin |
| PATCH | `/api/v1/admin/vendors/:id/suspend` | Admin |
| GET | `/api/v1/admin/products` | Admin |
| PATCH | `/api/v1/admin/products/:id/status` | Admin |
| GET | `/api/v1/admin/orders` | Admin |
| GET | `/api/v1/admin/users` | Admin |
| DELETE | `/api/v1/admin/users/:id` | Admin |
| GET | `/api/v1/admin/feedback` | Admin |
| GET | `/api/v1/admin/export/analytics` | Admin |

## Setup

### Prerequisites
- Node.js 18+ and npm
- Flutter 3.x with Dart SDK
- MongoDB Atlas account
- Cloudinary account
- Firebase project (for push notifications)

### 1. Environment Configuration
```bash
cd backend
cp .env.example .env
# Fill in your credentials (see .env.example for all required vars)
```

### 2. Backend
```bash
cd backend
npm install
node seed-admin.js          # Create default admin user
node seed-categories.js     # Seed 10 default product categories
node seed-data.js           # Populate sample vendors + products
npm run dev                 # Start dev server on port 5000
```

### 3. Frontend
```bash
cd frontend/localtrade_app
flutter pub get
flutter run                  # Run on device/emulator
```

Update the API base URL in `lib/core/constants/app_constants.dart`:
- **Local dev (Android emulator):** `http://10.0.2.2:5000/api/v1`
- **Local dev (iOS/web):** `http://localhost:5000/api/v1`
- **Production:** `https://localtrade-backend-jg9l.onrender.com/api/v1`

### 4. Build
```bash
cd frontend/localtrade_app
flutter build apk            # Android APK
flutter build ios            # iOS (macOS + Xcode)
```

## Commands

| Command | Location | Description |
|---------|----------|-------------|
| `npm run dev` | backend | Start dev server with nodemon |
| `npm test` | backend | Run tests (in-memory MongoDB) |
| `npm run clear:data` | backend | Reset database |
| `node seed-admin.js` | backend | Create/update admin user |
| `node seed-categories.js` | backend | Seed default categories |
| `node seed-data.js` | backend | Seed sample vendors + products |
| `flutter run` | frontend | Run app on connected device |
| `flutter analyze` | frontend | Lint check |
| `flutter build apk` | frontend | Build release APK |

## Testing

Backend tests use Jest + Supertest with an in-memory MongoDB server (no external DB required).

```bash
cd backend
npm test                    # Run all tests
npm run test:watch          # Watch mode
```

Tests cover:
- Authentication (register, login, password reset, role-based access)
- Product CRUD (create, read, update, delete with authorization)
- Order lifecycle (place, track, update status, cancel)
- Reviews (purchase-gated, rating validation)
- Address handling (embedded subdocument format)

## Deployment

### Backend (Render)
The app is deployed on Render using the `render.yaml` blueprint. The backend runs at:
`https://localtrade-backend-jg9l.onrender.com`

### Frontend
Build the APK and distribute, or deploy to App Store / Google Play.

## Design System

The app follows a consistent design language defined in `DESIGN_LANGUAGE.md`:

- **Colors:** Cream background, coral accents, ink text — warm and accessible
- **Typography:** Inter/Noto Sans, 400/500 weights, sentence case, min 12px
- **Cards:** 16px radius, soft shadows, 12-18px padding
- **Buttons:** Primary (coral fill + ink text), secondary (outline), destructive (red)
- **Status badges:** Light-fill + dark-text pattern, never saturated fill
- **Touch targets:** 44px minimum, 52px for primary actions
- **Animations:** Micro (150-250ms), page transitions (250-300ms), staggered lists
- **Accessibility:** Reduce-motion support, high contrast, large tap targets

## Default Credentials

**Admin:**
- Email: `admin@gmail.com`
- Password: `admin123`

## License

Distributed under the MIT License. See `LICENSE` for more information.
