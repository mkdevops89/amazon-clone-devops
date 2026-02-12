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

# Accept the API URL as a build argument
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

# Build the Next.js application for production
RUN npm run build

# ==========================================
# Stage 4: Runner (Production Image)
# ==========================================
FROM base AS runner
WORKDIR /app
ENV NODE_ENV production

# Senior Best Practice: Run as non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy public assets and the standalone build output
COPY --from=builder /app/public ./public

# Set correct permissions for the nextjs user
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT 3000
# set hostname to localhost
ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]

