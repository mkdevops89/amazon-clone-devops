#!/bin/bash
# ops/scripts/download_images.sh

# Create the images directory if it doesn't exist
mkdir -p frontend/public/images

echo "Downloading placeholder images..."

# Headphones
curl -L -o frontend/public/images/headphones.jpg "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=600&auto=format&fit=crop"

# Smart Watch
curl -L -o frontend/public/images/watch.jpg "https://images.unsplash.com/photo-1523275335684-37898b6baf30?q=80&w=600&auto=format&fit=crop"

# Running Shoes
curl -L -o frontend/public/images/shoes.jpg "https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600&auto=format&fit=crop"

echo "Images downloaded to frontend/public/images/"
