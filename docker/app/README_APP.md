Environment variables:
  - MONGODB_URI: MongoDB connection string (required)
  - PORT: optional, defaults to 3000

Endpoints:
  GET /           -> health
  GET /items      -> list items
  POST /items     -> create item (JSON body)

