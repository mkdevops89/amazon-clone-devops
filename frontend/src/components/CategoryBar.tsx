"use client";

import { Menu } from 'lucide-react';
import Link from 'next/link';

const categories = [
    "All",
    "Today's Deals",
    "Customer Service",
    "Registry",
    "Gift Cards",
    "Sell",
    "Electronics",
    "Computers",
    "Home & Kitchen",
    "Fashion",
    "Books",
    "Kindle Books"
];

export default function CategoryBar() {
    return (
        <div className="bg-amazon-light text-white text-sm py-1.5 px-4 flex items-center gap-4 overflow-x-auto whitespace-nowrap scrollbar-hide">
            <button className="flex items-center gap-1 font-bold hover:outline hover:outline-1 hover:outline-white px-2 py-1 rounded-sm">
                <Menu size={20} />
                All
            </button>

            {categories.slice(1).map((cat) => (
                <Link
                    key={cat}
                    href="#"
                    className="hover:outline hover:outline-1 hover:outline-white px-2 py-1 rounded-sm transition-all"
                >
                    {cat}
                </Link>
            ))}
        </div>
    );
}
