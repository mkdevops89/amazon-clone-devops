"use client";

import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { ChevronLeft, ChevronRight } from 'lucide-react';

const slides = [
    {
        id: 1,
        image: "https://images.pexels.com/photos/459653/pexels-photo-459653.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1", // Tech/Laptop
        title: "Upgrade Your Tech",
        subtitle: "Latest gadgets and accessories"
    },
    {
        id: 2,
        image: "https://images.pexels.com/photos/2526878/pexels-photo-2526878.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1", // Running/Fitness
        title: "Get Active",
        subtitle: "Essentials for your fitness journey"
    },
    {
        id: 3,
        image: "https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1", // Healthy Food/Kitchen (Replacing Air Fryer specific with general food)
        title: "Kitchen Upgrades",
        subtitle: "Cook like a pro at home"
    }
];

export default function HeroCarousel() {
    const [current, setCurrent] = useState(0);

    useEffect(() => {
        const timer = setInterval(() => {
            setCurrent((prev) => (prev + 1) % slides.length);
        }, 5000);
        return () => clearInterval(timer);
    }, []);

    const nextSlide = () => setCurrent((prev) => (prev + 1) % slides.length);
    const prevSlide = () => setCurrent((prev) => (prev - 1 + slides.length) % slides.length);

    return (
        <div className="relative w-full h-[300px] md:h-[400px] lg:h-[500px] overflow-hidden bg-gray-900 group">
            <AnimatePresence mode='wait'>
                <motion.div
                    key={current}
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{ duration: 0.5 }}
                    className="absolute inset-0"
                >
                    <div
                        className="absolute inset-0 bg-cover bg-center"
                        style={{ backgroundImage: `url(${slides[current].image})` }}
                    />
                    {/* Gradient Overlay - Amazon style fade to white/gray at bottom */}
                    <div className="absolute inset-0 bg-gradient-to-t from-[#e3e6e6] via-transparent to-transparent h-full" />

                    <div className="absolute inset-0 bg-black/20" /> {/* Slight darken for text readability */}
                </motion.div>
            </AnimatePresence>

            <button
                onClick={prevSlide}
                className="absolute left-4 top-1/2 -translate-y-1/2 p-2 bg-transparent border-2 border-white/50 rounded hover:bg-white/10 text-white opacity-0 group-hover:opacity-100 transition-opacity"
            >
                <ChevronLeft size={32} />
            </button>

            <button
                onClick={nextSlide}
                className="absolute right-4 top-1/2 -translate-y-1/2 p-2 bg-transparent border-2 border-white/50 rounded hover:bg-white/10 text-white opacity-0 group-hover:opacity-100 transition-opacity"
            >
                <ChevronRight size={32} />
            </button>

            <div className="absolute bottom-10 left-1/2 -translate-x-1/2 flex gap-2">
                {slides.map((_, index) => (
                    <div
                        key={index}
                        className={`w-3 h-3 rounded-full transition-colors ${index === current ? 'bg-amazon-orange' : 'bg-white/50'}`}
                    />
                ))}
            </div>
        </div>
    );
}
