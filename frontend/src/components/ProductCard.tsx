"use client";

import Link from 'next/link';

interface ProductCardProps {
    id: number;
    title: string;
    price: number;
    image: string;
    category: string;
}

export default function ProductCard({ id, title, price, image, category }: ProductCardProps) {
    return (
        <div className="bg-white p-4 flex flex-col h-full rounded-sm z-30 relative hover:-translate-y-1 transition-transform duration-200">
            <div className="relative h-48 w-full mb-4 flex items-center justify-center">
                <img
                    src={image}
                    alt={title}
                    className="max-h-full max-w-full object-contain"
                />
            </div>

            <div className="flex-1 flex flex-col gap-2">
                <Link
                    href={`/product/${id}`}
                    className="text-lg font-medium text-gray-900 hover:text-amazon-orange hover:underline line-clamp-2"
                >
                    {title}
                </Link>

                {/* Rating Mock */}
                <div className="flex items-center gap-1 text-sm text-amazon-blue">
                    <span>★★★★☆</span>
                    <span className="text-xs text-gray-500">1,234</span>
                </div>

                <div className="mt-auto">
                    <div className="flex items-baseline gap-1">
                        <span className="text-xs align-top font-bold text-gray-900">$</span>
                        <span className="text-2xl font-bold text-gray-900">{Math.floor(price)}</span>
                        <span className="text-xs align-top font-bold text-gray-900">{(price % 1).toFixed(2).substring(1)}</span>
                    </div>

                    <div className="flex items-center gap-1 mt-1">
                        <span className="text-xs text-gray-500">List: </span>
                        <span className="text-xs text-gray-500 line-through">${(price * 1.2).toFixed(2)}</span>
                    </div>

                    <p className="text-xs text-gray-600 mt-1">
                        Delivery <span className="font-bold">Mon, Feb 26</span>
                    </p>

                    <button className="w-full mt-3 bg-amazon-yellow border border-yellow-500 rounded-full py-1.5 text-sm shadow-sm hover:bg-yellow-400 focus:ring-2 focus:ring-yellow-500 active:ring-amazon-orange">
                        Add to Cart
                    </button>
                </div>
            </div>
        </div>
    );
}
