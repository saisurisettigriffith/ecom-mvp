# E-commerce MVP with Delivery Promise Service

This repository captures a two-day, production-shaped plan for an e-commerce MVP that focuses on a delivery promise (ETA) service implemented with Spring Boot services and a React storefront. The layout, infrastructure, and milestones mirror the GitHub Project guidance described in the project brief.

## Repository Layout

```
ecom-mvp/
  docker-compose.yml
  .env
  platform/
    nginx/
      default.conf
    prometheus/
      prometheus.yml
  libs/
    common-dto/
    common-events/
  services/
    api-gateway/
    catalog-service/
    inventory-service/
    promise-service/
    order-service/
    payment-service/
  web/
    storefront-react/
  scripts/
    seed.sql
```

## Environment

All supporting infrastructure runs locally through Docker Compose.

```
MYSQL_HOST=localhost
MYSQL_USER=ecom
MYSQL_PASSWORD=ecom
MYSQL_DB=ecom
REDIS_HOST=localhost
KAFKA_BROKERS=localhost:9092
TZ=Europe/Dublin
```

## Day 1 – Backend-first Thin Slice, Then React

### 09:00–10:30 — Infra + scaffolding

1. Initialize the monorepo and Docker Compose stack (MySQL, Redis, Kafka, Prometheus, Grafana, Nginx).
2. Scaffold Spring Boot services for Catalog, Inventory, Promise (3.3.x) with dependencies (Web, Actuator, JPA, Validation, Flyway, Redis, Kafka, Lombok).
3. Commit message: `chore: repo init + compose + services skeleton`.

### 10:30–12:30 — Catalog + Inventory (ATP view)

1. Catalog Service:
   * Tables: `product`, `product_image`.
   * Endpoints: `GET /products`, `GET /products/{id}`.
   * Seed ~50 products via Flyway or [`scripts/seed.sql`](scripts/seed.sql).
2. Inventory Service:
   * Tables: `inventory`, `warehouse`, `inventory_outbox`.
   * Endpoint: `GET /inventory/atp?sku=&postalCode=`.
   * Determine nearest warehouse availability.
3. Commit message: `feat: catalog + inventory ATP endpoint + seed`.

### 13:30–16:00 — Promise Service (ETA) v1

1. Pull ATP from the Inventory service, and combine with warehouse cutoff, pack hours, and carrier SLA matrix.
2. Endpoint: `GET /promise?sku=&postalCode=&method=STANDARD`.
3. Cache responses in Redis for 10–15 minutes with TTL and ETag.
4. Confidence formula blends inventory freshness, carrier reliability, distance, and pack variance.
5. Fallback messaging for low confidence.
6. Commit message: `feat: promise-service /promise with confidence + redis cache`.

### 16:00–18:00 — React Storefront

1. Pages: `/product/:sku`, `/cart`.
2. Hook `useDeliveryPromise` calls `/api/promise`.
3. Render promise message in UI, fallback to range messaging.
4. Commit message: `feat(frontend): product + cart + promise UI`.

## Day 2 – Persisted Promises, CDC, Observability

### 09:00–11:00 — Order Service & Idempotency

* Tables: `order`, `order_item`, `order_promise`, `idempotency_key`.
* Endpoint: `POST /orders` (with `Idempotency-Key`).
* Flow: validate cart, recompute promise, persist `order_promise`, emit `order.created` event.
* Commit message: `feat: order-service + persist promisedDate + idempotency`.

### 11:00–12:30 — Payment Stub + Saga Events

* Payment service simulates `POST /payments/auth` returning `AUTHORIZED`.
* Kafka topics: `order.created`, `payment.authorized`, `inventory.reserved`, `shipment.created`, `promise.recalc`.
* Inventory service consumes `order.created` and publishes `inventory.reserved`.
* Commit message: `feat: payment stub + basic saga events`.

### 13:30–15:00 — CDC/Outbox + Search Sync

* Inventory service scans `inventory_outbox` and publishes `inventory.updated` to Kafka.
* Optional catalog outbox and search indexer stub for future Elasticsearch wiring.
* Commit message: `feat: outbox publisher + topics + search-indexer stub`.

### 15:00–16:30 — Observability + Gateway

* OpenTelemetry auto-instrumentation exporting to Prometheus through Micrometer.
* Grafana dashboards for HTTP latency, error rate, Kafka consumer lag.
* Nginx reverse proxy routes API calls to services and serves React build artifacts.
* Commit message: `chore: observability + nginx routing`.

### 16:30–18:00 — CI/CD + README + Demo

* GitHub Actions for Java build/test and Docker image publishing.
* React build pipeline and container image.
* Update README with setup instructions and demo script.
* Commit message: `ci: github actions + docs + demo`.

## Key Schemas and Tables

The `scripts/seed.sql` file contains starter data for warehouse, catalog, and inventory tables. Formal DDL for services follows the schema definitions outlined in the project brief (e.g., `product`, `inventory`, `order`, `order_promise`, `inventory_outbox`, `idempotency_key`).

## API Surface (MVP)

* Catalog: `GET /products`, `GET /products/{id or sku}`.
* Inventory: `GET /inventory/atp`.
* Promise: `GET /promise` (returns delivery date, confidence, warehouse, explanations, expiry).
* Orders: `POST /orders` (idempotent) and `GET /orders/{id}`.
* Payment: `POST /payments/auth`.

## Events and Topics

* `catalog.updated`
* `inventory.updated`
* `order.created`
* `payment.authorized`
* `inventory.reserved`
* `promise.recalc`

## Demo Script

```bash
docker compose up -d
mysql -h127.0.0.1 -uecom -pecom ecom < scripts/seed.sql
curl :80/api/catalog/products?sku=SKU123 | jq
curl ":80/api/promise?sku=SKU123&postalCode=D01%20X2Y3" | jq
curl -H "Content-Type: application/json" \
     -H "Idempotency-Key: demo-key-123" \
     -d '{
       "userId": 42,
       "items": [{"sku": "SKU123", "qty": 1}],
       "address": {"line1": "1 Capel St", "postalCode": "D01 X2Y3"},
       "paymentMethod": "CARD",
       "promise": {"sku": "SKU123", "postalCode": "D01 X2Y3", "method": "STANDARD"}
     }' \
     :80/api/orders | jq
```

## Next Steps

* Flesh out each service with Spring Boot projects, Flyway migrations, and Kafka integrations.
* Implement the React storefront with routing, state management, and promise UI elements.
* Add GitHub Actions workflows and container build scripts.
* Expand observability dashboards and alerts (e.g., low confidence ratios, order failures).
