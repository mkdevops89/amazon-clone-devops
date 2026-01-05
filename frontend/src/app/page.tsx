import Navbar from '../components/Navbar';
import Hero from '../components/Hero';
import ProductCard from '../components/ProductCard';

export default function Home() {
  const products = [
    { id: 1, title: "Wireless Headphones", price: 299.99, category: "Electronics", image: "/headphones.jpg" },
    { id: 2, title: "Smart Watch Series 7", price: 399.00, category: "Wearables", image: "/watch.jpg" },
    { id: 3, title: "Gaming Laptop Pro", price: 1299.99, category: "Computers", image: "/laptop.jpg" },
    { id: 4, title: "4K Monitor 27-inch", price: 349.50, category: "Monitors", image: "/monitor.jpg" },
    { id: 5, title: "Mechanical Keyboard", price: 89.99, category: "Accessories", image: "/keyboard.jpg" },
    { id: 6, title: "Ergonomic Office Chair", price: 199.99, category: "Furniture", image: "/chair.jpg" },
    { id: 7, title: "Running Shoes", price: 59.99, category: "Fashion", image: "/shoes.jpg" },
    { id: 8, title: "Electric Coffee Maker", price: 45.00, category: "Appliances", image: "/coffee.jpg" },
  ];

  return (
    <main style={{ minHeight: '100vh', paddingBottom: '2rem' }}>
      <Navbar />
      <Hero />

      <div className="container" style={{ position: 'relative', zIndex: 10 }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
          gap: '1.5rem',
          padding: '1rem'
        }}>
          {products.map(product => (
            <ProductCard
              key={product.id}
              title={product.title}
              price={product.price}
              category={product.category}
              image={product.image}
            />
          ))}
        </div>
      </div>
    </main>
  );
}
