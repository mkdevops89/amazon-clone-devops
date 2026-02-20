"use client";

import { useEffect, useState, use } from 'react';
import Navbar from '../../../components/Navbar';
import Link from 'next/link';

interface Product {
    id: number;
    name: string;
    price: number;
    category: string;
    imageUrl?: string;
}

export default function ProductDetail({ params }: { params: Promise<{ id: string }> }) {
    const [product, setProduct] = useState<Product | null>(null);
    const [loading, setLoading] = useState(true);
    const [addingToCart, setAddingToCart] = useState(false);

    // Unwrap params using React.use() as required by Next.js 15
    const unwrappedParams = use(params);

    useEffect(() => {
        const fetchProduct = async () => {
            try {
                const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.devcloudproject.com/api';
                const res = await fetch(`${apiUrl}/products/${unwrappedParams.id}`);
                if (res.ok) {
                    const data = await res.json();
                    setProduct(data);
                } else {
                    console.error("Product not found");
                }
            } catch (error) {
                console.error("Error fetching product:", error);
            } finally {
                setLoading(false);
            }
        };

        fetchProduct();
    }, [unwrappedParams.id]);

    const addToCart = async () => {
        if (!product) return;
        setAddingToCart(true);
        const sessionId = localStorage.getItem("sessionId");
        const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'https://api.devcloudproject.com/api';

        try {
            const res = await fetch(`${apiUrl}/cart/add`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    productId: product.id,
                    quantity: 1,
                    sessionId: sessionId
                }),
            });

            if (res.ok) {
                window.dispatchEvent(new Event('cart-updated'));
                // Optional: Show a subtle "Added to cart" toast here
            }
        } catch (error) {
            console.error("Error adding to cart:", error);
        } finally {
            setAddingToCart(false);
        }
    };

    if (loading) {
        return (
            <main className="min-h-screen bg-white">
                <Navbar />
                <div className="container mx-auto px-4 py-8 animate-pulse">
                    <div className="h-6 bg-gray-200 w-1/4 mb-8 rounded"></div>
                    <div className="grid grid-cols-1 md:grid-cols-12 gap-8 relative">
                        <div className="md:col-span-5 h-[500px] bg-gray-100 rounded"></div>
                        <div className="md:col-span-4 h-96 bg-gray-100 rounded"></div>
                        <div className="md:col-span-3 h-64 bg-gray-100 rounded"></div>
                    </div>
                </div>
            </main>
        );
    }

    if (!product) {
        return (
            <main className="min-h-screen bg-white">
                <Navbar />
                <div className="container mx-auto px-4 py-16 text-center">
                    <h1 className="text-2xl font-bold mb-4">Product Not Found</h1>
                    <Link href="/" className="text-amazon-blue hover:text-amazon-orange hover:underline inline-flex items-center gap-2">
                        Return to Homepage
                    </Link>
                </div>
            </main>
        );
    }

    return (
        <main className="min-h-screen bg-white text-gray-900 pb-20">
            <Navbar />

            {/* Breadcrumb */}
            <div className="bg-white border-b border-gray-200 relative z-10 w-full mb-4">
                <div className="container mx-auto px-4 py-2 text-xs text-gray-500 flex items-center gap-2">
                    <Link href="/" className="hover:underline">Home</Link>
                    <span>›</span>
                    <Link href={`/?q=${product.category}`} className="hover:underline capitalize">{product.category}</Link>
                    <span>›</span>
                    <span className="truncate max-w-[200px] md:max-w-md">{product.name}</span>
                </div>
            </div>

            <div className="container mx-auto px-4">
                <div className="grid grid-cols-1 md:grid-cols-12 gap-8">

                    {/* Left Column: Image Gallery (5 cols) */}
                    <div className="md:col-span-5 flex flex-col items-center">
                        <div className="w-full flex justify-center sticky top-24 pt-4 pb-8 h-[400px] md:h-[500px]">
                            <img
                                src={product.imageUrl || '/images/default.jpg'}
                                alt={product.name}
                                className="max-h-full max-w-full object-contain mix-blend-multiply"
                            />
                        </div>
                    </div>

                    {/* Middle Column: Product Info (4 cols) */}
                    <div className="md:col-span-4 pt-4">
                        <h1 className="text-2xl sm:text-3xl font-medium leading-tight mb-2">
                            {product.name}
                        </h1>

                        <Link href="#" className="text-amazon-blue hover:text-amazon-orange hover:underline text-sm mb-2 block">
                            Visit the {product.category} Store
                        </Link>

                        {/* Ratings Mock */}
                        <div className="flex items-center gap-4 text-sm mb-4 border-b border-gray-300 pb-4">
                            <div className="flex items-center text-amazon-blue hover:text-amazon-orange cursor-pointer hover:underline gap-1">
                                <span className="text-amber-500 flex text-lg tracking-widest">★★★★☆</span>
                                <span>(4.2)</span>
                            </div>
                            <span className="text-amazon-blue hover:text-amazon-orange cursor-pointer hover:underline">124 Ratings</span>
                        </div>

                        <div className="mb-4">
                            <div className="flex items-start text-amazon-red gap-1">
                                <span className="text-lg mt-1 font-medium">-20%</span>
                                <span className="text-3xl font-medium">
                                    <span className="text-sm align-top font-medium mt-1 mr-0.5">$</span>
                                    {Math.floor(product.price)}
                                    <span className="text-sm align-top font-medium mt-1">{(product.price % 1).toFixed(2).substring(1)}</span>
                                </span>
                            </div>
                            <div className="text-gray-500 text-sm mt-1">
                                List Price: <span className="line-through">${(product.price * 1.25).toFixed(2)}</span>
                            </div>
                        </div>

                        <div className="mb-6">
                            <p className="text-sm border border-amazon-orange bg-orange-50 text-amazon-orange inline-block px-3 py-1 font-medium mb-4 rounded-sm">
                                Amazon's <span className="text-gray-900">Choice</span>
                            </p>
                            <h3 className="font-bold text-md mb-2">About this item</h3>
                            <ul className="text-sm text-gray-800 list-disc pl-5 space-y-2">
                                <li>Premium build quality engineered for long-lasting durability and peak performance in everyday use.</li>
                                <li>Sleek, modern design that perfectly complements any {product.category} setup or environment.</li>
                                <li>Optimized for both beginners and experts, delivering a seamless out-of-the-box experience.</li>
                                <li>Backed by our comprehensive 1-year worry-free warranty and 24/7 customer support.</li>
                                <li>Eco-friendly packaging and energy-efficient operation.</li>
                            </ul>
                        </div>
                    </div>

                    {/* Right Column: Buy Box (3 cols) */}
                    <div className="md:col-span-3 pt-4">
                        <div className="border border-gray-300 rounded-lg p-5 bg-white shadow-sm sticky top-24">

                            <div className="flex items-baseline gap-1 mb-2">
                                <span className="text-sm align-top font-bold text-gray-900">$</span>
                                <span className="text-2xl font-bold text-gray-900">{Math.floor(product.price)}</span>
                                <span className="text-sm align-top font-bold text-gray-900">{(product.price % 1).toFixed(2).substring(1)}</span>
                            </div>

                            <div className="text-sm text-gray-900 mb-4 leading-relaxed">
                                <span className="text-amazon-blue hover:underline cursor-pointer">FREE Returns</span>
                                <br />
                                <span>FREE delivery <span className="font-bold">Wednesday, Feb 28</span></span>
                                <br />
                                <span className="text-amazon-blue hover:underline cursor-pointer mt-1 inline-block">Or fastest delivery Tomorrow, Feb 24. Order within 10 hrs 30 mins</span>
                            </div>

                            <div className="flex items-center gap-1 text-amazon-green-dark mb-4">
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                <span className="text-sm text-amazon-blue hover:underline cursor-pointer">Deliver to Michael - Austin 78701</span>
                            </div>

                            <div className="text-amazon-green-dark text-lg font-medium mb-4">
                                In Stock
                            </div>

                            <div className="mb-4">
                                <select className="bg-gray-100 border border-gray-300 text-gray-900 text-sm rounded-md focus:ring-amazon-yellow focus:border-amazon-yellow block w-full p-2 shadow-sm cursor-pointer">
                                    <option>Qty: 1</option>
                                    <option>Qty: 2</option>
                                    <option>Qty: 3</option>
                                    <option>Qty: 4</option>
                                </select>
                            </div>

                            <button
                                onClick={addToCart}
                                disabled={addingToCart}
                                className={`w-full bg-amazon-yellow hover:bg-yellow-400 text-sm font-medium py-3 rounded-full shadow-sm mb-3 transition-colors ${addingToCart ? 'opacity-70 cursor-wait' : ''}`}
                            >
                                {addingToCart ? 'Adding to Cart...' : 'Add to Cart'}
                            </button>

                            <button
                                className="w-full bg-amazon-orange hover:bg-orange-400 text-sm font-medium py-3 rounded-full shadow-sm transition-colors"
                            >
                                Buy Now
                            </button>

                            <div className="mt-4 text-xs text-gray-500 space-y-2 border-t border-gray-200 pt-4">
                                <div className="grid grid-cols-2 gap-2">
                                    <span>Ships from</span>
                                    <span>Amazon</span>
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <span>Sold by</span>
                                    <span>Amazon</span>
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <span>Returns</span>
                                    <span className="text-amazon-blue">Eligible for Return</span>
                                </div>
                            </div>
                        </div>
                    </div>

                </div>
            </div>
        </main>
    );
}
