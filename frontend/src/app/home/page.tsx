"use client";

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Navbar from '../../components/Navbar';
import Hero from '../../components/Hero';
import ProductCard from '../../components/ProductCard';

interface Product {
  id: number;
  name: string;
  price: number;
  category: string;
  imageUrl?: string;
}

function HomeContent() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const searchParams = useSearchParams();
  const searchQuery = searchParams.get('search');

  useEffect(() => {
    setLoading(true);
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.devcloudproject.com/api';
    const fetchUrl = searchQuery
      ? `${apiUrl}/products/search?q=${encodeURIComponent(searchQuery)}`
      : `${apiUrl}/products`;

    fetch(fetchUrl)
      .then(res => res.json())
      .then(data => {
        setProducts(Array.isArray(data) ? data : []);
        setLoading(false);
      })
      .catch(err => {
        console.error("Failed to fetch products:", err);
        setLoading(false);
      });
  }, [searchQuery]);

  return (
    <>
      {!searchQuery && <Hero />}

      <div className="container" style={{ position: 'relative', zIndex: 10, marginTop: searchQuery ? '2rem' : '0' }}>
        {searchQuery && (
          <h2 style={{ marginBottom: '1rem', fontSize: '1.2rem', fontWeight: '400' }}>
            Results for <span style={{ color: '#c45500', fontWeight: '700' }}>"{searchQuery}"</span>
          </h2>
        )}

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: '1.5rem',
          padding: '1rem'
        }}>
          {loading ? (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '3rem' }}>
              <p>Loading products from Amazon Storefront...</p>
            </div>
          ) : products.length === 0 ? (
            <div style={{ gridColumn: '1 / -1', textAlign: 'center', padding: '3rem' }}>
              <p style={{ fontSize: '1.2rem' }}>No products found matching your search.</p>
              <button
                onClick={() => window.location.href = '/'}
                style={{ marginTop: '1rem', color: '#007185', background: 'none', border: 'none', cursor: 'pointer', textDecoration: 'underline' }}
              >
                Clear search and view all products
              </button>
            </div>
          ) : (
            products.map(product => (
              <ProductCard
                key={product.id}
                id={product.id}
                title={product.name}
                price={product.price}
                category={product.category}
                image={product.imageUrl || "/images/default.jpg"}
              />
            ))
          )}
        </div>
      </div>
    </>
  );
}

export default function Home() {
  return (
    <main style={{ minHeight: '100vh', paddingBottom: '2rem', backgroundColor: '#eaeded' }}>
      <Navbar />
      <Suspense fallback={<div className="text-center p-10">Loading search context...</div>}>
        <HomeContent />
      </Suspense>
    </main>
  );
}
