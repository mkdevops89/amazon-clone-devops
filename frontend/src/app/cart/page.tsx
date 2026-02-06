"use client";

import { useEffect, useState } from 'react';
import Link from 'next/link';
import Navbar from '../../components/Navbar';
import api from '../../services/api';

interface CartItem {
    id: number;
    productId: number;
    productName: string;
    productPrice: number;
    quantity: number;
    imageUrl?: string;
    category?: string;
}

export default function CartPage() {
    const [cartItems, setCartItems] = useState<CartItem[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchCart = async () => {
        setLoading(true);
        try {
            const sessionId = localStorage.getItem("sessionId");
            const response = await api.get(`/cart?sessionId=${sessionId}`);

            // Map the backend CartItem to our local interface
            // Backend CartItem has a 'product' object
            const items = response.data.map((item: any) => ({
                id: item.id,
                productId: item.product.id,
                productName: item.product.name,
                productPrice: item.product.price,
                quantity: item.quantity,
                imageUrl: item.product.imageUrl || "/images/default.jpg",
                category: item.product.category
            }));

            setCartItems(items);

            // Update local storage for Navbar sync
            const navItems = items.map((i: any) => ({ id: i.productId, quantity: i.quantity }));
            localStorage.setItem("cart_items", JSON.stringify(navItems));
            window.dispatchEvent(new Event('cart-updated'));

        } catch (error) {
            console.error("Failed to fetch cart:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchCart();
    }, []);

    const updateQuantity = async (productId: number, delta: number) => {
        try {
            const sessionId = localStorage.getItem("sessionId");
            await api.post("/cart/add", {
                productId,
                quantity: delta,
                sessionId
            });
            fetchCart();
        } catch (error) {
            console.error("Failed to update quantity:", error);
        }
    };

    const subtotal = cartItems.reduce((acc, item) => acc + (item.productPrice * item.quantity), 0);
    const totalItems = cartItems.reduce((acc, item) => acc + item.quantity, 0);

    return (
        <main style={{ minHeight: '100vh', backgroundColor: '#eaeded', paddingBottom: '3rem' }}>
            <Navbar />

            <div className="container" style={{ marginTop: '2rem', display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>

                {/* Left Side: Cart Items */}
                <div style={{ flex: 3, minWidth: '350px', backgroundColor: 'white', padding: '1.5rem', borderRadius: '4px' }}>
                    <h1 style={{ fontSize: '1.8rem', fontWeight: '500', marginBottom: '0.5rem' }}>Shopping Cart</h1>
                    <div style={{ textAlign: 'right', borderBottom: '1px solid #ddd', paddingBottom: '0.5rem', marginBottom: '1rem', color: '#565959', fontSize: '0.9rem' }}>
                        Price
                    </div>

                    {loading ? (
                        <p style={{ textAlign: 'center', padding: '2rem' }}>Loading your cart...</p>
                    ) : cartItems.length === 0 ? (
                        <div style={{ textAlign: 'center', padding: '3rem' }}>
                            <p style={{ fontSize: '1.2rem', marginBottom: '1rem' }}>Your Shopping Cart is empty.</p>
                            <Link href="/" style={{ color: '#007185', textDecoration: 'none' }}>Continue shopping</Link>
                        </div>
                    ) : (
                        cartItems.map(item => (
                            <div key={item.id} style={{ display: 'flex', padding: '1rem 0', borderBottom: '1px solid #ddd', gap: '1.5rem' }}>
                                <div style={{ width: '150px', display: 'flex', justifyContent: 'center' }}>
                                    <img src={item.imageUrl} alt={item.productName} style={{ maxHeight: '150px', maxWidth: '100%', objectFit: 'contain' }} />
                                </div>
                                <div style={{ flex: 1 }}>
                                    <h3 style={{ fontSize: '1.1rem', fontWeight: '700', marginBottom: '0.3rem' }}>{item.productName}</h3>
                                    <p style={{ color: '#007600', fontSize: '0.8rem', marginBottom: '0.5rem' }}>In Stock</p>
                                    <p style={{ fontSize: '0.8rem', color: '#565959' }}>Category: {item.category}</p>

                                    <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginTop: '1rem' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', border: '1px solid #ddd', borderRadius: '8px', overflow: 'hidden', backgroundColor: '#f0f2f2' }}>
                                            <button
                                                onClick={() => updateQuantity(item.productId, -1)}
                                                style={{ padding: '0.3rem 0.8rem', border: 'none', background: 'none', cursor: 'pointer', fontSize: '1rem' }}
                                                disabled={item.quantity <= 1}
                                            >
                                                -
                                            </button>
                                            <span style={{ padding: '0 0.8rem', backgroundColor: 'white', fontSize: '0.9rem' }}>{item.quantity}</span>
                                            <button
                                                onClick={() => updateQuantity(item.productId, 1)}
                                                style={{ padding: '0.3rem 0.8rem', border: 'none', background: 'none', cursor: 'pointer', fontSize: '1rem' }}
                                            >
                                                +
                                            </button>
                                        </div>
                                        <div style={{ width: '1px', height: '14px', backgroundColor: '#ddd' }}></div>
                                        <button
                                            onClick={() => updateQuantity(item.productId, -item.quantity)}
                                            style={{ background: 'none', border: 'none', color: '#007185', fontSize: '0.8rem', cursor: 'pointer' }}
                                        >
                                            Delete
                                        </button>
                                    </div>
                                </div>
                                <div style={{ textAlign: 'right', fontWeight: '700', fontSize: '1.1rem' }}>
                                    ${item.productPrice.toFixed(2)}
                                </div>
                            </div>
                        ))
                    )}

                    {!loading && cartItems.length > 0 && (
                        <div style={{ textAlign: 'right', marginTop: '1.5rem', fontSize: '1.2rem' }}>
                            Subtotal ({totalItems} items): <span style={{ fontWeight: '700' }}>${subtotal.toFixed(2)}</span>
                        </div>
                    )}
                </div>

                {/* Right Side: Subtotal Card */}
                <div style={{ flex: 1, minWidth: '250px', backgroundColor: 'white', padding: '1.5rem', borderRadius: '4px', height: 'fit-content' }}>
                    <div style={{ fontSize: '1.1rem', marginBottom: '1.5rem' }}>
                        Subtotal ({totalItems} items): <span style={{ fontWeight: '700' }}>${subtotal.toFixed(2)}</span>
                    </div>
                    <button
                        disabled={cartItems.length === 0}
                        style={{
                            width: '100%',
                            padding: '0.6rem',
                            backgroundColor: cartItems.length === 0 ? '#ddd' : '#ffd814',
                            borderColor: '#fcd200',
                            borderRadius: '20px',
                            border: '1px solid',
                            cursor: cartItems.length === 0 ? 'not-allowed' : 'pointer',
                            fontWeight: '500',
                            fontSize: '0.9rem'
                        }}
                    >
                        Proceed to Checkout
                    </button>
                </div>

            </div>
        </main>
    );
}
