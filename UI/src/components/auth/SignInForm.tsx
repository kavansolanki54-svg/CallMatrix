"use client";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Button from "@/components/ui/button/Button";
import { EyeCloseIcon, EyeIcon } from "@/icons";
import { authService } from "@/lib/services";
import Link from "next/link";
import { useRouter } from "next/navigation";
import React, { useState } from "react";

export default function SignInForm() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const response = await authService.login({
        email,
        passwordHash: password,
      });

      if (response.success && response.data) {
        localStorage.setItem("token", response.data.token);
        localStorage.setItem("refreshToken", response.data.refreshToken);
        localStorage.setItem("user", JSON.stringify(response.data.user));
        router.push("/");
      } else {
        setError(response.message || "Invalid login credentials");
      }
    } catch (err: any) {
      console.error("Login failed", err);
      const status = err.response?.status;
      const serverMessage = err.response?.data?.message || err.response?.data?.Message;
      
      if (status === 404) {
        setError(serverMessage || "User not found");
      } else if (status === 401) {
        setError(serverMessage || "username and password is invalid");
      } else {
        setError(serverMessage || "Failed to connect to CallMatrix Web API");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1 lg:w-1/2 w-full justify-center p-6 md:p-12 relative overflow-hidden bg-gray-50/50 dark:bg-gray-900/30">
      {/* Premium ambient glow blobs */}
      <div className="absolute top-1/4 right-1/4 w-80 h-80 bg-brand-500/10 dark:bg-brand-500/15 rounded-full blur-[100px] -z-10 animate-pulse"></div>
      <div className="absolute bottom-1/4 left-1/4 w-80 h-80 bg-indigo-500/10 dark:bg-indigo-500/15 rounded-full blur-[100px] -z-10 animate-pulse"></div>

      <div className="flex flex-col justify-center w-full max-w-md mx-auto bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl border border-gray-100 dark:border-gray-800 p-8 rounded-2xl shadow-[0_20px_50px_rgba(0,0,0,0.08)] dark:shadow-[0_20px_50px_rgba(0,0,0,0.25)] relative transition-all duration-300 hover:shadow-[0_30px_60px_rgba(70,95,255,0.08)] dark:hover:shadow-[0_30px_60px_rgba(70,95,255,0.15)]">
        <div className="mb-8 text-center">
          <div className="w-14 h-14 mx-auto mb-4 rounded-2xl bg-gradient-to-tr from-brand-500 via-brand-600 to-indigo-600 flex items-center justify-center text-white font-extrabold text-2xl shadow-[0_8px_30px_rgb(70,95,255,0.3)] animate-bounce-slow">
            CM
          </div>
          <h1 className="text-2xl font-extrabold text-gray-900 dark:text-white mb-2 tracking-tight">
            Welcome back
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 font-medium">
            Sign in to access your dashboard & workspace
          </p>
        </div>

        {error && (
          <div className="mb-6 p-4 rounded-xl bg-red-50/80 dark:bg-red-950/20 border border-red-200/50 dark:border-red-800/40 text-red-600 dark:text-red-400 text-sm font-semibold flex items-center gap-2 animate-shake">
            <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="space-y-5">
            <div>
              <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1.5 block">Email Address</Label>
              <input
                type="email"
                placeholder="info@gmail.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full px-4 py-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200"
              />
            </div>
            <div>
              <Label className="text-gray-700 dark:text-gray-300 font-medium mb-1.5 block">Password</Label>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  placeholder="Enter password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="w-full px-4 py-3 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-gray-900/50 text-gray-900 dark:text-white focus:ring-2 focus:ring-brand-500/30 focus:border-brand-500 focus:outline-none transition-all duration-200"
                />
                <span
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                >
                  {showPassword ? <EyeIcon className="w-5 h-5" /> : <EyeCloseIcon className="w-5 h-5" />}
                </span>
              </div>
            </div>

            <div className="pt-2">
              <Button 
                type="submit" 
                className="w-full justify-center py-3 bg-gradient-to-r from-brand-600 to-indigo-600 hover:from-brand-500 hover:to-indigo-500 text-white font-semibold rounded-xl shadow-[0_8px_30px_rgb(70,95,255,0.2)] hover:shadow-[0_8px_30px_rgb(70,95,255,0.35)] active:scale-[0.98] transition-all duration-200 disabled:opacity-50"
                disabled={loading}
              >
                {loading ? "Signing in..." : "Sign In"}
              </Button>
            </div>
          </div>
        </form>

        <div className="mt-8 text-center border-t border-gray-100 dark:border-gray-800/80 pt-6">
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Don't have an account?{" "}
            <Link
              href="/signup"
              className="text-brand-500 hover:text-brand-600 dark:text-brand-400 font-bold transition-colors"
            >
              Sign Up
            </Link>
          </p>
        </div>
      </div>
    </div>
  );
}
