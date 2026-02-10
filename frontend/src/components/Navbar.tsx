"use client";

import Link from 'next/link';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Search, ShoppingCart, MapPin } from 'lucide-react';
import CategoryBar from './CategoryBar';

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
        <nav className="bg-amazon text-white sticky top-0 z-50 flex flex-col">
            {/* Main Header */}
            <div className="container mx-auto px-4 py-2 flex items-center justify-between gap-4 h-[60px]">

                {/* Logo */}
                <Link href="/" className="flex items-center pt-2 hover:outline hover:outline-1 hover:outline-white p-1 rounded-sm">
                    <span className="text-2xl font-bold tracking-tighter">
                        Amazon<span className="text-amazon-orange">Clone</span>
                    </span>
                </Link>

                {/* Deliver To (Location) - Hidden on mobile */}
                <div className="hidden md:flex flex-col items-start leading-tight hover:outline hover:outline-1 hover:outline-white p-2 rounded-sm cursor-pointer ml-2">
                    <span className="text-xs text-gray-300 ml-4">Deliver to</span>
                    <div className="flex items-center gap-1 font-bold text-sm">
                        <MapPin size={15} />
                        <span>United States</span>
                    </div>
                </div>

                {/* Search Bar */}
                <form onSubmit={handleSearch} className="flex-1 max-w-[800px] flex items-center h-10 rounded-md overflow-hidden focus-within:ring-3 focus-within:ring-amazon-orange">
                    <button type="button" className="bg-gray-100 text-gray-600 px-3 h-full text-xs hover:bg-gray-200 border-r border-gray-300">
                        All
                    </button>
                    <input
                        type="text"
                        placeholder="Search Amazon Clone"
                        className="flex-1 h-full px-3 text-black outline-none placeholder:text-gray-500"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />
                    <button type="submit" className="bg-amazon-yellow h-full px-4 hover:bg-yellow-500 transition-colors">
                        <Search size={24} className="text-black" />
                    </button>
                </form>

                {/* Right Side Actions */}
                <div className="flex items-center gap-2">

                    {/* Account & Lists */}
                    <Link href="/login" className="hidden md:flex flex-col leading-tight hover:outline hover:outline-1 hover:outline-white p-2 rounded-sm">
                        <span className="text-xs">Hello, sign in</span>
                        <span className="font-bold text-sm">Account & Lists</span>
                    </Link>

                    {/* Returns & Orders */}
                    <Link href="/orders" className="hidden md:flex flex-col leading-tight hover:outline hover:outline-1 hover:outline-white p-2 rounded-sm">
                        <span className="text-xs">Returns</span>
                        <span className="font-bold text-sm">& Orders</span>
                    </Link>

                    {/* Cart */}
                    <Link href="/cart" className="flex items-end gap-1 hover:outline hover:outline-1 hover:outline-white p-2 rounded-sm relative">
                        <div className="relative">
                            <ShoppingCart size={32} />
                            <span className="absolute -top-1 -right-1 bg-amazon-orange text-black font-bold text-xs w-5 h-5 flex items-center justify-center rounded-full">
                                {cartCount}
                            </span>
                        </div>
                        <span className="font-bold text-sm hidden md:inline mb-1">Cart</span>
                    </Link>
                </div>
            </div>

            {/* Sub-Navigation */}
            <CategoryBar />
        </nav>
    );
}
