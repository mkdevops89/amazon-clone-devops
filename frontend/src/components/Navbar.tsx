"use client";

import Link from 'next/link';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Navbar() {
    const [searchQuery, setSearchQuery] = useState("");
    const [cartCount, setCartCount] = useState(0);
    const router = useRouter();

    useEffect(() => {
        // Initialize Session ID if missing
        if (typeof window !== "undefined" && !localStorage.getItem("sessionId")) {
            localStorage.setItem("sessionId", crypto.randomUUID());
        }

        // Sync cart count from local storage or API
        const updateCartCount = () => {
            const user = typeof window !== "undefined" ? localStorage.getItem("user") : null;
            const sessionId = typeof window !== "undefined" ? localStorage.getItem("sessionId") : null;

            // For now, we'll just check local storage for a quick update
            // Ideally this would be a fetch to /api/cart
            const items = typeof window !== "undefined" ? JSON.parse(localStorage.getItem("cart_items") || "[]") : [];
            setCartCount(items.reduce((acc: number, item: any) => acc + item.quantity, 0));
        };

        updateCartCount();
        window.addEventListener('cart-updated', updateCartCount);
        return () => window.removeEventListener('cart-updated', updateCartCount);
    }, []);

    const handleSearch = (e: React.FormEvent) => {
        e.preventDefault();
        if (searchQuery.trim()) {
            router.push(`/?search=${encodeURIComponent(searchQuery.trim())}`);
        }
    };

    return (
        <nav style={{ backgroundColor: 'var(--secondary)', color: 'white', padding: '0.5rem 0' }}>
            <div className="container" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: '60px' }}>

                {/* Logo */}
                <Link href="/" style={{ fontSize: '1.5rem', fontWeight: 'bold', color: 'white', textDecoration: 'none', marginRight: '2rem' }}>
                    Amazon<span style={{ color: 'var(--primary)' }}>Clone</span>
                </Link>

                {/* Search Bar */}
                <form onSubmit={handleSearch} style={{ flex: 1, display: 'flex', maxWidth: '800px' }}>
                    <input
                        type="text"
                        placeholder="Search Amazon Clone"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        style={{
                            width: '100%',
                            padding: '0.6rem',
                            borderRadius: '4px 0 0 4px',
                            border: 'none',
                            outline: 'none',
                            color: 'black'
                        }}
                    />
                    <button type="submit" style={{
                        backgroundColor: 'var(--primary)',
                        border: 'none',
                        borderRadius: '0 4px 4px 0',
                        padding: '0 1rem',
                        fontWeight: 'bold',
                        cursor: 'pointer'
                    }}>
                        Search
                    </button>
                </form>

                {/* Actions */}
                <div style={{ display: 'flex', gap: '1.5rem', marginLeft: '2rem' }}>
                    <Link href="/login" style={{ color: 'white', display: 'flex', flexDirection: 'column', fontSize: '0.8rem', textDecoration: 'none' }}>
                        <span>Hello, Sign in</span>
                        <span style={{ fontWeight: 'bold', fontSize: '0.9rem' }}>Account & Lists</span>
                    </Link>

                    <Link href="/orders" style={{ color: 'white', display: 'flex', flexDirection: 'column', fontSize: '0.8rem', textDecoration: 'none' }}>
                        <span>Returns</span>
                        <span style={{ fontWeight: 'bold', fontSize: '0.9rem' }}>& Orders</span>
                    </Link>

                    <Link href="/cart" style={{ color: 'white', display: 'flex', alignItems: 'end', textDecoration: 'none', position: 'relative' }}>
                        <span style={{ fontSize: '1.2rem', fontWeight: 'bold' }}>🛒 Cart</span>
                        {cartCount > 0 && (
                            <span style={{
                                position: 'absolute',
                                top: '-8px',
                                right: '-8px',
                                backgroundColor: '#f08804',
                                color: 'black',
                                borderRadius: '50%',
                                padding: '2px 6px',
                                fontSize: '0.75rem',
                                fontWeight: 'bold'
                            }}>
                                {cartCount}
                            </span>
                        )}
                    </Link>
                </div>

            </div>

            {/* Sub-nav */}
            <div style={{ backgroundColor: 'var(--secondary-light)', padding: '0.5rem 0', marginTop: '0.5rem' }}>
                <div className="container" style={{ display: 'flex', gap: '1rem', fontSize: '0.9rem' }}>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>All</Link>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>Today's Deals</Link>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>Customer Service</Link>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>Registry</Link>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>Gift Cards</Link>
                    <Link href="#" style={{ color: 'white', textDecoration: 'none' }}>Sell</Link>
                </div>
            </div>
        </nav>
    );
}
