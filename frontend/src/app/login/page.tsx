"use client";

import { Authenticator, ThemeProvider, Theme, useTheme } from '@aws-amplify/ui-react';
import '@aws-amplify/ui-react/styles.css';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useEffect } from 'react';
import { fetchAuthSession } from 'aws-amplify/auth';

// -------------------------------------------------------------
// AWS Amplify Custom Theme: Amazon.com Persona
// By overriding Amplify's design tokens, we morph the default 
// Cognito UI into a pixel-perfect Amazon Sign-In replicate.
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
                borderRadius: { value: '3px' },
                _focus: {
                    borderColor: { value: '#e77600' }, // Amazon Orange Focus
                    boxShadow: { value: '0 0 3px 2px rgba(228,121,17,.5)' }
                }
            },
            text: {
            }
        },
    },
};

const components = {
    Header() {
        return (
            <div style={{ textAlign: 'center', marginBottom: '1.5rem', marginTop: '3rem' }}>
                <Link href="/" style={{ fontSize: '2.5rem', fontWeight: 'bold', textDecoration: 'none', color: 'black' }}>
                    Amazon<span style={{ color: '#ff9900' }}>Clone</span>
                </Link>
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
                <div>© 1996-2024, AmazonClone.com, Inc. or its affiliates</div>
            </div>
        );
    },
};

export default function Login() {
    const router = useRouter();

    useEffect(() => {
        // Check if they are already logged in to skip UI
        fetchAuthSession()
            .then((session) => {
                if (session.tokens) {
                    router.push('/');
                }
            })
            .catch(() => { /* not logged in, show UI */ });
    }, [router]);

    return (
        <div style={{
            minHeight: '100vh',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            background: 'linear-gradient(to bottom, #f0f2f2, #ffffff)',
            fontFamily: 'system-ui, -apple-system, sans-serif'
        }}>
            <ThemeProvider theme={amazonTheme}>
                <div style={{
                    width: '100%',
                    maxWidth: '350px',
                    padding: '1.5rem 2rem',
                    borderRadius: '8px',
                    backgroundColor: 'white',
                    border: '1px solid #ddd',
                    boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                    marginTop: '1rem',
                    marginBottom: '2rem'
                }}>
                    <Authenticator
                        components={components}
                        hideSignUp={false}
                    >
                        {({ signOut, user }) => {
                            // Immediately push them to the home page once Cognito validation succeeds!
                            // The next-js router will automatically synchronize with our Spring Boot API 
                            // on the next page load.
                            if (user) {
                                router.push("/");
                                setTimeout(() => window.location.reload(), 200);
                            }
                            return <></>;
                        }}
                    </Authenticator>
                </div>
            </ThemeProvider>
        </div>
    );
}
