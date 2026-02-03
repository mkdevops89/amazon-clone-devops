import api from "./api";

const AUTH_URL = "/auth";

const register = (username: string, email: string, password: string, role?: string[]) => {
    return api.post(AUTH_URL + "/signup", {
        username,
        email,
        password,
        role
    });
};

const login = (username: string, password: string) => {
    return api
        .post(AUTH_URL + "/signin", {
            username,
            password,
        })
        .then((response) => {
            if (response.data.accessToken) {
                if (typeof window !== "undefined") {
                    localStorage.setItem("user", JSON.stringify(response.data));
                }
            }
            return response.data;
        });
};

const logout = () => {
    if (typeof window !== "undefined") {
        localStorage.removeItem("user");
    }
};

const getCurrentUser = () => {
    if (typeof window !== "undefined") {
        const userStr = localStorage.getItem("user");
        if (userStr) return JSON.parse(userStr);
    }
    return null;
};

const AuthService = {
    register,
    login,
    logout,
    getCurrentUser,
};

export default AuthService;
