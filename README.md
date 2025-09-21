# ACA Lead Order Form

A comprehensive order form application with user authentication, admin dashboard, and GoHighLevel CRM integration.

## Features

### User Authentication
- Auto-login via URL parameters from GoHighLevel CRM
- User dashboard with order history and repeat ordering
- Role-based access control (Admin, User, Buyer)

### Admin Dashboard
- User management with role assignment
- Order management and status tracking
- GoHighLevel integration testing and setup
- Activity logging and analytics

### GoHighLevel Integration
- Private integration token support
- OAuth configuration (alternative)
- API testing for Contacts, Opportunities, and Tags
- Location-based API calls

## Tech Stack

- **Frontend**: HTML, CSS, JavaScript
- **Backend**: Supabase (PostgreSQL + Auth)
- **Deployment**: Vercel
- **API**: GoHighLevel SDK
- **Integration**: GoHighLevel CRM

## Setup

### 1. Supabase Setup
Run the SQL files in order:
1. `supabase-schema.sql` - Basic schema
2. `admin-schema.sql` - Admin functionality
3. `add-admin-columns.sql` - Admin columns

### 2. Environment Variables (Vercel)
Set up these environment variables in Vercel:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

### 3. GoHighLevel Integration
1. Get your Private Integration Token from GoHighLevel
2. Find your Location ID
3. Configure in Admin Dashboard > Integrations

## Deployment

### Local Development
```bash
npm install
vercel dev
```

### Deploy to Vercel
```bash
vercel --prod
```

## File Structure

```
├── api/ghl/                 # Vercel API routes for GoHighLevel
│   ├── test-contacts.js
│   ├── test-opportunities.js
│   └── test-tags.js
├── index.html              # Main application (user dashboard)
├── admin.html              # Admin dashboard
├── order-form.html         # Order form page
├── package.json            # Dependencies
├── vercel.json             # Vercel configuration
└── *.sql                   # Database schema files
```

## Usage

### For Users
1. Access via GoHighLevel CRM link with auto-login
2. View order history and place new orders
3. Modify or repeat previous orders

### For Admins
1. Access admin dashboard at `/admin.html`
2. Manage users and orders
3. Configure GoHighLevel integration
4. Monitor system activity

## GoHighLevel Integration

The application uses GoHighLevel's private integration tokens for API access. Server-side API routes handle all GoHighLevel communication to avoid CORS issues.

### Supported APIs
- **Contacts**: Search and manage contacts
- **Opportunities**: View and track opportunities
- **Tags**: Manage contact tags

## License

MIT