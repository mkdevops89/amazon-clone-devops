"use client";

import { useState } from "react";
import api from "../services/api";

interface ProductProps {
    id: number;
    title: string;
    price: number;
    image: string;
    category: string;
}

export default function ProductCard({ id, title, price, image, category }: ProductProps) {
    const [adding, setAdding] = useState(false);
    const [added, setAdded] = useState(false);

    const handleAddToCart = async () => {
        setAdding(true);
        try {
            const sessionId = localStorage.getItem("sessionId") || Math.random().toString(36).substring(7);
            if (!localStorage.getItem("sessionId")) {
                localStorage.setItem("sessionId", sessionId);
            }

            await api.post("/cart/add", {
                productId: id,
                quantity: 1,
                sessionId: sessionId
            });

            // Update local storage for immediate UI feedback in Navbar
            const cartItems = JSON.parse(localStorage.getItem("cart_items") || "[]");
            const existingItem = cartItems.find((item: any) => item.id === id);
            if (existingItem) {
                existingItem.quantity += 1;
            } else {
                cartItems.push({ id, title, price, quantity: 1, image, category });
            }
            localStorage.setItem("cart_items", JSON.stringify(cartItems));

            // Trigger Navbar update
            window.dispatchEvent(new Event('cart-updated'));

            setAdded(true);
            setTimeout(() => setAdded(false), 2000);
        } catch (error) {
            console.error("Failed to add to cart:", error);
            // alert("Failed to add items to cart. Please try again.");
        } finally {
            setAdding(false);
        }
    };

    return (
        <div className="glass-panel" style={{
            padding: '1.5rem',
            display: 'flex',
            flexDirection: 'column',
            height: '100%',
            backgroundColor: 'white',
            zIndex: 1,
            position: 'relative',
            border: '1px solid #ddd',
            borderRadius: '4px'
        }}>
            <h3 style={{ fontSize: '1.1rem', marginBottom: '0.5rem', height: '2.4rem', overflow: 'hidden' }}>{title}</h3>

            <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', marginBottom: '1rem', background: '#f8f8f8', minHeight: '180px', borderRadius: '4px' }}>
                <img
                    src={image}
                    alt={title}
                    style={{ maxHeight: '160px', maxWidth: '100%', objectFit: 'contain' }}
                />
            </div>

            <div style={{ marginBottom: '0.5rem' }}>
                <span style={{ fontSize: '0.8rem', color: '#007185', fontWeight: 'bold' }}>{category}</span>
            </div>

            <div style={{ fontSize: '1.3rem', fontWeight: 'bold', display: 'flex', alignItems: 'start' }}>
                <span style={{ fontSize: '0.8rem', marginTop: '4px' }}>$</span>
                {price}
            </div>

            <div style={{ marginTop: '0.5rem', color: '#565959', fontSize: '0.9rem' }}>
                FREE delivery <span style={{ fontWeight: 'bold' }}>Tomorrow</span>
            </div>

            <button
                onClick={handleAddToCart}
                disabled={adding}
                style={{
                    marginTop: '1rem',
                    width: '100%',
                    padding: '0.5rem',
                    backgroundColor: added ? '#2e7d32' : (adding ? '#ccc' : '#ffd814'),
                    borderColor: added ? '#2e7d32' : '#fcd200',
                    color: added ? 'white' : 'black',
                    borderRadius: '20px',
                    cursor: adding ? 'not-allowed' : 'pointer',
                    fontWeight: '500',
                    border: '1px solid',
                    transition: 'all 0.2s'
                }}
            >
                {adding ? "Adding..." : (added ? "Added!" : "Add to Cart")}
            </button>
        </div>
    );
}
