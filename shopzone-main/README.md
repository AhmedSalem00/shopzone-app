<p align="center">
  <img src="https://img.icons8.com/3d-fluency/94/shopping-bag.png" alt="ShopZone Logo" width="80"/>
</p>

<h1 align="center">ShopZone</h1>

<p align="center">
  <strong>A modern, full-stack mobile e-commerce application built with Flutter & PostgreSQL</strong>
</p>

<p align="center">
  <a href="#features"><img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=for-the-badge" alt="Platform"/></a>
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Node.js-Express-339933?style=for-the-badge&logo=node.js&logoColor=white" alt="Node.js"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15+-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Auth-JWT-black?style=flat-square" alt="JWT"/>
  <img src="https://img.shields.io/badge/State-Provider-purple?style=flat-square" alt="Provider"/>
  <img src="https://img.shields.io/badge/API-REST-green?style=flat-square" alt="REST"/>
</p>

---

## 📱 About

**ShopZone** is a production-ready mobile e-commerce application featuring a polished Flutter frontend and a robust Node.js/Express REST API backed by PostgreSQL. Designed with clean architecture and scalable patterns, it serves as both a ready-to-deploy shop and a strong foundation for custom e-commerce projects.

---

## ✨ Features

### 🛍️ Storefront
- **Product catalog** with grid/list views, search, and category filtering
- **Featured carousel** highlighting promoted products
- **Product detail** with image gallery, ratings, stock status, and discount badges
- **Smart sorting** — by price, rating, or newest arrivals

### 🛒 Shopping Experience
- **Real-time cart** with quantity controls and live totals
- **Automatic shipping** calculation (free over $50)
- **Discount pricing** with percentage-off badges and strikethrough original prices
- **Wishlist** support (database-ready)

### 🔐 Authentication & Security
- **JWT-based auth** with secure token storage
- **Bcrypt password hashing** — no plaintext, ever
- **Protected routes** — cart, orders, and profile endpoints require authentication
- **Input validation** and parameterized queries to prevent SQL injection

### 📦 Order Management
- **Transactional checkout** — atomic order creation with stock validation and rollback
- **Order history** with item details and status tracking
- **Automatic stock decrement** on successful purchase

---

## 🏗️ Architecture

```
shopzone/
│
├── 📱 lib/                          # Flutter Application
│   ├── main.dart                    # App entry point & provider setup
│   ├── models/
│   │   └── models.dart              # Product, CartItem, Category data classes
│   ├── services/
│   │   └── api_service.dart         # HTTP client — all API communication
│   ├── providers/
│   │   └── cart_provider.dart       # Cart state management (ChangeNotifier)
│   ├── screens/
│   │   ├── login_screen.dart        # Auth (login + registration)
│   │   ├── home_screen.dart         # Main storefront
│   │   ├── product_detail_screen.dart
│   │   └── cart_screen.dart         # Cart & checkout summary
│   └── utils/
│       └── constants.dart           # Theme, colors, API base URL
│
├── 🖥️ backend/                      # Express REST API
│   ├── server.js                    # Entry point & route mounting
│   ├── config/
│   │   └── db.js                    # PostgreSQL connection pool
│   ├── middleware/
│   │   └── auth.js                  # JWT verification middleware
│   └── routes/
│       ├── auth.js                  # POST /register, /login
│       ├── products.js              # GET /products, /products/:id, /meta/categories
│       ├── cart.js                   # CRUD cart operations
│       └── orders.js                # GET /orders, POST /orders (transactional)
│
├── 🗄️ sql/
│   ├── schema.sql                   # Complete database schema (10 tables)
│   └── seed.sql                     # Sample data (5 categories, 10 products)
│
└── pubspec.yaml
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.1 |
| Node.js | ≥ 18 |
| PostgreSQL | ≥ 14 |

### 1 — Database Setup

```bash
# Create database and load schema + sample data
createdb ecommerce
psql ecommerce < sql/schema.sql
psql ecommerce < sql/seed.sql
```

### 2 — Backend

```bash
cd backend
cp .env.example .env     # ← edit with your DB credentials & JWT secret
npm install
npm run dev              # → http://localhost:3000
```

### 3 — Flutter App

```bash
flutter pub get
flutter run
```

> **Connectivity note:**
> | Platform | `baseUrl` in `lib/utils/constants.dart` |
> |----------|----------------------------------------|
> | Android Emulator | `http://10.0.2.2:3000/api` (default) |
> | iOS Simulator | `http://localhost:3000/api` |
> | Physical Device | `http://<your-local-ip>:3000/api` |

---

## 🔌 API Reference

### Authentication

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| `POST` | `/api/auth/register` | `{ email, password, full_name }` | `{ user, token }` |
| `POST` | `/api/auth/login` | `{ email, password }` | `{ user, token }` |

### Products (public)

| Method | Endpoint | Query Params | Description |
|--------|----------|-------------|-------------|
| `GET` | `/api/products` | `category_id`, `search`, `featured`, `sort` | List & filter products |
| `GET` | `/api/products/:id` | — | Single product with images |
| `GET` | `/api/products/meta/categories` | — | All categories |

**Sort options:** `price_asc`, `price_desc`, `rating`

### Cart 🔒

| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| `GET` | `/api/cart` | — | Get user's cart |
| `POST` | `/api/cart` | `{ product_id, quantity }` | Add item (upserts) |
| `PUT` | `/api/cart/:id` | `{ quantity }` | Update quantity |
| `DELETE` | `/api/cart/:id` | — | Remove item |

### Orders 🔒

| Method | Endpoint | Body | Description |
|--------|----------|------|-------------|
| `GET` | `/api/orders` | — | Order history |
| `POST` | `/api/orders` | `{ address_id, payment_method }` | Place order (transactional) |

> 🔒 = Requires `Authorization: Bearer <token>` header

---

## 🗄️ Database Schema

```
users ──────┬──── addresses
            ├──── cart_items ───── products ──── product_images
            ├──── wishlist ──────── products
            ├──── reviews ───────── products
            └──── orders ────┬──── order_items ── products
                             └──── addresses

categories ──── products
```

**10 tables:** `users`, `categories`, `products`, `product_images`, `addresses`, `orders`, `order_items`, `cart_items`, `wishlist`, `reviews`

---

## 🧰 Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile UI** | Flutter 3.x + Material 3 | Cross-platform native app |
| **State** | Provider | Reactive cart management |
| **Networking** | `http` package | REST API communication |
| **Images** | `cached_network_image` | Cached, lazy-loaded product images |
| **Fonts** | `google_fonts` (Poppins) | Premium typography |
| **API** | Express.js | REST endpoints |
| **Auth** | JWT + bcrypt | Stateless auth with hashed passwords |
| **Database** | PostgreSQL | Relational data with UUID primary keys |
| **ORM** | `pg` (node-postgres) | Direct SQL with parameterized queries |

---

## 🗺️ Roadmap

- [ ] Payment gateway integration (Stripe)
- [ ] Push notifications for order updates
- [ ] Product reviews & ratings UI
- [ ] Address management screen
- [ ] Order tracking with status timeline
- [ ] Admin dashboard (web)
- [ ] Image upload for products
- [ ] Social login (Google, Apple)
- [ ] Dark mode theme

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch — `git checkout -b feature/amazing-feature`
3. **Commit** your changes — `git commit -m 'Add amazing feature'`
4. **Push** to the branch — `git push origin feature/amazing-feature`
5. **Open** a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.

---

<p align="center">
  Built with ❤️ using Flutter & PostgreSQL
</p>