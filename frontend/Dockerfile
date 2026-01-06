# ==========================================
# Stage 1: Base Image
# ==========================================
FROM node:20-alpine AS base

# ==========================================
# Stage 2: Dependencies
# ==========================================
FROM base AS deps
WORKDIR /app

# Copy package.json and lockfile
COPY package.json package-lock.json ./

# Install dependencies (npm ci is faster and stricter than npm install)
RUN npm ci

# ==========================================
# Stage 3: Builder
# ==========================================
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the Next.js application for production
RUN npm run build

# ==========================================
# Stage 4: Runner (Production Image)
# ==========================================
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production

# Copy public assets and the standalone build output
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
