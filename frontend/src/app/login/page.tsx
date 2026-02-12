"use client";

import { useState } from "react";
import Link from 'next/link';
import AuthService from "../../services/auth.service";
import { useRouter } from "next/navigation";

export default function Login() {
    const [username, setUsername] = useState("");
    const [password, setPassword] = useState("");
    const [loading, setLoading] = useState(false);
    const [message, setMessage] = useState("");
    const router = useRouter();

    const handleLogin = (e: React.FormEvent) => {
        e.preventDefault();
        setMessage("");
        setLoading(true);

        AuthService.login(username, password).then(
            () => {
                router.push("/");
                // We use a small delay or reload to ensure the UI updates with auth state
                setTimeout(() => {
                    window.location.reload();
                }, 500);
            },
            (error) => {
                const resMessage =
                    (error.response &&
                        error.response.data &&
                        error.response.data.message) ||
                    error.message ||
                    error.toString();

                setLoading(false);
                setMessage(resMessage);
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

            {/* Login Card */}
            <div style={{
                width: '100%',
                maxWidth: '350px',
                padding: '1.5rem 2rem',
                borderRadius: '8px',
                backgroundColor: 'white',
                border: '1px solid #ddd',
                boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)'
            }}>
                <h1 style={{ fontSize: '1.8rem', marginBottom: '1rem', fontWeight: '500' }}>Sign in</h1>

                <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '0.8rem' }}>
                    <div>
                        <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '700', marginBottom: '0.3rem' }}>Username</label>
                        <input
                            type="text"
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
                        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                            <label style={{ display: 'block', fontSize: '0.85rem', fontWeight: '700', marginBottom: '0.3rem' }}>Password</label>
                            <Link href="#" style={{ fontSize: '0.8rem', color: '#0066c0', textDecoration: 'none' }}>Forgot your password?</Link>
                        </div>
                        <input
                            type="password"
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
                        {loading ? "Signing in..." : "Sign in"}
                    </button>

                    {message && (
                        <div style={{
                            padding: '0.8rem',
                            marginTop: '0.5rem',
                            fontSize: '0.8rem',
                            color: '#c40000',
                            backgroundColor: '#fff',
                            border: '1px solid #c40000',
                            borderRadius: '4px'
                        }}>
                            {message}
                        </div>
                    )}
                </form>

                <div style={{ marginTop: '1.5rem', fontSize: '0.75rem', lineHeight: '1.4' }}>
                    By continuing, you agree to Amazon Clone's <Link href="#" style={{ color: '#0066c0', textDecoration: 'none' }}>Conditions of Use</Link> and <Link href="#" style={{ color: '#0066c0', textDecoration: 'none' }}>Privacy Notice</Link>.
                </div>
            </div>

            {/* New to Amazon */}
            <div style={{
                marginTop: '1.5rem',
                width: '100%',
                maxWidth: '350px',
                textAlign: 'center'
            }}>
                <div style={{
                    position: 'relative',
                    borderBottom: '1px solid #e7e7e7',
                    marginBottom: '1.2rem',
                    marginTop: '0.5rem'
                }}>
                    <span style={{
                        position: 'absolute',
                        top: '-10px',
                        left: '50%',
                        transform: 'translateX(-50%)',
                        background: '#fff',
                        padding: '0 10px',
                        color: '#767676',
                        fontSize: '0.75rem'
                    }}>New to Amazon?</span>
                </div>

                <Link href="/register" style={{ textDecoration: 'none', width: '100%' }}>
                    <button style={{
                        width: '100%',
                        padding: '0.5rem',
                        background: 'linear-gradient(to bottom, #f7f8fa, #e7e9ec)',
                        border: '1px solid #adb1b8',
                        borderRadius: '3px',
                        cursor: 'pointer',
                        fontSize: '0.8rem'
                    }}>
                        Create your Amazon account
                    </button>
                </Link>
            </div>
        </div>
    );
}
