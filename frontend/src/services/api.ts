import axios from "axios";

const API_URL = "http://localhost:8080/api";

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
            if (parsedUser.accessToken) {
                config.headers["Authorization"] = "Bearer " + parsedUser.accessToken;
            }
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

export default api;
