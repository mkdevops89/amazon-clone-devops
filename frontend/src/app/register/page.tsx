"use client";

import { useState } from "react";
import Link from 'next/link';
import AuthService from "../../services/auth.service";
import { useRouter } from "next/navigation";

export default function Register() {
    const [username, setUsername] = useState("");
    const [email, setEmail] = useState("");
    const [password, setPassword] = useState("");
    const [successful, setSuccessful] = useState(false);
    const [message, setMessage] = useState("");
    const [loading, setLoading] = useState(false);
    const router = useRouter();

    const handleRegister = (e: React.FormEvent) => {
        e.preventDefault();
        setMessage("");
        setSuccessful(false);
        setLoading(true);

        AuthService.register(username, email, password).then(
            (response) => {
                setMessage(response.data.message);
                setSuccessful(true);
                setLoading(false);
                setTimeout(() => router.push("/login"), 2000);
            },
            (error) => {
                const resMessage =
                    (error.response &&
                        error.response.data &&
                        error.response.data.message) ||
                    error.message ||
                    error.toString();

                setMessage(resMessage);
                setSuccessful(false);
                setLoading(false);
            }
        );
    };

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            paddingTop: '3rem',
            background: 'linear-gradient(to bottom, #f0f2f2, #ffffff)',
            fontFamily: 'system-ui, -apple-system, sans-serif'
        }}>
            {/* Logo */}
            <Link href="/" style={{ marginBottom: '1.5rem', fontSize: '2.5rem', fontWeight: 'bold', textDecoration: 'none', color: 'black' }}>
                Amazon<span style={{ color: '#ff9900' }}>Clone</span>
            </Link>

            {/* Register Card */}
            <div style={{
                width: '100%',
                maxWidth: '350px',
                padding: '1.5rem 2rem',
                borderRadius: '8px',
                backgroundColor: 'white',
                border: '1px solid #ddd',
                boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'
            }}>
                <h1 style={{ fontSize: '1.8rem', marginBottom: '1rem', fontWeight: '500' }}>Create account</h1>

                <form onSubmit={handleRegister} style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
                    <div>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '700', marginBottom: '0.3rem' }}>Your name</label>
                        <input
                            type="text"
                            placeholder="First and last name"
                            style={{
                                width: '100%',
                                padding: '0.6rem',
                                borderRadius: '3px',
                                border: '1px solid #a6a6a6',
                                outline: 'none',
                                boxSizing: 'border-box'
                            }}
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '700', marginBottom: '0.3rem' }}>Email</label>
                        <input
                            type="email"
                            style={{
                                width: '100%',
                                padding: '0.6rem',
                                borderRadius: '3px',
                                border: '1px solid #a6a6a6',
                                outline: 'none',
                                boxSizing: 'border-box'
                            }}
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                        />
                    </div>
                    <div>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '700', marginBottom: '0.3rem' }}>Password</label>
                        <input
                            type="password"
                            placeholder="At least 6 characters"
                            style={{
                                width: '100%',
                                padding: '0.6rem',
                                borderRadius: '3px',
                                border: '1px solid #a6a6a6',
                                outline: 'none',
                                boxSizing: 'border-box'
                            }}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                        />
                        <div style={{ fontSize: '0.75rem', marginTop: '0.3rem', color: '#111' }}>
                            <i>!</i> Passwords must be at least 6 characters.
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={loading}
                        style={{
                            marginTop: '0.5rem',
                            padding: '0.6rem',
                            background: loading ? '#ddd' : 'linear-gradient(to bottom, #f7dfa1, #f0c14b)',
                            border: '1px solid #a88734 #9c7e31 #846a29',
                            borderRadius: '3px',
                            cursor: loading ? 'not-allowed' : 'pointer',
                            fontSize: '0.9rem',
                            fontWeight: '400'
                        }}
                    >
                        {loading ? "Creating account..." : "Continue"}
                    </button>

                    {message && (
                        <div style={{
                            padding: '0.8rem',
                            marginTop: '0.5rem',
                            fontSize: '0.8rem',
                            color: successful ? '#006621' : '#c40000',
                            backgroundColor: '#fff',
                            border: successful ? '1px solid #006621' : '1px solid #c40000',
                            borderRadius: '4px'
                        }}>
                            {message}
                        </div>
                    )}
                </form>

                <div style={{ marginTop: '1.5rem', fontSize: '0.75rem', lineHeight: '1.4' }}>
                    By creating an account, you agree to Amazon Clone's <Link href="#" style={{ color: '#0066c0', textDecoration: 'none' }}>Conditions of Use</Link> and <Link href="#" style={{ color: '#0066c0', textDecoration: 'none' }}>Privacy Notice</Link>.
                </div>

                <div style={{ marginTop: '1.5rem', paddingTop: '1rem', borderTop: '1px solid #e7e7e7', fontSize: '0.8rem' }}>
                    Already have an account? <Link href="/login" style={{ color: '#0066c0', textDecoration: 'none' }}>Sign in</Link>
                </div>
            </div>
        </div>
    );
}
