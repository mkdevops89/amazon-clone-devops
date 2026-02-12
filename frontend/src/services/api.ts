import axios from "axios";

const API_URL = "https://api.devcloudproject.com/api";

const api = axios.create({
    baseURL: API_URL,
    headers: {
        "Content-Type": "application/json",
    },
});

api.interceptors.request.use(
    (config) => {
        const user = typeof window !== "undefined" ? localStorage.getItem("user") : null;
        if (user) {
            const parsedUser = JSON.parse(user);
            if (parsedUser && parsedUser.accessToken) {
                config.headers["Authorization"] = "Bearer " + parsedUser.accessToken;
            }
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
