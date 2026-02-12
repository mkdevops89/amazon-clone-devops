"use client";

import { useEffect, useState, Suspense } from 'react';
import { useSearchParams } from 'next/navigation';
import Navbar from '../components/Navbar';
import HeroCarousel from '../components/HeroCarousel';
import ProductCard from '../components/ProductCard';

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
      {!searchQuery && <HeroCarousel />}

      <div className={`container mx-auto px-4 relative z-30 ${!searchQuery ? '-mt-20 md:-mt-32' : 'mt-8'}`}>
        {searchQuery && (
          <h2 className="text-xl mb-4">
            Results for <span className="font-bold text-amazon-orange">"{searchQuery}"</span>
          </h2>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {loading ? (
            Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="bg-white p-4 h-96 animate-pulse rounded-sm">
                <div className="h-48 bg-gray-200 mb-4 rounded"></div>
                <div className="h-4 bg-gray-200 w-3/4 mb-2 rounded"></div>
                <div className="h-4 bg-gray-200 w-1/2 rounded"></div>
              </div>
            ))
          ) : products.length === 0 ? (
            <div className="col-span-full text-center py-12 bg-white rounded-sm shadow-sm">
              <p className="text-lg text-gray-700">No products found matching your search.</p>
              <button
                onClick={() => window.location.href = '/'}
                className="mt-4 text-amazon-blue hover:underline hover:text-amazon-orange transition-colors"
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
    <main className="min-h-screen pb-10 bg-gray-100">
      <Navbar />
      <Suspense fallback={<div className="text-center p-10">Loading...</div>}>
        <HomeContent />
      </Suspense>
    </main>
  );
}
