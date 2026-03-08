"use client";

import { Authenticator, ThemeProvider, Theme, useAuthenticator, View } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useEffect } from 'react';
import { fetchAuthSession } from 'aws-amplify/auth';

// -------------------------------------------------------------
// AWS Amplify Custom Theme: Amazon.com Persona
// Overriding Amplify's design tokens
// -------------------------------------------------------------
const amazonTheme: Theme = {
    name: 'AmazonAuthTheme',
    tokens: {
        colors: {
            brand: {
                primary: {
                    10: '#f7dfa1',
                    20: '#f0c14b',
                    40: '#e4b335',
                    60: '#d7a422',
                    80: '#c59416',
                    90: '#b68710',
                    100: '#a87c06', // Amazon Yellow
                },
            },
            font: {
                interactive: { value: '#0066c0' }, // Amazon Blue links
            },
        },
        components: {
            authenticator: {
                router: {
                    borderWidth: { value: '0' },
                    backgroundColor: { value: 'transparent' },
                    boxShadow: { value: 'none' }, // Remove default glow/shadow
                },
            },
            button: {
                primary: {
                    backgroundColor: { value: 'linear-gradient(to bottom, #f7dfa1, #f0c14b)' },
                    borderColor: { value: '#a88734' },
                    color: { value: '#111' },
                    _hover: {
                        backgroundColor: { value: 'linear-gradient(to bottom, #f5d78e, #eeb933)' },
                        borderColor: { value: '#a88734' },
                        color: { value: '#111' }
                    },
                    _active: {
                        backgroundColor: { value: '#f0c14b' },
                        borderColor: { value: '#a88734' },
                    }
                },
                link: {
                    color: { value: '#0066c0' },
                    _hover: { color: { value: '#c45500' } }
                }
            },
            fieldcontrol: {
                paddingBlockStart: { value: '0.6rem' },
                paddingBlockEnd: { value: '0.6rem' },
                borderColor: { value: '#a6a6a6' },
                _focus: {
                    borderColor: { value: '#e77600' }, // Amazon Orange Focus
                    boxShadow: { value: '0 0 3px 2px rgba(228,121,17,.5)' }
                }
            },
        },
    },
};

const components = {
    Header() {
        return (
            <div style={{ textAlign: 'center', marginBottom: '1rem' }}>
                <h1 style={{ fontSize: '1.8rem', fontWeight: '500', textAlign: 'left', marginBottom: '1rem', color: '#111' }}>
                    Sign in
                </h1>
            </div>
        );
    },
    Footer() {
        return (
            <div style={{ textAlign: 'center', marginTop: '2rem', fontSize: '11px', color: '#555' }}>
                <div style={{ marginBottom: '10px' }}>
                    <span style={{ color: '#0066c0', cursor: 'pointer' }}>Conditions of Use</span> &nbsp;&nbsp;&nbsp;
                    <span style={{ color: '#0066c0', cursor: 'pointer' }}>Privacy Notice</span> &nbsp;&nbsp;&nbsp;
                    <span style={{ color: '#0066c0', cursor: 'pointer' }}>Help</span>
                </div>
                <div>© 1996-2026, AmazonClone.com, Inc. or its affiliates</div>
            </div>
        );
    },
    SignIn: {
        Footer() {
            const { toSignUp } = useAuthenticator();
            return (
                <View textAlign="center" padding="0">
                    <div style={{ marginTop: '1.5rem', fontSize: '0.75rem', lineHeight: '1.4', textAlign: 'left' }}>
                        By continuing, you agree to Amazon Clone's <span style={{ color: '#0066c0', cursor: 'pointer' }}>Conditions of Use</span> and <span style={{ color: '#0066c0', cursor: 'pointer' }}>Privacy Notice</span>.
                    </div>
                    {/* New to Amazon */}
                    <div style={{ marginTop: '1.5rem', width: '100%', textAlign: 'center' }}>
                        <div style={{ position: 'relative', borderBottom: '1px solid #e7e7e7', marginBottom: '1.2rem', marginTop: '0.5rem' }}>
                            <span style={{ position: 'absolute', top: '-10px', left: '50%', transform: 'translateX(-50%)', background: '#fff', padding: '0 10px', color: '#767676', fontSize: '0.75rem' }}>
                                New to Amazon?
                            </span>
                        </div>
                        <button
                            onClick={toSignUp}
                            style={{
                                width: '100%',
                                padding: '0.5rem',
                                background: 'linear-gradient(to bottom, #f7f8fa, #e7e9ec)',
                                border: '1px solid #adb1b8',
                                borderRadius: '3px',
                                cursor: 'pointer',
                                fontSize: '0.8rem',
                                color: '#111'
                            }}>
                            Create your Amazon account
                        </button>
                    </div>
                </View>
            );
        }
    }
};

export default function Login() {
    return (
        <Authenticator.Provider>
            <LoginInner />
        </Authenticator.Provider>
    );
}

function LoginInner() {
    const router = useRouter();

    // Handle redirect when user is authenticated
    const { user } = useAuthenticator((context) => [context.user]);
    useEffect(() => {
        if (user) {
            router.push("/");
            // Force a hard reload to clear cache and show logged-in state in Navbar
            setTimeout(() => window.location.reload(), 200);
        }
    }, [user, router]);

    // Handle initial session check
    useEffect(() => {
        fetchAuthSession()
            .then((session) => {
                if (session.tokens) {
                    router.push('/');
                }
            })
            .catch(() => { });
    }, [router]);

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            background: '#ffffff',
            fontFamily: 'system-ui, -apple-system, sans-serif'
        }}>
            <style>{`
                    .amplify-tabs { display: none !important; }
                    .amplify-router { box-shadow: none !important; border: none !important; }
                    [data-amplify-authenticator] { box-shadow: none !important; }
                `}</style>

            {/* 1. Logo Outside of typical box */}
            <div style={{ textAlign: 'center', marginBottom: '1rem', marginTop: '2rem' }}>
                <Link href="/" style={{ fontSize: '2.5rem', fontWeight: 'bold', textDecoration: 'none', color: 'black' }}>
                    Amazon<span style={{ color: '#ff9900' }}></span>
                </Link>
            </div>

            <ThemeProvider theme={amazonTheme}>
                <div style={{
                    width: '100%',
                    maxWidth: '350px',
                    padding: '1.5rem 2rem',
                    borderRadius: '8px',
                    backgroundColor: 'white',
                    border: '1px solid #ddd',
                    marginBottom: '2rem'
                }}>
                    <Authenticator
                        components={components}
                    >
                    </Authenticator>
                </div>
            </ThemeProvider>
        </div>
    );
}
