# CareerCraft

CareerCraft is a full-stack project with a **Flutter frontend** and a **Node.js/Express backend** for GitHub-powered career tooling (README generation, repo chat, interview practice, resume support, and activity tracking).

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js, Express, MongoDB (Mongoose)
- **AI/GitHub Integrations:** Gemini API, GitHub REST API

## Project Structure

```text
CareerCraft/
├── backend/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   ├── controllers/     # Request/response handling
│   ├── middleware/      # Auth middleware
│   ├── models/          # Mongoose schemas
│   ├── repositories/    # DB access abstraction
│   ├── routes/          # API route declarations
│   ├── services/        # Business logic + integrations
│   └── utils/           # Shared helper utilities
├── frontend/
│   ├── lib/
│   └── ...
└── README.md
```

## Backend Architecture (Layered / MVC-inspired)

The backend now follows clean separation of concerns:

1. **Routes**
   - Define URL paths and middleware.
   - Delegate execution to controllers only.

2. **Controllers**
   - Parse request inputs.
   - Return HTTP responses/status codes.
   - Call service methods.

3. **Services**
   - Own business rules and orchestration.
   - Integrate external systems (GitHub, Gemini).
   - Stay independent from Express internals.

4. **Repositories**
   - Isolate all Mongoose queries.
   - Keep persistence logic out of services/controllers.

5. **Models**
   - Mongoose schemas and domain entities.

## Backend Setup

1. Install dependencies:

```bash
cd backend
npm install
```

2. Create `.env` file in `backend/` with:

```env
PORT=5000
MONGO_URI=<your_mongodb_connection>
JWT_SECRET=<your_jwt_secret>
GITHUB_CLIENT_ID=<your_github_oauth_client_id>
GITHUB_CLIENT_SECRET=<your_github_oauth_client_secret>
GEMINI_API_KEY=<your_gemini_api_key>
GEMINI_MODEL=<gemini_model_name>
```

3. Start backend:

```bash
npm run dev
```

## Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

## API Modules

- `/auth/github` - OAuth login, profile, repository listing
- `/ai/readme` - README/social post/resume points generation
- `/chat` - repository chat sessions and history
- `/repositories` - favourites management
- `/activity` - recent activity logging
- `/interviews` - repo summaries and mock interview flow
- `/resume` - resume draft management

## Improvements Applied

- Reorganized backend into **controller/service/repository/model** layers.
- Reduced route files to thin routers with clean imports.
- Moved business logic and persistence logic out of route handlers.
- Created `app.js` for Express app wiring and simplified `server.js` bootstrap.
- Fixed maintainability issues in AI route logic by centralizing logic in service classes.

## Suggested Next Improvements

1. Add **automated tests**:
   - Unit tests for services.
   - Integration tests for routes using supertest.

2. Add **request validation**:
   - Use Joi/Zod for robust DTO validation.

3. Add **centralized error middleware**:
   - Standardized API error format.

4. Add **logging/observability**:
   - Structured logging (pino/winston), request correlation IDs.

5. Add **rate limiting/caching**:
   - Protect Gemini/GitHub endpoints and reduce duplicate external calls.

6. Add **OpenAPI/Swagger docs**:
   - Better API discoverability and frontend-backend contracts.

7. Improve **security hardening**:
   - Helmet, stricter CORS policy, token rotation strategy.

---

If needed, I can also provide a second pass that introduces DTOs, validation middleware, and full test coverage while preserving current API contracts.
