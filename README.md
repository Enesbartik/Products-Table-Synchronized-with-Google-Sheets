git add README.md# Products Table Synchronized with Google Sheets

A Ruby on Rails application that manages products in a local database and synchronizes them bidirectionally with Google Sheets.

## Overview

This project was built as a case study for:

- Ruby on Rails CRUD development
- Google Sheets API integration
- Two-way data synchronization
- Background jobs
- Scheduled jobs
- Service objects
- Filtering and related-product views
- Automated testing without calling the real Google API

## Main Features

### Product management

Users can:

- List products
- View product details
- Create products
- Edit products
- Delete products

Each product contains:

- `sync_key`
- `name`
- `price`
- `stock`
- `category`
- `sheet_managed`
- `last_synced_at`

The stock value may be `0`.

### Product filtering

Products can be filtered by:

- Product name
- Category
- Minimum price
- Maximum price
- Source:
  - Google Sheets
  - Local

Multiple filters can be used together.

### Related products

The product detail page displays up to five other products from the same category.

The currently viewed product is excluded from this list.

## Google Sheets Synchronization

The application supports synchronization in both directions.

### Rails to Google Sheets

When a product is created, updated, or deleted in Rails:

1. The database transaction is completed.
2. A background job is enqueued.
3. The synchronization service finds the product in Google Sheets by `sync_key`.
4. The service:
   - Appends a new row when the product does not exist
   - Updates the existing row when the product already exists
   - Deletes the matching row when the Rails product is deleted
5. Rails updates:
   - `sheet_managed`
   - `last_synced_at`

The stable `sync_key` prevents duplicate rows.

### Google Sheets to Rails

Google Sheets data can be synchronized to Rails in two ways:

- Manually, using the sync button
- Automatically, using a recurring background job

The synchronization service:

- Creates missing Rails products
- Updates existing products
- Deletes Sheet-managed products that were removed from the Sheet
- Preserves local-only records
- Records row-level validation errors in the Sheet

### Infinite-loop prevention

Sheet-to-Rails synchronization sets a temporary `skip_sheet_sync` flag before saving imported records.

This prevents a Sheet-originated change from immediately triggering another Rails-to-Sheet synchronization job.

## Google Sheet Structure

The worksheet is named `Products`.

Expected columns:

| Column | Field |
|---|---|
| A | `sync_key` |
| B | `name` |
| C | `price` |
| D | `stock` |
| E | `category` |
| F | `sync_status` |
| G | `sync_error` |
| H | `last_synced_at` |

## Project Architecture

### Models

`Product`

Responsible for:

- Validations
- UUID assignment
- Synchronization callbacks
- Preventing unnecessary synchronization jobs

### Controllers

`ProductsController`

Responsible for:

- CRUD requests
- Product filtering
- Loading related products

`SheetSyncsController`

Responsible for:

- Starting a manual Sheet-to-Rails synchronization

### Services

`GoogleSheets::Client`

Responsible for low-level Google Sheets API operations:

- Reading values
- Appending values
- Updating values
- Deleting rows
- Batch updates

`Products::SyncToSheet`

Responsible for Rails-to-Sheet business logic.

`Products::SyncFromSheet`

Responsible for Sheet-to-Rails business logic.

### Jobs

`SyncProductToSheetJob`

Handles asynchronous create, update, and delete synchronization from Rails to Google Sheets.

`SyncProductsFromSheetJob`

Runs the Sheet-to-Rails synchronization service.

The recurring configuration automatically enqueues this job at the configured interval.

## Requirements

Tested with:

- Ruby `3.4.10`
- Rails `8.1.3.1`
- SQLite
- Google Sheets API
- Solid Queue

## Installation

Clone the repository:

```bash
git clone https://github.com/Enesbartik/Products-Table-Synchronized-with-Google-Sheets.git
cd Products-Table-Synchronized-with-Google-Sheets
```

Install dependencies:

```bash
bundle install
```

Prepare the databases:

```bash
bin/rails db:prepare
```

## Google Service Account Setup

1. Create a Google Cloud project.
2. Enable the Google Sheets API.
3. Create a service account.
4. Download its JSON credentials file.
5. Save it locally as:

```text
config/google_service_account.json
```

6. Make sure the file is ignored by Git:

```gitignore
/config/google_service_account.json
```

7. Share the target Google Sheet with the service account email and grant Editor access.

Never commit the service-account JSON file, private key, access token, or spreadsheet credentials to GitHub.

## Rails Credentials

Store the spreadsheet configuration in Rails credentials:

```bash
bin/rails credentials:edit
```

Example:

```yaml
google_sheets:
  spreadsheet_id: "YOUR_SPREADSHEET_ID"
  worksheet_name: "Products"
```

Do not place real credentials directly in this README.

## Running the Application

Start the Rails server in the first terminal:

```bash
bin/rails server
```

Start Solid Queue in a second terminal:

```bash
bin/jobs
```

Open:

```text
http://localhost:3000
```

The manual sync button remains available even though Sheet-to-Rails synchronization also runs automatically.

## Recurring Synchronization

Recurring jobs are configured in:

```text
config/recurring.yml
```

Example:

```yaml
development:
  sync_products_from_sheet:
    class: SyncProductsFromSheetJob
    schedule: every 1 minute

production:
  sync_products_from_sheet:
    class: SyncProductsFromSheetJob
    schedule: every 5 minutes
```

Validate the recurring configuration with:

```bash
bin/jobs check
```

## Running Tests

Run all tests:

```bash
bin/rails test
```

The test suite covers:

- Product validations
- Product CRUD
- Name filtering
- Category filtering
- Price interval filtering
- Local and Sheet-managed filtering
- Combined filters
- Related products
- Related-product limit
- Sheet-to-Rails synchronization
- Rails-to-Sheet synchronization
- Background jobs
- Product synchronization callbacks
- Create, update, and delete behavior
- Infinite-loop prevention
- Protection of local-only records

Google API calls are replaced with fake clients or stubs during tests.

At the time this README was prepared, the suite completed with:

```text
40 runs
0 failures
0 errors
```

## Important Design Decisions

### Stable external identity

Products are matched across Rails and Google Sheets using `sync_key`, not product names or Sheet row numbers.

### Upsert behavior

The Rails-to-Sheet service:

- Inserts when `sync_key` is missing from the Sheet
- Updates when the same `sync_key` already exists

This makes repeated synchronization safer and prevents duplicate rows.

### Background processing

External API requests are executed through Active Job so normal page requests do not need to wait for Google Sheets.

### Commit callbacks

External synchronization is enqueued after the database transaction commits.

This reduces the risk of sending data to Google Sheets before the Rails record is safely stored.

### Dependency injection

Synchronization services accept a client object.

Production uses the real Google Sheets client, while tests use fake clients. This keeps tests fast and independent of network access.

## Future Improvements

Possible additions:

- Pagination
- Product sorting
- Synchronization history
- Retry and failure status UI
- Conflict-resolution rules
- Authentication and authorization
- Production deployment
- API endpoints
- Monitoring and alerting

## License

This project is intended as a learning and portfolio case study.
