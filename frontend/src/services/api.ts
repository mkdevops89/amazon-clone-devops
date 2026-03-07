import axios from "axios";

const API_URL = "https://api.devcloudproject.com/api";

const api = axios.create({
    baseURL: API_URL,
    headers: {
        "Content-Type": "application/json",
    },
});

import { fetchAuthSession } from 'aws-amplify/auth';

api.interceptors.request.use(
    async (config) => {
        try {
            const session = await fetchAuthSession();
            if (session?.tokens?.accessToken) {
                config.headers["Authorization"] = `Bearer ${session.tokens.accessToken.toString()}`;
            }
        } catch (e) {
            // Not authenticated, send request anonymously.
        }
        return config;
    },
    (error) => {
        if (error.response && error.response.status === 401) {
            // If token is invalid (expired/bad), clear it so next request is anonymous
            localStorage.removeItem("user");
            // Optional: Redirect to login or just reload
            // window.location.href = "/login";
        }
        return Promise.reject(error);
    }
);

export default api;
