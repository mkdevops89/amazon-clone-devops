"use client";

import { useEffect, useState } from 'react';
import Navbar from '../components/Navbar';
import Hero from '../components/Hero';
import ProductCard from '../components/ProductCard';

interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
  imageUrl?: string;
}

export default function Home() {
  const [products, setProducts] = useState<Product[]>([]);

  useEffect(() => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.devcloudproject.com/api';
    fetch(`${apiUrl}/products`)
      .then(res => res.json())
      .then(data => setProducts(data))
      .catch(err => console.error("Failed to fetch products:", err));
  }, []);

  return (
    <main style={{ minHeight: '100vh', paddingBottom: '2rem' }}>
      <Navbar />
      <Hero />

      <div className="container" style={{ position: 'relative', zIndex: 10 }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: '1.5rem',
          padding: '1rem'
        }}>
          {products.length === 0 ? (
            <p className="text-center p-10">Loading products from Amazon Storefront...</p>
          ) : (
            products.map(product => (
              <ProductCard
                key={product.id}
                title={product.name}
                price={product.price}
                category={product.category}
                image={product.imageUrl || "/images/default.jpg"}
              />
            ))
          )}
        </div>
      </div>
    </main>
  );
}
